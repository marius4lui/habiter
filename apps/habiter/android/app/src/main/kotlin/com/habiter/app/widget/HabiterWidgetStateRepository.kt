package com.habiter.app.widget

import android.content.SharedPreferences

object HabiterWidgetStateRepository {
    const val SNAPSHOT_KEY = "habiter_widget_snapshot"
    private val undoWindow = java.time.Duration.ofMinutes(5)

    fun read(preferences: SharedPreferences): HabiterWidgetContentState {
        val source = preferences.getString(SNAPSHOT_KEY, null)
            ?: return HabiterWidgetContentState.Missing
        val state = runCatching { HabiterWidgetState.parse(source) }.getOrNull()
            ?: return HabiterWidgetContentState.Stale()
        return project(state)
    }

    fun project(
        state: HabiterWidgetState,
        now: java.time.Instant = java.time.Instant.now(),
    ): HabiterWidgetContentState {
        if (state.stale) return HabiterWidgetContentState.Stale(state)
        if (!state.hasAnyHabits) return HabiterWidgetContentState.NoHabits(state)
        if (state.scheduledCount == 0) return HabiterWidgetContentState.FreeToday(state)
        if (state.lastCompletion != null &&
            !java.time.Duration.between(state.lastCompletion.completedAt, now).isNegative &&
            java.time.Duration.between(state.lastCompletion.completedAt, now) <= undoWindow
        ) return HabiterWidgetContentState.JustCompleted(state)
        if (state.allComplete) return HabiterWidgetContentState.AllComplete(state)
        return HabiterWidgetContentState.Active(state)
    }
}
