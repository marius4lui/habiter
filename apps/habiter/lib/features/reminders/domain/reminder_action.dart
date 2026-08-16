import 'reminder_signal.dart';

enum ReminderActionKind {
  open('open'),
  complete('complete'),
  snooze('snooze'),
  feasibilityGood('feasibility_good'),
  feasibilityMaybe('feasibility_maybe'),
  feasibilityBad('feasibility_bad');

  const ReminderActionKind(this.platformId);
  final String platformId;

  factory ReminderActionKind.fromPlatformId(String? value) => switch (value) {
    'mark_complete' || 'complete' => ReminderActionKind.complete,
    'snooze' => ReminderActionKind.snooze,
    'feasibility_good' => ReminderActionKind.feasibilityGood,
    'feasibility_maybe' => ReminderActionKind.feasibilityMaybe,
    'feasibility_bad' => ReminderActionKind.feasibilityBad,
    _ => ReminderActionKind.open,
  };

  FeasibilityRating? get feasibility => switch (this) {
    ReminderActionKind.feasibilityGood => FeasibilityRating.good,
    ReminderActionKind.feasibilityMaybe => FeasibilityRating.maybe,
    ReminderActionKind.feasibilityBad => FeasibilityRating.bad,
    _ => null,
  };
}
