import 'package:home_widget/home_widget.dart';

import '../domain/widget_bridge.dart';
import '../domain/widget_snapshot.dart';

final class AndroidWidgetBridge implements WidgetBridge {
  const AndroidWidgetBridge();

  static const snapshotKey = 'habiter_widget_snapshot';
  static const receiverName = 'HabiterWidgetReceiver';
  static const qualifiedReceiverName =
      'com.habiter.app.widget.HabiterWidgetReceiver';

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    final saved = await HomeWidget.saveWidgetData<String>(
      snapshotKey,
      snapshot.toJson(),
    );
    if (saved != true) throw StateError('Widget snapshot was not persisted.');
    await updateAll();
  }

  @override
  Future<void> updateAll() => HomeWidget.updateWidget(
    name: receiverName,
    qualifiedAndroidName: qualifiedReceiverName,
  );

  @override
  Future<bool> hasInstalledWidgets() async =>
      (await HomeWidget.getInstalledWidgets()).isNotEmpty;

  @override
  Future<bool> isPinningSupported() async =>
      await HomeWidget.isRequestPinWidgetSupported() ?? false;

  @override
  Future<WidgetPinResult> requestPin() async {
    if (!await isPinningSupported()) return WidgetPinResult.unsupported;
    await HomeWidget.requestPinWidget(
      name: receiverName,
      qualifiedAndroidName: qualifiedReceiverName,
    );
    return WidgetPinResult.requested;
  }
}
