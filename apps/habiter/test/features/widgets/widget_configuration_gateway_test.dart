import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/data/android_widget_bridge.dart';
import 'package:habiter/features/widgets/domain/widget_configuration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.habiter/widget-config');
  const bridge = AndroidWidgetBridge(channel: channel, supported: true);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('typed bridge lists, saves and resets one widget instance', () async {
    final calls = <MethodCall>[];
    final source = WidgetConfiguration(
      widgetId: 17,
      displayName: 'Training',
      contentMode: WidgetContentMode.focus,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'listWidgetInstances') {
            return <Map<String, Object?>>[
              <String, Object?>{
                'widgetId': 17,
                'widthDp': 250,
                'heightDp': 120,
                'breakpoint': 'mediumHero',
                'configuration': source.toJson(),
              },
            ];
          }
          if (call.method == 'pendingWidgetConfiguration') return 17;
          return null;
        });

    final pendingWidgetId = await bridge.pendingWidgetConfiguration();
    final instances = await bridge.listWidgetInstances();
    await bridge.saveWidgetConfiguration(
      instances.single.configuration.copyWith(
        contentMode: WidgetContentMode.minimal,
      ),
    );
    await bridge.resetWidgetConfiguration(17);
    await bridge.cancelWidgetConfiguration();

    expect(pendingWidgetId, 17);
    expect(instances.single.widgetId, 17);
    expect(instances.single.breakpoint, WidgetBreakpoint.mediumHero);
    expect(instances.single.configuration.displayName, 'Training');
    expect(calls.map((call) => call.method), <String>[
      'pendingWidgetConfiguration',
      'listWidgetInstances',
      'saveWidgetConfiguration',
      'resetWidgetConfiguration',
      'cancelWidgetConfiguration',
    ]);
    expect(calls[2].arguments, <String, Object?>{
      'widgetId': 17,
      'configuration': isA<String>(),
    });
    expect(calls[3].arguments, <String, Object?>{'widgetId': 17});
  });

  test('typed bridge rejects malformed instance payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => <Object?>[
            <String, Object?>{'widgetId': 17},
          ],
        );

    expect(bridge.listWidgetInstances(), throwsFormatException);
  });

  test('unsupported platforms expose a safe empty no-op gateway', () async {
    const unsupported = AndroidWidgetBridge(channel: channel, supported: false);

    expect(await unsupported.listWidgetInstances(), isEmpty);
    expect(await unsupported.pendingWidgetConfiguration(), isNull);
    await unsupported.saveWidgetConfiguration(
      WidgetConfiguration.defaults(widgetId: 17),
    );
    await unsupported.resetWidgetConfiguration(17);
    await unsupported.cancelWidgetConfiguration();
  });
}
