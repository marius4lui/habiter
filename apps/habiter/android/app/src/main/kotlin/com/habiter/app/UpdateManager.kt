package com.habiter.app

import android.Manifest
import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.ByteArrayOutputStream
import java.security.MessageDigest
import java.net.HttpURLConnection
import java.net.URL
import javax.net.ssl.HttpsURLConnection

internal class UpdateManager(private val activity: MainActivity) {
    private val downloads = activity.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val connectivity = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val preferences = activity.getSharedPreferences("habiter_updates", Context.MODE_PRIVATE)

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getRuntimeInfo" -> result.success(runtimeInfo())
                "getNetworkStatus" -> result.success(networkStatus())
                "fetchManifest" -> fetchManifest(call, result)
                "enqueueDownload" -> result.success(enqueue(call))
                "getDownloadStatus" -> result.success(downloadStatus(requiredId(call)))
                "verifyDownload" -> result.success(verifyDownload(requiredId(call), call))
                "removeDownload" -> {
                    removeDownload(requiredId(call))
                    result.success(null)
                }
                "clearDownloads" -> {
                    clearDownloads()
                    result.success(null)
                }
                "installUpdate" -> result.success(install(requiredId(call), requiredLong(call, "buildNumber")))
                "openInstallerPermission" -> {
                    openInstallerPermission(result)
                }
                "openStore" -> result.success(openStore())
                "storedDownloadBytes" -> result.success(storedDownloadBytes())
                "cleanupAfterUpgrade" -> {
                    cleanupAfterUpgrade(requiredLong(call, "currentBuild"))
                    result.success(null)
                }
                "consumePendingOpen" -> result.success(consumePendingOpen())
                else -> result.notImplemented()
            }
        } catch (error: UpdateFailure) {
            result.error(error.code, error.message, null)
        } catch (error: Exception) {
            result.error("update_platform_error", error.message, null)
        }
    }

    private fun runtimeInfo(): Map<String, Any?> {
        val installer = installerSource()
        val distribution = UpdateSecurity.effectiveDistribution(BuildConfig.HABITER_DISTRIBUTION, installer)
        return mapOf(
            "distribution" to distribution,
            "directInstallAllowed" to (distribution == "direct"),
            "installerSource" to installer
        )
    }

    private fun consumePendingOpen(): Boolean {
        val intent = activity.intent ?: return false
        val pending = intent.getBooleanExtra("openUpdateCenter", false)
        if (pending) intent.removeExtra("openUpdateCenter")
        return pending
    }

    private fun installerSource(): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.packageManager.getInstallSourceInfo(activity.packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            activity.packageManager.getInstallerPackageName(activity.packageName)
        }
    } catch (_: Exception) {
        null
    }

    private fun networkStatus(): Map<String, Any> {
        val network = connectivity.activeNetwork
        val capabilities = network?.let(connectivity::getNetworkCapabilities)
        val online = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true &&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        return mapOf("isOnline" to online, "isMetered" to connectivity.isActiveNetworkMetered)
    }

    private fun fetchManifest(call: MethodCall, result: MethodChannel.Result) {
        val url = requiredString(call, "url")
        val etag = call.argument<String>("etag")
        Thread({
            var connection: HttpsURLConnection? = null
            try {
                val endpoint = URL(url)
                if (endpoint.protocol != "https") throw UpdateFailure("unsafe_manifest_url")
                connection = endpoint.openConnection() as? HttpsURLConnection
                    ?: throw UpdateFailure("unsafe_manifest_url")
                connection.instanceFollowRedirects = false
                connection.connectTimeout = MANIFEST_TIMEOUT_MS
                connection.readTimeout = MANIFEST_TIMEOUT_MS
                connection.setRequestProperty("Accept", "application/json")
                connection.setRequestProperty("User-Agent", "Habiter/${BuildConfig.VERSION_NAME} Android")
                if (etag != null) connection.setRequestProperty("If-None-Match", etag)

                val statusCode = connection.responseCode
                val body = if (statusCode == HttpURLConnection.HTTP_OK) {
                    connection.inputStream.use { input ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        var total = 0
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            total += count
                            if (total > MAX_MANIFEST_BYTES) {
                                throw UpdateFailure("manifest_too_large")
                            }
                            output.write(buffer, 0, count)
                        }
                        output.toString(Charsets.UTF_8.name())
                    }
                } else {
                    ""
                }
                val response = mapOf(
                    "statusCode" to statusCode,
                    "body" to body,
                    "etag" to connection.getHeaderField("ETag"),
                )
                activity.runOnUiThread { result.success(response) }
            } catch (error: Exception) {
                Log.w(TAG, "Native manifest request failed", error)
                val code = (error as? UpdateFailure)?.code ?: "manifest_network_error"
                activity.runOnUiThread { result.error(code, error.message, null) }
            } finally {
                connection?.disconnect()
            }
        }, "habiter-manifest-fetch").start()
    }

    private fun enqueue(call: MethodCall): Long {
        requireDirectDistribution()
        val url = requiredString(call, "url")
        val fileName = requiredString(call, "fileName")
        val sha256 = requiredString(call, "sha256")
        val size = requiredLong(call, "size")
        val build = requiredLong(call, "buildNumber")
        if (!UpdateSecurity.isSecureArtifactUrl(url)) throw UpdateFailure("unsafe_url")
        if (!UpdateSecurity.isSafeApkFileName(fileName)) throw UpdateFailure("unsafe_file_name")
        if (!UpdateSecurity.isValidSha256(sha256)) throw UpdateFailure("invalid_hash")
        if (!UpdateSecurity.isNewerBuild(BuildConfig.VERSION_CODE.toLong(), build)) {
            throw UpdateFailure("stale_apk")
        }
        val root = updateDirectory()
        if (!UpdateSecurity.hasEnoughStorage(size, root.usableSpace)) {
            throw UpdateFailure("insufficient_storage")
        }
        val destination = File(root, fileName)
        if (destination.exists() && !destination.delete()) throw UpdateFailure("storage_unavailable")
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(activity.getString(R.string.update_download_title))
            .setMimeType(APK_MIME)
            .setAllowedOverMetered(call.argument<Boolean>("allowMetered") == true)
            .setAllowedOverRoaming(false)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(activity, Environment.DIRECTORY_DOWNLOADS, "updates/$fileName")
        val id = downloads.enqueue(request)
        metadata(id, JSONObject().apply {
            put("url", url)
            put("fileName", fileName)
            put("path", destination.absolutePath)
            put("sha256", sha256)
            put("size", size)
            put("buildNumber", build)
            put("verified", false)
        })
        return id
    }

    private fun downloadStatus(id: Long): Map<String, Any?> {
        downloads.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
            if (!cursor.moveToFirst()) return missingDownload()
            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val downloaded = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
            return mapOf(
                "phase" to UpdateSecurity.downloadPhase(status),
                "downloadedBytes" to downloaded.coerceAtLeast(0),
                "totalBytes" to total.coerceAtLeast(0),
                "failureCode" to if (status == DownloadManager.STATUS_FAILED) "download_manager_$reason" else null
            )
        }
    }

    private fun verifyDownload(id: Long, call: MethodCall): Map<String, Any?> {
        requireDirectDistribution()
        val metadata = metadata(id) ?: return invalid(id, "download_missing")
        val expectedHash = requiredString(call, "sha256")
        val expectedSize = requiredLong(call, "size")
        val expectedBuild = requiredLong(call, "buildNumber")
        val expectedVersion = requiredString(call, "version")
        if (
            metadata.optString("sha256") != expectedHash ||
            metadata.optLong("size") != expectedSize ||
            metadata.optLong("buildNumber") != expectedBuild
        ) return invalid(id, "metadata_mismatch")
        val file = verifiedPath(metadata) ?: return invalid(id, "download_missing")
        verificationFailure(metadata, file, expectedBuild)?.let { return invalid(id, it) }
        metadata.put("verified", true)
        metadata(id, metadata)
        showReadyNotificationOnce(expectedBuild, expectedVersion)
        return mapOf("valid" to true, "failureCode" to null)
    }

    private fun install(id: Long, expectedBuild: Long): String {
        requireDirectDistribution()
        val metadata = metadata(id) ?: throw UpdateFailure("download_missing")
        if (!metadata.optBoolean("verified") || metadata.optLong("buildNumber") != expectedBuild) {
            throw UpdateFailure("download_not_verified")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !activity.packageManager.canRequestPackageInstalls()) {
            return "permissionRequired"
        }
        val file = verifiedPath(metadata) ?: throw UpdateFailure("download_missing")
        verificationFailure(metadata, file, expectedBuild)?.let { failure ->
            removeDownload(id)
            throw UpdateFailure(failure)
        }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, APK_MIME)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        activity.startActivity(intent)
        return "launched"
    }

    private var installerPermissionResult: MethodChannel.Result? = null

    private fun openInstallerPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success("granted")
            return
        }
        requireDirectDistribution()
        if (installerPermissionResult != null) {
            result.error("installer_permission_in_progress", "Installer permission settings are already open.", null)
            return
        }
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:${activity.packageName}")
        }
        if (intent.resolveActivity(activity.packageManager) == null) {
            result.success("unavailable")
            return
        }
        installerPermissionResult = result
        try {
            activity.startActivityForResult(intent, INSTALLER_PERMISSION_REQUEST)
        } catch (_: Exception) {
            installerPermissionResult = null
            result.success("unavailable")
        }
    }

    fun handleActivityResult(requestCode: Int): Boolean {
        if (requestCode != INSTALLER_PERMISSION_REQUEST) return false
        val result = installerPermissionResult ?: return true
        installerPermissionResult = null
        val granted = Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            activity.packageManager.canRequestPackageInstalls()
        result.success(if (granted) "granted" else "denied")
        return true
    }

    private fun openStore(): Boolean {
        val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=${activity.packageName}"))
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=${activity.packageName}"))
        return try {
            activity.startActivity(market)
            true
        } catch (_: Exception) {
            try {
                activity.startActivity(web)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun removeDownload(id: Long) {
        downloads.remove(id)
        metadata(id)?.optString("path")?.takeIf(String::isNotBlank)?.let { File(it).delete() }
        preferences.edit().remove(metadataKey(id)).apply()
    }

    private fun storedDownloadBytes(): Long = updateDirectory().listFiles()
        ?.filter(File::isFile)
        ?.sumOf(File::length) ?: 0L

    private fun clearDownloads() {
        preferences.all.keys.filter { it.startsWith(METADATA_PREFIX) }.forEach { key ->
            key.removePrefix(METADATA_PREFIX).toLongOrNull()?.let(::removeDownload)
        }
        updateDirectory().listFiles()?.filter(File::isFile)?.forEach(File::delete)
    }

    private fun cleanupAfterUpgrade(currentBuild: Long) {
        preferences.all.keys.filter { it.startsWith(METADATA_PREFIX) }.forEach { key ->
            val id = key.removePrefix(METADATA_PREFIX).toLongOrNull() ?: return@forEach
            val item = metadata(id)
            if (item == null || item.optLong("buildNumber") <= currentBuild) removeDownload(id)
        }
        val knownPaths = preferences.all.keys.filter { it.startsWith(METADATA_PREFIX) }
            .mapNotNull { key -> key.removePrefix(METADATA_PREFIX).toLongOrNull()?.let(::metadata)?.optString("path") }
            .toSet()
        updateDirectory().listFiles()?.filter { it.absolutePath !in knownPaths }?.forEach(File::delete)
    }

    private fun showReadyNotificationOnce(build: Long, version: String) {
        val notifiedKey = "notified_$build"
        if (!UpdateSecurity.shouldPostReadyNotification(
                preferences.getBoolean(notifiedKey, false),
                notificationsAllowed()
            )
        ) return
        val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                UPDATE_CHANNEL,
                activity.getString(R.string.update_ready_channel),
                NotificationManager.IMPORTANCE_DEFAULT
            ))
        }
        val intent = Intent(activity, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("openUpdateCenter", true)
        }
        val pending = PendingIntent.getActivity(
            activity,
            build.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(activity, UPDATE_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(activity.getString(R.string.update_ready_title))
            .setContentText(activity.getString(R.string.update_ready_body, version))
            .setContentIntent(pending)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()
        try {
            NotificationManagerCompat.from(activity).notify(READY_NOTIFICATION_BASE + build.toInt(), notification)
            preferences.edit().putBoolean(notifiedKey, true).commit()
        } catch (_: SecurityException) {
            // Notification permission can be revoked between the explicit check and posting.
        }
    }

    private fun notificationsAllowed(): Boolean {
        if (!NotificationManagerCompat.from(activity).areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    private fun archivePackage(file: File): PackageInfo? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        activity.packageManager.getPackageArchiveInfo(
            file.absolutePath,
            PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong())
        )
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        @Suppress("DEPRECATION")
        activity.packageManager.getPackageArchiveInfo(file.absolutePath, PackageManager.GET_SIGNING_CERTIFICATES)
    } else {
        @Suppress("DEPRECATION")
        activity.packageManager.getPackageArchiveInfo(file.absolutePath, PackageManager.GET_SIGNATURES)
    }

    private fun installedPackage(): PackageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        activity.packageManager.getPackageInfo(
            activity.packageName,
            PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong())
        )
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        @Suppress("DEPRECATION")
        activity.packageManager.getPackageInfo(activity.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
    } else {
        @Suppress("DEPRECATION")
        activity.packageManager.getPackageInfo(activity.packageName, PackageManager.GET_SIGNATURES)
    }

    private fun signerDigests(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signing = info.signingInfo ?: return emptySet()
            if (signing.hasMultipleSigners()) signing.apkContentsSigners else signing.signingCertificateHistory
        } else {
            @Suppress("DEPRECATION")
            info.signatures ?: emptyArray()
        }
        return signatures.map { bytesToHex(MessageDigest.getInstance("SHA-256").digest(it.toByteArray())) }.toSet()
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return bytesToHex(digest.digest())
    }

    private fun verificationFailure(metadata: JSONObject, file: File, expectedBuild: Long): String? {
        val expectedSize = metadata.optLong("size")
        val expectedHash = metadata.optString("sha256")
        if (!UpdateSecurity.sizeMatches(expectedSize, file.length())) return "wrong_size"
        if (!UpdateSecurity.digestMatches(expectedHash, sha256(file))) return "wrong_hash"
        val archive = archivePackage(file) ?: return "invalid_apk"
        if (archive.packageName != activity.packageName) return "foreign_package"
        if (
            archive.longVersionCodeCompat() != expectedBuild ||
            !UpdateSecurity.isNewerBuild(BuildConfig.VERSION_CODE.toLong(), expectedBuild)
        ) return "stale_apk"
        return if (UpdateSecurity.signersMatch(signerDigests(installedPackage()), signerDigests(archive))) {
            null
        } else {
            "foreign_signer"
        }
    }

    private fun verifiedPath(metadata: JSONObject): File? {
        val root = updateDirectory().canonicalFile
        val file = File(metadata.optString("path")).canonicalFile
        if (!file.path.startsWith(root.path + File.separator) || !file.isFile) return null
        return file
    }

    private fun updateDirectory(): File {
        val downloadsRoot = activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw UpdateFailure("storage_unavailable")
        return File(downloadsRoot, "updates").also {
            if (!it.exists() && !it.mkdirs()) throw UpdateFailure("storage_unavailable")
        }
    }

    private fun invalid(id: Long, code: String): Map<String, Any?> {
        removeDownload(id)
        return mapOf("valid" to false, "failureCode" to code)
    }

    private fun requireDirectDistribution() {
        if (runtimeInfo()["directInstallAllowed"] != true) throw UpdateFailure("direct_install_forbidden")
    }

    private fun metadata(id: Long): JSONObject? = preferences.getString(metadataKey(id), null)?.let {
        runCatching { JSONObject(it) }.getOrNull()
    }

    private fun metadata(id: Long, value: JSONObject) {
        preferences.edit().putString(metadataKey(id), value.toString()).apply()
    }

    private fun requiredId(call: MethodCall): Long = requiredString(call, "downloadId").toLongOrNull()
        ?: throw UpdateFailure("invalid_download_id")

    private fun requiredString(call: MethodCall, name: String): String = call.argument<String>(name)
        ?.takeIf(String::isNotBlank) ?: throw UpdateFailure("invalid_$name")

    private fun requiredLong(call: MethodCall, name: String): Long = call.argument<Number>(name)?.toLong()
        ?.takeIf { it > 0 } ?: throw UpdateFailure("invalid_$name")

    private fun missingDownload(): Map<String, Any?> = mapOf(
        "phase" to "missing",
        "downloadedBytes" to 0L,
        "totalBytes" to 0L,
        "failureCode" to "download_missing"
    )

    private fun metadataKey(id: Long) = "$METADATA_PREFIX$id"

    private fun PackageInfo.longVersionCodeCompat(): Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        longVersionCode
    } else {
        @Suppress("DEPRECATION")
        versionCode.toLong()
    }

    private fun bytesToHex(bytes: ByteArray): String = bytes.joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }

    private class UpdateFailure(val code: String) : IllegalStateException(code)

    private companion object {
        const val TAG = "HabiterUpdates"
        const val MANIFEST_TIMEOUT_MS = 15_000
        const val MAX_MANIFEST_BYTES = 4 * 1024 * 1024
        const val APK_MIME = "application/vnd.android.package-archive"
        const val METADATA_PREFIX = "download_"
        const val UPDATE_CHANNEL = "habiter_updates"
        const val READY_NOTIFICATION_BASE = 150000
        const val INSTALLER_PERMISSION_REQUEST = 150001
    }
}
