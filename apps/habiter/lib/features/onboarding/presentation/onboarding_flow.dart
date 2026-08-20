import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/motion.dart';
import '../../widgets/domain/widget_bridge.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_state.dart';
import 'onboarding_scaffold.dart';
import 'steps/first_habit_step.dart';
import 'steps/habit_ready_step.dart';
import 'steps/intent_step.dart';
import 'steps/reminder_step.dart';
import 'steps/rhythm_explainer_step.dart';
import 'steps/rhythm_step.dart';
import 'steps/welcome_step.dart';
import 'steps/widget_intro_step.dart';
import 'steps/widget_pin_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final currentStep = controller.state.currentStep;
    final duration = HabiterMotion.standard.duration(
      reduced: context.reduceMotion,
    );
    final pages = <Page<void>>[
      for (final step in OnboardingProgress.through(currentStep))
        _OnboardingPage(
          key: ValueKey<OnboardingStep>(step),
          name: '/onboarding/${step.name}',
          duration: duration,
          child: KeyedSubtree(
            key: ValueKey<String>('onboarding-page-${step.name}'),
            child: _step(context, controller, step),
          ),
        ),
    ];

    return NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navigatorKey.currentState?.pop(),
      child: Navigator(
        key: _navigatorKey,
        pages: pages,
        onDidRemovePage: (page) => _didRemovePage(controller, page),
      ),
    );
  }

  void _didRemovePage(OnboardingController controller, Page<Object?> page) {
    final key = page.key;
    if (key is! ValueKey<OnboardingStep>) return;
    if (controller.state.currentStep != key.value) return;
    unawaited(controller.back());
  }

  Widget _step(
    BuildContext context,
    OnboardingController controller,
    OnboardingStep step,
  ) {
    if (step == OnboardingStep.welcome || step == OnboardingStep.notStarted) {
      return WelcomeStep(controller: controller);
    }
    if (step == OnboardingStep.intent) {
      return IntentStep(controller: controller);
    }
    if (step == OnboardingStep.firstHabit) {
      return FirstHabitStep(controller: controller);
    }
    if (step == OnboardingStep.rhythm && controller.state.habitDraft != null) {
      return RhythmStep(controller: controller);
    }
    if (step == OnboardingStep.rhythmExplainer &&
        controller.state.habitDraft != null) {
      return RhythmExplainerStep(controller: controller);
    }
    if (step == OnboardingStep.reminder &&
        controller.state.habitDraft != null) {
      return ReminderStep(controller: controller);
    }
    if (step == OnboardingStep.habitReady &&
        controller.state.habitDraft != null) {
      return HabitReadyStep(controller: controller);
    }
    if (step == OnboardingStep.widgetIntro) {
      return WidgetIntroStep(controller: controller);
    }
    if (step == OnboardingStep.widgetPin) {
      return WidgetPinStep(
        controller: controller,
        bridge: context.read<WidgetBridge>(),
      );
    }
    return OnboardingScaffold(
      step: step,
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

  String _title(OnboardingStep step) => switch (step) {
    OnboardingStep.intent => 'What would you like to strengthen?',
    OnboardingStep.firstHabit => 'Start with something small.',
    OnboardingStep.rhythm => 'How often does this fit your life?',
    OnboardingStep.rhythmExplainer => 'How your habit counts.',
    OnboardingStep.reminderModel => 'Reminders help with timing.',
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
    OnboardingStep.rhythmExplainer => Icons.calendar_view_week_rounded,
    OnboardingStep.reminderModel => Icons.schedule_rounded,
    OnboardingStep.reminder => Icons.notifications_none_rounded,
    OnboardingStep.habitReady => Icons.check_circle_rounded,
    OnboardingStep.widgetIntro => Icons.widgets_rounded,
    OnboardingStep.widgetPin => Icons.add_to_home_screen_rounded,
    _ => Icons.eco_rounded,
  };
}

final class _OnboardingPage extends Page<void> {
  const _OnboardingPage({
    required super.key,
    required super.name,
    required this.duration,
    required this.child,
  });

  final Duration duration;
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (_, _, _) => child,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: HabiterMotion.standard.curve,
              ),
            ),
        child: child,
      ),
    ),
  );
}
