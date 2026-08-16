package com.habiter.app.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class HabiterWidgetPinResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        context.getSharedPreferences(HabiterWidgetPinPlugin.PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(HabiterWidgetPinPlugin.RESULT_KEY, "pinned")
            .apply()
    }
}
