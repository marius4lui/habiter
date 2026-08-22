package com.habiter.app.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.os.Bundle
import com.habiter.app.MainActivity

class HabiterWidgetConfigurationActivity : MainActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(Activity.RESULT_CANCELED)
        if (HabiterWidgetConfigurationLaunch.widgetId(
                action = intent?.action,
                widgetId = intent?.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                ) ?: AppWidgetManager.INVALID_APPWIDGET_ID,
            ) == null
        ) {
            finish()
        }
    }
}

internal object HabiterWidgetConfigurationLaunch {
    fun widgetId(action: String?, widgetId: Int): Int? = widgetId.takeIf {
        action == AppWidgetManager.ACTION_APPWIDGET_CONFIGURE &&
            it != AppWidgetManager.INVALID_APPWIDGET_ID
    }
}
