package com.habiter.app.widget

import android.app.PendingIntent
import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class HabiterWidgetPinPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "requestPin" -> result.success(requestPin())
            "pinResult" -> result.success(
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                    .getString(RESULT_KEY, "idle"),
            )
            "hasInstalledWidgets" -> result.success(hasInstalledWidgets())
            "listWidgetInstances" -> result.success(listWidgetInstances())
            "pendingWidgetConfiguration" -> result.success(pendingConfigurationWidgetId())
            "saveWidgetConfiguration" -> saveWidgetConfiguration(call, result)
            "resetWidgetConfiguration" -> resetWidgetConfiguration(call, result)
            "cancelWidgetConfiguration" -> {
                cancelWidgetConfiguration()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported

    private fun requestPin(): Boolean {
        if (!isSupported()) return false
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit().putString(RESULT_KEY, "requested").apply()
        val callbackIntent = Intent(context, HabiterWidgetPinResultReceiver::class.java)
        val callback = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            callbackIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return AppWidgetManager.getInstance(context).requestPinAppWidget(
            ComponentName(context, HabiterWidgetReceiver::class.java),
            null,
            callback,
        )
    }

    private fun hasInstalledWidgets(): Boolean =
        installedWidgetIds().isNotEmpty()

    private fun listWidgetInstances(): List<Map<String, Any>> {
        val manager = AppWidgetManager.getInstance(context)
        val widgetIds = installedWidgetIds()
        HabiterWidgetConfigurationRepository.prune(context, widgetIds.toSet())
        return widgetIds.map { widgetId ->
            val options = manager.getAppWidgetOptions(widgetId)
            val width = maxOf(
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0),
            )
            val height = maxOf(
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0),
            )
            val layout = HabiterWidgetLayout.forSize(width, height)
            val configuration = HabiterWidgetConfigurationRepository.read(context, widgetId)
            mapOf(
                "widgetId" to widgetId,
                "widthDp" to width,
                "heightDp" to height,
                "breakpoint" to layout.wireName,
                "configuration" to configuration.toJson(),
            )
        }
    }

    private fun saveWidgetConfiguration(call: MethodCall, result: MethodChannel.Result) {
        val widgetId = call.argument<Int>("widgetId")
        val source = call.argument<String>("configuration")
        if (widgetId == null || source == null) {
            result.error("invalid_widget_configuration", "Widget id and configuration are required.", null)
            return
        }
        if (widgetId !in installedWidgetIds()) {
            result.error("unknown_widget", "The widget instance is no longer installed.", null)
            return
        }
        val configuration = runCatching {
            HabiterWidgetConfiguration.parse(source, widgetId)
        }.getOrElse {
            result.error("invalid_widget_configuration", "The widget configuration is invalid.", null)
            return
        }
        if (!HabiterWidgetConfigurationRepository.save(context, configuration)) {
            result.error("widget_configuration_write_failed", "The widget configuration could not be saved.", null)
            return
        }
        HabiterWidgetReceiver.requestUpdate(context, widgetId)
        completeWidgetConfiguration(widgetId)
        result.success(null)
    }

    private fun resetWidgetConfiguration(call: MethodCall, result: MethodChannel.Result) {
        val widgetId = call.argument<Int>("widgetId")
        if (widgetId == null) {
            result.error("invalid_widget_id", "A widget id is required.", null)
            return
        }
        if (!HabiterWidgetConfigurationRepository.delete(context, intArrayOf(widgetId))) {
            result.error("widget_configuration_write_failed", "The widget configuration could not be reset.", null)
            return
        }
        if (widgetId in installedWidgetIds()) HabiterWidgetReceiver.requestUpdate(context, widgetId)
        result.success(null)
    }

    private fun installedWidgetIds(): IntArray =
        AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, HabiterWidgetReceiver::class.java))

    private fun pendingConfigurationWidgetId(): Int? {
        val host = activity as? HabiterWidgetConfigurationActivity ?: return null
        return HabiterWidgetConfigurationLaunch.widgetId(
            action = host.intent?.action,
            widgetId = host.intent?.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ) ?: AppWidgetManager.INVALID_APPWIDGET_ID,
        )
    }

    private fun completeWidgetConfiguration(widgetId: Int) {
        val host = activity as? HabiterWidgetConfigurationActivity ?: return
        if (pendingConfigurationWidgetId() != widgetId) return
        host.setResult(
            Activity.RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
        )
        host.finish()
    }

    private fun cancelWidgetConfiguration() {
        val host = activity as? HabiterWidgetConfigurationActivity ?: return
        host.setResult(Activity.RESULT_CANCELED)
        host.finish()
    }

    companion object {
        const val CHANNEL = "com.habiter.app/widget_pin"
        const val PREFERENCES = "habiter_widget_pin"
        const val RESULT_KEY = "result"
        private const val REQUEST_CODE = 7012
    }
}
