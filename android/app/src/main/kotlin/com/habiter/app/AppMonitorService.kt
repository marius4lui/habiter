package com.habiter.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
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
        private const val POLL_INTERVAL_MS = 500L
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var prefs: SharedPreferences
    
    private val monitorRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        createNotificationChannel()
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
            // Show blocking screen
            showBlockingScreen(foregroundPackage)
        }
    }
    
    private fun getForegroundPackage(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000
        
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
        val intent = Intent(this, BlockingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_package", blockedPackage)
        }
        startActivity(intent)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Lock"
            val descriptionText = "Monitoring locked apps"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
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
            .build()
    }
}
