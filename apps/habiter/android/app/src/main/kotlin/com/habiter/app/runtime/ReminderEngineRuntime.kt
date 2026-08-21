package com.habiter.app.runtime

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.habiter.app.RuntimeRecoveryReceiver
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

internal class ReminderEngineRuntime(
    private val context: Context,
    private val state: RuntimeStateStore,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var timeZoneChannel: MethodChannel? = null
    private var evaluating = false
    private var evaluateAgain = false

    private val scheduledEvaluation = Runnable { evaluate("foreground_timer") }

    fun reconcile(enabled: Boolean) {
        if (!enabled) {
            stop()
            RuntimeRecoveryReceiver.cancel(context)
            return
        }
        ensureEngine()
    }

    fun invalidate(reason: String) {
        ensureEngine()
        evaluate(reason)
    }

    fun stop() {
        handler.removeCallbacks(scheduledEvaluation)
        channel?.setMethodCallHandler(null)
        timeZoneChannel?.setMethodCallHandler(null)
        channel = null
        timeZoneChannel = null
        engine?.destroy()
        engine = null
        evaluating = false
        evaluateAgain = false
    }

    private fun ensureEngine() {
        if (engine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)
        val created = FlutterEngine(context)
        engine = created
        channel = MethodChannel(
            created.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler(::handleDartCall)
        }
        timeZoneChannel = MethodChannel(
            created.dartExecutor.binaryMessenger,
            TIME_ZONE_CHANNEL,
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method == "getTimeZoneId") {
                    result.success(TimeZone.getDefault().id)
                } else {
                    result.notImplemented()
                }
            }
        }
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                DART_ENTRYPOINT,
            ),
        )
    }

    private fun handleDartCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "ready") {
            result.notImplemented()
            return
        }
        result.success(null)
        evaluate("engine_ready")
    }

    private fun evaluate(reason: String) {
        if (!state.features().remindersEnabled) return
        if (evaluating) {
            evaluateAgain = true
            return
        }
        val methodChannel = channel ?: return
        evaluating = true
        handler.removeCallbacks(scheduledEvaluation)
        methodChannel.invokeMethod("evaluate", mapOf("reason" to reason), object : MethodChannel.Result {
            override fun success(result: Any?) {
                evaluating = false
                val map = result as? Map<*, *> ?: emptyMap<Any?, Any?>()
                val next = (map["nextEvaluationAt"] as? Number)?.toLong()
                val dispatched = map["dispatched"] == true
                state.recordReminderEvaluation(next, dispatched)
                scheduleNext(next)
                drainQueuedEvaluation()
            }

            override fun error(code: String, message: String?, details: Any?) {
                evaluating = false
                Log.w(TAG, "Reminder evaluation failed safely: $code")
                drainQueuedEvaluation()
            }

            override fun notImplemented() {
                evaluating = false
                Log.w(TAG, "Reminder runtime entry point is not ready")
                drainQueuedEvaluation()
            }
        })
    }

    private fun scheduleNext(nextEvaluationAt: Long?) {
        handler.removeCallbacks(scheduledEvaluation)
        if (nextEvaluationAt == null || !state.features().remindersEnabled) {
            RuntimeRecoveryReceiver.cancel(context)
            return
        }
        RuntimeRecoveryReceiver.scheduleNext(context, nextEvaluationAt)
        handler.postDelayed(
            scheduledEvaluation,
            (nextEvaluationAt - System.currentTimeMillis()).coerceAtLeast(0L),
        )
    }

    private fun drainQueuedEvaluation() {
        if (!evaluateAgain) return
        evaluateAgain = false
        handler.post { evaluate("queued_invalidation") }
    }

    companion object {
        private const val CHANNEL = "com.habiter.app/runtime_engine"
        private const val DART_ENTRYPOINT = "habiterReminderRuntimeMain"
        private const val TIME_ZONE_CHANNEL = "com.habiter.app/timezone"
        private const val TAG = "HabiterRuntime"
    }
}
