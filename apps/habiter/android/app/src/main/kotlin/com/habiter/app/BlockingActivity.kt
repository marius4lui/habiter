package com.habiter.app

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat

/** Fallback blocking host kept out of Recents; the runtime normally uses [BlockingOverlay]. */
class BlockingActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        val appName = intent.getStringExtra(EXTRA_BLOCKED_APP_NAME)
            ?: getString(R.string.app_lock_generic_app_name)
        val habits = intent.getStringArrayListExtra(EXTRA_INCOMPLETE_HABITS).orEmpty()
        val model = BlockingUiModel(
            blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE).orEmpty(),
            blockedAppName = appName,
            incompleteHabits = habits,
        )
        setContentView(
            BlockingUi.create(
                context = this,
                model = model,
                onOpenHabiter = ::openHabiter,
                onGoHome = ::goHome,
            ),
        )
    }

    private fun openHabiter() {
        startActivity(Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("habiter_destination", "today")
        })
        finish()
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        goHome()
    }

    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
        const val EXTRA_BLOCKED_APP_NAME = "blocked_app_name"
        const val EXTRA_INCOMPLETE_HABITS = "incomplete_habits"
    }
}
