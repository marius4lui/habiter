package com.habiter.app

import android.app.Activity
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability

internal class StoreUpdateCoordinator(private val activity: MainActivity) {
    private val manager: AppUpdateManager = AppUpdateManagerFactory.create(activity)
    private var downloadedBytes = 0L
    private var totalBytes = 0L
    private var lastStatus = InstallStatus.UNKNOWN
    private val listener = InstallStateUpdatedListener { state ->
        downloadedBytes = state.bytesDownloaded()
        totalBytes = state.totalBytesToDownload()
        lastStatus = state.installStatus()
    }

    init {
        manager.registerListener(listener)
    }

    fun start(immediate: Boolean, callback: (String) -> Unit) {
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                val type = if (immediate) AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE
                val options = AppUpdateOptions.newBuilder(type).build()
                val available = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE ||
                    (immediate && info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS)
                if (!available || !info.isUpdateTypeAllowed(options)) {
                    callback("unavailable")
                    return@addOnSuccessListener
                }
                manager.startUpdateFlow(info, activity, options)
                    .addOnSuccessListener { resultCode ->
                        lastStatus = when (resultCode) {
                            Activity.RESULT_OK -> InstallStatus.PENDING
                            Activity.RESULT_CANCELED -> InstallStatus.CANCELED
                            else -> InstallStatus.FAILED
                        }
                        callback(
                            when (resultCode) {
                                Activity.RESULT_OK -> "launched"
                                Activity.RESULT_CANCELED -> "canceled"
                                else -> "unavailable"
                            }
                        )
                    }
                    .addOnFailureListener { callback("unavailable") }
            }
            .addOnFailureListener { callback("unavailable") }
    }

    fun status(callback: (Map<String, Any?>) -> Unit) {
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                val status = info.installStatus().takeIf { it != InstallStatus.UNKNOWN } ?: lastStatus
                callback(statusMap(status))
            }
            .addOnFailureListener {
                callback(
                    mapOf(
                        "phase" to "failed",
                        "downloadedBytes" to downloadedBytes,
                        "totalBytes" to totalBytes,
                        "failureCode" to "store_update_status_failed",
                    )
                )
            }
    }

    fun complete(callback: (String) -> Unit) {
        manager.completeUpdate()
            .addOnSuccessListener { callback("launched") }
            .addOnFailureListener { callback("unavailable") }
    }

    fun resumeInterruptedImmediateUpdate() {
        manager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.updateAvailability() != UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                return@addOnSuccessListener
            }
            val options = AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()
            if (info.isUpdateTypeAllowed(options)) {
                manager.startUpdateFlow(info, activity, options)
            }
        }
    }

    fun dispose() = manager.unregisterListener(listener)

    private fun statusMap(status: Int): Map<String, Any?> = mapOf(
        "phase" to when (status) {
            InstallStatus.PENDING -> "queued"
            InstallStatus.DOWNLOADING, InstallStatus.INSTALLING -> "running"
            InstallStatus.DOWNLOADED, InstallStatus.INSTALLED -> "complete"
            InstallStatus.FAILED, InstallStatus.CANCELED -> "failed"
            else -> "missing"
        },
        "downloadedBytes" to downloadedBytes,
        "totalBytes" to totalBytes,
        "failureCode" to when (status) {
            InstallStatus.FAILED -> "store_update_failed"
            InstallStatus.CANCELED -> "store_update_canceled"
            else -> null
        },
    )
}
