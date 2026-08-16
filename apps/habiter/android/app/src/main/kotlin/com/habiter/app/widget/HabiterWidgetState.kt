package com.habiter.app.widget

import org.json.JSONObject
import java.time.Duration
import java.time.Instant

data class HabiterWidgetHabit(
    val id: String,
    val name: String,
    val icon: String,
    val completed: Boolean,
    val scheduleLabel: String,
)

data class HabiterWidgetCompletion(
    val habitId: String,
    val habitName: String,
    val actionId: String,
    val completedAt: Instant,
)

data class HabiterWidgetAppLockState(
    val complete: Boolean,
    val incompleteHabitNames: Set<String>,
)

data class HabiterWidgetState(
    val schemaVersion: Int,
    val generatedAt: Instant,
    val localDate: String,
    val locale: String,
    val completedCount: Int,
    val scheduledCount: Int,
    val allComplete: Boolean,
    val hasAnyHabits: Boolean,
    val habits: List<HabiterWidgetHabit>,
    val lastCompletion: HabiterWidgetCompletion?,
    val appLock: HabiterWidgetAppLockState?,
    val stale: Boolean,
) {
    val nextHabit: HabiterWidgetHabit?
        get() = habits.firstOrNull { !it.completed }

    companion object {
        const val CURRENT_SCHEMA_VERSION = 1
        private val maximumAge = Duration.ofHours(36)

        fun parse(source: String, now: Instant = Instant.now()): HabiterWidgetState {
            val root = JSONObject(source)
            val generatedAt = Instant.parse(root.getString("generatedAt"))
            val habitsJson = root.optJSONArray("habits")
            val habits = buildList {
                if (habitsJson != null) {
                    for (index in 0 until habitsJson.length()) {
                        val item = habitsJson.getJSONObject(index)
                        add(
                            HabiterWidgetHabit(
                                id = item.getString("id"),
                                name = item.getString("name"),
                                icon = item.optString("icon", "✓"),
                                completed = item.optBoolean("isCompleted", false),
                                scheduleLabel = item.optString("scheduleLabel", ""),
                            ),
                        )
                    }
                }
            }
            val completionJson = root.optJSONObject("lastCompletion")
            val completion = completionJson?.let {
                HabiterWidgetCompletion(
                    habitId = it.getString("habitId"),
                    habitName = it.getString("habitName"),
                    actionId = it.getString("actionId"),
                    completedAt = Instant.parse(it.getString("completedAt")),
                )
            }
            val schemaVersion = root.optInt("schemaVersion", 0)
            val appLockJson = root.optJSONObject("appLock")
            val appLock = appLockJson?.let {
                val names = it.optJSONArray("incompleteHabitNames")
                HabiterWidgetAppLockState(
                    complete = it.optBoolean("complete", false),
                    incompleteHabitNames = buildSet {
                        if (names != null) {
                            for (index in 0 until names.length()) add(names.getString(index))
                        }
                    },
                )
            }
            return HabiterWidgetState(
                schemaVersion = schemaVersion,
                generatedAt = generatedAt,
                localDate = root.getString("localDate"),
                locale = root.optString("locale", "en"),
                completedCount = root.optInt("completedCount", 0),
                scheduledCount = root.optInt("scheduledCount", habits.size),
                allComplete = root.optBoolean("allComplete", false),
                hasAnyHabits = root.optBoolean("hasAnyHabits", habits.isNotEmpty()),
                habits = habits,
                lastCompletion = completion,
                appLock = appLock,
                stale = schemaVersion != CURRENT_SCHEMA_VERSION ||
                    Duration.between(generatedAt, now) > maximumAge,
            )
        }
    }
}

sealed interface HabiterWidgetContentState {
    data object Missing : HabiterWidgetContentState
    data object Stale : HabiterWidgetContentState
    data object NoHabits : HabiterWidgetContentState
    data object FreeToday : HabiterWidgetContentState
    data object AllComplete : HabiterWidgetContentState
    data class JustCompleted(val state: HabiterWidgetState) : HabiterWidgetContentState
    data class Active(val state: HabiterWidgetState) : HabiterWidgetContentState
}
