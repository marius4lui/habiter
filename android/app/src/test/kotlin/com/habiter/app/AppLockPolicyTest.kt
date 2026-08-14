package com.habiter.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppLockPolicyTest {
    @Test
    fun monitoringRequiresConsentPermissionsAndASelectedApp() {
        assertTrue(AppLockPolicy.shouldMonitor(true, true, true, 1))
        assertFalse(AppLockPolicy.shouldMonitor(false, true, true, 1))
        assertFalse(AppLockPolicy.shouldMonitor(true, false, true, 1))
        assertFalse(AppLockPolicy.shouldMonitor(true, true, false, 1))
        assertFalse(AppLockPolicy.shouldMonitor(true, true, true, 0))
    }

    @Test
    fun activePollingNeverUsesTheLegacyMainLoopInterval() {
        assertTrue(AppLockPolicy.ACTIVE_POLL_INTERVAL_MS >= 500L)
        assertTrue(AppLockPolicy.IDLE_POLL_INTERVAL_MS >= AppLockPolicy.ACTIVE_POLL_INTERVAL_MS)
    }
}
