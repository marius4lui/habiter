package com.habiter.app

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
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
        
        // Main container with gradient background
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            
            // Premium gradient background (dark blue to dark purple)
            background = GradientDrawable().apply {
                orientation = GradientDrawable.Orientation.TL_BR
                colors = intArrayOf(
                    Color.parseColor("#0F0F1A"),  // Deep dark blue
                    Color.parseColor("#1A1A2E"),  // Dark blue-purple
                    Color.parseColor("#16213E")   // Navy blue
                )
            }
        }
        
        // Card container with glassmorphism effect
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(64, 56, 64, 56)
            
            // Glassmorphism card background
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 40f
                setColor(Color.parseColor("#1F2937"))
                setStroke(2, Color.parseColor("#374151"))
            }
            elevation = 24f
        }
        
        // Lock icon with glow effect
        val lockIcon = TextView(this).apply {
            text = "🔒"
            textSize = 64f
            gravity = Gravity.CENTER
            setShadowLayer(32f, 0f, 0f, Color.parseColor("#D4A373"))
        }
        
        // Title with gradient-like styling
        val title = TextView(this).apply {
            text = "App Gesperrt"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 28, 0, 12)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            letterSpacing = -0.03f
        }
        
        // Subtitle message
        val message = TextView(this).apply {
            text = "Erledige zuerst deine Habits!"
            textSize = 16f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }
        
        // Primary button - Open Habiter
        val openButton = Button(this).apply {
            text = "Jetzt erledigen"
            textSize = 16f
            setTextColor(Color.WHITE)
            isAllCaps = false
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 28f
                // Warm accent gradient
                orientation = GradientDrawable.Orientation.LEFT_RIGHT
                colors = intArrayOf(
                    Color.parseColor("#D4A373"),
                    Color.parseColor("#E9C46A")
                )
            }
            
            setPadding(72, 32, 72, 32)
            elevation = 8f
            
            setOnClickListener { openHabiter() }
        }
        
        // Secondary button - Go Home
        val homeButton = Button(this).apply {
            text = "Später"
            textSize = 14f
            setTextColor(Color.parseColor("#6B7280"))
            isAllCaps = false
            setBackgroundColor(Color.TRANSPARENT)
            setPadding(0, 28, 0, 0)
            
            setOnClickListener { goHome() }
        }
        
        // Build layout hierarchy
        card.addView(lockIcon)
        card.addView(title)
        card.addView(message)
        card.addView(openButton)
        card.addView(homeButton)
        
        layout.addView(card)
        
        setContentView(layout)
        
        // Fade in animation
        layout.alpha = 0f
        layout.animate()
            .alpha(1f)
            .setDuration(300)
            .start()
    }
    
    private fun openHabiter() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
    }
    
    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        finish()
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Go to home instead of back to locked app
        goHome()
    }
}
