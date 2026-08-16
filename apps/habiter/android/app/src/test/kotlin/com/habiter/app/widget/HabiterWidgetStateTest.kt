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
