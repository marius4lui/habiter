package com.habiter.app.widget

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
        assertEquals(HabiterWidgetLayout.WIDE, HabiterWidgetLayout.forSize(250, 70))
        assertEquals(HabiterWidgetLayout.MEDIUM_HERO, HabiterWidgetLayout.forSize(250, 120))
        assertEquals(HabiterWidgetLayout.LARGE, HabiterWidgetLayout.forSize(250, 250))
        assertEquals(HabiterWidgetLayout.EXTRA_LARGE, HabiterWidgetLayout.forSize(320, 300))
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
}
