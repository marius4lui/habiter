package com.habiter.app

internal class StoreUpdateCoordinator(private val activity: MainActivity) {
    fun start(immediate: Boolean, callback: (String) -> Unit) = callback("unavailable")

    fun status(callback: (Map<String, Any?>) -> Unit) = callback(
        mapOf(
            "phase" to "missing",
            "downloadedBytes" to 0L,
            "totalBytes" to 0L,
            "failureCode" to "store_update_unavailable",
        )
    )

    fun complete(callback: (String) -> Unit) = callback("unavailable")

    fun resumeInterruptedImmediateUpdate() = Unit

    fun dispose() = Unit
}
