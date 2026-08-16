package com.habiter.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HabiterWidgetPinPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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
        AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, HabiterWidgetReceiver::class.java))
            .isNotEmpty()

    companion object {
        const val CHANNEL = "com.habiter.app/widget_pin"
        const val PREFERENCES = "habiter_widget_pin"
        const val RESULT_KEY = "result"
        private const val REQUEST_CODE = 7012
    }
}
