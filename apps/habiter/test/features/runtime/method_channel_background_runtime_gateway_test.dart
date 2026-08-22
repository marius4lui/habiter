import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/runtime/domain/background_runtime_gateway.dart';
import 'package:habiter/features/runtime/domain/runtime_feature_state.dart';
import 'package:habiter/features/runtime/infrastructure/method_channel_background_runtime_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.habiter/runtime');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getSnapshot' => <String, Object?>{
              'remindersEnabled': true,
              'appBlockEnabled': false,
              'notificationsGranted': true,
              'batteryOptimized': false,
            },
            'getDiagnostics' => <String, Object?>{
              'remindersEnabled': true,
              'appBlockEnabled': false,
              'runtimeStartedAt': 1710000000000,
              'lastStartReason': 'feature_change',
            },
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('decodes shared readiness and diagnostics snapshots', () async {
    const gateway = MethodChannelBackgroundRuntimeGateway(
      channel: channel,
      supported: true,
    );

    final snapshot = await gateway.snapshot();
    final diagnostics = await gateway.diagnostics();

    expect(
      snapshot,
      isA<BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>>(),
    );
    expect(
      (snapshot as BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>)
          .value
          .backgroundReady,
      isTrue,
    );
    expect(
      (diagnostics as BackgroundRuntimeSuccess).value.lastStartReason,
      'feature_change',
    );
  });

  test('reconcile sends the complete feature state', () async {
    const gateway = MethodChannelBackgroundRuntimeGateway(
      channel: channel,
      supported: true,
    );

    await gateway.reconcile(
      features: const RuntimeFeatureState(
        remindersEnabled: false,
        appBlockEnabled: true,
      ),
      reason: 'app_block_changed',
    );

    expect(calls.single.method, 'reconcile');
    expect(calls.single.arguments, <String, Object?>{
      'remindersEnabled': false,
      'appBlockEnabled': true,
      'reason': 'app_block_changed',
    });
  });
}
