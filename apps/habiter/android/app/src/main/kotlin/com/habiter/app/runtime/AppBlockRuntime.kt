package com.habiter.app.runtime

import android.app.AppOpsManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.provider.Settings
import android.util.Log
import com.habiter.app.AppLockPolicy
import com.habiter.app.BlockingOverlay
import com.habiter.app.BlockingUiState

internal class AppBlockRuntime(
    private val service: Service,
    private val handler: Handler,
    private val runtimeState: RuntimeStateStore,
    private val onFeatureStateChanged: () -> Unit,
) {
    private val usageStatsManager =
        service.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private val preferences = service.getSharedPreferences("app_lock", Context.MODE_PRIVATE)

    private var foregroundPackage: String? = null
    private var lastUsageQueryAt = System.currentTimeMillis() - INITIAL_USAGE_WINDOW_MS
    private var suppressedBlockedPackage: String? = null
    private var screenOn = true
    private var polling = false

    private val poll = object : Runnable {
        override fun run() {
            if (!polling || !screenOn) return
            checkForegroundApp()
            if (polling && screenOn) {
                handler.postDelayed(this, AppLockPolicy.ACTIVE_POLL_INTERVAL_MS)
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    screenOn = false
                    handler.removeCallbacks(poll)
                    foregroundPackage = null
                    suppressedBlockedPackage = null
                    lastUsageQueryAt = System.currentTimeMillis()
                    BlockingOverlay.dismiss()
                }
                Intent.ACTION_SCREEN_ON -> {
                    screenOn = true
                    if (polling) handler.post(poll)
                }
            }
        }
    }

    init {
        service.registerReceiver(
            screenReceiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            },
        )
    }

    fun reconcile(enabled: Boolean) {
        if (enabled == polling) return
        polling = enabled
        handler.removeCallbacks(poll)
        if (enabled && screenOn) {
            handler.post(poll)
        } else {
            BlockingOverlay.dismiss()
        }
    }

    fun stop() {
        polling = false
        handler.removeCallbacks(poll)
        BlockingOverlay.dismiss()
        runCatching { service.unregisterReceiver(screenReceiver) }
            .onFailure { Log.w(TAG, "Screen receiver cleanup failed", it) }
    }

    private fun checkForegroundApp() {
        val usageAccess = hasUsageStatsPermission()
        val overlayAccess = Settings.canDrawOverlays(service)
        if (!usageAccess || !overlayAccess) {
            preferences.edit().putBoolean("is_enabled", false).apply()
            runtimeState.setAppBlockEnabled(false)
            polling = false
            BlockingOverlay.dismiss()
            onFeatureStateChanged()
            return
        }

        val observed = getForegroundPackage()
        if (observed != suppressedBlockedPackage) suppressedBlockedPackage = null
        val blockedPackages = preferences
            .getStringSet("projected_blocked_packages", emptySet())
            ?.toSet()
            ?: emptySet()
        when (
            val state = AppLockPolicy.blockingUiState(
                enabled = true,
                hasUsageAccess = true,
                hasOverlayAccess = true,
                foregroundPackage = observed,
                blockedPackages = blockedPackages,
            )
        ) {
            BlockingUiState.Hidden -> BlockingOverlay.dismiss()
            is BlockingUiState.Visible -> if (state.blockedPackage == suppressedBlockedPackage) {
                BlockingOverlay.dismiss()
            } else {
                showBlockingScreen(state.blockedPackage)
            }
        }
    }

    private fun getForegroundPackage(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = lastUsageQueryAt.coerceAtMost(endTime)
        lastUsageQueryAt = endTime
        return runCatching {
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    foregroundPackage = event.packageName
                }
            }
            foregroundPackage
        }.onFailure {
            foregroundPackage = null
            Log.w(TAG, "Unable to resolve foreground package", it)
        }.getOrNull()
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = service.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                service.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                service.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun showBlockingScreen(blockedPackage: String) {
        val appName = runCatching {
            val info = service.packageManager.getApplicationInfo(blockedPackage, 0)
            service.packageManager.getApplicationLabel(info).toString()
        }.getOrElse {
            Log.w(TAG, "Unable to resolve blocked app label", it)
            blockedPackage
        }
        val blockers = preferences
            .getStringSet("projection_blockers_$blockedPackage", emptySet())
            ?.sortedWith(String.CASE_INSENSITIVE_ORDER)
            ?: emptyList()
        BlockingOverlay.show(
            context = service,
            blockedPackage = blockedPackage,
            blockedAppName = appName,
            incompleteHabits = blockers,
            onLeaveBlockedApp = { packageName ->
                suppressedBlockedPackage = packageName
                BlockingOverlay.dismiss()
            },
        )
    }

    companion object {
        private const val INITIAL_USAGE_WINDOW_MS = 10_000L
        private const val TAG = "HabiterRuntime"
    }
}
