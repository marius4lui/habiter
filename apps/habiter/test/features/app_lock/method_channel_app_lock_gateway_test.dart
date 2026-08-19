import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/domain/app_lock_gateway.dart';
import 'package:habiter/features/app_lock/domain/app_block_projection.dart';
import 'package:habiter/features/app_lock/infrastructure/method_channel_app_lock_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.habiter/applock');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('typed adapter preserves method names, arguments and results', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getInstalledApps' => <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'org.example.app',
                'appName': 'Example',
                'iconBytes': <int>[1, 2],
              },
            ],
            'getRecentUsage' => <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'org.example.app',
                'appName': 'Example',
                'foregroundMilliseconds': 120000,
                'lastUsedMilliseconds': 1787133600000,
              },
            ],
            'hasUsageStatsPermission' || 'hasOverlayPermission' => true,
            'startMonitoring' => true,
            'isBatteryOptimized' => false,
            _ => null,
          };
        });
    const gateway = MethodChannelAppLockGateway(
      channel: channel,
      supported: true,
    );

    expect(
      (await gateway.installedApps() as AppLockSuccess).value,
      hasLength(1),
    );
    expect((await gateway.recentUsage() as AppLockSuccess).value, hasLength(1));
    final permissions =
        (await gateway.permissions()
                as AppLockSuccess<AppLockPermissionSnapshot>)
            .value;
    expect(permissions.ready, isTrue);
    expect(
      (await gateway.start(<String>['org.example.app']) as AppLockSuccess<bool>)
          .value,
      isTrue,
    );
    await gateway.syncCompletion(
      complete: false,
      incompleteHabitNames: <String>['Walk'],
    );
    await gateway.publishProjections(
      AppBlockProjectionSnapshot(const <AppBlockGateProjection>[]),
    );
    await gateway.stop();

    expect(
      calls.map((call) => call.method),
      containsAll(<String>[
        'getInstalledApps',
        'getRecentUsage',
        'hasUsageStatsPermission',
        'hasOverlayPermission',
        'startMonitoring',
        'updateIncompleteHabits',
        'habitsIncomplete',
        'updateGateProjections',
        'stopMonitoring',
      ]),
    );
    expect(
      calls.firstWhere((call) => call.method == 'startMonitoring').arguments,
      <String, Object?>{
        'lockedPackages': <String>['org.example.app'],
      },
    );
  });

  test('unsupported and platform errors are typed and fail open', () async {
    const unsupported = MethodChannelAppLockGateway(
      channel: channel,
      supported: false,
    );
    expect(
      await unsupported.start(<String>['app']),
      isA<AppLockFailure<bool>>().having(
        (failure) => failure.kind,
        'kind',
        AppLockFailureKind.unsupported,
      ),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) => throw PlatformException(code: 'denied'),
        );
    const failing = MethodChannelAppLockGateway(
      channel: channel,
      supported: true,
    );
    expect(
      await failing.stop(),
      isA<AppLockFailure<void>>().having(
        (failure) => failure.kind,
        'kind',
        AppLockFailureKind.platform,
      ),
    );
  });
}
