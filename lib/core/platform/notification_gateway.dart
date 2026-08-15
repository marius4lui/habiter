import 'dart:collection';

final class NotificationRequest {
  NotificationRequest({
    required this.id,
    required this.scheduledFor,
    required this.title,
    required this.body,
    Map<String, String> payload = const <String, String>{},
  }) : payload = UnmodifiableMapView<String, String>(payload);

  final int id;
  final DateTime scheduledFor;
  final String title;
  final String body;
  final Map<String, String> payload;
}

abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<void> schedule(NotificationRequest request);

  Future<void> cancel(int id);

  Future<List<NotificationRequest>> pending();
}
