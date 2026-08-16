package com.habiter.app.widget

import android.content.SharedPreferences

object HabiterWidgetStateRepository {
    const val SNAPSHOT_KEY = "habiter_widget_snapshot"

    fun read(preferences: SharedPreferences): HabiterWidgetContentState {
        val source = preferences.getString(SNAPSHOT_KEY, null)
            ?: return HabiterWidgetContentState.Missing
        val state = runCatching { HabiterWidgetState.parse(source) }.getOrNull()
            ?: return HabiterWidgetContentState.Stale
        if (state.stale) return HabiterWidgetContentState.Stale
        if (!state.hasAnyHabits) return HabiterWidgetContentState.NoHabits
        if (state.scheduledCount == 0) return HabiterWidgetContentState.FreeToday
        if (state.allComplete) return HabiterWidgetContentState.AllComplete
        return HabiterWidgetContentState.Active(state)
    }
}
