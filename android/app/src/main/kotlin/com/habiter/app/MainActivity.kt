package com.habiter.app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.habiter.app/applock"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = getInstalledNonSystemApps()
                    result.success(apps)
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "startMonitoring" -> {
                    val lockedPackages = call.argument<List<String>>("lockedPackages") ?: emptyList()
                    val success = startMonitoringService(lockedPackages)
                    result.success(success)
                }
                "stopMonitoring" -> {
                    stopMonitoringService()
                    result.success(null)
                }
                "updateLockedApps" -> {
                    val lockedPackages = call.argument<List<String>>("lockedPackages") ?: emptyList()
                    updateLockedApps(lockedPackages)
                    result.success(null)
                }
                "habitsComplete" -> {
                    notifyHabitsComplete(true)
                    result.success(null)
                }
                "habitsIncomplete" -> {
                    notifyHabitsComplete(false)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledNonSystemApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any?>>()
        
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(android.content.pm.PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }
        
        for (appInfo in packages) {
            // Skip system apps
            if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) continue
            // Skip our own app
            if (appInfo.packageName == packageName) continue
            
            try {
                val appName = pm.getApplicationLabel(appInfo).toString()
                val iconDrawable = pm.getApplicationIcon(appInfo)
                val iconBytes = drawableToBytes(iconDrawable)
                
                apps.add(mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to appName,
                    "iconBytes" to iconBytes
                ))
            } catch (e: Exception) {
                // Skip apps we can't get info for
            }
        }
        
        return apps.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray? {
        return try {
            val bitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> {
                    val bitmap = Bitmap.createBitmap(
                        drawable.intrinsicWidth.coerceAtLeast(1),
                        drawable.intrinsicHeight.coerceAtLeast(1),
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                }
            }
            
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun hasOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(this)
    }

    private fun requestOverlayPermission() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun startMonitoringService(lockedPackages: List<String>): Boolean {
        if (!hasUsageStatsPermission()) return false
        
        // Save locked packages to SharedPreferences
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet("locked_packages", lockedPackages.toSet())
            .putBoolean("is_enabled", true)
            .apply()
        
        // Start the service
        val intent = Intent(this, AppMonitorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        return true
    }

    private fun stopMonitoringService() {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_enabled", false).apply()
        
        val intent = Intent(this, AppMonitorService::class.java)
        stopService(intent)
    }

    private fun updateLockedApps(lockedPackages: List<String>) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet("locked_packages", lockedPackages.toSet())
            .apply()
    }

    private fun notifyHabitsComplete(complete: Boolean) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("habits_complete", complete)
            .apply()
    }
}
