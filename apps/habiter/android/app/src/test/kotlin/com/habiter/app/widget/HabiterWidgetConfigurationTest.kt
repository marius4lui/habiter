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

    @Test
    fun `preset baselines accept explicit serialized overrides`() {
        val minimal = HabiterWidgetConfiguration.parse(
            """{"schemaVersion":1,"widgetId":17,"preset":"minimal"}""",
            17,
        )
        val focus = HabiterWidgetConfiguration.parse(
            """{"schemaVersion":1,"widgetId":17,"preset":"focus","showProgress":true,"maximumHabits":2}""",
            17,
        )

        assertEquals(HabiterWidgetPreset.MINIMAL, minimal.preset)
        assertEquals(HabiterWidgetContentMode.MINIMAL, minimal.contentMode)
        assertFalse(minimal.showProgress)
        assertTrue(HabiterWidgetElement.TODAY_HEADER in minimal.hiddenElements)
        assertEquals(HabiterWidgetContentMode.FOCUS, focus.contentMode)
        assertTrue(focus.showProgress)
        assertEquals(2, focus.maximumHabits)
    }

    @Test
    fun `full cracked options roundtrip and resolve per breakpoint`() {
        val source = HabiterWidgetConfiguration(
            widgetId = 17,
            preset = HabiterWidgetPreset.DASHBOARD,
            accentMode = HabiterWidgetAccentMode.CUSTOM,
            density = HabiterWidgetDensity.COMPACT,
            surfaceTransparency = 0.2,
            listSettings = HabiterWidgetListSettings(
                completedPlacement = HabiterWidgetCompletedPlacement.END,
                pinnedHabitIds = listOf("train"),
                overflowBehavior = HabiterWidgetOverflowBehavior.SWITCH_TO_FOCUS,
            ),
            progressSettings = HabiterWidgetProgressSettings(
                segmentHeight = 8.0,
                segmentGap = 2.0,
                maximumSegments = 12,
                completedStyle = HabiterWidgetProgressCompletedStyle.MUTED,
                remainingStyle = HabiterWidgetProgressRemainingStyle.OUTLINE,
            ),
            completionSettings = HabiterWidgetCompletionSettings(
                buttonStyle = HabiterWidgetCompletionButtonStyle.WHOLE_ROW,
                showUndo = false,
                feedback = HabiterWidgetCompletionFeedback.DETAILED,
                focusNextHabit = true,
            ),
            geometry = HabiterWidgetGeometry(
                habitRowRadius = 18.0,
                buttonRadius = 12.0,
                horizontalPadding = 16.0,
                verticalPadding = 10.0,
                rowGap = 5.0,
                sectionGap = 11.0,
            ),
            typography = HabiterWidgetTypography(
                habitTitleSize = 20.0,
                secondaryTextSize = 12.0,
                counterSize = 16.0,
                fontWeight = HabiterWidgetFontWeight.BOLD,
            ),
            stateStyles = HabiterWidgetStateStyles(
                justCompleted = HabiterWidgetJustCompletedStyle.NEXT_HABIT,
                allComplete = HabiterWidgetAllCompleteStyle.ICON_ONLY,
                freeToday = HabiterWidgetFreeTodayStyle.MINIMAL,
                noHabits = HabiterWidgetNoHabitsStyle.COMPACT,
                missingStale = HabiterWidgetMissingStaleStyle.COMPACT,
            ),
            interactions = HabiterWidgetInteractionMap(
                background = HabiterWidgetBackgroundAction.NEXT_HABIT,
                habitRow = HabiterWidgetHabitRowAction.COMPLETE,
                completionControl = HabiterWidgetCompletionAction.OPEN_HABIT,
            ),
            breakpointOverrides = mapOf(
                HabiterWidgetLayout.EXTRA_LARGE to HabiterWidgetBreakpointOverride(
                    density = HabiterWidgetDensity.COMFORTABLE,
                    surfaceTransparency = 0.3,
                    geometry = HabiterWidgetGeometry(horizontalPadding = 24.0),
                    typography = HabiterWidgetTypography(habitTitleSize = 24.0),
                ),
            ),
        )

        val restored = HabiterWidgetConfiguration.parse(source.toJson(), 17)
        val effective = restored.effectiveFor(HabiterWidgetLayout.EXTRA_LARGE)

        assertEquals(listOf("train"), restored.listSettings.pinnedHabitIds)
        assertEquals(12, restored.progressSettings.maximumSegments)
        assertFalse(restored.completionSettings.showUndo)
        assertEquals(HabiterWidgetAllCompleteStyle.ICON_ONLY, restored.stateStyles.allComplete)
        assertEquals(HabiterWidgetHabitRowAction.COMPLETE, restored.interactions.habitRow)
        assertEquals(HabiterWidgetDensity.COMFORTABLE, effective.density)
        assertEquals(0.3, effective.surfaceTransparency, 0.0)
        assertEquals(24.0, effective.geometry.horizontalPadding!!, 0.0)
        assertEquals(18.0, effective.geometry.habitRowRadius!!, 0.0)
        assertEquals(24.0, effective.typography.habitTitleSize!!, 0.0)
        assertEquals(16.0, effective.typography.counterSize!!, 0.0)
    }

    @Test
    fun `pinned habits and completed placement remain deterministic`() {
        val configuration = HabiterWidgetConfiguration(
            widgetId = 17,
            listSettings = HabiterWidgetListSettings(
                pinnedHabitIds = listOf("train"),
                completedPlacement = HabiterWidgetCompletedPlacement.END,
            ),
        )

        assertEquals(listOf("train", "read", "water"), configuration.select(habits).map { it.id })
    }

    @Test
    fun `one tap off resolves completion control to open habit`() {
        val configuration = HabiterWidgetConfiguration(
            widgetId = 17,
            oneTapCompletion = false,
        )

        assertEquals(
            HabiterWidgetCompletionAction.OPEN_HABIT,
            configuration.effectiveFor(HabiterWidgetLayout.COMPACT).interactions.completionControl,
        )
    }
}
