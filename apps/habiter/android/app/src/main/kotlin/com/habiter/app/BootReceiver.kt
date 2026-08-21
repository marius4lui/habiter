package com.habiter.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    private val tag = "HabiterAppLock"
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("app_lock", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("is_enabled", false)
            
            if (isEnabled) {
                // Start the monitoring service
                val serviceIntent = Intent(context, HabiterRuntimeService::class.java)
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    prefs.edit().putBoolean("is_enabled", false).apply()
                    Log.w(tag, "App Lock disabled because boot restart failed", e)
                }
                
                // Schedule watchdog to ensure service stays alive
                WatchdogReceiver.schedule(context)
            }
        }
    }
}
