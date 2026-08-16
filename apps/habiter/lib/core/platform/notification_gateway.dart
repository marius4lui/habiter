import 'dart:collection';

enum NotificationCategory { reminder, calibration, fineTuning, overview }

final class NotificationActionSpec {
  const NotificationActionSpec({
    required this.id,
    required this.title,
    this.opensApp = false,
  });

  final String id;
  final String title;
  final bool opensApp;
}

final class NotificationRequest {
  NotificationRequest({
    required this.id,
    required this.scheduledFor,
    required this.title,
    required this.body,
    Map<String, String> payload = const <String, String>{},
    this.category = NotificationCategory.reminder,
    Iterable<NotificationActionSpec> actions = const <NotificationActionSpec>[],
  }) : payload = UnmodifiableMapView<String, String>(payload),
       actions = List<NotificationActionSpec>.unmodifiable(actions);

  final int id;
  final DateTime scheduledFor;
  final String title;
  final String body;
  final Map<String, String> payload;
  final NotificationCategory category;
  final List<NotificationActionSpec> actions;
}

abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<void> schedule(NotificationRequest request);

  Future<void> cancel(int id);

  Future<List<NotificationRequest>> pending();
}
