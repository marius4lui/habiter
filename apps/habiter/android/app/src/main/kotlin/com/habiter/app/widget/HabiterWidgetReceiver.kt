package com.habiter.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
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
}
