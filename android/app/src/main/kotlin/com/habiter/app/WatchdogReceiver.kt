package com.habiter.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

/**
 * Watchdog receiver that periodically checks if AppMonitorService is running
 * and restarts it if necessary. This helps combat aggressive battery optimization
 * on devices from Xiaomi, Huawei, Samsung, etc.
 */
class WatchdogReceiver : BroadcastReceiver() {
    
    companion object {
        private const val WATCHDOG_INTERVAL_MS = 60_000L  // Check every 60 seconds
        private const val REQUEST_CODE = 2001
        
        /**
         * Schedule the watchdog alarm
         */
        fun schedule(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WatchdogReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            
            // Use setInexactRepeating to be battery-friendly
            alarmManager.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + WATCHDOG_INTERVAL_MS,
                WATCHDOG_INTERVAL_MS,
                pendingIntent
            )
        }
        
        /**
         * Cancel the watchdog alarm
         */
        fun cancel(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WatchdogReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
            )
            pendingIntent?.let { alarmManager.cancel(it) }
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("is_enabled", false)
        
        if (isEnabled) {
            // Restart service if app lock is enabled
            val serviceIntent = Intent(context, AppMonitorService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                // Service might already be running or system restrictions
            }
        }
    }
}
