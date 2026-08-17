package com.habiter.app

import android.app.DownloadManager
import java.net.URI

internal object UpdateSecurity {
    private val sha256Pattern = Regex("^[a-f0-9]{64}$")
    private val safeFileNamePattern = Regex("^[A-Za-z0-9][A-Za-z0-9._-]+\\.apk$")
    private val storeInstallers = setOf(
        "com.android.vending",
        "com.google.android.feedback"
    )

    fun isSecureArtifactUrl(value: String): Boolean = runCatching {
        val uri = URI(value)
        uri.scheme.equals("https", ignoreCase = true) && !uri.host.isNullOrBlank() && uri.userInfo == null
    }.getOrDefault(false)

    fun isValidSha256(value: String): Boolean = sha256Pattern.matches(value)

    fun isSafeApkFileName(value: String): Boolean = safeFileNamePattern.matches(value)

    fun sizeMatches(expected: Long, actual: Long): Boolean = expected > 0 && expected == actual

    fun digestMatches(expected: String, actual: String): Boolean =
        isValidSha256(expected) && expected.equals(actual, ignoreCase = false)

    fun signersMatch(installed: Set<String>, archive: Set<String>): Boolean =
        installed.isNotEmpty() && installed == archive

    fun effectiveDistribution(buildDistribution: String, installerSource: String?): String =
        if (buildDistribution == "store" || installerSource in storeInstallers) "play" else "direct"

    fun isNewerBuild(currentBuild: Long, targetBuild: Long): Boolean = targetBuild > currentBuild

    fun downloadPhase(status: Int): String = when (status) {
        DownloadManager.STATUS_PENDING -> "queued"
        DownloadManager.STATUS_RUNNING -> "running"
        DownloadManager.STATUS_PAUSED -> "paused"
        DownloadManager.STATUS_SUCCESSFUL -> "complete"
        DownloadManager.STATUS_FAILED -> "failed"
        else -> "missing"
    }
}
