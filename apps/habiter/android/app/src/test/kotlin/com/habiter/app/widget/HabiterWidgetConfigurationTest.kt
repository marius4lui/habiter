package com.habiter.app.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HabiterWidgetConfigurationTest {
    private val habits = listOf(
        HabiterWidgetHabit("water", "Water", "💧", true, "Daily"),
        HabiterWidgetHabit("read", "Read", "📚", false, "Daily"),
        HabiterWidgetHabit("train", "Train", "🏋️", false, "3× per week"),
    )

    @Test
    fun `missing configuration preserves legacy defaults`() {
        val configuration = HabiterWidgetConfiguration.parseOrDefaults(null, 17)

        assertEquals(HabiterWidgetHabitFilter.ALL_TODAY, configuration.habitFilter)
        assertEquals(HabiterWidgetContentMode.AUTO, configuration.contentMode)
        assertEquals(HabiterWidgetThemeMode.SYSTEM, configuration.themeMode)
        assertEquals(HabiterWidgetProgressMode.AUTOMATIC, configuration.progressMode)
        assertTrue(configuration.showProgress)
        assertTrue(configuration.showCompleted)
        assertTrue(configuration.oneTapCompletion)
        assertEquals(habits, configuration.project(habits))
    }

    @Test
    fun `configuration roundtrips with isolated widget identity`() {
        val source = HabiterWidgetConfiguration(
            widgetId = 17,
            displayName = "Training",
            habitFilter = HabiterWidgetHabitFilter.SELECTED,
            selectedHabitIds = listOf("train"),
            contentMode = HabiterWidgetContentMode.FOCUS,
            breakpointOverrides = mapOf(
                HabiterWidgetLayout.COMPACT to HabiterWidgetBreakpointOverride(
                    contentMode = HabiterWidgetContentMode.MINIMAL,
                    maximumHabits = 1,
                ),
            ),
        )

        val restored = HabiterWidgetConfiguration.parse(source.toJson(), 17)
        val otherWidget = HabiterWidgetConfiguration.parseOrDefaults(source.toJson(), 18)

        assertEquals("Training", restored.displayName)
        assertEquals(listOf("train"), restored.project(habits).map { it.id })
        assertEquals(
            HabiterWidgetContentMode.MINIMAL,
            restored.effectiveFor(HabiterWidgetLayout.COMPACT).contentMode,
        )
        assertEquals(HabiterWidgetContentMode.AUTO, otherWidget.contentMode)
    }

    @Test
    fun `legacy schema migrates and invalid or future data falls back`() {
        val migrated = HabiterWidgetConfiguration.parseOrDefaults(
            """{"schemaVersion":0,"widgetId":17,"contentMode":"minimal","showProgress":false,"textScale":9}""",
            17,
        )
        val corrupted = HabiterWidgetConfiguration.parseOrDefaults("{not json", 17)
        val future = HabiterWidgetConfiguration.parseOrDefaults(
            """{"schemaVersion":99,"widgetId":17,"contentMode":"minimal"}""",
            17,
        )

        assertEquals(HabiterWidgetContentMode.MINIMAL, migrated.contentMode)
        assertFalse(migrated.showProgress)
        assertEquals(1.0, migrated.textScale, 0.0)
        assertEquals(HabiterWidgetContentMode.AUTO, corrupted.contentMode)
        assertEquals(HabiterWidgetContentMode.AUTO, future.contentMode)
    }

    @Test
    fun `selection ignores missing ids and breakpoint overrides layer safely`() {
        val configuration = HabiterWidgetConfiguration(
            widgetId = 17,
            habitFilter = HabiterWidgetHabitFilter.SELECTED,
            selectedHabitIds = listOf("deleted", "train", "not-today"),
            progressMode = HabiterWidgetProgressMode.SEGMENTS,
            cornerRadius = 24.0,
            hiddenElements = setOf(HabiterWidgetElement.SCHEDULE_LABEL),
            breakpointOverrides = mapOf(
                HabiterWidgetLayout.WIDE to HabiterWidgetBreakpointOverride(
                    progressMode = HabiterWidgetProgressMode.COUNTER,
                    outerPadding = 4.0,
                    textScale = 1.4,
                    hiddenElements = setOf(HabiterWidgetElement.HABIT_ICON),
                ),
            ),
        )

        val effective = configuration.effectiveFor(HabiterWidgetLayout.WIDE)

        assertEquals(listOf("train"), configuration.project(habits).map { it.id })
        assertEquals(HabiterWidgetProgressMode.COUNTER, effective.progressMode)
        assertEquals(4.0, effective.outerPadding!!, 0.0)
        assertEquals(24.0, effective.cornerRadius!!, 0.0)
        assertFalse(effective.shows(HabiterWidgetElement.SCHEDULE_LABEL))
        assertFalse(effective.shows(HabiterWidgetElement.HABIT_ICON))
    }
}
