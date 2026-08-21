package com.habiter.app.widget

internal data class HabiterWidgetPresentation(
    val content: HabiterWidgetContentState,
    val effective: EffectiveHabiterWidgetConfiguration,
)

internal object HabiterWidgetProjector {
    fun project(
        content: HabiterWidgetContentState,
        configuration: HabiterWidgetConfiguration,
        layout: HabiterWidgetLayout,
    ): HabiterWidgetPresentation {
        var effective = configuration.effectiveFor(layout)
        val source = content.stateOrNull
            ?: return HabiterWidgetPresentation(content, effective)
        if (content is HabiterWidgetContentState.Stale ||
            content is HabiterWidgetContentState.NoHabits
        ) {
            return HabiterWidgetPresentation(content, effective)
        }
        val selected = configuration.select(source.habits)
        var visible = if (configuration.showCompleted) {
            selected
        } else {
            selected.filterNot { it.completed }
        }
        val maximum = effective.maximumHabits ?: layout.defaultMaximumHabits
        if (visible.size > maximum) {
            when (effective.listSettings.overflowBehavior) {
                HabiterWidgetOverflowBehavior.TRUNCATE -> {
                    visible = if (effective.maximumHabits == null && layout.defaultMaximumHabits == 1) {
                        visible.focusHabit
                    } else {
                        visible.take(maximum)
                    }
                }
                HabiterWidgetOverflowBehavior.OPEN_ONLY -> {
                    visible = visible.filterNot { it.completed }.take(maximum)
                }
                HabiterWidgetOverflowBehavior.SWITCH_TO_FOCUS -> {
                    effective = effective.copy(contentMode = HabiterWidgetContentMode.FOCUS)
                    visible = visible.focusHabit.take(1)
                }
            }
        }
        if (effective.contentMode == HabiterWidgetContentMode.FOCUS ||
            effective.contentMode == HabiterWidgetContentMode.MINIMAL
        ) {
            visible = visible.focusHabit.take(1)
        }
        val projected = source.copy(
            completedCount = selected.count { it.completed },
            scheduledCount = selected.size,
            allComplete = selected.isNotEmpty() && selected.all { it.completed },
            habits = visible,
        )
        val lastCompletedWasSelected = projected.lastCompletion?.habitId?.let { id ->
            selected.any { it.id == id }
        } == true
        val shouldAdvance = effective.completionSettings.focusNextHabit ||
            effective.stateStyles.justCompleted == HabiterWidgetJustCompletedStyle.NEXT_HABIT
        val projectedContent = when {
            selected.isEmpty() -> HabiterWidgetContentState.FreeToday(projected)
            content is HabiterWidgetContentState.JustCompleted &&
                lastCompletedWasSelected &&
                !shouldAdvance -> HabiterWidgetContentState.JustCompleted(projected)
            projected.allComplete -> HabiterWidgetContentState.AllComplete(projected)
            else -> HabiterWidgetContentState.Active(projected)
        }
        return HabiterWidgetPresentation(projectedContent, effective)
    }
}

internal val HabiterWidgetLayout.defaultMaximumHabits: Int
    get() = when (this) {
        HabiterWidgetLayout.COMPACT,
        HabiterWidgetLayout.COMPACT_SQUARE,
        HabiterWidgetLayout.WIDE,
        HabiterWidgetLayout.MEDIUM_HERO,
        -> 1
        HabiterWidgetLayout.LARGE -> 3
        HabiterWidgetLayout.EXTRA_LARGE -> 6
    }

private val List<HabiterWidgetHabit>.focusHabit: List<HabiterWidgetHabit>
    get() {
        val pending = firstOrNull { !it.completed }
        return listOfNotNull(pending ?: firstOrNull())
    }

private val HabiterWidgetContentState.stateOrNull: HabiterWidgetState?
    get() = when (this) {
        HabiterWidgetContentState.Missing -> null
        is HabiterWidgetContentState.Stale -> state
        is HabiterWidgetContentState.NoHabits -> state
        is HabiterWidgetContentState.FreeToday -> state
        is HabiterWidgetContentState.AllComplete -> state
        is HabiterWidgetContentState.JustCompleted -> state
        is HabiterWidgetContentState.Active -> state
    }
