package com.habiter.app.widget

import android.content.Context
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
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
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
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import com.habiter.app.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

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
        provideContent {
            val homeWidgetState = currentState<HomeWidgetGlanceState>()
            val content = HabiterWidgetStateRepository.read(homeWidgetState.preferences)
            val size = LocalSize.current
            val layout = HabiterWidgetLayout.forSize(size.width.value.toInt(), size.height.value.toInt())
            WidgetSurface(context, content, layout)
        }
    }
}

@Composable
private fun WidgetSurface(
    context: Context,
    content: HabiterWidgetContentState,
    layout: HabiterWidgetLayout,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(HabiterWidgetTheme.surface)
            .cornerRadius(24.dp)
            .clickable(onClick = actionStartActivity<MainActivity>(context)),
    ) {
        when (content) {
            HabiterWidgetContentState.Missing -> EmptyState(layout, java.util.Locale.getDefault().language == "de", "Open Habiter to get started.", "Habiter öffnen, um zu starten.")
            is HabiterWidgetContentState.Stale -> EmptyState(layout, content.state?.isGerman ?: (java.util.Locale.getDefault().language == "de"), "Open Habiter to sync.", "Öffne Habiter zum Synchronisieren.")
            is HabiterWidgetContentState.NoHabits -> EmptyState(layout, content.state.isGerman, "Your first habit is waiting.", "Dein erstes Habit wartet.")
            is HabiterWidgetContentState.FreeToday -> EmptyState(layout, content.state.isGerman, "🍃 Today is free.", "🍃 Heute ist frei.")
            is HabiterWidgetContentState.AllComplete -> CompletedState(content.state, layout)
            is HabiterWidgetContentState.JustCompleted -> JustCompletedState(content.state, layout)
            is HabiterWidgetContentState.Active -> ActiveState(content.state, layout)
        }
    }
}

@Composable
private fun JustCompletedState(state: HabiterWidgetState, layout: HabiterWidgetLayout) {
    val completion = state.lastCompletion ?: return
    val action = actionRunCallback<HabiterWidgetUndoActionCallback>(
        actionParametersOf(
            HabiterWidgetAction.habitIdKey to completion.habitId,
            HabiterWidgetAction.localDateKey to state.localDate,
            HabiterWidgetAction.sourceActionIdKey to completion.actionId,
        ),
    )
    Row(
        modifier = GlanceModifier.fillMaxSize().padding(if (layout == HabiterWidgetLayout.COMPACT) 12.dp else 20.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text("✓", style = TextStyle(color = HabiterWidgetTheme.success, fontSize = 24.sp, fontWeight = FontWeight.Bold))
        Spacer(GlanceModifier.width(10.dp))
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(completion.habitName, maxLines = 1, style = titleStyle(16))
            if (layout != HabiterWidgetLayout.COMPACT) {
                Text(if (state.locale.startsWith("de")) "Erledigt" else "Completed", style = mutedStyle(13))
            }
        }
        Box(
            modifier = GlanceModifier
                .background(HabiterWidgetTheme.surfaceAccent)
                .cornerRadius(14.dp)
                .clickable(onClick = action)
                .semantics { contentDescription = if (state.isGerman) "${completion.habitName} rückgängig machen" else "Undo ${completion.habitName}" }
                .padding(horizontal = 12.dp, vertical = 8.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(if (layout == HabiterWidgetLayout.COMPACT) "↶" else if (state.locale.startsWith("de")) "Rückgängig" else "Undo", style = titleStyle(13))
        }
    }
}

@Composable
private fun ActiveState(state: HabiterWidgetState, layout: HabiterWidgetLayout) {
    when (layout) {
        HabiterWidgetLayout.COMPACT -> Compact(state)
        HabiterWidgetLayout.COMPACT_SQUARE -> CompactSquare(state)
        HabiterWidgetLayout.WIDE -> Wide(state)
        HabiterWidgetLayout.MEDIUM_HERO -> MediumHero(state)
        HabiterWidgetLayout.LARGE -> HabitList(state, maximumHabits = 3, padding = 18)
        HabiterWidgetLayout.EXTRA_LARGE -> HabitList(state, maximumHabits = 6, padding = 22)
    }
}

@Composable
private fun Compact(state: HabiterWidgetState) {
    val habit = state.nextHabit ?: return
    Row(
        modifier = GlanceModifier.fillMaxSize().padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                "${habit.icon} ${habit.name}",
                maxLines = 1,
                style = titleStyle(15),
            )
            Text(progressLabel(state), maxLines = 1, style = mutedStyle(12))
        }
        CompleteControl(state, habit, compact = true)
    }
}

@Composable
private fun CompactSquare(state: HabiterWidgetState) {
    val habit = state.nextHabit ?: return
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(10.dp),
        horizontalAlignment = Alignment.Horizontal.Start,
    ) {
        Text(progressLabel(state), maxLines = 1, style = mutedStyle(11))
        Spacer(GlanceModifier.height(5.dp))
        Text("${habit.icon} ${habit.name}", maxLines = 1, style = titleStyle(15))
        Spacer(GlanceModifier.defaultWeight())
        CompactSquareCompleteControl(state, habit)
    }
}

@Composable
private fun CompactSquareCompleteControl(state: HabiterWidgetState, habit: HabiterWidgetHabit) {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(HabiterWidgetTheme.primary)
            .cornerRadius(12.dp)
            .clickable(onClick = completionAction(state, habit))
            .semantics { contentDescription = if (state.isGerman) "${habit.name} erledigen" else "Complete ${habit.name}" }
            .padding(horizontal = 8.dp, vertical = 7.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text("✓ ${completeLabel(state)}", maxLines = 1, style = TextStyle(color = HabiterWidgetTheme.surface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
    }
}

@Composable
private fun Wide(state: HabiterWidgetState) {
    val habit = state.nextHabit ?: return
    Row(
        modifier = GlanceModifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(progressLabel(state), maxLines = 1, style = mutedStyle(13))
        Spacer(GlanceModifier.width(14.dp))
        Text("${habit.icon} ${habit.name}", modifier = GlanceModifier.defaultWeight(), maxLines = 1, style = titleStyle(16))
        CompleteControl(state, habit, compact = true)
    }
}

@Composable
private fun MediumHero(state: HabiterWidgetState) {
    val habit = state.nextHabit ?: return
    Column(modifier = GlanceModifier.fillMaxSize().padding(18.dp)) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(todayLabel(state), style = mutedStyle(13))
            Spacer(GlanceModifier.defaultWeight())
            Text("${state.completedCount} / ${state.scheduledCount}", style = titleStyle(14))
        }
        Spacer(GlanceModifier.height(8.dp))
        ProgressSegments(state)
        Spacer(GlanceModifier.height(12.dp))
        Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text("${habit.icon} ${habit.name}", maxLines = 1, style = titleStyle(19))
                Text(habit.scheduleLabel, maxLines = 1, style = mutedStyle(13))
            }
            Spacer(GlanceModifier.width(12.dp))
            CompleteControl(state, habit, compact = false)
        }
    }
}

@Composable
private fun HabitList(state: HabiterWidgetState, maximumHabits: Int, padding: Int) {
    Column(modifier = GlanceModifier.fillMaxSize().padding(padding.dp)) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Text(todayLabel(state), style = titleStyle(17))
            Spacer(GlanceModifier.defaultWeight())
            Text("${state.completedCount} / ${state.scheduledCount}", style = titleStyle(15))
        }
        Spacer(GlanceModifier.height(9.dp))
        ProgressSegments(state)
        Spacer(GlanceModifier.height(12.dp))
        state.habits.take(maximumHabits).forEach { habit ->
            HabitRow(state, habit)
            Spacer(GlanceModifier.height(7.dp))
        }
    }
}

@Composable
private fun HabitRow(state: HabiterWidgetState, habit: HabiterWidgetHabit) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(HabiterWidgetTheme.surfaceAccent)
            .cornerRadius(14.dp)
            .padding(horizontal = 12.dp, vertical = 9.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Text(if (habit.completed) "✓" else habit.icon, style = titleStyle(17))
        Spacer(GlanceModifier.width(10.dp))
        Text(habit.name, modifier = GlanceModifier.defaultWeight(), maxLines = 1, style = titleStyle(15))
        if (!habit.completed) CompleteControl(state, habit, compact = true)
    }
}

@Composable
private fun CompleteControl(state: HabiterWidgetState, habit: HabiterWidgetHabit, compact: Boolean) {
    val action = completionAction(state, habit)
    Box(
        modifier = GlanceModifier
            .background(HabiterWidgetTheme.primary)
            .cornerRadius(14.dp)
            .clickable(onClick = action)
            .semantics { contentDescription = if (state.isGerman) "${habit.name} erledigen" else "Complete ${habit.name}" }
            .padding(horizontal = if (compact) 12.dp else 14.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(if (compact) "✓" else completeLabel(state), style = TextStyle(color = HabiterWidgetTheme.surface, fontSize = 13.sp, fontWeight = FontWeight.Bold))
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
private fun ProgressSegments(state: HabiterWidgetState) {
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        repeat(state.scheduledCount.coerceIn(1, 8)) { index ->
            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .height(5.dp)
                    .background(if (index < state.completedCount) HabiterWidgetTheme.success else HabiterWidgetTheme.surfaceAccent)
                    .cornerRadius(3.dp),
            ) {}
            if (index < state.scheduledCount - 1) Spacer(GlanceModifier.width(4.dp))
        }
    }
}

@Composable
private fun CompletedState(state: HabiterWidgetState, layout: HabiterWidgetLayout) {
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(if (layout == HabiterWidgetLayout.COMPACT) 10.dp else 20.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        Text("✓", style = TextStyle(color = HabiterWidgetTheme.success, fontSize = if (layout == HabiterWidgetLayout.COMPACT) 22.sp else 38.sp, fontWeight = FontWeight.Bold))
        if (layout != HabiterWidgetLayout.COMPACT) {
            Spacer(GlanceModifier.height(8.dp))
            Text(if (state.isGerman) "Alles für heute erledigt." else "Everything for today is done.", maxLines = 2, style = titleStyle(17))
        }
    }
}

@Composable
private fun EmptyState(layout: HabiterWidgetLayout, isGerman: Boolean, english: String, german: String) {
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(if (layout == HabiterWidgetLayout.COMPACT) 12.dp else 20.dp),
        verticalAlignment = Alignment.Vertical.CenterVertically,
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        Text(if (isGerman) german else english, maxLines = if (layout == HabiterWidgetLayout.COMPACT) 1 else 3, style = titleStyle(if (layout == HabiterWidgetLayout.COMPACT) 14 else 17))
    }
}

private fun progressLabel(state: HabiterWidgetState): String =
    if (state.locale.startsWith("de")) "Heute ${state.completedCount}/${state.scheduledCount}" else "Today ${state.completedCount}/${state.scheduledCount}"

private fun todayLabel(state: HabiterWidgetState): String = if (state.locale.startsWith("de")) "Heute" else "Today"

private fun completeLabel(state: HabiterWidgetState): String = if (state.locale.startsWith("de")) "Erledigen" else "Complete"

private val HabiterWidgetState.isGerman: Boolean
    get() = locale.startsWith("de", ignoreCase = true)

private fun titleStyle(size: Int) = TextStyle(color = HabiterWidgetTheme.onSurface, fontSize = size.sp, fontWeight = FontWeight.Medium)

private fun mutedStyle(size: Int) = TextStyle(color = HabiterWidgetTheme.onSurfaceMuted, fontSize = size.sp)
