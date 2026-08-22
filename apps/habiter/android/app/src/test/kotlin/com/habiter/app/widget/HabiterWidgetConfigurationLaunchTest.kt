package com.habiter.app.widget

import android.appwidget.AppWidgetManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class HabiterWidgetConfigurationLaunchTest {
    @Test
    fun `accepts a valid host configuration launch`() {
        assertEquals(
            17,
            HabiterWidgetConfigurationLaunch.widgetId(
                AppWidgetManager.ACTION_APPWIDGET_CONFIGURE,
                17,
            ),
        )
    }

    @Test
    fun `rejects invalid ids and unrelated launches`() {
        assertNull(
            HabiterWidgetConfigurationLaunch.widgetId(
                AppWidgetManager.ACTION_APPWIDGET_CONFIGURE,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ),
        )
        assertNull(HabiterWidgetConfigurationLaunch.widgetId("unrelated", 17))
    }
}
