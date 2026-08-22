package com.habiter.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.habiter.app.runtime.RuntimeStateStore

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        if (!RuntimeStateStore(context).features().shouldRun) return

        val reason = if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            HabiterRuntimeService.REASON_BOOT
        } else {
            HabiterRuntimeService.REASON_PACKAGE_REPLACED
        }
        val serviceIntent = Intent(context, HabiterRuntimeService::class.java).apply {
            action = HabiterRuntimeService.ACTION_EVALUATE_REMINDERS
            putExtra(HabiterRuntimeService.EXTRA_START_REASON, reason)
        }
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            RuntimeRecoveryReceiver.reconcilePersisted(context)
        }.onFailure { Log.w(TAG, "Runtime reconstruction failed", it) }
    }

    companion object {
        private const val TAG = "HabiterRuntime"
    }
}
