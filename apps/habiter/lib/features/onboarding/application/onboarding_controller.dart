import 'package:flutter/foundation.dart';

import '../../../core/ids/id_generator.dart';
import '../../../core/time/clock.dart';
import 'onboarding_repository.dart';
import 'onboarding_state.dart';

final class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required OnboardingRepository repository,
    required IdGenerator ids,
    required Clock clock,
  }) : _repository = repository,
       _ids = ids,
       _clock = clock;

  final OnboardingRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  OnboardingState _state = const OnboardingState();
  bool _initialized = false;
  bool _loading = false;
  String? _diagnostic;

  OnboardingState get state => _state;
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get diagnostic => _diagnostic;
  bool get shouldShowOnboarding =>
      _initialized && !_state.isComplete && _diagnostic == null;

  Future<void> initialize({required bool hasExistingHabits}) async {
    if (_initialized || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final saved = await _repository.load();
      if (saved != null) {
        _state = saved;
      } else {
        final existingUser =
            hasExistingHabits || await _repository.hasPriorProductData();
        _state = existingUser
            ? OnboardingState(
                currentStep: OnboardingStep.completed,
                completedAt: _clock.now(),
              )
            : const OnboardingState(currentStep: OnboardingStep.welcome);
        await _repository.save(_state);
      }
      _diagnostic = null;
      _initialized = true;
    } catch (_) {
      _diagnostic = 'Onboarding state could not be loaded.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> start() => _moveTo(OnboardingStep.intent);

  Future<void> selectIntent(OnboardingIntent intent) => _replace(
    _state.copyWith(intent: intent, currentStep: OnboardingStep.firstHabit),
  );

  Future<void> selectHabit(OnboardingHabitDraft draft) => _replace(
    _state.copyWith(habitDraft: draft, currentStep: OnboardingStep.rhythm),
  );

  Future<void> configureRhythm(OnboardingHabitDraft draft) => _replace(
    _state.copyWith(
      habitDraft: draft,
      currentStep: OnboardingStep.rhythmExplainer,
    ),
  );

  Future<void> confirmRhythmUnderstanding() =>
      _moveTo(OnboardingStep.reminderModel);

  Future<void> confirmReminderModel() => _moveTo(OnboardingStep.reminder);

  Future<void> configureReminder(OnboardingHabitDraft draft) =>
      _replace(_state.copyWith(habitDraft: draft));

  Future<String> reserveFirstHabitId() async {
    final existing = _state.firstHabitId;
    if (existing != null) return existing;
    final id = _ids.next();
    await _replace(_state.copyWith(firstHabitId: id));
    return id;
  }

  Future<void> markHabitReady() => _replace(
    _state.copyWith(
      currentStep: OnboardingStep.widgetIntro,
      widgetPromotionState: WidgetPromotionState.presented,
    ),
  );

  Future<void> showWidgetIntro() => _replace(
    _state.copyWith(
      currentStep: OnboardingStep.widgetIntro,
      widgetPromotionState: WidgetPromotionState.presented,
    ),
  );

  Future<void> beginWidgetPin() =>
      _replace(_state.copyWith(currentStep: OnboardingStep.widgetPin));

  Future<void> recordWidgetPinAttempt() =>
      _replace(_state.copyWith(widgetPinAttempted: true));

  Future<void> deferWidget() => _complete(
    promotionState: WidgetPromotionState.deferred,
    widgetPinned: false,
  );

  Future<void> markWidgetPinned() => _complete(
    promotionState: WidgetPromotionState.pinned,
    widgetPinned: true,
  );

  Future<void> finishWithoutPin() => _complete(
    promotionState: _state.widgetPromotionState,
    widgetPinned: false,
  );

  Future<void> dismissWidgetPromotion() => _replace(
    _state.copyWith(widgetPromotionState: WidgetPromotionState.dismissed),
  );

  Future<void> back() {
    final previous = OnboardingProgress.previousOf(_state.currentStep);
    return _moveTo(previous);
  }

  Future<void> _complete({
    required WidgetPromotionState promotionState,
    required bool widgetPinned,
  }) => _replace(
    _state.copyWith(
      currentStep: OnboardingStep.completed,
      widgetPromotionState: promotionState,
      widgetPinned: widgetPinned,
      completedAt: _clock.now(),
    ),
  );

  Future<void> _moveTo(OnboardingStep step) =>
      _replace(_state.copyWith(currentStep: step));

  Future<void> _replace(OnboardingState next) async {
    await _repository.save(next);
    _state = next;
    _diagnostic = null;
    notifyListeners();
  }
}
