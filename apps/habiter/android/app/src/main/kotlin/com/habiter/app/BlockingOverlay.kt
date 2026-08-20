package com.habiter.app

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import androidx.appcompat.view.ContextThemeWrapper

/** Displays only the blocking state for the package that is currently in the foreground. */
internal object BlockingOverlay {
    private const val TAG = "HabiterAppLock"

    private val handler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var currentModel: BlockingUiModel? = null

    val isShowing: Boolean
        get() = overlayView != null

    val currentBlockedPackage: String?
        get() = currentModel?.blockedPackage

    fun show(
        context: Context,
        blockedPackage: String,
        blockedAppName: String,
        incompleteHabits: List<String>,
        onLeaveBlockedApp: (String) -> Unit,
    ) {
        val appContext = context.applicationContext
        val model = BlockingUiModel(
            blockedPackage = blockedPackage,
            blockedAppName = blockedAppName,
            incompleteHabits = incompleteHabits,
        )
        handler.post {
            val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!Settings.canDrawOverlays(appContext) || !powerManager.isInteractive) {
                removeImmediately()
                return@post
            }
            if (model == currentModel && overlayView != null) return@post

            removeImmediately()
            try {
                val themedContext = ContextThemeWrapper(appContext, R.style.BlockingTheme)
                val view = BlockingUi.create(
                    context = themedContext,
                    model = model,
                    onOpenHabiter = {
                        onLeaveBlockedApp(model.blockedPackage)
                        removeImmediately()
                        openHabiter(appContext, model.incompleteHabits.singleOrNull())
                    },
                    onGoHome = {
                        onLeaveBlockedApp(model.blockedPackage)
                        removeImmediately()
                        goHome(appContext)
                    },
                )
                val manager = appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                manager.addView(view, createLayoutParams())
                windowManager = manager
                overlayView = view
                currentModel = model
            } catch (error: Exception) {
                removeImmediately()
                Log.w(TAG, "Unable to show blocking overlay", error)
            }
        }
    }

    fun dismiss() {
        handler.post { removeImmediately() }
    }

    fun reconcileLockedPackages(lockedPackages: Set<String>) {
        handler.post {
            if (currentModel?.blockedPackage !in lockedPackages) removeImmediately()
        }
    }

    private fun removeImmediately() {
        val view = overlayView
        val manager = windowManager
        overlayView = null
        windowManager = null
        currentModel = null
        if (view != null && manager != null) {
            runCatching { manager.removeViewImmediate(view) }
                .onFailure { Log.w(TAG, "Unable to dismiss blocking overlay", it) }
        }
    }

    private fun createLayoutParams(): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.CENTER
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
    }

    private fun openHabiter(context: Context, habitName: String?) {
        runCatching {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("habiter_destination", "today")
                habitName?.let { putExtra("habiter_habit_name", it) }
            }
            context.startActivity(intent)
        }.onFailure { Log.w(TAG, "Unable to return to Habiter", it) }
    }

    private fun goHome(context: Context) {
        runCatching {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }.onFailure { Log.w(TAG, "Unable to return to the launcher", it) }
    }
}
