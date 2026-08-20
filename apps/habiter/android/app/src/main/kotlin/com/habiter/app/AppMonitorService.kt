package com.habiter.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat

class AppMonitorService : Service() {
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_lock_channel"
        private const val INITIAL_USAGE_WINDOW_MS = 10_000L
        private const val TAG = "HabiterAppLock"
    }
    
    private lateinit var monitorThread: HandlerThread
    private lateinit var handler: Handler
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var prefs: SharedPreferences
    
    @Volatile
    private var foregroundPackage: String? = null
    @Volatile
    private var lastUsageQueryAt = 0L
    @Volatile
    private var suppressedBlockedPackage: String? = null
    
    // Screen state tracking for battery optimization
    @Volatile
    private var isScreenOn = true
    @Volatile
    private var monitoring = false
    
    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (isScreenOn && monitoring) {
                checkForegroundApp()
            }
            if (isScreenOn && monitoring) {
                handler.postDelayed(this, AppLockPolicy.ACTIVE_POLL_INTERVAL_MS)
            }
        }
    }
    
    // Screen on/off receiver to save battery
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    handler.removeCallbacks(monitorRunnable)
                    foregroundPackage = null
                    suppressedBlockedPackage = null
                    lastUsageQueryAt = System.currentTimeMillis()
                    BlockingOverlay.dismiss()
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    if (monitoring) handler.post(monitorRunnable)
                }
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        monitorThread = HandlerThread("habiter-app-lock-monitor").apply { start() }
        handler = Handler(monitorThread.looper)
        lastUsageQueryAt = System.currentTimeMillis() - INITIAL_USAGE_WINDOW_MS
        createNotificationChannel()
        
        // Register screen receiver
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        if (!monitoring) {
            monitoring = true
            handler.post(monitorRunnable)
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        monitoring = false
        handler.removeCallbacksAndMessages(null)
        monitorThread.quitSafely()
        BlockingOverlay.dismiss()
        runCatching { unregisterReceiver(screenReceiver) }
            .onFailure { Log.w(TAG, "Screen receiver cleanup failed", it) }
        super.onDestroy()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun checkForegroundApp() {
        val isEnabled = prefs.getBoolean("is_enabled", false)
        val blockedPackages = prefs.getStringSet("projected_blocked_packages", emptySet())
            ?.toSet() ?: emptySet()
        val usageAccess = hasUsageStatsPermission()
        val overlayAccess = Settings.canDrawOverlays(this)

        val observedForegroundPackage = if (usageAccess) getForegroundPackage() else null
        if (observedForegroundPackage != suppressedBlockedPackage) {
            suppressedBlockedPackage = null
        }

        val uiState = AppLockPolicy.blockingUiState(
            enabled = isEnabled,
            hasUsageAccess = usageAccess,
            hasOverlayAccess = overlayAccess,
            foregroundPackage = observedForegroundPackage,
            blockedPackages = blockedPackages,
        )
        when (uiState) {
            BlockingUiState.Hidden -> BlockingOverlay.dismiss()
            is BlockingUiState.Visible -> {
                if (uiState.blockedPackage == suppressedBlockedPackage) {
                    BlockingOverlay.dismiss()
                } else {
                    showBlockingScreen(uiState.blockedPackage)
                }
            }
        }

        if (isEnabled && (!usageAccess || !overlayAccess)) {
            BlockingOverlay.dismiss()
            prefs.edit().putBoolean("is_enabled", false).apply()
            stopSelf()
        }
    }
    
    private fun getForegroundPackage(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = lastUsageQueryAt.coerceAtMost(endTime)
        lastUsageQueryAt = endTime

        return runCatching {
            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
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
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }
    
    private fun showBlockingScreen(blockedPackage: String) {
        // Get app name for display
        val blockedAppName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(blockedPackage, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            Log.w(TAG, "Unable to resolve blocked app label", e)
            blockedPackage
        }
        
        // Get incomplete habit names from SharedPreferences
        val incompleteHabits = prefs.getStringSet("projection_blockers_$blockedPackage", emptySet())
            ?.sortedWith(String.CASE_INSENSITIVE_ORDER) ?: emptyList()
        
        BlockingOverlay.show(
            context = this,
            blockedPackage = blockedPackage,
            blockedAppName = blockedAppName,
            incompleteHabits = incompleteHabits,
            onLeaveBlockedApp = ::suppressUntilForegroundChanges,
        )
    }

    private fun suppressUntilForegroundChanges(blockedPackage: String) {
        suppressedBlockedPackage = blockedPackage
        BlockingOverlay.dismiss()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Lock"
            val descriptionText = "Monitoring locked apps until habits are complete"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Habiter App Lock")
            .setContentText("Complete your habits to unlock apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
