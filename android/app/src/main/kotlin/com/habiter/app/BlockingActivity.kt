package com.habiter.app

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class BlockingActivity : AppCompatActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make fullscreen
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).let { controller ->
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        
        // Keep screen on and show over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        // Build UI programmatically
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(0xFF1A1A2E.toInt())
            setPadding(48, 48, 48, 48)
        }
        
        val lockIcon = TextView(this).apply {
            text = "🔒"
            textSize = 72f
            gravity = android.view.Gravity.CENTER
        }
        
        val title = TextView(this).apply {
            text = "App Locked"
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }
        
        val message = TextView(this).apply {
            text = "Complete your habits first to unlock this app!"
            textSize = 16f
            setTextColor(0xFFB0B0B0.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }
        
        val openHabiterButton = Button(this).apply {
            text = "Open Habiter"
            textSize = 16f
            setOnClickListener { openHabiter() }
        }
        
        val goHomeButton = Button(this).apply {
            text = "Go Home"
            textSize = 14f
            setBackgroundColor(android.graphics.Color.TRANSPARENT)
            setTextColor(0xFF808080.toInt())
            setPadding(0, 24, 0, 0)
            setOnClickListener { goHome() }
        }
        
        layout.addView(lockIcon)
        layout.addView(title)
        layout.addView(message)
        layout.addView(openHabiterButton)
        layout.addView(goHomeButton)
        
        setContentView(layout)
    }
    
    private fun openHabiter() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
    }
    
    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        finish()
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Go to home instead of back to locked app
        goHome()
    }
}
