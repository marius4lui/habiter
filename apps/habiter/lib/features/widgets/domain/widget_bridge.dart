import 'widget_snapshot.dart';

enum WidgetPinResult { requested, pinned, declined, unsupported, failed }

abstract interface class WidgetBridge {
  Future<void> publish(WidgetSnapshot snapshot);

  Future<void> updateAll();

  Future<bool> isPinningSupported();

  Future<WidgetPinResult> requestPin();

  Future<bool> hasInstalledWidgets();
}
