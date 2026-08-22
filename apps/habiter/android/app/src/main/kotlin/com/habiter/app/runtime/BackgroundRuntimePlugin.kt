package com.habiter.app.runtime

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.habiter.app.HabiterRuntimeService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class BackgroundRuntimePlugin(private val activity: Activity) {
    private val state = RuntimeStateStore(activity)

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSnapshot" -> result.success(snapshot())
            "getDiagnostics" -> result.success(state.diagnostics())
            "reconcile" -> reconcile(call, result)
            "invalidateReminders" -> invalidateReminders(result)
            "openBatterySettings" -> {
                openBatterySettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun snapshot(): Map<String, Any?> {
        val features = state.features()
        return mapOf(
            "remindersEnabled" to features.remindersEnabled,
            "appBlockEnabled" to features.appBlockEnabled,
            "notificationsGranted" to NotificationManagerCompat
                .from(activity)
                .areNotificationsEnabled(),
            "batteryOptimized" to isBatteryOptimized(),
        )
    }

    private fun reconcile(call: MethodCall, result: MethodChannel.Result) {
        val features = RuntimeFeatureState(
            remindersEnabled = call.argument<Boolean>("remindersEnabled") ?: false,
            appBlockEnabled = call.argument<Boolean>("appBlockEnabled") ?: false,
        )
        state.setFeatures(features)
        activity.getSharedPreferences("app_lock", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("is_enabled", features.appBlockEnabled)
            .apply()
        runCatching {
            reconcileService(
                features,
                call.argument<String>("reason") ?: "feature_change",
            )
        }.onSuccess {
            result.success(null)
        }.onFailure {
            result.error(
                "runtime_reconcile_failed",
                "Background runtime could not be reconciled.",
                null,
            )
        }
    }

    private fun invalidateReminders(result: MethodChannel.Result) {
        val features = state.features()
        if (!features.remindersEnabled) {
            result.success(null)
            return
        }
        runCatching {
            startService(
                reason = "reminder_invalidation",
                action = HabiterRuntimeService.ACTION_EVALUATE_REMINDERS,
            )
        }.onSuccess {
            result.success(null)
        }.onFailure {
            result.error(
                "runtime_invalidation_failed",
                "Reminder runtime could not be invalidated.",
                null,
            )
        }
    }

    private fun reconcileService(features: RuntimeFeatureState, reason: String) {
        if (!features.shouldRun) {
            activity.stopService(Intent(activity, HabiterRuntimeService::class.java))
            return
        }
        startService(reason = reason)
    }

    private fun startService(reason: String, action: String? = null) {
        val intent = Intent(activity, HabiterRuntimeService::class.java).apply {
            this.action = action
            putExtra(HabiterRuntimeService.EXTRA_START_REASON, reason)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
    }

    private fun isBatteryOptimized(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val manager = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        return !manager.isIgnoringBatteryOptimizations(activity.packageName)
    }

    private fun openBatterySettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !isBatteryOptimized()) return
        activity.startActivity(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }
}
