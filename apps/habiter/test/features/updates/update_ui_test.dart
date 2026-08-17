import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/features/updates/application/update_controller.dart';
import 'package:habiter/features/updates/data/signed_manifest_client.dart';
import 'package:habiter/features/updates/data/update_local_repository.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_platform_gateway.dart';
import 'package:habiter/features/updates/domain/update_policy.dart';
import 'package:habiter/features/updates/presentation/release_story_screen.dart';
import 'package:habiter/features/updates/presentation/update_center_screen.dart';
import 'package:habiter/features/updates/presentation/update_experience_gate.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';
import 'update_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Update Center is localized and usable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _idleController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        textScale: 1.6,
        controller: controller,
        home: const UpdateCenterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update-Center'), findsWidgets);
    expect(find.text('Jetzt prüfen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ausgewogen'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ausgewogen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aggregated story supports dark, wide and reduced-motion UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final releases = manifestOf([
      _storyRelease(build: 10500, channel: 'stable'),
      releaseJson(build: 10400, channel: 'stable'),
    ]).releases;
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        dark: true,
        disableAnimations: true,
        home: ReleaseStoryScreen(
          releases: releases,
          isUpgrade: true,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update installed'), findsOneWidget);
    await _scrollStoryUntilVisible(tester, find.text('Details by version'));
    expect(find.text('Details by version'), findsOneWidget);
    expect(find.text('Habiter ${releases.first.version}'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('German story stays usable on a compact phone at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final releases = manifestOf([
      _storyRelease(build: 10500, channel: 'stable'),
    ]).releases;
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        textScale: 2,
        disableAnimations: true,
        home: ReleaseStoryScreen(
          releases: releases,
          isUpgrade: false,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollStoryUntilVisible(tester, find.text('Später'));

    expect(find.text('Später'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a future mandatory deadline shows a live rounded countdown', (
    tester,
  ) async {
    final releases = manifestOf([
      releaseJson(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: DateTime.now().add(const Duration(minutes: 90)),
      ),
    ]).releases;
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        home: ReleaseStoryScreen(
          releases: releases,
          isUpgrade: false,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Required in 2 hours'), findsOneWidget);
  });

  testWidgets('verified online deadline replaces the app with mandatory UI', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      releaseJson(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    final controller = await _checkedController(fixture, now: now);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        controller: controller,
        home: const UpdateExperienceGate(child: Text('private habits')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('private habits'), findsNothing);
  });

  testWidgets('offline expired cache warns but leaves the app usable', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      releaseJson(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    final platform = _FakePlatform(buildNumber: 10400)
      ..network = const UpdateNetworkStatus(isOnline: false, isMetered: false);
    final controller = await _controller(
      fixture,
      now: now,
      platform: platform,
      cacheEnvelope: true,
    );
    await controller.check(UpdateCheckTrigger.manual);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        controller: controller,
        home: const UpdateExperienceGate(child: Text('private habits')),
      ),
    );
    await tester.pump();

    expect(find.text('private habits'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('a verified mandatory screen fails open after going offline', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      releaseJson(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    final platform = _FakePlatform(buildNumber: 10400);
    final controller = await _controller(fixture, now: now, platform: platform);
    await controller.check(UpdateCheckTrigger.manual);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        controller: controller,
        home: const UpdateExperienceGate(child: Text('private habits')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);

    platform.network = const UpdateNetworkStatus(
      isOnline: false,
      isMetered: false,
    );
    await controller.check(UpdateCheckTrigger.manual);
    await tester.pump();

    expect(find.text('private habits'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('Update Center light golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      _storyRelease(build: 10500, channel: 'stable'),
    ]);
    final controller = await _checkedController(fixture, now: now);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        controller: controller,
        home: const UpdateCenterScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(UpdateCenterScreen),
      matchesGoldenFile('goldens/update_center_de_light.png'),
    );
  });

  testWidgets('aggregated release story dark golden', (tester) async {
    tester.view.physicalSize = const Size(900, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final releases = manifestOf([
      _storyRelease(build: 10500, channel: 'stable'),
      releaseJson(build: 10400, channel: 'stable'),
    ]).releases;
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        dark: true,
        disableAnimations: true,
        home: ReleaseStoryScreen(
          releases: releases,
          isUpgrade: true,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ReleaseStoryScreen),
      matchesGoldenFile('goldens/release_story_en_dark.png'),
    );
  });

  testWidgets('Update Center English dark wide golden', (tester) async {
    tester.view.physicalSize = const Size(900, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      _storyRelease(build: 10500, channel: 'stable'),
    ]);
    final controller = await _checkedController(fixture, now: now);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        dark: true,
        controller: controller,
        home: const UpdateCenterScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(UpdateCenterScreen),
      matchesGoldenFile('goldens/update_center_en_dark_wide.png'),
    );
  });

  testWidgets('German release story light compact golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final releases = manifestOf([
      _storyRelease(build: 10500, channel: 'stable'),
    ]).releases;
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        textScale: 1.3,
        disableAnimations: true,
        home: ReleaseStoryScreen(
          releases: releases,
          isUpgrade: false,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ReleaseStoryScreen),
      matchesGoldenFile('goldens/release_story_de_light_compact.png'),
    );
  });

  testWidgets('German mandatory update dark golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 8, 17, 12);
    final fixture = await _signed([
      _storyRelease(
        build: 10500,
        channel: 'stable',
        mandatoryAfter: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    final controller = await _checkedController(fixture, now: now);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        dark: true,
        controller: controller,
        home: const UpdateExperienceGate(child: Text('habits')),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(UpdateExperienceGate),
      matchesGoldenFile('goldens/mandatory_update_de_dark.png'),
    );
  });
}

Map<String, Object?> _storyRelease({
  required int build,
  required String channel,
  DateTime? mandatoryAfter,
}) {
  final release = releaseJson(
    build: build,
    channel: channel,
    mandatoryAfter: mandatoryAfter,
  );
  final presentations = release['presentation']! as Map<String, Object?>;
  for (final entry in <String, List<Map<String, Object?>>>{
    'de': [
      {
        'id': 'verified',
        'title': 'Sicher verifiziert',
        'description': 'Signatur, Größe und Hash werden vollständig geprüft.',
        'icon': 'security',
      },
      {
        'id': 'profiles',
        'title': 'Dein Profil',
        'description': 'Du bestimmst Intervall und erlaubte Netzwerke.',
        'icon': 'speed',
      },
      {
        'id': 'stories',
        'title': 'Alles Neue',
        'description': 'Highlights und Details bleiben übersichtlich.',
        'icon': 'history',
      },
    ],
    'en': [
      {
        'id': 'verified',
        'title': 'Verified safely',
        'description': 'Signature, size, and hash are checked end to end.',
        'icon': 'security',
      },
      {
        'id': 'profiles',
        'title': 'Your profile',
        'description': 'You control the interval and allowed networks.',
        'icon': 'speed',
      },
      {
        'id': 'stories',
        'title': 'What is new',
        'description': 'Highlights and details remain easy to explore.',
        'icon': 'history',
      },
    ],
  }.entries) {
    final presentation = presentations[entry.key]! as Map<String, Object?>;
    presentation['highlights'] = entry.value;
  }
  return release;
}

Future<void> _scrollStoryUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pump();
  }
}

UpdateController _idleController() => UpdateController(
  repository: UpdateLocalRepository(InMemoryKeyValueStore()),
  client: SignedManifestClient(),
  verifier: ManifestVerifier(publicKeyRing: const {}),
  platform: _FakePlatform(buildNumber: 10400),
  clock: FakeClock(DateTime.utc(2026, 8, 17, 12)),
);

Future<UpdateController> _checkedController(
  ({String envelope, List<int> publicKey}) fixture, {
  required DateTime now,
}) async {
  final controller = await _controller(
    fixture,
    now: now,
    platform: _FakePlatform(buildNumber: 10400),
  );
  await controller.check(UpdateCheckTrigger.manual);
  return controller;
}

Future<UpdateController> _controller(
  ({String envelope, List<int> publicKey}) fixture, {
  required DateTime now,
  required _FakePlatform platform,
  bool cacheEnvelope = false,
}) async {
  final repository = UpdateLocalRepository(InMemoryKeyValueStore());
  await repository.save(
    UpdateLocalState(
      profile: UpdateProfile.saver,
      previousAppBuild: 10400,
      lastCheckedAt: now,
      cachedEnvelope: cacheEnvelope ? fixture.envelope : null,
    ),
  );
  final controller = UpdateController(
    repository: repository,
    client: SignedManifestClient(
      client: MockClient(
        (_) async => http.Response(
          fixture.envelope,
          200,
          headers: {'etag': '"manifest"'},
        ),
      ),
    ),
    verifier: ManifestVerifier(publicKeyRing: {'test-key': fixture.publicKey}),
    platform: platform,
    clock: FakeClock(now),
  );
  await controller.initialize();
  return controller;
}

Future<({String envelope, List<int> publicKey})> _signed(
  List<Map<String, Object?>> releases,
) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(
    List<int>.generate(32, (index) => index),
  );
  final payload = manifestPayload(releases);
  final signature = await algorithm.sign(payload, keyPair: keyPair);
  final publicKey = await keyPair.extractPublicKey();
  String encode(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');
  return (
    envelope: jsonEncode({
      'schemaVersion': 1,
      'keyId': 'test-key',
      'algorithm': 'ed25519',
      'payload': encode(payload),
      'signature': encode(signature.bytes),
    }),
    publicKey: publicKey.bytes,
  );
}

Widget _app({
  required Locale locale,
  required Widget home,
  UpdateController? controller,
  bool dark = false,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  final app = MaterialApp(
    locale: locale,
    theme: HabiterTheme.light(),
    darkTheme: HabiterTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: home,
  );
  return controller == null
      ? app
      : ChangeNotifierProvider.value(value: controller, child: app);
}

final class _FakePlatform implements UpdatePlatformGateway {
  _FakePlatform({required int buildNumber})
    : info = UpdateRuntimeInfo(
        platform: 'android',
        version: '1.4.0',
        buildNumber: buildNumber,
        supportsUpdates: true,
        supportsDirectInstall: true,
        androidDistribution: AndroidDistribution.direct,
      );

  final UpdateRuntimeInfo info;
  UpdateNetworkStatus network = const UpdateNetworkStatus(
    isOnline: true,
    isMetered: false,
  );

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) async {}

  @override
  Future<void> clearDownloads() async {}

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async =>
      const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.missing,
        downloadedBytes: 0,
        totalBytes: 0,
      );

  @override
  Future<String> enqueueDownload(
    UpdateCandidate candidate, {
    required bool allowMetered,
  }) async => 'download';

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async => UpdateInstallResult.launched;

  @override
  Future<UpdateNetworkStatus> networkStatus() async => network;

  @override
  Future<void> openInstallerPermission() async {}

  @override
  Future<UpdateInstallResult> openExternal(UpdateCandidate candidate) async =>
      UpdateInstallResult.externalOpened;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<UpdateRuntimeInfo> runtimeInfo() async => info;

  @override
  Future<int> storedDownloadBytes() async => 0;

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async => const UpdateVerificationResult.valid();
}
