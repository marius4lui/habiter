package com.habiter.app

object AppLockPolicy {
    const val ACTIVE_POLL_INTERVAL_MS = 750L
    const val IDLE_POLL_INTERVAL_MS = 3_000L

    fun shouldMonitor(
        enabled: Boolean,
        hasUsageAccess: Boolean,
        hasOverlayAccess: Boolean,
        lockedPackageCount: Int,
    ): Boolean = enabled && hasUsageAccess && hasOverlayAccess && lockedPackageCount > 0
}
