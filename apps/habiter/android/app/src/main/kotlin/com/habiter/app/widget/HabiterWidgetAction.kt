package com.habiter.app.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

object HabiterWidgetAction {
    val habitIdKey = ActionParameters.Key<String>("habitId")
    val localDateKey = ActionParameters.Key<String>("localDate")
    val actionIdKey = ActionParameters.Key<String>("actionId")
    val sourceActionIdKey = ActionParameters.Key<String>("sourceActionId")
}

class HabiterWidgetUndoActionCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val habitId = parameters[HabiterWidgetAction.habitIdKey] ?: return
        val localDate = parameters[HabiterWidgetAction.localDateKey] ?: return
        val sourceActionId = parameters[HabiterWidgetAction.sourceActionIdKey] ?: return
        val uri = Uri.Builder()
            .scheme("habiter-widget")
            .authority("undoCompletion")
            .appendQueryParameter("habitId", habitId)
            .appendQueryParameter("localDate", localDate)
            .appendQueryParameter("actionId", "undo:$sourceActionId")
            .appendQueryParameter("sourceActionId", sourceActionId)
            .build()
        HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
    }
}

class HabiterWidgetActionCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val habitId = parameters[HabiterWidgetAction.habitIdKey] ?: return
        val localDate = parameters[HabiterWidgetAction.localDateKey] ?: return
        val actionId = parameters[HabiterWidgetAction.actionIdKey] ?: return
        val uri = Uri.Builder()
            .scheme("habiter-widget")
            .authority("completeHabit")
            .appendQueryParameter("habitId", habitId)
            .appendQueryParameter("localDate", localDate)
            .appendQueryParameter("actionId", actionId)
            .build()
        HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
    }
}
