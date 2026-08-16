package com.habiter.app.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class HabiterWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HabiterWidget>() {
    override val glanceAppWidget = HabiterWidget()
}
