package com.habiter.app.runtime

data class RuntimeFeatureState(
    val remindersEnabled: Boolean,
    val appBlockEnabled: Boolean,
) {
    val shouldRun: Boolean
        get() = remindersEnabled || appBlockEnabled

    fun notificationText(): String = when {
        remindersEnabled && appBlockEnabled -> "Reminders and App Block are active."
        remindersEnabled -> "Reminders are running locally in the background."
        appBlockEnabled -> "App Block is active."
        else -> "Habiter background features are inactive."
    }
}
