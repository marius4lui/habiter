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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _rankedTemplates(widget.controller.state.intent);
    return OnboardingScaffold(
      step: 3,
      title: context.l10n.onboardingFirstHabitTitle,
      subtitle: context.l10n.onboardingFirstHabitBody,
      onBack: widget.controller.back,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 132,
              crossAxisSpacing: HabiterSpace.sm,
              mainAxisSpacing: HabiterSpace.sm,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) => _TemplateCard(
              template: templates[index],
              onTap: () => _selectTemplate(templates[index]),
            ),
          ),
          const SizedBox(height: HabiterSpace.md),
          OutlinedButton.icon(
            onPressed: () => setState(() => _custom = !_custom),
            icon: const Icon(Icons.edit_rounded),
            label: Text(context.l10n.customHabitAction),
          ),
          if (_custom) ...<Widget>[
            const SizedBox(height: HabiterSpace.md),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.onboardingCustomHabitName,
              ),
              onSubmitted: (_) => _selectCustom(),
            ),
            const SizedBox(height: HabiterSpace.sm),
            FilledButton(
              onPressed: _selectCustom,
              child: Text(context.l10n.continueLabel),
            ),
          ],
        ],
      ),
    );
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
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await context.read<HapticGateway>().selection();
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: template.localizedName(context.l10n),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HabiterSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(template.icon, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              Text(
                template.localizedName(context.l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _schedule(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _schedule(BuildContext context) => switch (template.frequency) {
    HabitFrequency.daily => context.l10n.onboardingEveryDay,
    HabitFrequency.weekly => context.l10n.onboardingTimesPerWeek(
      template.targetCount,
    ),
    HabitFrequency.custom => context.l10n.onboardingSpecificDays,
  };
}
