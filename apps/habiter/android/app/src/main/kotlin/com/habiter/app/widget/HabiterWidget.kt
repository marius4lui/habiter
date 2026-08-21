package com.habiter.app.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.habiter.app.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class HabiterWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Responsive(
        setOf(
            DpSize(110.dp, 60.dp),
            DpSize(110.dp, 110.dp),
            DpSize(180.dp, 110.dp),
            DpSize(180.dp, 180.dp),
            DpSize(250.dp, 60.dp),
            DpSize(250.dp, 120.dp),
            DpSize(250.dp, 180.dp),
            DpSize(250.dp, 250.dp),
            DpSize(320.dp, 300.dp),
        ),
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val widgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        val configuration = HabiterWidgetConfigurationRepository.read(context, widgetId)
        provideContent {
            val homeWidgetState = currentState<HomeWidgetGlanceState>()
            val content = HabiterWidgetStateRepository.read(homeWidgetState.preferences)
            val size = LocalSize.current
            val layout = HabiterWidgetLayout.forSize(
                size.width.value.toInt(),
                size.height.value.toInt(),
            )
            val presentation = HabiterWidgetProjector.project(content, configuration, layout)
            WidgetSurface(context, presentation, layout)
        }
    }
}

@Composable
private fun WidgetSurface(
    context: Context,
    presentation: HabiterWidgetPresentation,
    layout: HabiterWidgetLayout,
) {
    val effective = presentation.effective
    val colors = HabiterWidgetTheme.colorsFor(effective)
    val state = presentation.content.stateOrNull
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.surface)
            .cornerRadius((effective.cornerRadius ?: 24.0).toInt().dp)
            .clickable(
                onClick = launchAction(
                    context,
                    effective.interactions.background,
                    state?.nextHabit,
                ),
            ),
    ) {
        when (val content = presentation.content) {
            HabiterWidgetContentState.Missing -> EmptyState(
                layout,
                effective,
                colors,
                java.util.Locale.getDefault().language == "de",
                EmptyKind.MISSING,
            )
            is HabiterWidgetContentState.Stale -> EmptyState(
                layout,
                effective,
                colors,
                content.state?.isGerman ?: (java.util.Locale.getDefault().language == "de"),
                EmptyKind.STALE,
            )
            is HabiterWidgetContentState.NoHabits -> EmptyState(
                layout,
                effective,
                colors,
                content.state.isGerman,
                EmptyKind.NO_HABITS,
            )
            is HabiterWidgetContentState.FreeToday -> EmptyState(
                layout,
                effective,
                colors,
                content.state.isGerman,
                EmptyKind.FREE_TODAY,
            )
            is HabiterWidgetContentState.AllComplete -> CompletedState(
                content.state,
                layout,
                effective,
                colors,
            )
            is HabiterWidgetContentState.JustCompleted -> JustCompletedState(
                context,
                content.state,
                layout,
                effective,
                colors,
            )
            is HabiterWidgetContentState.Active -> ActiveState(
                context,
                content.state,
                layout,
                effective,
                colors,
            )
        }
    }
}

private fun launchAction(
    context: Context,
    mapping: HabiterWidgetBackgroundAction,
    nextHabit: HabiterWidgetHabit?,
): Action = when (mapping) {
    HabiterWidgetBackgroundAction.NEXT_HABIT -> launchHabiter(context, nextHabit?.id)
    HabiterWidgetBackgroundAction.TODAY -> launchHabiter(context, openToday = true)
    HabiterWidgetBackgroundAction.APP -> launchHabiter(context)
}

private fun launchHabiter(
    context: Context,
    habitId: String? = null,
    openToday: Boolean = false,
): Action {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        flags = habiterWidgetLaunchFlags
        data = when {
            habitId != null -> Uri.parse("habiter://habit/$habitId")
            openToday -> Uri.parse("habiter://today")
            else -> Uri.parse("habiter://app")
        }
        habitId?.let { putExtra("openHabitId", it) }
        putExtra("openToday", openToday)
    }
    return actionStartActivity(intent)
}

internal val habiterWidgetLaunchFlags =
    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP

@Composable
private fun ActiveState(
    context: Context,
    state: HabiterWidgetState,
    layout: HabiterWidgetLayout,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    when (effective.contentMode) {
        HabiterWidgetContentMode.MINIMAL -> MinimalState(context, state, effective, colors)
        HabiterWidgetContentMode.FOCUS -> when (layout) {
            HabiterWidgetLayout.COMPACT -> Compact(context, state, effective, colors)
            HabiterWidgetLayout.COMPACT_SQUARE -> CompactSquare(context, state, effective, colors)
            else -> FocusState(context, state, effective, colors)
        }
        HabiterWidgetContentMode.LIST -> when (layout) {
            HabiterWidgetLayout.COMPACT -> Compact(context, state, effective, colors)
            HabiterWidgetLayout.WIDE -> Wide(context, state, effective, colors)
            else -> HabitList(context, state, layout, effective, colors)
        }
        HabiterWidgetContentMode.AUTO -> when (layout) {
            HabiterWidgetLayout.COMPACT -> Compact(context, state, effective, colors)
            HabiterWidgetLayout.COMPACT_SQUARE -> CompactSquare(context, state, effective, colors)
            HabiterWidgetLayout.WIDE -> Wide(context, state, effective, colors)
            HabiterWidgetLayout.MEDIUM_HERO -> FocusState(context, state, effective, colors)
            HabiterWidgetLayout.LARGE,
            HabiterWidgetLayout.EXTRA_LARGE,
            -> HabitList(context, state, layout, effective, colors)
        }
    }
}

@Composable
private fun MinimalState(
    context: Context,
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val habit = state.nextHabit ?: state.habits.firstOrNull() ?: return
    Row(
        modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 12, 8),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(
            habitText(habit, effective),
            modifier = GlanceModifier.defaultWeight(),
            maxLines = 1,
            style = titleStyle(colors, effective, 16),
        )
        if (!habit.completed) CompletionControl(context, state, habit, true, effective, colors)
    }
}

@Composable
private fun Compact(
    context: Context,
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val habit = state.nextHabit ?: state.habits.firstOrNull() ?: return
    Row(
        modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 12, 6),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(habitText(habit, effective), maxLines = 1, style = titleStyle(colors, effective, 15))
            if (showsCounter(effective, default = true)) {
                Text(progressLabel(state), maxLines = 1, style = mutedStyle(colors, effective, 12))
            }
        }
        if (!habit.completed) CompletionControl(context, state, habit, true, effective, colors)
    }
}

@Composable
private fun CompactSquare(
    context: Context,
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val habit = state.nextHabit ?: state.habits.firstOrNull() ?: return
    Column(
        modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 10, 10),
        horizontalAlignment = Alignment.Horizontal.Start,
    ) {
        if (showsCounter(effective, default = true)) {
            Text(progressLabel(state), maxLines = 1, style = mutedStyle(colors, effective, 11))
            Spacer(GlanceModifier.height(sectionGap(effective, 5).dp))
        }
        Text(habitText(habit, effective), maxLines = 1, style = titleStyle(colors, effective, 15))
        Spacer(GlanceModifier.defaultWeight())
        if (!habit.completed) CompletionControl(context, state, habit, false, effective, colors, fill = true)
    }
}

@Composable
private fun Wide(
    context: Context,
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val habit = state.nextHabit ?: state.habits.firstOrNull() ?: return
    Row(
        modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 16, 6),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        if (showsCounter(effective, default = true)) {
            Text(progressLabel(state), maxLines = 1, style = mutedStyle(colors, effective, 13))
            Spacer(GlanceModifier.width(sectionGap(effective, 14).dp))
        }
        Text(
            habitText(habit, effective),
            modifier = GlanceModifier.defaultWeight(),
            maxLines = 1,
            style = titleStyle(colors, effective, 16),
        )
        if (!habit.completed) CompletionControl(context, state, habit, true, effective, colors)
    }
}

@Composable
private fun FocusState(
    context: Context,
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val habit = state.nextHabit ?: state.habits.firstOrNull() ?: return
    Column(modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 18, 14)) {
        Header(state, effective, colors)
        if (showsSegments(effective, default = true)) {
            Spacer(GlanceModifier.height(sectionGap(effective, 8).dp))
            ProgressSegments(state, effective, colors)
        }
        Spacer(GlanceModifier.defaultWeight())
        Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(habitText(habit, effective), maxLines = 1, style = titleStyle(colors, effective, 19))
                if (effective.shows(HabiterWidgetElement.SCHEDULE_LABEL)) {
                    Text(habit.scheduleLabel, maxLines = 1, style = mutedStyle(colors, effective, 13))
                }
            }
            Spacer(GlanceModifier.width(sectionGap(effective, 12).dp))
            if (!habit.completed) CompletionControl(context, state, habit, false, effective, colors)
        }
    }
}

@Composable
private fun HabitList(
    context: Context,
    state: HabiterWidgetState,
    layout: HabiterWidgetLayout,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val fallbackPadding = if (layout == HabiterWidgetLayout.EXTRA_LARGE) 22 else 18
    Column(modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, fallbackPadding, fallbackPadding)) {
        Header(state, effective, colors)
        if (showsSegments(effective, default = true)) {
            Spacer(GlanceModifier.height(sectionGap(effective, 9).dp))
            ProgressSegments(state, effective, colors)
        }
        Spacer(GlanceModifier.height(sectionGap(effective, 12).dp))
        state.habits.forEachIndexed { index, habit ->
            HabitRow(context, state, habit, effective, colors)
            if (index < state.habits.lastIndex) {
                Spacer(GlanceModifier.height(rowGap(effective, 7).dp))
            }
        }
    }
}

@Composable
private fun Header(
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    if (!effective.shows(HabiterWidgetElement.TODAY_HEADER) &&
        !showsCounter(effective, default = true)
    ) return
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        if (effective.shows(HabiterWidgetElement.TODAY_HEADER)) {
            Text(todayLabel(state), style = titleStyle(colors, effective, 15))
        }
        Spacer(GlanceModifier.defaultWeight())
        if (showsCounter(effective, default = true)) {
            Text(
                "${state.completedCount} / ${state.scheduledCount}",
                style = counterStyle(colors, effective, 14),
            )
        }
    }
}

@Composable
private fun HabitRow(
    context: Context,
    state: HabiterWidgetState,
    habit: HabiterWidgetHabit,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val base = GlanceModifier
        .fillMaxWidth()
        .background(colors.surfaceAccent)
        .cornerRadius((effective.geometry.habitRowRadius ?: 14.0).toInt().dp)
        .padding(
            horizontal = (effective.geometry.horizontalPadding ?: 12.0).toInt().dp,
            vertical = (effective.geometry.verticalPadding ?: densityValue(effective, 7, 9)).toInt().dp,
        )
    Row(
        modifier = base.withHabitRowAction(context, state, habit, effective),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        if (habit.completed && effective.shows(HabiterWidgetElement.COMPLETION_CHECKMARK)) {
            Text("✓", style = TextStyle(color = colors.success, fontSize = textSize(effective, 17).sp))
            Spacer(GlanceModifier.width(8.dp))
        } else if (effective.shows(HabiterWidgetElement.HABIT_ICON)) {
            Text(habit.icon, style = titleStyle(colors, effective, 17))
            Spacer(GlanceModifier.width(8.dp))
        }
        Column(modifier = GlanceModifier.defaultWeight()) {
            if (effective.shows(HabiterWidgetElement.HABIT_NAME)) {
                Text(habit.name, maxLines = 1, style = titleStyle(colors, effective, 15))
            }
            if (effective.shows(HabiterWidgetElement.SCHEDULE_LABEL)) {
                Text(habit.scheduleLabel, maxLines = 1, style = mutedStyle(colors, effective, 11))
            }
        }
        if (!habit.completed &&
            effective.completionSettings.buttonStyle != HabiterWidgetCompletionButtonStyle.WHOLE_ROW
        ) {
            CompletionControl(context, state, habit, true, effective, colors)
        }
    }
}

private fun GlanceModifier.withHabitRowAction(
    context: Context,
    state: HabiterWidgetState,
    habit: HabiterWidgetHabit,
    effective: EffectiveHabiterWidgetConfiguration,
): GlanceModifier {
    val mapping = if (
        effective.completionSettings.buttonStyle == HabiterWidgetCompletionButtonStyle.WHOLE_ROW &&
        effective.shows(HabiterWidgetElement.COMPLETION_BUTTON) &&
        !habit.completed
    ) {
        if (effective.interactions.completionControl == HabiterWidgetCompletionAction.OPEN_HABIT) {
            HabiterWidgetHabitRowAction.OPEN_HABIT
        } else {
            HabiterWidgetHabitRowAction.COMPLETE
        }
    } else {
        effective.interactions.habitRow
    }
    val action = when (mapping) {
        HabiterWidgetHabitRowAction.OPEN_HABIT -> launchHabiter(context, habit.id)
        HabiterWidgetHabitRowAction.COMPLETE -> if (habit.completed) null else completionAction(state, habit)
        HabiterWidgetHabitRowAction.NONE -> null
    }
    return if (action == null) this else clickable(onClick = action)
}

@Composable
private fun CompletionControl(
    context: Context,
    state: HabiterWidgetState,
    habit: HabiterWidgetHabit,
    compact: Boolean,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
    fill: Boolean = false,
) {
    if (!effective.shows(HabiterWidgetElement.COMPLETION_BUTTON)) return
    val style = when (effective.completionSettings.buttonStyle) {
        HabiterWidgetCompletionButtonStyle.AUTOMATIC -> if (compact) {
            HabiterWidgetCompletionButtonStyle.CHECK_ONLY
        } else {
            HabiterWidgetCompletionButtonStyle.TEXT_ONLY
        }
        HabiterWidgetCompletionButtonStyle.WHOLE_ROW -> return
        else -> effective.completionSettings.buttonStyle
    }
    val label = when (style) {
        HabiterWidgetCompletionButtonStyle.CHECK_ONLY -> "✓"
        HabiterWidgetCompletionButtonStyle.TEXT_ONLY -> completeLabel(state)
        HabiterWidgetCompletionButtonStyle.CHECK_AND_TEXT -> "✓ ${completeLabel(state)}"
        else -> "✓"
    }
    val action = if (effective.interactions.completionControl == HabiterWidgetCompletionAction.OPEN_HABIT) {
        launchHabiter(context, habit.id)
    } else {
        completionAction(state, habit)
    }
    val base = GlanceModifier
        .background(colors.primary)
        .cornerRadius((effective.geometry.buttonRadius ?: 14.0).toInt().dp)
        .clickable(onClick = action)
        .semantics {
            contentDescription = if (state.isGerman) "${habit.name} erledigen" else "Complete ${habit.name}"
        }
        .padding(horizontal = if (compact) 12.dp else 14.dp, vertical = 8.dp)
    Box(
        modifier = if (fill) base.fillMaxWidth().height(48.dp) else base.size(48.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            maxLines = 1,
            style = TextStyle(
                color = colors.onPrimary,
                fontSize = textSize(effective, if (compact) 13 else 12).sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}

private fun completionAction(state: HabiterWidgetState, habit: HabiterWidgetHabit): Action {
    val actionId = "${habit.id}:${state.generatedAt.toEpochMilli()}"
    return actionRunCallback<HabiterWidgetActionCallback>(
        actionParametersOf(
            HabiterWidgetAction.habitIdKey to habit.id,
            HabiterWidgetAction.localDateKey to state.localDate,
            HabiterWidgetAction.actionIdKey to actionId,
        ),
    )
}

@Composable
private fun ProgressSegments(
    state: HabiterWidgetState,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    if (!effective.shows(HabiterWidgetElement.PROGRESS_SEGMENTS)) return
    val maximum = effective.progressSettings.maximumSegments ?: 8
    val count = state.scheduledCount.coerceIn(1, maximum)
    val completed = if (state.scheduledCount <= maximum) {
        state.completedCount
    } else {
        ((state.completedCount.toDouble() / state.scheduledCount) * count).toInt()
    }
    val height = (effective.progressSettings.segmentHeight ?: 5.0).toInt()
    val gap = (effective.progressSettings.segmentGap ?: 4.0).toInt()
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        repeat(count) { index ->
            val color = if (index < completed) {
                when (effective.progressSettings.completedStyle) {
                    HabiterWidgetProgressCompletedStyle.SOLID -> colors.success
                    HabiterWidgetProgressCompletedStyle.MUTED -> colors.primary
                    HabiterWidgetProgressCompletedStyle.HIDDEN -> colors.surface
                }
            } else {
                when (effective.progressSettings.remainingStyle) {
                    HabiterWidgetProgressRemainingStyle.TRACK -> colors.surfaceAccent
                    HabiterWidgetProgressRemainingStyle.OUTLINE -> colors.onSurfaceMuted
                    HabiterWidgetProgressRemainingStyle.HIDDEN -> colors.surface
                }
            }
            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .height(height.dp)
                    .background(color)
                    .cornerRadius((height / 2).coerceAtLeast(1).dp),
            ) {}
            if (index < count - 1) Spacer(GlanceModifier.width(gap.dp))
        }
    }
}

@Composable
private fun JustCompletedState(
    context: Context,
    state: HabiterWidgetState,
    layout: HabiterWidgetLayout,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val completion = state.lastCompletion ?: return
    if (effective.stateStyles.justCompleted == HabiterWidgetJustCompletedStyle.CHECK_ONLY ||
        effective.completionSettings.feedback == HabiterWidgetCompletionFeedback.MINIMAL
    ) {
        Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (effective.shows(HabiterWidgetElement.COMPLETION_CHECKMARK)) {
                Text("✓", style = TextStyle(color = colors.success, fontSize = textSize(effective, 32).sp))
            }
        }
        return
    }
    val completionLayout = HabiterWidgetCompletionLayout.forLayout(layout)
    val action = actionRunCallback<HabiterWidgetUndoActionCallback>(
        actionParametersOf(
            HabiterWidgetAction.habitIdKey to completion.habitId,
            HabiterWidgetAction.localDateKey to state.localDate,
            HabiterWidgetAction.sourceActionIdKey to completion.actionId,
        ),
    )
    val showStatus = effective.stateStyles.justCompleted == HabiterWidgetJustCompletedStyle.FULL &&
        effective.completionSettings.feedback != HabiterWidgetCompletionFeedback.MINIMAL
    val stacked = completionLayout.transientArrangement == HabiterWidgetCompletionArrangement.STACKED
    if (stacked) {
        Column(
            modifier = GlanceModifier.fillMaxSize().configuredPadding(
                effective,
                completionLayout.horizontalPaddingDp,
                completionLayout.verticalPaddingDp,
            ),
            verticalAlignment = Alignment.Vertical.CenterVertically,
            horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
        ) {
            CompletionSummary(state, completion, effective, colors, showStatus)
            if (showsUndo(effective)) {
                Spacer(GlanceModifier.height(6.dp))
                CompletionUndoControl(state, completion, effective, colors, action, true)
            }
        }
    } else {
        Row(
            modifier = GlanceModifier.fillMaxSize().configuredPadding(
                effective,
                completionLayout.horizontalPaddingDp,
                completionLayout.verticalPaddingDp,
            ),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            CompletionSummary(state, completion, effective, colors, showStatus, GlanceModifier.defaultWeight())
            if (showsUndo(effective)) {
                Spacer(GlanceModifier.width(6.dp))
                CompletionUndoControl(state, completion, effective, colors, action, completionLayout.showFullUndoLabel)
            }
        }
    }
}

@Composable
private fun CompletionSummary(
    state: HabiterWidgetState,
    completion: HabiterWidgetCompletion,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
    showStatus: Boolean,
    modifier: GlanceModifier = GlanceModifier,
) {
    Row(modifier = modifier, verticalAlignment = Alignment.Vertical.CenterVertically) {
        if (effective.shows(HabiterWidgetElement.COMPLETION_CHECKMARK)) {
            Text("✓", style = TextStyle(color = colors.success, fontSize = textSize(effective, 24).sp))
            Spacer(GlanceModifier.width(8.dp))
        }
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(completion.habitName, maxLines = 1, style = titleStyle(colors, effective, 15))
            if (showStatus) {
                Text(
                    HabiterWidgetCompletionCopy.status(state.isGerman),
                    maxLines = 1,
                    style = mutedStyle(colors, effective, 12),
                )
            }
        }
    }
}

@Composable
private fun CompletionUndoControl(
    state: HabiterWidgetState,
    completion: HabiterWidgetCompletion,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
    action: Action,
    full: Boolean,
) {
    Box(
        modifier = GlanceModifier
            .background(colors.surfaceAccent)
            .cornerRadius((effective.geometry.buttonRadius ?: 14.0).toInt().dp)
            .clickable(onClick = action)
            .semantics {
                contentDescription = HabiterWidgetCompletionCopy.undoDescription(
                    habitName = completion.habitName,
                    isGerman = state.isGerman,
                )
            }
            .size(48.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            HabiterWidgetCompletionCopy.undoLabel(state.isGerman, full),
            maxLines = 1,
            style = titleStyle(colors, effective, 12),
        )
    }
}

private fun showsUndo(effective: EffectiveHabiterWidgetConfiguration): Boolean =
    effective.completionSettings.showUndo && effective.shows(HabiterWidgetElement.UNDO_BUTTON)

@Composable
private fun CompletedState(
    state: HabiterWidgetState,
    layout: HabiterWidgetLayout,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
) {
    val style = effective.stateStyles.allComplete
    val showMessage = effective.shows(HabiterWidgetElement.DONE_STATE_TEXT) &&
        style != HabiterWidgetAllCompleteStyle.ICON_ONLY &&
        style != HabiterWidgetAllCompleteStyle.MINIMAL
    val horizontal = layout == HabiterWidgetLayout.COMPACT || layout == HabiterWidgetLayout.WIDE
    if (horizontal) {
        Row(
            modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 14, 8),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            if (effective.shows(HabiterWidgetElement.COMPLETION_CHECKMARK)) {
                Text("✓", style = TextStyle(color = colors.success, fontSize = textSize(effective, 28).sp))
            }
            if (showMessage) {
                Spacer(GlanceModifier.width(10.dp))
                Text(
                    HabiterWidgetCompletionCopy.settledMessage(state.isGerman),
                    modifier = GlanceModifier.defaultWeight(),
                    maxLines = 1,
                    style = titleStyle(colors, effective, 15),
                )
            }
        }
    } else {
        Column(
            modifier = GlanceModifier.fillMaxSize().configuredPadding(effective, 18, 14),
            verticalAlignment = Alignment.Vertical.CenterVertically,
            horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
        ) {
            if (effective.shows(HabiterWidgetElement.COMPLETION_CHECKMARK)) {
                Text("✓", style = TextStyle(color = colors.success, fontSize = textSize(effective, 32).sp))
            }
            if (showMessage) {
                Spacer(GlanceModifier.height(8.dp))
                Text(
                    HabiterWidgetCompletionCopy.settledMessage(state.isGerman),
                    maxLines = 2,
                    style = titleStyle(colors, effective, 16),
                )
            }
        }
    }
}

private enum class EmptyKind { MISSING, STALE, NO_HABITS, FREE_TODAY }

@Composable
private fun EmptyState(
    layout: HabiterWidgetLayout,
    effective: EffectiveHabiterWidgetConfiguration,
    colors: HabiterWidgetColors,
    isGerman: Boolean,
    kind: EmptyKind,
) {
    val (icon, english, german) = when (kind) {
        EmptyKind.MISSING -> Triple("↻", "Open Habiter to get started.", "Habiter öffnen, um zu starten.")
        EmptyKind.STALE -> Triple("↻", "Open Habiter to sync.", "Öffne Habiter zum Synchronisieren.")
        EmptyKind.NO_HABITS -> Triple("＋", "Your first habit is waiting.", "Dein erstes Habit wartet.")
        EmptyKind.FREE_TODAY -> Triple("🍃", "Today is free.", "Heute ist frei.")
    }
    val compactStyle = when (kind) {
        EmptyKind.MISSING,
        EmptyKind.STALE,
        -> effective.stateStyles.missingStale == HabiterWidgetMissingStaleStyle.COMPACT
        EmptyKind.NO_HABITS -> effective.stateStyles.noHabits == HabiterWidgetNoHabitsStyle.COMPACT
        EmptyKind.FREE_TODAY -> effective.stateStyles.freeToday == HabiterWidgetFreeTodayStyle.MINIMAL
    }
    val iconOnly = kind == EmptyKind.FREE_TODAY &&
        effective.stateStyles.freeToday == HabiterWidgetFreeTodayStyle.ICON_ONLY
    val textOnly = kind == EmptyKind.FREE_TODAY &&
        effective.stateStyles.freeToday == HabiterWidgetFreeTodayStyle.TEXT_ONLY
    val showText = effective.shows(HabiterWidgetElement.EMPTY_STATE_TEXT) && !iconOnly && !compactStyle
    Column(
        modifier = GlanceModifier.fillMaxSize().configuredPadding(
            effective,
            if (layout == HabiterWidgetLayout.COMPACT) 12 else 20,
            if (layout == HabiterWidgetLayout.COMPACT) 8 else 16,
        ),
        verticalAlignment = Alignment.Vertical.CenterVertically,
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        if (!textOnly) Text(icon, style = TextStyle(color = colors.primary, fontSize = textSize(effective, 22).sp))
        if (showText) {
            Spacer(GlanceModifier.height(5.dp))
            Text(
                if (isGerman) german else english,
                maxLines = if (layout == HabiterWidgetLayout.COMPACT) 1 else 3,
                style = titleStyle(colors, effective, if (layout == HabiterWidgetLayout.COMPACT) 13 else 16),
            )
        }
    }
}

private fun habitText(
    habit: HabiterWidgetHabit,
    effective: EffectiveHabiterWidgetConfiguration,
): String {
    val showIcon = effective.shows(HabiterWidgetElement.HABIT_ICON)
    val showName = effective.shows(HabiterWidgetElement.HABIT_NAME)
    return when {
        showIcon && showName -> "${habit.icon} ${habit.name}"
        showIcon -> habit.icon
        showName -> habit.name
        else -> ""
    }
}

private fun showsSegments(
    effective: EffectiveHabiterWidgetConfiguration,
    default: Boolean,
): Boolean = effective.shows(HabiterWidgetElement.PROGRESS_SEGMENTS) && when (effective.progressMode) {
    HabiterWidgetProgressMode.AUTOMATIC -> default
    HabiterWidgetProgressMode.SEGMENTS,
    HabiterWidgetProgressMode.BOTH,
    -> true
    HabiterWidgetProgressMode.HIDDEN,
    HabiterWidgetProgressMode.COUNTER,
    -> false
}

private fun showsCounter(
    effective: EffectiveHabiterWidgetConfiguration,
    default: Boolean,
): Boolean = effective.shows(HabiterWidgetElement.COUNTER) && when (effective.progressMode) {
    HabiterWidgetProgressMode.AUTOMATIC -> default
    HabiterWidgetProgressMode.COUNTER,
    HabiterWidgetProgressMode.BOTH,
    -> true
    HabiterWidgetProgressMode.HIDDEN,
    HabiterWidgetProgressMode.SEGMENTS,
    -> false
}

private fun GlanceModifier.configuredPadding(
    effective: EffectiveHabiterWidgetConfiguration,
    fallbackHorizontal: Int,
    fallbackVertical: Int,
): GlanceModifier = padding(
    horizontal = (
        effective.geometry.horizontalPadding ?: effective.outerPadding ?: fallbackHorizontal.toDouble()
    ).toInt().dp,
    vertical = (
        effective.geometry.verticalPadding ?: effective.outerPadding ?: fallbackVertical.toDouble()
    ).toInt().dp,
)

private fun densityValue(
    effective: EffectiveHabiterWidgetConfiguration,
    compact: Int,
    comfortable: Int,
): Double = if (effective.density == HabiterWidgetDensity.COMPACT) {
    compact.toDouble()
} else {
    comfortable.toDouble()
}

private fun rowGap(effective: EffectiveHabiterWidgetConfiguration, fallback: Int): Int =
    (effective.geometry.rowGap ?: densityValue(effective, (fallback - 2).coerceAtLeast(0), fallback)).toInt()

private fun sectionGap(effective: EffectiveHabiterWidgetConfiguration, fallback: Int): Int =
    (effective.geometry.sectionGap ?: densityValue(effective, (fallback - 2).coerceAtLeast(0), fallback)).toInt()

private fun textSize(
    effective: EffectiveHabiterWidgetConfiguration,
    fallback: Int,
    explicit: Double? = null,
): Int = ((explicit ?: fallback.toDouble()) * effective.textScale).toInt().coerceIn(9, 30)

private fun fontWeight(effective: EffectiveHabiterWidgetConfiguration): FontWeight =
    when (effective.typography.fontWeight) {
        HabiterWidgetFontWeight.REGULAR -> FontWeight.Normal
        HabiterWidgetFontWeight.BOLD -> FontWeight.Bold
        HabiterWidgetFontWeight.SYSTEM,
        HabiterWidgetFontWeight.MEDIUM,
        -> FontWeight.Medium
    }

private fun titleStyle(
    colors: HabiterWidgetColors,
    effective: EffectiveHabiterWidgetConfiguration,
    fallback: Int,
): TextStyle = TextStyle(
    color = colors.onSurface,
    fontSize = textSize(effective, fallback, effective.typography.habitTitleSize).sp,
    fontWeight = fontWeight(effective),
)

private fun mutedStyle(
    colors: HabiterWidgetColors,
    effective: EffectiveHabiterWidgetConfiguration,
    fallback: Int,
): TextStyle = TextStyle(
    color = colors.onSurfaceMuted,
    fontSize = textSize(effective, fallback, effective.typography.secondaryTextSize).sp,
)

private fun counterStyle(
    colors: HabiterWidgetColors,
    effective: EffectiveHabiterWidgetConfiguration,
    fallback: Int,
): TextStyle = TextStyle(
    color = colors.onSurface,
    fontSize = textSize(effective, fallback, effective.typography.counterSize).sp,
    fontWeight = FontWeight.Bold,
)

private fun progressLabel(state: HabiterWidgetState): String =
    if (state.isGerman) {
        "Heute ${state.completedCount}/${state.scheduledCount}"
    } else {
        "Today ${state.completedCount}/${state.scheduledCount}"
    }

private fun todayLabel(state: HabiterWidgetState): String = if (state.isGerman) "Heute" else "Today"

private fun completeLabel(state: HabiterWidgetState): String = if (state.isGerman) "Erledigen" else "Complete"

private val HabiterWidgetState.isGerman: Boolean
    get() = locale.startsWith("de", ignoreCase = true)

private val HabiterWidgetContentState.stateOrNull: HabiterWidgetState?
    get() = when (this) {
        HabiterWidgetContentState.Missing -> null
        is HabiterWidgetContentState.Stale -> state
        is HabiterWidgetContentState.NoHabits -> state
        is HabiterWidgetContentState.FreeToday -> state
        is HabiterWidgetContentState.AllComplete -> state
        is HabiterWidgetContentState.JustCompleted -> state
        is HabiterWidgetContentState.Active -> state
    }
