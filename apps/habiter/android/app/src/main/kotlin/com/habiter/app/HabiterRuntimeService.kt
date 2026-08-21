package com.habiter.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.habiter.app.runtime.AppBlockRuntime
import com.habiter.app.runtime.ReminderEngineRuntime
import com.habiter.app.runtime.RuntimeStateStore

class HabiterRuntimeService : Service() {
    private lateinit var runtimeThread: HandlerThread
    private lateinit var handler: Handler
    private lateinit var runtimeState: RuntimeStateStore
    private lateinit var appBlockRuntime: AppBlockRuntime
    private lateinit var reminderRuntime: ReminderEngineRuntime

    private val heartbeat = object : Runnable {
        override fun run() {
            runtimeState.recordHeartbeat()
            handler.postDelayed(this, HEARTBEAT_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        runtimeState = RuntimeStateStore(this)
        runtimeThread = HandlerThread("habiter-runtime").apply { start() }
        handler = Handler(runtimeThread.looper)
        appBlockRuntime = AppBlockRuntime(
            service = this,
            handler = handler,
            runtimeState = runtimeState,
            onFeatureStateChanged = ::reconcileFeatures,
        )
        reminderRuntime = ReminderEngineRuntime(this, runtimeState)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val features = runtimeState.features()
        if (!features.shouldRun) {
            stopSelf()
            return START_NOT_STICKY
        }
        startForeground(
            NOTIFICATION_ID,
            createNotification(features.notificationText()),
        )
        runtimeState.recordStarted(
            intent?.getStringExtra(EXTRA_START_REASON) ?: REASON_STICKY,
        )
        reconcileFeatures()
        RuntimeRecoveryReceiver.reconcilePersisted(this)
        if (intent?.action == ACTION_EVALUATE_REMINDERS) {
            reminderRuntime.invalidate(
                intent.getStringExtra(EXTRA_START_REASON) ?: REASON_RECOVERY,
            )
        }
        handler.removeCallbacks(heartbeat)
        handler.post(heartbeat)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        reminderRuntime.stop()
        appBlockRuntime.stop()
        runtimeThread.quitSafely()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun reconcileFeatures() {
        val features = runtimeState.features()
        if (!features.shouldRun) {
            stopSelf()
            return
        }
        appBlockRuntime.reconcile(features.appBlockEnabled)
        reminderRuntime.reconcile(features.remindersEnabled)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, createNotification(features.notificationText()))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Habiter background runtime",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps local reminders and App Block active"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun createNotification(text: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Habiter is active")
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    companion object {
        const val EXTRA_START_REASON = "start_reason"
        const val ACTION_EVALUATE_REMINDERS = "com.habiter.app.action.EVALUATE_REMINDERS"
        const val REASON_STICKY = "sticky_restart"
        const val REASON_APP_BLOCK = "app_block_changed"
        const val REASON_RECOVERY = "recovery_alarm"
        const val REASON_BOOT = "boot"
        const val REASON_PACKAGE_REPLACED = "package_replaced"

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "habiter_runtime_channel"
        private const val HEARTBEAT_INTERVAL_MS = 60_000L
    }
}
