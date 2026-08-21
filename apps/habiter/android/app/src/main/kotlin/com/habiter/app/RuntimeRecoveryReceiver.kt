package com.habiter.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.habiter.app.runtime.RuntimeRecoveryPolicy
import com.habiter.app.runtime.RuntimeStateStore

class RuntimeRecoveryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val state = RuntimeStateStore(context)
        if (!state.features().shouldRun) {
            cancel(context)
            return
        }
        val serviceIntent = Intent(context, HabiterRuntimeService::class.java).apply {
            action = HabiterRuntimeService.ACTION_EVALUATE_REMINDERS
            putExtra(
                HabiterRuntimeService.EXTRA_START_REASON,
                HabiterRuntimeService.REASON_RECOVERY,
            )
        }
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }.onFailure { Log.w(TAG, "Runtime recovery start failed", it) }
    }

    companion object {
        private const val REQUEST_CODE = 2001
        private const val TAG = "HabiterRuntime"

        fun scheduleNext(context: Context, evaluationAt: Long) {
            RuntimeStateStore(context).setNextReminderEvaluation(evaluationAt)
            schedule(context, evaluationAt)
        }

        fun reconcilePersisted(context: Context) {
            val store = RuntimeStateStore(context)
            val wakeAt = RuntimeRecoveryPolicy.nextWakeAt(
                now = System.currentTimeMillis(),
                plannedEvaluationAt = store.nextReminderEvaluation(),
                remindersEnabled = store.features().remindersEnabled,
            )
            if (wakeAt == null) cancel(context) else schedule(context, wakeAt)
        }

        fun cancel(context: Context, clearPersisted: Boolean = true) {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            pendingIntent(context, PendingIntent.FLAG_NO_CREATE)?.let(manager::cancel)
            if (clearPersisted) RuntimeStateStore(context).setNextReminderEvaluation(null)
        }

        private fun schedule(context: Context, evaluationAt: Long) {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val operation = pendingIntent(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    !manager.canScheduleExactAlarms() -> manager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        evaluationAt,
                        operation,
                    )
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        evaluationAt,
                        operation,
                    )
                else -> manager.setExact(AlarmManager.RTC_WAKEUP, evaluationAt, operation)
            }
        }

        private fun pendingIntent(context: Context, flags: Int): PendingIntent? =
            PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                Intent(context, RuntimeRecoveryReceiver::class.java),
                PendingIntent.FLAG_IMMUTABLE or flags,
            )
    }
}
