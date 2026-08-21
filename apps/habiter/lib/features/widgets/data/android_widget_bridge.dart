import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';

import '../domain/home_widget_platform.dart';
import '../domain/widget_bridge.dart';
import '../domain/widget_configuration.dart';
import '../domain/widget_configuration_gateway.dart';
import '../domain/widget_snapshot.dart';

final class AndroidWidgetBridge
    implements WidgetBridge, WidgetConfigurationGateway {
  const AndroidWidgetBridge({
    MethodChannel channel = const MethodChannel('com.habiter.app/widget_pin'),
    bool? supported,
  }) : _channel = channel,
       _supported = supported;

  static const snapshotKey = 'habiter_widget_snapshot';
  static const receiverName = 'HabiterWidgetReceiver';
  static const qualifiedReceiverName =
      'com.habiter.app.widget.HabiterWidgetReceiver';
  final MethodChannel _channel;
  final bool? _supported;

  bool get _isSupported => _supported ?? supportsHomeWidget;

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    if (!_isSupported) return;
    final saved = await HomeWidget.saveWidgetData<String>(
      snapshotKey,
      snapshot.toJson(),
    );
    if (saved != true) throw StateError('Widget snapshot was not persisted.');
    await updateAll();
  }

  @override
  Future<void> updateAll() async {
    if (!_isSupported) return;
    await HomeWidget.updateWidget(
      name: receiverName,
      qualifiedAndroidName: qualifiedReceiverName,
    );
  }

  @override
  Future<bool> hasInstalledWidgets() async {
    if (!_isSupported) return false;
    return await _channel.invokeMethod<bool>('hasInstalledWidgets') ?? false;
  }

  @override
  Future<bool> isPinningSupported() async {
    if (!_isSupported) return false;
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  @override
  Future<WidgetPinResult> requestPin() async {
    if (!await isPinningSupported()) return WidgetPinResult.unsupported;
    final requested = await _channel.invokeMethod<bool>('requestPin') ?? false;
    if (!requested) return WidgetPinResult.failed;
    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final result = await _channel.invokeMethod<String>('pinResult');
      if (result == 'pinned') return WidgetPinResult.pinned;
    }
    return WidgetPinResult.declined;
  }

  @override
  Future<List<WidgetInstance>> listWidgetInstances() async {
    if (!_isSupported) return const <WidgetInstance>[];
    final values = await _channel.invokeListMethod<Object?>(
      'listWidgetInstances',
    );
    if (values == null) return const <WidgetInstance>[];
    return values
        .map((value) {
          if (value is! Map) {
            throw const FormatException(
              'Widget instance response is malformed.',
            );
          }
          return WidgetInstance.fromMap(Map<String, Object?>.from(value));
        })
        .toList(growable: false);
  }

  @override
  Future<void> saveWidgetConfiguration(
    WidgetConfiguration configuration,
  ) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>(
      'saveWidgetConfiguration',
      <String, Object?>{
        'widgetId': configuration.widgetId,
        'configuration': configuration.toJson(),
      },
    );
  }

  @override
  Future<void> resetWidgetConfiguration(int widgetId) async {
    if (!_isSupported) return;
    await _channel.invokeMethod<void>(
      'resetWidgetConfiguration',
      <String, Object?>{'widgetId': widgetId},
    );
  }
}
