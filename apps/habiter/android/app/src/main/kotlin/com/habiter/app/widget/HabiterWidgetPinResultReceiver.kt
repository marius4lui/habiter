package com.habiter.app.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class HabiterWidgetPinResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            HabiterWidgetConfigurationRepository.save(
                context,
                HabiterWidgetConfiguration.defaults(widgetId),
            )
        }
        context.getSharedPreferences(HabiterWidgetPinPlugin.PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(HabiterWidgetPinPlugin.RESULT_KEY, "pinned")
            .apply()
    }
}
