import 'package:habiter/core/platform/notification_gateway.dart';

final class NotificationCall {
  const NotificationCall(this.operation, [this.id]);

  final String operation;
  final int? id;
}

final class RecordingNotificationGateway implements NotificationGateway {
  final Map<int, NotificationRequest> _pending = <int, NotificationRequest>{};
  final List<NotificationCall> calls = <NotificationCall>[];
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
    calls.add(const NotificationCall('initialize'));
  }

  @override
  Future<void> schedule(NotificationRequest request) async {
    _pending[request.id] = request;
    calls.add(NotificationCall('schedule', request.id));
  }

  @override
  Future<void> cancel(int id) async {
    _pending.remove(id);
    calls.add(NotificationCall('cancel', id));
  }

  @override
  Future<List<NotificationRequest>> pending() async {
    calls.add(const NotificationCall('pending'));
    return List<NotificationRequest>.unmodifiable(_pending.values);
  }
}
