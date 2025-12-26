package com.habiter.app

import android.animation.ObjectAnimator
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
import android.view.animation.OvershootInterpolator
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
    private var pulseAnimator: ObjectAnimator? = null
    
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
                pulseAnimator?.cancel()
                pulseAnimator = null
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
        // Main container with gradient background
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            
            // Premium gradient background
            background = GradientDrawable().apply {
                orientation = GradientDrawable.Orientation.TL_BR
                colors = intArrayOf(
                    Color.parseColor("#E60F0F1A"),  // 90% opacity deep dark
                    Color.parseColor("#E61A1A2E"),  // 90% opacity dark blue
                    Color.parseColor("#E616213E")   // 90% opacity navy
                )
            }
            setPadding(48, 48, 48, 48)
        }
        
        // Card with enhanced glassmorphism effect
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(56, 48, 56, 48)
            
            // Glassmorphism background with glow
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 48f
                // Gradient from slightly lighter to darker
                orientation = GradientDrawable.Orientation.TOP_BOTTOM
                colors = intArrayOf(
                    Color.parseColor("#331F2937"),  // Semi-transparent top
                    Color.parseColor("#221F2937")   // More transparent bottom
                )
                setStroke(2, Color.parseColor("#40FFFFFF")) // Subtle white border
            }
            
            elevation = 32f
        }
        
        // Lock icon with pulsing glow
        val lockIcon = TextView(context).apply {
            text = "🔒"
            textSize = 64f
            gravity = Gravity.CENTER
            setShadowLayer(48f, 0f, 0f, Color.parseColor("#D4A373"))
            tag = "lockIcon" // For animation reference
        }
        
        // Title
        val title = TextView(context).apply {
            text = "App Gesperrt"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 28, 0, 12)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            letterSpacing = -0.03f
        }
        
        // Blocked app name
        val blockedAppText = TextView(context).apply {
            text = blockedAppName
            textSize = 15f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        // Habits section label
        val habitsLabel = TextView(context).apply {
            text = "Erledige zuerst:"
            textSize = 13f
            setTextColor(Color.parseColor("#D4A373")) // Warm accent
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            letterSpacing = 0.05f
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
                textSize = 15f
                setTextColor(Color.parseColor("#E5E7EB"))
                gravity = Gravity.CENTER
                setPadding(0, 8, 0, 8)
            }
            habitsContainer.addView(habitRow)
        }
        
        if (incompleteHabits.size > 5) {
            val moreText = TextView(context).apply {
                text = "+${incompleteHabits.size - 5} weitere..."
                textSize = 13f
                setTextColor(Color.parseColor("#6B7280"))
                gravity = Gravity.CENTER
            }
            habitsContainer.addView(moreText)
        }
        
        // Primary button - Open Habiter
        val openButton = Button(context).apply {
            text = "Jetzt erledigen"
            textSize = 16f
            setTextColor(Color.WHITE)
            isAllCaps = false
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 28f
                orientation = GradientDrawable.Orientation.LEFT_RIGHT
                colors = intArrayOf(
                    Color.parseColor("#D4A373"),
                    Color.parseColor("#E9C46A")
                )
            }
            
            setPadding(64, 28, 64, 28)
            elevation = 12f
            
            setOnClickListener {
                dismiss()
                openHabiter(context)
            }
        }
        
        // Secondary button - Go Home
        val homeButton = Button(context).apply {
            text = "Später"
            textSize = 14f
            setTextColor(Color.parseColor("#6B7280"))
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
        
        // Start pulsing animation on lock icon
        startPulseAnimation(lockIcon)
        
        return container
    }
    
    private fun startPulseAnimation(view: View) {
        pulseAnimator = ObjectAnimator.ofFloat(view, "alpha", 1f, 0.6f, 1f).apply {
            duration = 2000
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
            start()
        }
    }
    
    private fun animateIn() {
        overlayView?.apply {
            alpha = 0f
            scaleX = 0.85f
            scaleY = 0.85f
            
            animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(350)
                .setInterpolator(OvershootInterpolator(0.8f))
                .start()
        }
    }
    
    private fun animateOut(onComplete: () -> Unit) {
        overlayView?.animate()
            ?.alpha(0f)
            ?.scaleX(0.85f)
            ?.scaleY(0.85f)
            ?.setDuration(200)
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
