package com.habiter.app

import org.junit.Assert.assertEquals
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

    @Test
    fun blockedForegroundAppShowsItsPackage() {
        assertEquals(
            BlockingUiState.Visible("app.blocked.a"),
            resolve(foregroundPackage = "app.blocked.a"),
        )
    }

    @Test
    fun launcherOrUnblockedAppDismissesTheBlockingUi() {
        assertEquals(BlockingUiState.Hidden, resolve(foregroundPackage = "launcher"))
        assertEquals(BlockingUiState.Hidden, resolve(foregroundPackage = "app.allowed"))
        assertEquals(BlockingUiState.Hidden, resolve(foregroundPackage = null))
        assertEquals(
            BlockingUiState.Hidden,
            AppLockPolicy.blockingUiState(
                enabled = true,
                hasUsageAccess = true,
                hasOverlayAccess = true,
                foregroundPackage = "app.blocked.a",
                blockedPackages = emptySet(),
            ),
        )
    }

    @Test
    fun switchingBetweenBlockedAppsUpdatesTheVisiblePackage() {
        assertEquals(
            BlockingUiState.Visible("app.blocked.a"),
            resolve(foregroundPackage = "app.blocked.a"),
        )
        assertEquals(
            BlockingUiState.Visible("app.blocked.b"),
            resolve(foregroundPackage = "app.blocked.b"),
        )
    }

    @Test
    fun disabledFeatureRevokedPermissionOrOpenProjectionDismissesTheUi() {
        assertEquals(
            BlockingUiState.Hidden,
            resolve(foregroundPackage = "app.blocked.a", enabled = false),
        )
        assertEquals(
            BlockingUiState.Hidden,
            resolve(foregroundPackage = "app.blocked.a", hasUsageAccess = false),
        )
        assertEquals(
            BlockingUiState.Hidden,
            resolve(foregroundPackage = "app.blocked.a", hasOverlayAccess = false),
        )
    }

    private fun resolve(
        foregroundPackage: String?,
        enabled: Boolean = true,
        hasUsageAccess: Boolean = true,
        hasOverlayAccess: Boolean = true,
        blockedPackages: Set<String> = setOf("app.blocked.a", "app.blocked.b"),
    ) = AppLockPolicy.blockingUiState(
        enabled = enabled,
        hasUsageAccess = hasUsageAccess,
        hasOverlayAccess = hasOverlayAccess,
        foregroundPackage = foregroundPackage,
        blockedPackages = blockedPackages,
    )
}
