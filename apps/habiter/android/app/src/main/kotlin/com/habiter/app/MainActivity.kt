package com.habiter.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
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
import java.util.TimeZone
import android.util.Log
import com.habiter.app.widget.HabiterWidgetPinPlugin

open class MainActivity: FlutterActivity() {
    private val TAG = "HabiterAppLock"
    private val CHANNEL = "com.habiter.app/applock"
    private val TIME_ZONE_CHANNEL = "com.habiter.app/timezone"
    private val SETTINGS_CHANNEL = "com.habiter.app/settings"
    private val UPDATE_CHANNEL = "com.habiter.app/updates"
    private var updateMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(HabiterWidgetPinPlugin())
        val updateManager = UpdateManager(this)
        updateMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).also {
            it.setMethodCallHandler(updateManager::handle)
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = getInstalledNonSystemApps()
                    result.success(apps)
                }
                "getRecentUsage" -> {
                    result.success(getRecentUsage())
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
                "isBatteryOptimized" -> {
                    result.success(isBatteryOptimized())
                }
                "requestBatteryOptimizationExemption" -> {
                    requestBatteryOptimizationExemption()
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
                "updateIncompleteHabits" -> {
                    val habitNames = call.argument<List<String>>("habitNames") ?: emptyList()
                    updateIncompleteHabits(habitNames)
                    result.success(null)
                }
                "updateGateProjections" -> {
                    val projections = call.argument<List<Map<String, Any?>>>("projections") ?: emptyList()
                    updateGateProjections(projections)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIME_ZONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZoneId" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("openUpdateCenter", false)) {
            intent.removeExtra("openUpdateCenter")
            updateMethodChannel?.invokeMethod("openUpdateCenter", null)
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
            // Skip system apps and packages the user cannot launch.
            if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) continue
            // Skip our own app
            if (appInfo.packageName == packageName) continue
            if (pm.getLaunchIntentForPackage(appInfo.packageName) == null) continue
            
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
                Log.w(TAG, "Skipping an app that could not be inspected", e)
            }
        }
        
        return apps.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun getRecentUsage(): List<Map<String, Any?>> {
        if (!hasUsageStatsPermission()) return emptyList()
        val now = System.currentTimeMillis()
        val start = now - 7L * 24L * 60L * 60L * 1000L
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val launchable = getInstalledNonSystemApps().associateBy {
            it["packageName"] as String
        }
        return manager.queryAndAggregateUsageStats(start, now).values
            .filter { it.totalTimeInForeground > 0L && launchable.containsKey(it.packageName) }
            .map { stats ->
                mapOf(
                    "packageName" to stats.packageName,
                    "appName" to launchable[stats.packageName]?.get("appName"),
                    "foregroundMilliseconds" to stats.totalTimeInForeground,
                    "lastUsedMilliseconds" to stats.lastTimeUsed,
                )
            }
            .sortedByDescending { (it["foregroundMilliseconds"] as Long) }
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray? {
        return try {
            // Get or create bitmap from drawable
            val sourceBitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> {
                    val width = drawable.intrinsicWidth.coerceIn(1, 96)
                    val height = drawable.intrinsicHeight.coerceIn(1, 96)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                }
            }
            
            // Scale down to 48x48 for faster loading
            val scaledBitmap = Bitmap.createScaledBitmap(sourceBitmap, 48, 48, true)
            
            val stream = ByteArrayOutputStream()
            // Use JPEG at 70% quality for smaller size (much faster than PNG)
            scaledBitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            Log.w(TAG, "Unable to render an installed-app icon", e)
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

    private fun isBatteryOptimized(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            return !pm.isIgnoringBatteryOptimizations(packageName)
        }
        return false
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
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
        
        // Schedule watchdog to keep service alive
        WatchdogReceiver.schedule(this)
        
        return true
    }

    private fun stopMonitoringService() {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_enabled", false).apply()
        BlockingOverlay.dismiss()
        
        val intent = Intent(this, AppMonitorService::class.java)
        stopService(intent)
        
        // Cancel watchdog
        WatchdogReceiver.cancel(this)
    }

    private fun updateLockedApps(lockedPackages: List<String>) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet("locked_packages", lockedPackages.toSet())
            .apply()
        BlockingOverlay.reconcileLockedPackages(lockedPackages.toSet())
    }

    private fun notifyHabitsComplete(complete: Boolean) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("habits_complete", complete)
            .apply()
        
        // Dismiss overlay when habits are complete
        if (complete) {
            BlockingOverlay.dismiss()
        }
    }

    private fun updateIncompleteHabits(habitNames: List<String>) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet("incomplete_habits", habitNames.toSet())
            .apply()
    }

    private fun updateGateProjections(projections: List<Map<String, Any?>>) {
        val prefs = getSharedPreferences("app_lock", Context.MODE_PRIVATE)
        val previous = prefs.getStringSet("projected_packages", emptySet()) ?: emptySet()
        val editor = prefs.edit()
        previous.forEach { editor.remove("projection_blockers_$it") }

        val projected = mutableSetOf<String>()
        val blocked = mutableSetOf<String>()
        projections.forEach { projection ->
            val packageName = projection["packageName"] as? String ?: return@forEach
            projected += packageName
            if (projection["blocked"] == true) {
                blocked += packageName
                val blockers = (projection["blockers"] as? List<*>)
                    ?.mapNotNull { (it as? Map<*, *>)?.get("name") as? String }
                    ?.toSet()
                    ?: emptySet()
                editor.putStringSet("projection_blockers_$packageName", blockers)
            }
        }
        editor
            .putStringSet("projected_packages", projected)
            .putStringSet("projected_blocked_packages", blocked)
            .apply()
        BlockingOverlay.reconcileLockedPackages(blocked)
    }
}
