package com.habiter.app

import android.animation.ValueAnimator
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Modern glassmorphism overlay that shows when user opens a locked app.
 * Uses SYSTEM_ALERT_WINDOW to float above all apps.
 */
object BlockingOverlay {
    
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private val handler = Handler(Looper.getMainLooper())
    
    fun show(context: Context, blockedAppName: String, incompleteHabits: List<String>) {
        if (overlayView != null) return // Already showing
        
        handler.post {
            try {
                windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                overlayView = createOverlayView(context, blockedAppName, incompleteHabits)
                
                val params = createLayoutParams()
                windowManager?.addView(overlayView, params)
                
                // Animate in
                animateIn()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun dismiss() {
        handler.post {
            try {
                overlayView?.let { view ->
                    animateOut {
                        windowManager?.removeView(view)
                        overlayView = null
                    }
                }
            } catch (e: Exception) {
                overlayView = null
            }
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
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }
    }
    
    private fun createOverlayView(context: Context, blockedAppName: String, incompleteHabits: List<String>): View {
        // Main container with dark translucent background
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E6000000")) // 90% opacity black
            setPadding(48, 48, 48, 48)
        }
        
        // Card with glassmorphism effect
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(64, 48, 64, 48)
            
            // Glassmorphism background
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 48f
                setColor(Color.parseColor("#CC1A1A2E")) // Dark blue with transparency
                setStroke(2, Color.parseColor("#40FFFFFF")) // Subtle white border
            }
            
            elevation = 24f
        }
        
        // Lock icon
        val lockIcon = TextView(context).apply {
            text = "🔒"
            textSize = 56f
            gravity = Gravity.CENTER
        }
        
        // Title
        val title = TextView(context).apply {
            text = "App Gesperrt"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 8)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
        }
        
        // Blocked app name
        val blockedAppText = TextView(context).apply {
            text = blockedAppName
            textSize = 16f
            setTextColor(Color.parseColor("#80FFFFFF"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        // Habits section
        val habitsLabel = TextView(context).apply {
            text = "Erledige zuerst:"
            textSize = 14f
            setTextColor(Color.parseColor("#D4A373")) // Warm accent
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
        }
        
        // Habit list container
        val habitsContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        // Add each habit
        val displayHabits = if (incompleteHabits.isEmpty()) {
            listOf("Deine Habits für heute")
        } else {
            incompleteHabits.take(5) // Max 5 habits shown
        }
        
        for (habit in displayHabits) {
            val habitRow = TextView(context).apply {
                text = "○  $habit"
                textSize = 16f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(0, 8, 0, 8)
            }
            habitsContainer.addView(habitRow)
        }
        
        if (incompleteHabits.size > 5) {
            val moreText = TextView(context).apply {
                text = "+${incompleteHabits.size - 5} weitere..."
                textSize = 14f
                setTextColor(Color.parseColor("#80FFFFFF"))
                gravity = Gravity.CENTER
            }
            habitsContainer.addView(moreText)
        }
        
        // Open Habiter button
        val openButton = Button(context).apply {
            text = "Jetzt erledigen"
            textSize = 16f
            setTextColor(Color.WHITE)
            isAllCaps = false
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 32f
                setColor(Color.parseColor("#D4A373")) // Warm accent
            }
            
            setPadding(64, 24, 64, 24)
            
            setOnClickListener {
                dismiss()
                openHabiter(context)
            }
        }
        
        // Go Home button
        val homeButton = Button(context).apply {
            text = "Später"
            textSize = 14f
            setTextColor(Color.parseColor("#80FFFFFF"))
            isAllCaps = false
            setBackgroundColor(Color.TRANSPARENT)
            setPadding(0, 24, 0, 0)
            
            setOnClickListener {
                dismiss()
                goHome(context)
            }
        }
        
        // Build layout
        card.addView(lockIcon)
        card.addView(title)
        card.addView(blockedAppText)
        card.addView(habitsLabel)
        card.addView(habitsContainer)
        card.addView(openButton)
        card.addView(homeButton)
        
        container.addView(card)
        
        return container
    }
    
    private fun animateIn() {
        overlayView?.apply {
            alpha = 0f
            scaleX = 0.9f
            scaleY = 0.9f
            
            animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(200)
                .setInterpolator(AccelerateDecelerateInterpolator())
                .start()
        }
    }
    
    private fun animateOut(onComplete: () -> Unit) {
        overlayView?.animate()
            ?.alpha(0f)
            ?.scaleX(0.9f)
            ?.scaleY(0.9f)
            ?.setDuration(150)
            ?.setInterpolator(AccelerateDecelerateInterpolator())
            ?.withEndAction(onComplete)
            ?.start() ?: onComplete()
    }
    
    private fun openHabiter(context: Context) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun goHome(context: Context) {
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
