package com.habiter.app.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class HabiterWidgetPresentationTest {
    private val source = HabiterWidgetState(
        schemaVersion = 1,
        generatedAt = Instant.parse("2026-08-16T10:00:00Z"),
        localDate = "2026-08-16",
        locale = "en",
        completedCount = 1,
        scheduledCount = 3,
        allComplete = false,
        hasAnyHabits = true,
        habits = listOf(
            HabiterWidgetHabit("water", "Water", "💧", true, "Daily"),
            HabiterWidgetHabit("read", "Read", "📚", false, "Daily"),
            HabiterWidgetHabit("train", "Train", "🏋️", false, "3× per week"),
        ),
        lastCompletion = null,
        appLock = null,
        stale = false,
    )

    @Test
    fun `two instances project independent habits and progress`() {
        val training = HabiterWidgetConfiguration(
            widgetId = 17,
            habitFilter = HabiterWidgetHabitFilter.SELECTED,
            selectedHabitIds = listOf("train"),
            contentMode = HabiterWidgetContentMode.FOCUS,
        )
        val all = HabiterWidgetConfiguration(widgetId = 18, contentMode = HabiterWidgetContentMode.LIST)

        val first = HabiterWidgetProjector.project(
            HabiterWidgetContentState.Active(source),
            training,
            HabiterWidgetLayout.MEDIUM_HERO,
        )
        val second = HabiterWidgetProjector.project(
            HabiterWidgetContentState.Active(source),
            all,
            HabiterWidgetLayout.MEDIUM_HERO,
        )

        val firstState = (first.content as HabiterWidgetContentState.Active).state
        val secondState = (second.content as HabiterWidgetContentState.Active).state
        assertEquals(listOf("train"), firstState.habits.map { it.id })
        assertEquals(1, firstState.scheduledCount)
        assertEquals(0, firstState.completedCount)
        assertEquals(3, secondState.scheduledCount)
        assertEquals(HabiterWidgetContentMode.FOCUS, first.effective.contentMode)
        assertEquals(HabiterWidgetContentMode.LIST, second.effective.contentMode)
    }

    @Test
    fun `default responsive layouts retain the next open habit at every breakpoint`() {
        val expectedVisibleCounts = mapOf(
            HabiterWidgetLayout.COMPACT to 1,
            HabiterWidgetLayout.COMPACT_SQUARE to 1,
            HabiterWidgetLayout.WIDE to 1,
            HabiterWidgetLayout.MEDIUM_HERO to 1,
            HabiterWidgetLayout.LARGE to 3,
            HabiterWidgetLayout.EXTRA_LARGE to 3,
        )

        expectedVisibleCounts.forEach { (layout, expectedCount) ->
            val presentation = HabiterWidgetProjector.project(
                HabiterWidgetContentState.Active(source),
                HabiterWidgetConfiguration.defaults(widgetId = 17),
                layout,
            )
            val projected = (presentation.content as HabiterWidgetContentState.Active).state

            assertEquals(layout.name, expectedCount, projected.habits.size)
            if (expectedCount == 1) {
                assertEquals(layout.name, "read", projected.habits.single().id)
            }
            assertEquals(layout.name, 1, projected.completedCount)
            assertEquals(layout.name, 3, projected.scheduledCount)
        }
    }

    @Test
    fun `deleted selections become a safe free-today state`() {
        val configuration = HabiterWidgetConfiguration(
            widgetId = 17,
            habitFilter = HabiterWidgetHabitFilter.SELECTED,
            selectedHabitIds = listOf("deleted", "not-today"),
        )

        val presentation = HabiterWidgetProjector.project(
            HabiterWidgetContentState.Active(source),
            configuration,
            HabiterWidgetLayout.COMPACT,
        )

        assertTrue(presentation.content is HabiterWidgetContentState.FreeToday)
    }

    @Test
    fun `hidden completed habits retain selected progress and done state`() {
        val completed = source.copy(
            completedCount = 1,
            scheduledCount = 1,
            allComplete = true,
            habits = listOf(source.habits.first()),
        )
        val presentation = HabiterWidgetProjector.project(
            HabiterWidgetContentState.AllComplete(completed),
            HabiterWidgetConfiguration(widgetId = 17, showCompleted = false),
            HabiterWidgetLayout.LARGE,
        )
        val state = (presentation.content as HabiterWidgetContentState.AllComplete).state

        assertTrue(state.habits.isEmpty())
        assertEquals(1, state.completedCount)
        assertEquals(1, state.scheduledCount)
    }

    @Test
    fun `advanced visibility hides completed habits at one breakpoint`() {
        val presentation = HabiterWidgetProjector.project(
            HabiterWidgetContentState.Active(source),
            HabiterWidgetConfiguration(
                widgetId = 17,
                breakpointOverrides = mapOf(
                    HabiterWidgetLayout.LARGE to HabiterWidgetBreakpointOverride(
                        hiddenElements = setOf(HabiterWidgetElement.COMPLETED_HABITS),
                    ),
                ),
            ),
            HabiterWidgetLayout.LARGE,
        )
        val state = (presentation.content as HabiterWidgetContentState.Active).state

        assertEquals(listOf("read", "train"), state.habits.map { it.id })
        assertEquals(1, state.completedCount)
        assertEquals(3, state.scheduledCount)
    }

    @Test
    fun `overflow can switch one instance to focus`() {
        val configuration = HabiterWidgetConfiguration(
            widgetId = 17,
            maximumHabits = 1,
            listSettings = HabiterWidgetListSettings(
                overflowBehavior = HabiterWidgetOverflowBehavior.SWITCH_TO_FOCUS,
            ),
        )

        val presentation = HabiterWidgetProjector.project(
            HabiterWidgetContentState.Active(source),
            configuration,
            HabiterWidgetLayout.LARGE,
        )

        assertEquals(HabiterWidgetContentMode.FOCUS, presentation.effective.contentMode)
        assertEquals(1, (presentation.content as HabiterWidgetContentState.Active).state.habits.size)
    }

    @Test
    fun `custom colors enforce text and interaction contrast`() {
        val palette = HabiterWidgetTheme.customPalette(
            HabiterWidgetColorTokens(
                surface = "#FFFFFF",
                surfaceAccent = "#FFFFFF",
                primary = "#FFFFFE",
                text = "#FFFFFF",
                mutedText = "#EEEEEE",
                success = "#FFFFFF",
            ),
        )

        assertTrue(HabiterWidgetTheme.contrast(palette.onSurface, palette.surface) >= 4.5)
        assertTrue(HabiterWidgetTheme.contrast(palette.onSurfaceMuted, palette.surface) >= 3.0)
        assertTrue(HabiterWidgetTheme.contrast(palette.primary, palette.surface) >= 4.5)
        assertTrue(HabiterWidgetTheme.contrast(palette.success, palette.surface) >= 3.0)
        assertFalse(palette.onSurface == palette.surface)
    }
}
