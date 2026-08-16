import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';

import '../domain/widget_bridge.dart';
import '../domain/widget_snapshot.dart';

final class AndroidWidgetBridge implements WidgetBridge {
  const AndroidWidgetBridge();

  static const snapshotKey = 'habiter_widget_snapshot';
  static const receiverName = 'HabiterWidgetReceiver';
  static const qualifiedReceiverName =
      'com.habiter.app.widget.HabiterWidgetReceiver';
  static const _pinChannel = MethodChannel('com.habiter.app/widget_pin');

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
      await _pinChannel.invokeMethod<bool>('hasInstalledWidgets') ?? false;

  @override
  Future<bool> isPinningSupported() async =>
      await _pinChannel.invokeMethod<bool>('isSupported') ?? false;

  @override
  Future<WidgetPinResult> requestPin() async {
    if (!await isPinningSupported()) return WidgetPinResult.unsupported;
    final requested =
        await _pinChannel.invokeMethod<bool>('requestPin') ?? false;
    if (!requested) return WidgetPinResult.failed;
    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final result = await _pinChannel.invokeMethod<String>('pinResult');
      if (result == 'pinned') return WidgetPinResult.pinned;
    }
    return WidgetPinResult.declined;
  }
}
