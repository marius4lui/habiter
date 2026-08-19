package com.habiter.app

internal object AppLockPolicy {
    const val ACTIVE_POLL_INTERVAL_MS = 750L
    const val IDLE_POLL_INTERVAL_MS = 3_000L

    fun shouldMonitor(
        enabled: Boolean,
        hasUsageAccess: Boolean,
        hasOverlayAccess: Boolean,
        lockedPackageCount: Int,
    ): Boolean = enabled && hasUsageAccess && hasOverlayAccess && lockedPackageCount > 0

    fun blockingUiState(
        enabled: Boolean,
        hasUsageAccess: Boolean,
        hasOverlayAccess: Boolean,
        habitsComplete: Boolean,
        foregroundPackage: String?,
        lockedPackages: Set<String>,
    ): BlockingUiState {
        val shouldShow = enabled &&
            hasUsageAccess &&
            hasOverlayAccess &&
            !habitsComplete &&
            foregroundPackage != null &&
            foregroundPackage in lockedPackages
        return if (shouldShow) {
            BlockingUiState.Visible(requireNotNull(foregroundPackage))
        } else {
            BlockingUiState.Hidden
        }
    }
}

internal sealed interface BlockingUiState {
    data object Hidden : BlockingUiState

    data class Visible(val blockedPackage: String) : BlockingUiState
}
