package com.habiter.app.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.time.LocalDate

class HabiterWidgetLifecycleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        requestRefresh(context, intent.action ?: "lifecycle")
    }

    companion object {
        fun requestRefresh(context: Context, reason: String) {
            val uri = Uri.Builder()
                .scheme("habiter-widget")
                .authority("refresh")
                .appendQueryParameter("habitId", "")
                .appendQueryParameter("localDate", LocalDate.now().toString())
                .appendQueryParameter("actionId", "refresh:$reason:${System.currentTimeMillis()}")
                .build()
            HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
        }
    }
}
