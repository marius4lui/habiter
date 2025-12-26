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
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class AppMonitorService : Service() {
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_lock_channel"
        private const val POLL_INTERVAL_MS = 150L  // Reduced from 500ms for faster detection
        private const val BLOCK_COOLDOWN_MS = 1000L  // Prevent spam blocking
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var prefs: SharedPreferences
    
    // Race condition prevention
    private var lastBlockedPackage: String? = null
    private var lastBlockTime = 0L
    
    // Screen state tracking for battery optimization
    private var isScreenOn = true
    
    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (isScreenOn) {
                checkForegroundApp()
            }
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }
    
    // Screen on/off receiver to save battery
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    // Immediately check when screen turns on
                    handler.post { checkForegroundApp() }
                }
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
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
        
        // Start monitoring
        handler.post(monitorRunnable)
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(monitorRunnable)
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun checkForegroundApp() {
        val isEnabled = prefs.getBoolean("is_enabled", false)
        val habitsComplete = prefs.getBoolean("habits_complete", false)
        
        if (!isEnabled || habitsComplete) return
        
        val lockedPackages = prefs.getStringSet("locked_packages", emptySet()) ?: emptySet()
        if (lockedPackages.isEmpty()) return
        
        val foregroundPackage = getForegroundPackage()
        
        if (foregroundPackage != null && lockedPackages.contains(foregroundPackage)) {
            showBlockingScreen(foregroundPackage)
        }
    }
    
    private fun getForegroundPackage(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 500  // Reduced window for faster detection
        
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        var lastForegroundPackage: String? = null
        
        val event = UsageEvents.Event()
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastForegroundPackage = event.packageName
            }
        }
        
        return lastForegroundPackage
    }
    
    private fun showBlockingScreen(blockedPackage: String) {
        val now = System.currentTimeMillis()
        
        // Race condition prevention: Don't spam block the same app
        if (blockedPackage == lastBlockedPackage && 
            now - lastBlockTime < BLOCK_COOLDOWN_MS) {
            return
        }
        
        lastBlockedPackage = blockedPackage
        lastBlockTime = now
        
        // Get app name for display
        val blockedAppName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(blockedPackage, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            blockedPackage
        }
        
        // Get incomplete habit names from SharedPreferences
        val incompleteHabits = prefs.getStringSet("incomplete_habits", emptySet())
            ?.toList() ?: emptyList()
        
        // Show modern overlay
        BlockingOverlay.show(this, blockedAppName, incompleteHabits)
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
