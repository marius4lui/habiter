package com.habiter.app

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.widget.AppCompatButton
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import kotlin.math.min

internal data class BlockingUiModel(
    val blockedPackage: String,
    val blockedAppName: String,
    val incompleteHabits: List<String>,
)

/** Builds the shared, scroll-safe App Block experience for overlays and fallback activities. */
internal object BlockingUi {
    private const val MAX_VISIBLE_HABITS = 5

    fun create(
        context: Context,
        model: BlockingUiModel,
        onOpenHabiter: () -> Unit,
        onGoHome: () -> Unit,
    ): View {
        val root = FrameLayout(context).apply {
            background = ColorDrawable(color(context, R.color.app_lock_scrim))
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        }
        val baseInset = context.dp(20)
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, windowInsets ->
            val insets = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or
                    WindowInsetsCompat.Type.displayCutout() or
                    WindowInsetsCompat.Type.mandatorySystemGestures(),
            )
            view.setPadding(
                baseInset + insets.left,
                baseInset + insets.top,
                baseInset + insets.right,
                baseInset + insets.bottom,
            )
            windowInsets
        }

        val scrollView = ScrollView(context).apply {
            isFillViewport = true
            clipToPadding = false
            isVerticalScrollBarEnabled = false
        }
        root.addView(
            scrollView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        val page = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, context.dp(20), 0, context.dp(20))
        }
        scrollView.addView(
            page,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        val card = MaxWidthLinearLayout(context, context.dp(560)).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(context.dp(24), context.dp(24), context.dp(24), context.dp(20))
            background = roundedRectangle(
                fillColor = color(context, R.color.app_lock_surface),
                radius = context.dp(28).toFloat(),
                strokeColor = color(context, R.color.app_lock_outline),
                strokeWidth = context.dp(1),
            )
            elevation = context.dp(3).toFloat()
        }
        page.addView(
            card,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )

        card.addView(TextView(context).apply {
            text = context.getString(R.string.app_lock_brand)
            setTextColor(color(context, R.color.app_lock_primary))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            letterSpacing = 0.12f
            gravity = Gravity.CENTER
        })
        card.addSpacer(context.dp(28))

        card.addView(TextView(context).apply {
            text = context.getString(R.string.app_lock_paused_title, model.blockedAppName)
            setTextColor(color(context, R.color.app_lock_on_surface))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
        }, matchWidth())
        card.addSpacer(context.dp(10))

        val habitCount = model.incompleteHabits.size
        card.addView(TextView(context).apply {
            text = if (habitCount == 0) {
                context.getString(R.string.app_lock_status_generic)
            } else {
                context.resources.getQuantityString(
                    R.plurals.app_lock_habits_until_release,
                    habitCount,
                    habitCount,
                )
            }
            setTextColor(color(context, R.color.app_lock_on_surface_muted))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
        }, matchWidth())
        card.addSpacer(context.dp(24))

        val visibleHabits = model.incompleteHabits.take(MAX_VISIBLE_HABITS)
        if (visibleHabits.isEmpty()) {
            card.addView(habitRow(context, context.getString(R.string.app_lock_generic_habit)), matchWidth())
        } else {
            visibleHabits.forEachIndexed { index, habit ->
                if (index > 0) card.addSpacer(context.dp(10))
                card.addView(habitRow(context, habit), matchWidth())
            }
        }
        if (habitCount > MAX_VISIBLE_HABITS) {
            card.addSpacer(context.dp(10))
            card.addView(TextView(context).apply {
                val remaining = habitCount - MAX_VISIBLE_HABITS
                text = context.resources.getQuantityString(
                    R.plurals.app_lock_more_habits,
                    remaining,
                    remaining,
                )
                setTextColor(color(context, R.color.app_lock_on_surface_muted))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
            }, matchWidth())
        }
        card.addSpacer(context.dp(24))

        card.addView(TextView(context).apply {
            text = context.getString(R.string.app_lock_rationale, model.blockedAppName)
            setTextColor(color(context, R.color.app_lock_on_surface_muted))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
        }, matchWidth())
        card.addSpacer(context.dp(24))

        val primaryLabel = if (habitCount == 1) {
            context.getString(R.string.app_lock_open_single_habit, model.incompleteHabits.first())
        } else {
            context.getString(R.string.app_lock_open_habits)
        }
        card.addView(AppCompatButton(context).apply {
            text = primaryLabel
            setTextColor(color(context, R.color.app_lock_on_primary))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            isAllCaps = false
            isSingleLine = false
            maxLines = 3
            gravity = Gravity.CENTER
            minHeight = context.dp(56)
            minimumHeight = context.dp(56)
            setPadding(context.dp(18), context.dp(12), context.dp(18), context.dp(12))
            backgroundTintList = null
            background = rippleBackground(
                fillColor = color(context, R.color.app_lock_primary),
                rippleColor = color(context, R.color.app_lock_primary_pressed),
                radius = context.dp(16).toFloat(),
            )
            setOnClickListener { onOpenHabiter() }
        }, matchWidth())
        card.addSpacer(context.dp(8))

        card.addView(AppCompatButton(context).apply {
            text = context.getString(R.string.app_lock_go_home)
            setTextColor(color(context, R.color.app_lock_primary))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            isAllCaps = false
            isSingleLine = false
            maxLines = 2
            gravity = Gravity.CENTER
            minHeight = context.dp(52)
            minimumHeight = context.dp(52)
            setPadding(context.dp(18), context.dp(10), context.dp(18), context.dp(10))
            backgroundTintList = null
            background = rippleBackground(
                fillColor = Color.TRANSPARENT,
                rippleColor = color(context, R.color.app_lock_surface_variant),
                radius = context.dp(16).toFloat(),
            )
            setOnClickListener { onGoHome() }
        }, matchWidth())

        ViewCompat.requestApplyInsets(root)
        return root
    }

    private fun habitRow(context: Context, habitName: String): View = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.TOP
        setPadding(context.dp(16), context.dp(14), context.dp(16), context.dp(14))
        background = roundedRectangle(
            fillColor = color(context, R.color.app_lock_surface_variant),
            radius = context.dp(16).toFloat(),
            strokeColor = color(context, R.color.app_lock_outline),
            strokeWidth = context.dp(1),
        )

        addView(TextView(context).apply {
            text = "○"
            setTextColor(color(context, R.color.app_lock_primary))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            gravity = Gravity.CENTER
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }, LinearLayout.LayoutParams(context.dp(28), ViewGroup.LayoutParams.WRAP_CONTENT))

        addView(LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(TextView(context).apply {
                text = habitName
                setTextColor(color(context, R.color.app_lock_on_surface))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            }, matchWidth())
            addView(TextView(context).apply {
                text = context.getString(R.string.app_lock_habit_open_today)
                setTextColor(color(context, R.color.app_lock_on_surface_muted))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            }, matchWidth())
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    }

    private fun matchWidth() = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
    )

    private fun LinearLayout.addSpacer(height: Int) {
        addView(View(context), LinearLayout.LayoutParams(1, height))
    }

    private fun roundedRectangle(
        fillColor: Int,
        radius: Float,
        strokeColor: Int? = null,
        strokeWidth: Int = 0,
    ) = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = radius
        setColor(fillColor)
        if (strokeColor != null && strokeWidth > 0) setStroke(strokeWidth, strokeColor)
    }

    private fun rippleBackground(fillColor: Int, rippleColor: Int, radius: Float) = RippleDrawable(
        ColorStateList.valueOf(rippleColor),
        roundedRectangle(fillColor, radius),
        roundedRectangle(Color.WHITE, radius),
    )

    private fun color(context: Context, resource: Int) = ContextCompat.getColor(context, resource)
}

private class MaxWidthLinearLayout(context: Context, private val maxWidthPx: Int) : LinearLayout(context) {
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val mode = MeasureSpec.getMode(widthMeasureSpec)
        val constrainedWidth = if (mode == MeasureSpec.UNSPECIFIED) {
            maxWidthPx
        } else {
            min(MeasureSpec.getSize(widthMeasureSpec), maxWidthPx)
        }
        super.onMeasure(
            MeasureSpec.makeMeasureSpec(constrainedWidth, mode),
            heightMeasureSpec,
        )
    }
}

private fun Context.dp(value: Int): Int = TypedValue.applyDimension(
    TypedValue.COMPLEX_UNIT_DIP,
    value.toFloat(),
    resources.displayMetrics,
).toInt()
