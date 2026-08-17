package com.habiter.app.widget

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class HabiterWidgetStateTest {
    @Test
    fun `snapshot parser preserves completion and next habit`() {
        val source = """
            {
              "schemaVersion": 1,
              "generatedAt": "2026-08-16T10:00:00Z",
              "localDate": "2026-08-16",
              "locale": "de",
              "completedCount": 1,
              "scheduledCount": 2,
              "allComplete": false,
              "hasAnyHabits": true,
              "habits": [
                {"id":"water","name":"Wasser","icon":"💧","isCompleted":true,"scheduleLabel":"Täglich"},
                {"id":"read","name":"Lesen","icon":"📚","isCompleted":false,"scheduleLabel":"Täglich"}
              ]
            }
        """.trimIndent()

        val state = HabiterWidgetState.parse(source, Instant.parse("2026-08-16T11:00:00Z"))

        assertFalse(state.stale)
        assertEquals("read", state.nextHabit?.id)
        assertEquals(1, state.completedCount)
        assertTrue(state.hasAnyHabits)
    }

    @Test
    fun `old snapshots become a safe stale state`() {
        val source = """
            {"schemaVersion":1,"generatedAt":"2026-08-14T00:00:00Z","localDate":"2026-08-14","locale":"en","completedCount":0,"scheduledCount":0,"allComplete":false,"hasAnyHabits":true,"habits":[]}
        """.trimIndent()

        val state = HabiterWidgetState.parse(source, Instant.parse("2026-08-16T00:00:01Z"))

        assertTrue(state.stale)
    }

    @Test
    fun `responsive size buckets cover compact wide hero large and tablet`() {
        assertEquals(HabiterWidgetLayout.COMPACT, HabiterWidgetLayout.forSize(110, 60))
        assertEquals(HabiterWidgetLayout.COMPACT_SQUARE, HabiterWidgetLayout.forSize(110, 110))
        assertEquals(HabiterWidgetLayout.COMPACT_SQUARE, HabiterWidgetLayout.forSize(180, 110))
        assertEquals(HabiterWidgetLayout.COMPACT_SQUARE, HabiterWidgetLayout.forSize(180, 180))
        assertEquals(HabiterWidgetLayout.WIDE, HabiterWidgetLayout.forSize(250, 70))
        assertEquals(HabiterWidgetLayout.MEDIUM_HERO, HabiterWidgetLayout.forSize(250, 120))
        assertEquals(HabiterWidgetLayout.MEDIUM_HERO, HabiterWidgetLayout.forSize(250, 180))
        assertEquals(HabiterWidgetLayout.LARGE, HabiterWidgetLayout.forSize(250, 250))
        assertEquals(HabiterWidgetLayout.EXTRA_LARGE, HabiterWidgetLayout.forSize(320, 300))
        assertEquals(HabiterWidgetLayout.COMPACT, HabiterWidgetLayout.forSize(179, 72))
        assertEquals(HabiterWidgetLayout.COMPACT_SQUARE, HabiterWidgetLayout.forSize(180, 199))
        assertEquals(HabiterWidgetLayout.WIDE, HabiterWidgetLayout.forSize(319, 99))
        assertEquals(HabiterWidgetLayout.MEDIUM_HERO, HabiterWidgetLayout.forSize(319, 189))
        assertEquals(HabiterWidgetLayout.LARGE, HabiterWidgetLayout.forSize(299, 259))
    }

    @Test
    fun `completion layouts reserve vertical space on narrow square widgets`() {
        val compact = HabiterWidgetCompletionLayout.forLayout(HabiterWidgetLayout.COMPACT)
        val square = HabiterWidgetCompletionLayout.forLayout(HabiterWidgetLayout.COMPACT_SQUARE)

        assertEquals(HabiterWidgetCompletionArrangement.INLINE, compact.transientArrangement)
        assertEquals(HabiterWidgetCompletionArrangement.ICON_ONLY, compact.settledArrangement)
        assertFalse(compact.showFullUndoLabel)
        assertEquals(HabiterWidgetCompletionArrangement.STACKED, square.transientArrangement)
        assertEquals(HabiterWidgetCompletionArrangement.STACKED, square.settledArrangement)
        assertTrue(square.showFullUndoLabel)
        assertTrue(square.showTransientStatus)
    }

    @Test
    fun `short wide completion layouts stay horizontal`() {
        val wide = HabiterWidgetCompletionLayout.forLayout(HabiterWidgetLayout.WIDE)

        assertEquals(HabiterWidgetCompletionArrangement.INLINE, wide.transientArrangement)
        assertEquals(HabiterWidgetCompletionArrangement.INLINE, wide.settledArrangement)
        assertEquals(1, wide.settledMessageMaxLines)
        assertFalse(wide.showTransientStatus)
    }

    @Test
    fun `completion copy is localized without losing compact undo affordance`() {
        assertEquals("Erledigt", HabiterWidgetCompletionCopy.status(isGerman = true))
        assertEquals("Completed", HabiterWidgetCompletionCopy.status(isGerman = false))
        assertEquals("Rückgängig", HabiterWidgetCompletionCopy.undoLabel(isGerman = true, full = true))
        assertEquals("Undo", HabiterWidgetCompletionCopy.undoLabel(isGerman = false, full = true))
        assertEquals("↶", HabiterWidgetCompletionCopy.undoLabel(isGerman = true, full = false))
        assertEquals("↶", HabiterWidgetCompletionCopy.undoLabel(isGerman = false, full = false))
    }

    @Test
    fun `undo semantics name the completed habit in both locales`() {
        assertEquals(
            "Abendroutine rückgängig machen",
            HabiterWidgetCompletionCopy.undoDescription("Abendroutine", isGerman = true),
        )
        assertEquals(
            "Undo Evening routine",
            HabiterWidgetCompletionCopy.undoDescription("Evening routine", isGerman = false),
        )
        assertEquals(
            "Alles für heute erledigt.",
            HabiterWidgetCompletionCopy.settledMessage(isGerman = true),
        )
        assertEquals(
            "Everything for today is done.",
            HabiterWidgetCompletionCopy.settledMessage(isGerman = false),
        )
    }

    @Test
    fun `widget launch reuses the root activity instead of stacking it`() {
        assertTrue(habiterWidgetLaunchFlags and Intent.FLAG_ACTIVITY_CLEAR_TOP != 0)
        assertTrue(habiterWidgetLaunchFlags and Intent.FLAG_ACTIVITY_SINGLE_TOP != 0)
    }

    @Test
    fun `snapshot exposes native app lock projection`() {
        val source = """
            {"schemaVersion":1,"generatedAt":"2026-08-16T10:00:00Z","localDate":"2026-08-16","locale":"en","completedCount":1,"scheduledCount":1,"allComplete":true,"hasAnyHabits":true,"habits":[],"appLock":{"complete":true,"incompleteHabitNames":[]}}
        """.trimIndent()

        val state = HabiterWidgetState.parse(source, Instant.parse("2026-08-16T10:01:00Z"))

        assertEquals(true, state.appLock?.complete)
        assertTrue(state.appLock?.incompleteHabitNames?.isEmpty() == true)
    }

    @Test
    fun `snapshot from the prior local day is stale after midnight`() {
        val source = """
            {"schemaVersion":1,"generatedAt":"2026-08-16T21:59:00Z","localDate":"2026-08-16","locale":"en","completedCount":0,"scheduledCount":1,"allComplete":false,"hasAnyHabits":true,"habits":[]}
        """.trimIndent()

        val state = HabiterWidgetState.parse(source, Instant.parse("2026-08-17T10:00:00Z"))

        assertTrue(state.stale)
    }

    @Test
    fun `content projection covers just completed and settled all complete states`() {
        val source = """
            {"schemaVersion":1,"generatedAt":"2026-08-16T10:00:00Z","localDate":"2026-08-16","locale":"de","completedCount":1,"scheduledCount":1,"allComplete":true,"hasAnyHabits":true,"habits":[{"id":"read","name":"Lesen","icon":"📚","isCompleted":true,"scheduleLabel":"Täglich"}],"lastCompletion":{"habitId":"read","habitName":"Lesen","actionId":"tap-1","completedAt":"2026-08-16T10:00:00Z"}}
        """.trimIndent()
        val parsed = HabiterWidgetState.parse(source, Instant.parse("2026-08-16T10:01:00Z"))

        val immediate = HabiterWidgetStateRepository.project(
            parsed,
            Instant.parse("2026-08-16T10:04:59Z"),
        )
        val settled = HabiterWidgetStateRepository.project(
            parsed,
            Instant.parse("2026-08-16T10:05:01Z"),
        )

        assertTrue(immediate is HabiterWidgetContentState.JustCompleted)
        assertTrue(settled is HabiterWidgetContentState.AllComplete)
    }
}
