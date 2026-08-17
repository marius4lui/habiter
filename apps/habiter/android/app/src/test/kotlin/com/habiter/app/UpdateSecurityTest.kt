package com.habiter.app

import android.app.DownloadManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UpdateSecurityTest {
    @Test
    fun rejectsUnsafeUrlsAndFileNames() {
        assertTrue(UpdateSecurity.isSecureArtifactUrl("https://get.habiter.dev/habiter.apk"))
        assertFalse(UpdateSecurity.isSecureArtifactUrl("http://get.habiter.dev/habiter.apk"))
        assertFalse(UpdateSecurity.isSecureArtifactUrl("https://user@example.com/habiter.apk"))
        assertTrue(UpdateSecurity.isSafeApkFileName("habiter-1.5.0.apk"))
        assertFalse(UpdateSecurity.isSafeApkFileName("../habiter.apk"))
    }

    @Test
    fun verifiesSizeDigestAndSignerSetsExactly() {
        val digest = "a".repeat(64)
        assertTrue(UpdateSecurity.sizeMatches(42, 42))
        assertFalse(UpdateSecurity.sizeMatches(42, 41))
        assertTrue(UpdateSecurity.hasEnoughStorage(42, 42))
        assertFalse(UpdateSecurity.hasEnoughStorage(42, 41))
        assertTrue(UpdateSecurity.digestMatches(digest, digest))
        assertFalse(UpdateSecurity.digestMatches(digest, "b".repeat(64)))
        assertTrue(UpdateSecurity.signersMatch(setOf("one"), setOf("one")))
        assertFalse(UpdateSecurity.signersMatch(setOf("one"), setOf("other")))
    }

    @Test
    fun storeInstallSourcesAlwaysDisableDirectDistribution() {
        assertEquals("play", UpdateSecurity.effectiveDistribution("store", null))
        assertEquals("play", UpdateSecurity.effectiveDistribution("direct", "com.android.vending"))
        assertEquals("direct", UpdateSecurity.effectiveDistribution("direct", null))
        assertEquals("direct", UpdateSecurity.effectiveDistribution("direct", "com.google.android.packageinstaller"))
    }

    @Test
    fun mapsResumableDownloadManagerStates() {
        assertEquals("running", UpdateSecurity.downloadPhase(DownloadManager.STATUS_RUNNING))
        assertEquals("paused", UpdateSecurity.downloadPhase(DownloadManager.STATUS_PAUSED))
        assertEquals("complete", UpdateSecurity.downloadPhase(DownloadManager.STATUS_SUCCESSFUL))
        assertEquals("failed", UpdateSecurity.downloadPhase(DownloadManager.STATUS_FAILED))
    }

    @Test
    fun postsTheReadyNotificationOnlyForTheFirstAllowedVerification() {
        assertTrue(UpdateSecurity.shouldPostReadyNotification(false, true))
        assertFalse(UpdateSecurity.shouldPostReadyNotification(true, true))
        assertFalse(UpdateSecurity.shouldPostReadyNotification(false, false))
    }

    @Test
    fun acceptsOnlyStrictlyNewerApkBuilds() {
        assertTrue(UpdateSecurity.isNewerBuild(10_400, 10_500))
        assertFalse(UpdateSecurity.isNewerBuild(10_500, 10_500))
        assertFalse(UpdateSecurity.isNewerBuild(10_500, 10_400))
    }
}
