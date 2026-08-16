import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/motion.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_state.dart';
import '../../widgets/domain/widget_bridge.dart';
import 'onboarding_scaffold.dart';
import 'steps/first_habit_step.dart';
import 'steps/habit_ready_step.dart';
import 'steps/intent_step.dart';
import 'steps/reminder_step.dart';
import 'steps/rhythm_step.dart';
import 'steps/welcome_step.dart';
import 'steps/widget_intro_step.dart';
import 'steps/widget_pin_step.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final step = controller.state.currentStep;
    return AnimatedSwitcher(
      duration: HabiterMotion.standard.duration(reduced: context.reduceMotion),
      switchInCurve: HabiterMotion.standard.curve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _step(context, controller, step),
    );
  }

  Widget _step(
    BuildContext context,
    OnboardingController controller,
    OnboardingStep step,
  ) {
    if (step == OnboardingStep.welcome || step == OnboardingStep.notStarted) {
      return WelcomeStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.welcome),
        controller: controller,
      );
    }
    if (step == OnboardingStep.intent) {
      return IntentStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.intent),
        controller: controller,
      );
    }
    if (step == OnboardingStep.firstHabit) {
      return FirstHabitStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.firstHabit),
        controller: controller,
      );
    }
    if (step == OnboardingStep.rhythm && controller.state.habitDraft != null) {
      return RhythmStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.rhythm),
        controller: controller,
      );
    }
    if (step == OnboardingStep.reminder &&
        controller.state.habitDraft != null) {
      return ReminderStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.reminder),
        controller: controller,
      );
    }
    if (step == OnboardingStep.habitReady &&
        controller.state.habitDraft != null) {
      return HabitReadyStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.habitReady),
        controller: controller,
      );
    }
    if (step == OnboardingStep.widgetIntro) {
      return WidgetIntroStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.widgetIntro),
        controller: controller,
      );
    }
    if (step == OnboardingStep.widgetPin) {
      return WidgetPinStep(
        key: const ValueKey<OnboardingStep>(OnboardingStep.widgetPin),
        controller: controller,
        bridge: context.read<WidgetBridge>(),
      );
    }
    return OnboardingScaffold(
      key: ValueKey<OnboardingStep>(step),
      step: _progress(step),
      title: _title(step),
      subtitle: 'Your setup is saved automatically.',
      onBack: controller.back,
      body: Center(
        child: Icon(
          _icon(step),
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  int _progress(OnboardingStep step) => switch (step) {
    OnboardingStep.intent => 2,
    OnboardingStep.firstHabit => 3,
    OnboardingStep.rhythm => 4,
    OnboardingStep.reminder => 5,
    OnboardingStep.habitReady => 6,
    OnboardingStep.widgetIntro => 7,
    OnboardingStep.widgetPin => 8,
    _ => 1,
  };

  String _title(OnboardingStep step) => switch (step) {
    OnboardingStep.intent => 'What would you like to strengthen?',
    OnboardingStep.firstHabit => 'Start with something small.',
    OnboardingStep.rhythm => 'How often does this fit your life?',
    OnboardingStep.reminder => 'Would you like a reminder?',
    OnboardingStep.habitReady => 'Your first habit is ready.',
    OnboardingStep.widgetIntro => 'Habiter belongs on your home screen.',
    OnboardingStep.widgetPin => 'Add the widget',
    _ => 'Habiter',
  };

  IconData _icon(OnboardingStep step) => switch (step) {
    OnboardingStep.intent => Icons.explore_rounded,
    OnboardingStep.firstHabit => Icons.add_task_rounded,
    OnboardingStep.rhythm => Icons.calendar_month_rounded,
    OnboardingStep.reminder => Icons.notifications_none_rounded,
    OnboardingStep.habitReady => Icons.check_circle_rounded,
    OnboardingStep.widgetIntro => Icons.widgets_rounded,
    OnboardingStep.widgetPin => Icons.add_to_home_screen_rounded,
    _ => Icons.eco_rounded,
  };
}
