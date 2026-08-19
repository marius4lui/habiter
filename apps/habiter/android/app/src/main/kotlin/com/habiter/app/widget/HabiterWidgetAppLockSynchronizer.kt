package com.habiter.app.widget

import android.content.Context

internal object HabiterWidgetAppLockSynchronizer {
    private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    private const val APP_LOCK_PREFERENCES = "app_lock"
    private const val COMPLETE_KEY = "habits_complete"
    private const val INCOMPLETE_KEY = "incomplete_habits"

    fun synchronize(context: Context) {
        val source = context
            .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            .getString(HabiterWidgetStateRepository.SNAPSHOT_KEY, null) ?: return
        val projection = runCatching { HabiterWidgetState.parse(source).appLock }.getOrNull() ?: return
        context.getSharedPreferences(APP_LOCK_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(COMPLETE_KEY, projection.complete)
            .putStringSet(INCOMPLETE_KEY, projection.incompleteHabitNames)
            .apply()
    }
}
