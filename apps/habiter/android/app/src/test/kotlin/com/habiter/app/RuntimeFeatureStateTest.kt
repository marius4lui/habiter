package com.habiter.app

import com.habiter.app.runtime.RuntimeFeatureState
import com.habiter.app.runtime.RuntimeRecoveryPolicy
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

    @Test
    fun `recovery only wakes for a future reminder evaluation`() {
        assertEquals(
            2_000L,
            RuntimeRecoveryPolicy.nextWakeAt(
                now = 1_000L,
                plannedEvaluationAt = 2_000L,
                remindersEnabled = true,
            ),
        )
        assertEquals(
            null,
            RuntimeRecoveryPolicy.nextWakeAt(
                now = 1_000L,
                plannedEvaluationAt = 2_000L,
                remindersEnabled = false,
            ),
        )
        assertEquals(
            null,
            RuntimeRecoveryPolicy.nextWakeAt(
                now = 2_000L,
                plannedEvaluationAt = 2_000L,
                remindersEnabled = true,
            ),
        )
    }
}
