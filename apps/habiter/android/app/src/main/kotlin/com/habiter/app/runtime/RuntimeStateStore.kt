package com.habiter.app.runtime

import android.content.Context

class RuntimeStateStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val legacyAppLock = context.getSharedPreferences(APP_LOCK_PREFERENCES, Context.MODE_PRIVATE)

    fun features(): RuntimeFeatureState = RuntimeFeatureState(
        remindersEnabled = preferences.getBoolean(REMINDERS_ENABLED, false),
        appBlockEnabled = if (preferences.contains(APP_BLOCK_ENABLED)) {
            preferences.getBoolean(APP_BLOCK_ENABLED, false)
        } else {
            legacyAppLock.getBoolean(LEGACY_APP_LOCK_ENABLED, false)
        },
    )

    fun setFeatures(state: RuntimeFeatureState) {
        preferences.edit()
            .putBoolean(REMINDERS_ENABLED, state.remindersEnabled)
            .putBoolean(APP_BLOCK_ENABLED, state.appBlockEnabled)
            .apply()
    }

    fun setAppBlockEnabled(enabled: Boolean): RuntimeFeatureState {
        val next = features().copy(appBlockEnabled = enabled)
        setFeatures(next)
        return next
    }

    fun setRemindersEnabled(enabled: Boolean): RuntimeFeatureState {
        val next = features().copy(remindersEnabled = enabled)
        setFeatures(next)
        if (!enabled) setNextReminderEvaluation(null)
        return next
    }

    fun nextReminderEvaluation(): Long =
        preferences.getLong(NEXT_REMINDER_EVALUATION_AT, 0L)

    fun setNextReminderEvaluation(value: Long?) {
        preferences.edit().apply {
            if (value == null) remove(NEXT_REMINDER_EVALUATION_AT)
            else putLong(NEXT_REMINDER_EVALUATION_AT, value)
        }.apply()
    }

    fun recordStarted(reason: String, now: Long = System.currentTimeMillis()) {
        preferences.edit()
            .putLong(RUNTIME_STARTED_AT, now)
            .putLong(LAST_HEARTBEAT_AT, now)
            .putString(LAST_START_REASON, reason)
            .apply()
    }

    fun recordHeartbeat(now: Long = System.currentTimeMillis()) {
        preferences.edit().putLong(LAST_HEARTBEAT_AT, now).apply()
    }

    fun diagnostics(): Map<String, Any?> {
        val state = features()
        return mapOf(
            "remindersEnabled" to state.remindersEnabled,
            "appBlockEnabled" to state.appBlockEnabled,
            "runtimeStartedAt" to preferences.getLong(RUNTIME_STARTED_AT, 0L),
            "lastHeartbeatAt" to preferences.getLong(LAST_HEARTBEAT_AT, 0L),
            "lastReminderEvaluationAt" to preferences.getLong(LAST_REMINDER_EVALUATION_AT, 0L),
            "nextReminderEvaluationAt" to preferences.getLong(NEXT_REMINDER_EVALUATION_AT, 0L),
            "lastNotificationDispatchAt" to preferences.getLong(LAST_NOTIFICATION_DISPATCH_AT, 0L),
            "lastStartReason" to preferences.getString(LAST_START_REASON, null),
        )
    }

    companion object {
        const val PREFERENCES = "habiter_runtime"
        const val REMINDERS_ENABLED = "reminders_enabled"
        const val APP_BLOCK_ENABLED = "app_block_enabled"
        const val RUNTIME_STARTED_AT = "runtime_started_at"
        const val LAST_HEARTBEAT_AT = "last_heartbeat_at"
        const val LAST_REMINDER_EVALUATION_AT = "last_reminder_evaluation_at"
        const val NEXT_REMINDER_EVALUATION_AT = "next_reminder_evaluation_at"
        const val LAST_NOTIFICATION_DISPATCH_AT = "last_notification_dispatch_at"
        const val LAST_START_REASON = "last_start_reason"

        private const val APP_LOCK_PREFERENCES = "app_lock"
        private const val LEGACY_APP_LOCK_ENABLED = "is_enabled"
    }
}
