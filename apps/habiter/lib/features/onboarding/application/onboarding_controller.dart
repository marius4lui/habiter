enum OnboardingState { welcome, active }

abstract final class OnboardingController {
  static OnboardingState stateFor(Iterable<Object> habits) =>
      habits.isEmpty ? OnboardingState.welcome : OnboardingState.active;
}
