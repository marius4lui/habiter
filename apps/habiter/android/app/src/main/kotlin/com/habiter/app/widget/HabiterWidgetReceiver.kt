package com.habiter.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class HabiterWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HabiterWidget>() {
    override val glanceAppWidget = HabiterWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        HabiterWidgetAppLockSynchronizer.synchronize(context)
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        HabiterWidgetLifecycleReceiver.requestRefresh(context, "enabled")
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        HabiterWidgetConfigurationRepository.delete(context, appWidgetIds)
        super.onDeleted(context, appWidgetIds)
    }

    companion object {
        fun requestUpdate(context: Context, appWidgetId: Int) {
            context.sendBroadcast(
                Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    component = ComponentName(context, HabiterWidgetReceiver::class.java)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                },
            )
        }
    }
}
