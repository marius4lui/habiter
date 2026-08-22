import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../providers/habit_provider.dart';
import '../../../runtime/infrastructure/method_channel_background_runtime_gateway.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
import '../onboarding_scaffold.dart';

class ReminderStep extends StatefulWidget {
  const ReminderStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<ReminderStep> createState() => _ReminderStepState();
}

class _ReminderStepState extends State<ReminderStep> {
  late bool _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.state.habitDraft!;
    _enabled = draft.reminderEnabled;
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.reminder,
    title: context.l10n.onboardingReminderTitle,
    subtitle: context.l10n.onboardingReminderBody,
    onBack: _saving ? null : widget.controller.back,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HabitIllustration(
          kind: HabitIllustrationKind.reminder,
          step: OnboardingStep.reminder,
          semanticLabel: context.l10n.onboardingReminderTitle,
          height: 132,
        ),
        const SizedBox(height: HabiterSpace.md),
        _ReminderChoice(
          code: '01',
          selected: !_enabled,
          label: context.l10n.onboardingNoReminder,
          onTap: () => _setEnabled(false),
        ),
        _ReminderChoice(
          code: '02',
          selected: _enabled,
          label: context.l10n.onboardingAddReminder,
          onTap: () => _setEnabled(true),
        ),
        if (_enabled) ...<Widget>[
          const SizedBox(height: HabiterSpace.sm),
          Container(
            padding: const EdgeInsets.all(HabiterSpace.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(HabiterRadius.prominent),
            ),
            child: Column(
              children: <Widget>[
                _ReminderFact(
                  code: '01',
                  title: context.l10n.onboardingSmartCalibrationTitle,
                  body: context.l10n.onboardingSmartCalibrationBody,
                ),
                _ReminderFact(
                  code: '02',
                  title: context.l10n.onboardingSmartFrequencyTitle,
                  body: context.l10n.onboardingSmartFrequencyBody,
                ),
                _ReminderFact(
                  code: '03',
                  title: context.l10n.onboardingSmartPrivacyTitle,
                  body: context.l10n.onboardingSmartPrivacyBody,
                ),
                _ReminderFact(
                  code: '04',
                  title: context.l10n.onboardingSmartControlTitle,
                  body: context.l10n.onboardingSmartControlBody,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
        if (_saving) ...<Widget>[
          const SizedBox(height: HabiterSpace.lg),
          const LinearProgressIndicator(minHeight: 4),
          const SizedBox(height: HabiterSpace.sm),
          Text(context.l10n.onboardingSaving, textAlign: TextAlign.center),
        ],
      ],
    ),
    primaryAction: FilledButton(
      onPressed: _saving ? null : _createHabit,
      child: Text(context.l10n.continueLabel),
    ),
  );

  Future<void> _setEnabled(bool value) async {
    await context.read<HapticGateway>().selection();
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  Future<void> _createHabit() async {
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    final haptics = context.read<HapticGateway>();
    var reminderEnabled = _enabled;
    if (reminderEnabled) {
      reminderEnabled = await provider.requestHabitReminderPermission();
    }
    if (!mounted) return;
    final draft = widget.controller.state.habitDraft!.copyWith(
      reminderEnabled: reminderEnabled,
      reminderTime: null,
      clearReminderTime: true,
    );
    await widget.controller.configureReminder(draft);
    final id = await widget.controller.reserveFirstHabitId();
    await provider.addHabit(
      id: id,
      name: draft.name,
      category: draft.category,
      frequency: draft.frequency,
      targetCount: draft.targetCount,
      color: draft.color,
      icon: draft.icon,
      customDays: draft.customDays,
      notificationEnabled: draft.reminderEnabled,
      notificationTime: draft.reminderTime,
    );
    if (draft.reminderEnabled) {
      await provider.enableSmartReminders(requestPermission: false);
      await provider.markReminderIntroductionSeen();
    }
    await haptics.success();
    await widget.controller.markHabitReady(
      backgroundSetupRequired:
          draft.reminderEnabled &&
          const MethodChannelBackgroundRuntimeGateway().isSupported,
    );
  }
}

class _ReminderFact extends StatelessWidget {
  const _ReminderFact({
    required this.code,
    required this.title,
    required this.body,
    this.showDivider = true,
  });

  final String code;
  final String title;
  final String body;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            code,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: HabiterSpace.sm2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: HabiterSpace.xs),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (showDivider) const Divider(height: HabiterSpace.lg),
    ],
  );
}

class _ReminderChoice extends StatelessWidget {
  const _ReminderChoice({
    required this.code,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.primary : scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiterRadius.card),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: selected ? 1 : 0.16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(HabiterSpace.md),
                child: Row(
                  children: <Widget>[
                    Text(
                      code,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: HabiterSpace.md),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: foreground, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: selected
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: foreground,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
