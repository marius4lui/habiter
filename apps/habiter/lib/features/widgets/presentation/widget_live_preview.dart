import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../models/habit.dart';
import '../domain/widget_configuration.dart';
import '../domain/widget_configuration_options.dart';
import '../domain/widget_configuration_projection.dart';
import '../domain/widget_habit_item.dart';

class WidgetLivePreview extends StatelessWidget {
  const WidgetLivePreview({
    super.key,
    required this.configuration,
    required this.habits,
    required this.breakpoint,
    required this.onBreakpointChanged,
  });

  final WidgetConfiguration configuration;
  final List<Habit> habits;
  final WidgetBreakpoint breakpoint;
  final ValueChanged<WidgetBreakpoint> onBreakpointChanged;

  @override
  Widget build(BuildContext context) {
    final items = habits
        .where((habit) => habit.isActive)
        .map(
          (habit) => WidgetHabitItem(
            id: habit.id,
            name: habit.name,
            icon: habit.icon,
            isCompleted: false,
            scheduleLabel: _scheduleLabel(context, habit),
          ),
        )
        .toList(growable: false);
    final projection = projectWidgetConfiguration(
      configuration: configuration,
      breakpoint: breakpoint,
      habits: items,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.widgetLivePreview,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            DropdownButton<WidgetBreakpoint>(
              key: const Key('widget-preview-breakpoint'),
              value: breakpoint,
              items: WidgetBreakpoint.values
                  .map(
                    (value) => DropdownMenuItem<WidgetBreakpoint>(
                      value: value,
                      child: Text(_breakpointLabel(context, value)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onBreakpointChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: HabiterSpace.sm),
        Semantics(
          key: const Key('widget-preview-semantics'),
          label: context.l10n.widgetLivePreviewSemantics(
            _breakpointLabel(context, breakpoint),
          ),
          image: true,
          child: Container(
            key: const Key('widget-live-preview'),
            height: 320,
            padding: const EdgeInsets.all(HabiterSpace.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(HabiterRadius.card),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final target = _previewSize(breakpoint, constraints.biggest);
                return Center(
                  child: SizedBox(
                    width: target.width,
                    height: target.height,
                    child: _ProjectedWidget(
                      projection: projection,
                      breakpoint: breakpoint,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectedWidget extends StatelessWidget {
  const _ProjectedWidget({required this.projection, required this.breakpoint});

  final WidgetConfigurationProjection projection;
  final WidgetBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final effective = projection.effective;
    final palette = _palette(context, effective);
    final padding =
        effective.outerPadding ??
        effective.geometry.horizontalPadding ??
        (breakpoint == WidgetBreakpoint.compact ? 10 : 16);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface.withValues(
            alpha: 1 - effective.surfaceTransparency,
          ),
          borderRadius: BorderRadius.circular(effective.cornerRadius ?? 24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: projection.habits.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.widgetPreviewEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.text),
                  ),
                )
              : _PreviewContent(projection: projection, palette: palette),
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.projection, required this.palette});

  final WidgetConfigurationProjection projection;
  final _PreviewPalette palette;

  @override
  Widget build(BuildContext context) {
    final effective = projection.effective;
    final minimal = effective.contentMode == WidgetContentMode.minimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!minimal && effective.shows(WidgetElement.todayHeader))
          Row(
            children: <Widget>[
              Text(
                context.l10n.today,
                style: _textStyle(effective, palette.text, 14, bold: true),
              ),
              const Spacer(),
              if (_showsCounter(effective))
                Text(
                  '${projection.completedCount} / ${projection.scheduledCount}',
                  style: _textStyle(effective, palette.text, 13, bold: true),
                ),
            ],
          ),
        if (!minimal && _showsSegments(effective)) ...<Widget>[
          SizedBox(height: effective.geometry.sectionGap ?? 8),
          _Segments(
            completed: projection.completedCount,
            total: projection.scheduledCount,
            effective: effective,
            palette: palette,
          ),
        ],
        if (!minimal) SizedBox(height: effective.geometry.sectionGap ?? 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: projection.habits
                .map(
                  (habit) => Padding(
                    padding: EdgeInsets.only(
                      bottom: effective.geometry.rowGap ?? 6,
                    ),
                    child: _HabitRow(
                      habit: habit,
                      effective: effective,
                      palette: palette,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.effective,
    required this.palette,
  });

  final WidgetHabitItem habit;
  final EffectiveWidgetConfiguration effective;
  final _PreviewPalette palette;

  @override
  Widget build(BuildContext context) {
    final minimal = effective.contentMode == WidgetContentMode.minimal;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: EdgeInsets.symmetric(
        horizontal: effective.geometry.horizontalPadding ?? 10,
        vertical: effective.geometry.verticalPadding ?? 7,
      ),
      decoration: minimal
          ? null
          : BoxDecoration(
              color: palette.surfaceAccent,
              borderRadius: BorderRadius.circular(
                effective.geometry.habitRowRadius ?? 14,
              ),
            ),
      child: Row(
        children: <Widget>[
          if (effective.shows(WidgetElement.habitIcon)) ...<Widget>[
            Text(habit.icon),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (effective.shows(WidgetElement.habitName))
                  Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      effective,
                      palette.text,
                      effective.typography.habitTitleSize ?? 14,
                      bold: true,
                    ),
                  ),
                if (!minimal && effective.shows(WidgetElement.scheduleLabel))
                  Text(
                    habit.scheduleLabel,
                    maxLines: 1,
                    style: _textStyle(
                      effective,
                      palette.muted,
                      effective.typography.secondaryTextSize ?? 10,
                    ),
                  ),
              ],
            ),
          ),
          if (effective.shows(WidgetElement.completionButton))
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(
                  effective.geometry.buttonRadius ?? 14,
                ),
              ),
              child: Icon(Icons.check_rounded, color: palette.onPrimary),
            ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.completed,
    required this.total,
    required this.effective,
    required this.palette,
  });

  final int completed;
  final int total;
  final EffectiveWidgetConfiguration effective;
  final _PreviewPalette palette;

  @override
  Widget build(BuildContext context) {
    final count = total.clamp(
      1,
      effective.progressSettings.maximumSegments ?? 8,
    );
    return Row(
      key: const Key('widget-preview-segments'),
      children: List<Widget>.generate(count, (index) {
        return Expanded(
          child: Container(
            height: effective.progressSettings.segmentHeight ?? 5,
            margin: EdgeInsetsDirectional.only(
              end: index == count - 1
                  ? 0
                  : effective.progressSettings.segmentGap ?? 4,
            ),
            decoration: BoxDecoration(
              color: index < completed
                  ? palette.success
                  : palette.surfaceAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

TextStyle _textStyle(
  EffectiveWidgetConfiguration effective,
  Color color,
  double size, {
  bool bold = false,
}) => TextStyle(
  color: color,
  fontSize: size * effective.textScale,
  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
);

bool _showsSegments(EffectiveWidgetConfiguration effective) =>
    effective.shows(WidgetElement.progressSegments) &&
    effective.progressMode != WidgetProgressMode.hidden &&
    effective.progressMode != WidgetProgressMode.counter;

bool _showsCounter(EffectiveWidgetConfiguration effective) =>
    effective.shows(WidgetElement.counter) &&
    effective.progressMode != WidgetProgressMode.hidden &&
    effective.progressMode != WidgetProgressMode.segments;

_PreviewPalette _palette(
  BuildContext context,
  EffectiveWidgetConfiguration effective,
) {
  final scheme = Theme.of(context).colorScheme;
  final dark = effective.themeMode == WidgetThemeMode.dark;
  final defaults = dark
      ? const _PreviewPalette(
          surface: Color(0xFF10231B),
          surfaceAccent: Color(0xFF1B3A2C),
          primary: Color(0xFF8ED8B4),
          onPrimary: Color(0xFF10231B),
          text: Color(0xFFF1F7F3),
          muted: Color(0xFFB7C9BF),
          success: Color(0xFF90E1BB),
        )
      : const _PreviewPalette(
          surface: Color(0xFFFFFBF5),
          surfaceAccent: Color(0xFFE3F2E8),
          primary: Color(0xFF285943),
          onPrimary: Colors.white,
          text: Color(0xFF17211C),
          muted: Color(0xFF53635A),
          success: Color(0xFF1D6B4B),
        );
  if (effective.themeMode == WidgetThemeMode.system &&
      effective.accentMode == WidgetAccentMode.dynamicColor) {
    return _PreviewPalette(
      surface: scheme.surface,
      surfaceAccent: scheme.surfaceContainerHighest,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      text: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      success: scheme.tertiary,
    );
  }
  final tokens = effective.colorTokens;
  return _PreviewPalette(
    surface: _color(tokens.surface) ?? defaults.surface,
    surfaceAccent: _color(tokens.surfaceAccent) ?? defaults.surfaceAccent,
    primary: _color(tokens.primary) ?? defaults.primary,
    onPrimary: defaults.onPrimary,
    text: _color(tokens.text) ?? defaults.text,
    muted: _color(tokens.mutedText) ?? defaults.muted,
    success: _color(tokens.success) ?? defaults.success,
  );
}

Color? _color(String? source) {
  if (source == null) return null;
  final digits = source.replaceFirst('#', '');
  final value = int.tryParse(digits, radix: 16);
  if (value == null) return null;
  return Color(digits.length == 6 ? 0xFF000000 | value : value);
}

Size _previewSize(WidgetBreakpoint breakpoint, Size available) {
  final logical = switch (breakpoint) {
    WidgetBreakpoint.compact => const Size(180, 82),
    WidgetBreakpoint.compactSquare => const Size(150, 150),
    WidgetBreakpoint.wide => const Size(290, 86),
    WidgetBreakpoint.mediumHero => const Size(290, 155),
    WidgetBreakpoint.large => const Size(290, 215),
    WidgetBreakpoint.extraLarge => const Size(290, 285),
  };
  final scale = (available.width / logical.width)
      .clamp(0.5, 1.0)
      .clamp(0.5, available.height / logical.height);
  return logical * scale;
}

String _scheduleLabel(BuildContext context, Habit habit) =>
    switch (habit.frequency) {
      HabitFrequency.daily => context.l10n.daily,
      HabitFrequency.weekly => '${habit.targetCount}× · ${context.l10n.weekly}',
      HabitFrequency.custom => context.l10n.widgetScheduleCustom,
    };

String _breakpointLabel(BuildContext context, WidgetBreakpoint value) =>
    switch (value) {
      WidgetBreakpoint.compact => context.l10n.widgetBreakpointCompact,
      WidgetBreakpoint.compactSquare =>
        context.l10n.widgetBreakpointCompactSquare,
      WidgetBreakpoint.wide => context.l10n.widgetBreakpointWide,
      WidgetBreakpoint.mediumHero => context.l10n.widgetBreakpointMediumHero,
      WidgetBreakpoint.large => context.l10n.widgetBreakpointLarge,
      WidgetBreakpoint.extraLarge => context.l10n.widgetBreakpointExtraLarge,
    };

final class _PreviewPalette {
  const _PreviewPalette({
    required this.surface,
    required this.surfaceAccent,
    required this.primary,
    required this.onPrimary,
    required this.text,
    required this.muted,
    required this.success,
  });

  final Color surface;
  final Color surfaceAccent;
  final Color primary;
  final Color onPrimary;
  final Color text;
  final Color muted;
  final Color success;
}
