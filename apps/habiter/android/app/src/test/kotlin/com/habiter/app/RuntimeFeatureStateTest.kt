package com.habiter.app

import com.habiter.app.runtime.RuntimeFeatureState
import org.junit.Assert.assertEquals
import org.junit.Test

class RuntimeFeatureStateTest {
    @Test
    fun `runtime only stops when both features are disabled`() {
        val cases = listOf(
            Triple(false, false, false),
            Triple(true, false, true),
            Triple(false, true, true),
            Triple(true, true, true),
        )

        cases.forEach { (reminders, appBlock, expected) ->
            assertEquals(
                expected,
                RuntimeFeatureState(reminders, appBlock).shouldRun,
            )
        }
    }

    @Test
    fun `notification text describes active features without App Lock ownership`() {
        assertEquals(
            "Reminders are running locally in the background.",
            RuntimeFeatureState(remindersEnabled = true, appBlockEnabled = false)
                .notificationText(),
        )
        assertEquals(
            "Reminders and App Block are active.",
            RuntimeFeatureState(remindersEnabled = true, appBlockEnabled = true)
                .notificationText(),
        )
    }
}
