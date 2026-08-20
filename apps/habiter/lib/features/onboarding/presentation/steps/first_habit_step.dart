import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/habit.dart';
import '../../../habits/presentation/templates/habit_template.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

class FirstHabitStep extends StatefulWidget {
  const FirstHabitStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<FirstHabitStep> createState() => _FirstHabitStepState();
}

class _FirstHabitStepState extends State<FirstHabitStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode(debugLabel: 'onboarding custom habit name');
  late final TextEditingController _name;
  bool _custom = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.controller.state.habitDraft?.name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _rankedTemplates(widget.controller.state.intent);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return OnboardingScaffold(
      step: OnboardingStep.firstHabit,
      title: context.l10n.onboardingFirstHabitTitle,
      subtitle: context.l10n.onboardingFirstHabitBody,
      onBack: widget.controller.back,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: largeText ? 286 : 164,
            child: ListView.separated(
              key: const ValueKey<String>('onboarding-template-strip'),
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: HabiterSpace.sm),
              itemBuilder: (context, index) => _TemplateSeed(
                index: index,
                width: largeText ? 212 : 164,
                template: templates[index],
                onTap: () => _selectTemplate(templates[index]),
              ),
            ),
          ),
          const SizedBox(height: HabiterSpace.md),
          OutlinedButton.icon(
            key: const ValueKey<String>('onboarding-custom-habit-toggle'),
            onPressed: _toggleCustom,
            icon: Icon(_custom ? Icons.close_rounded : Icons.edit_rounded),
            label: Text(context.l10n.customHabitAction),
          ),
          if (_custom) ...<Widget>[
            const SizedBox(height: HabiterSpace.md),
            Container(
              padding: const EdgeInsets.all(HabiterSpace.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(HabiterRadius.prominent),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      key: const ValueKey<String>('custom-habit-name'),
                      controller: _name,
                      focusNode: _nameFocus,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.l10n.onboardingCustomHabitName,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? context.l10n.nameRequired
                          : null,
                      onFieldSubmitted: (_) => _selectCustom(),
                    ),
                    const SizedBox(height: HabiterSpace.sm),
                    FilledButton(
                      onPressed: _selectCustom,
                      child: Text(context.l10n.continueLabel),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleCustom() {
    setState(() => _custom = !_custom);
    if (_custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocus.requestFocus();
      });
    }
  }

  Future<void> _selectTemplate(HabitTemplate template) async {
    await context.read<HapticGateway>().selection();
    if (!mounted) return;
    await widget.controller.selectHabit(
      OnboardingHabitDraft(
        name: template.localizedName(context.l10n),
        category: template.category,
        icon: template.icon,
        color: template.color,
        frequency: template.frequency,
        targetCount: template.targetCount,
        customDays: template.customDays,
        templateId: template.id,
      ),
    );
  }

  Future<void> _selectCustom() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    await context.read<HapticGateway>().selection();
    if (!mounted) return;
    await widget.controller.selectHabit(
      OnboardingHabitDraft(
        name: name,
        category: _category(widget.controller.state.intent),
        icon: '✓',
        color: '#285943',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      ),
    );
  }

  List<HabitTemplate> _rankedTemplates(OnboardingIntent? intent) {
    final group = _group(intent);
    final catalog = HabitTemplate.catalog.toList();
    catalog.sort((a, b) {
      final aScore = a.groups.contains(group)
          ? 0
          : a.groups.contains(HabitTemplateGroup.popular)
          ? 1
          : 2;
      final bScore = b.groups.contains(group)
          ? 0
          : b.groups.contains(HabitTemplateGroup.popular)
          ? 1
          : 2;
      return aScore.compareTo(bScore);
    });
    return catalog.take(8).toList(growable: false);
  }

  HabitTemplateGroup _group(OnboardingIntent? intent) => switch (intent) {
    OnboardingIntent.health => HabitTemplateGroup.health,
    OnboardingIntent.fitness => HabitTemplateGroup.fitness,
    OnboardingIntent.mindfulness => HabitTemplateGroup.mindfulness,
    OnboardingIntent.learning => HabitTemplateGroup.learning,
    OnboardingIntent.productivity => HabitTemplateGroup.productivity,
    OnboardingIntent.home => HabitTemplateGroup.home,
    OnboardingIntent.finance => HabitTemplateGroup.finance,
    _ => HabitTemplateGroup.popular,
  };

  String _category(OnboardingIntent? intent) => switch (intent) {
    OnboardingIntent.fitness => HabitCategories.fitness,
    OnboardingIntent.mindfulness => HabitCategories.mindfulness,
    OnboardingIntent.learning => HabitCategories.learning,
    OnboardingIntent.productivity => HabitCategories.productivity,
    OnboardingIntent.home => HabitCategories.home,
    OnboardingIntent.finance => HabitCategories.finance,
    _ => HabitCategories.health,
  };
}

class _TemplateSeed extends StatelessWidget {
  const _TemplateSeed({
    required this.index,
    required this.width,
    required this.template,
    required this.onTap,
  });

  final int index;
  final double width;
  final HabitTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = template.localizedName(context.l10n);
    return Semantics(
      button: true,
      label: name,
      child: SizedBox(
        width: width,
        child: Material(
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiterRadius.prominent),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(HabiterSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(template.icon, style: const TextStyle(fontSize: 28)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: HabiterSpace.xs),
                  Text(
                    _schedule(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _schedule(BuildContext context) => switch (template.frequency) {
    HabitFrequency.daily => context.l10n.onboardingEveryDay,
    HabitFrequency.weekly => context.l10n.onboardingTimesPerWeek(
      template.targetCount,
    ),
    HabitFrequency.custom => context.l10n.onboardingSpecificDays,
  };
}
