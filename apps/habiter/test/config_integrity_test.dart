import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Configuration Integrity Tests', () {
    test('release builds fail closed without signing material', () {
      final buildFile = File('android/app/build.gradle.kts').readAsStringSync();

      expect(buildFile, contains('releaseSigningAvailable'));
      expect(
        buildFile,
        contains('if (releaseRequested && !releaseSigningAvailable)'),
        reason: 'Every Android release build must require signing material.',
      );
      expect(buildFile, contains('Release signing files are required'));
    });

    test('AndroidManifest.xml should not request exact-alarm permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'AndroidManifest.xml not found',
      );

      final content = manifestFile.readAsStringSync();
      expect(
        content.contains('android.permission.SCHEDULE_EXACT_ALARM'),
        isFalse,
        reason:
            'Reminders use inexact scheduling by default and must not request '
            'the restricted exact-alarm permission.',
      );
    });

    test('release builds can access the update service', () {
      final content = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.ACCESS_NETWORK_STATE'));
    });

    test('mobile sync handoff has narrow verified and fallback links', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final info = File('ios/Runner/Info.plist').readAsStringSync();
      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(manifest, contains('android:autoVerify="true"'));
      expect(manifest, contains('android:host="mobile.habiter.dev"'));
      expect(manifest, contains('android:path="/auth/callback"'));
      expect(manifest, contains('android:scheme="dev.habiter.app"'));
      expect(info, contains('<string>dev.habiter.app</string>'));
      expect(entitlements, contains('applinks:mobile.habiter.dev'));
      expect(
        RegExp(
          'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;',
        ).allMatches(project).length,
        3,
      );
    });

    test('direct and store update flavors have isolated installer access', () {
      final buildFile = File('android/app/build.gradle.kts').readAsStringSync();
      final mainManifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final directManifest = File(
        'android/app/src/direct/AndroidManifest.xml',
      ).readAsStringSync();
      final storeManifest = File(
        'android/app/src/store/AndroidManifest.xml',
      ).readAsStringSync();

      expect(buildFile, contains('create("direct")'));
      expect(buildFile, contains('create("store")'));
      expect(buildFile, contains('applicationId = "com.habiter.app"'));
      expect(
        buildFile,
        isNot(contains('applicationIdSuffix')),
        reason: 'Both update distributions must upgrade the same app ID.',
      );
      expect(directManifest, contains('REQUEST_INSTALL_PACKAGES'));
      expect(directManifest, contains('androidx.core.content.FileProvider'));
      expect(mainManifest, isNot(contains('REQUEST_INSTALL_PACKAGES')));
      expect(storeManifest, isNot(contains('REQUEST_INSTALL_PACKAGES')));
      expect(storeManifest, isNot(contains('FileProvider')));
    });

    test('scheduled notifications declare delivery and action receivers', () {
      final content = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(content, contains('ScheduledNotificationReceiver'));
      expect(content, contains('ScheduledNotificationBootReceiver'));
      expect(content, contains('ActionBroadcastReceiver'));
      expect(content, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });

    test('iOS delegates foreground notification presentation', () {
      final content = File('ios/Runner/AppDelegate.swift').readAsStringSync();

      expect(content, contains('import UserNotifications'));
      expect(
        content,
        contains('UNUserNotificationCenter.current().delegate = self'),
      );
    });

    test(
      'proguard-rules.pro should exist and contain Gson and Local Notifications rules',
      () {
        final proguardFile = File('android/app/proguard-rules.pro');
        expect(
          proguardFile.existsSync(),
          isTrue,
          reason: 'proguard-rules.pro not found',
        );

        final content = proguardFile.readAsStringSync();

        expect(
          content.contains('-keepattributes Signature'),
          isTrue,
          reason:
              'Missing -keepattributes Signature in proguard-rules.pro. '
              'Required for Gson generics to work with R8/ProGuard.',
        );

        expect(
          content.contains('-keepattributes *Annotation*'),
          isTrue,
          reason: 'Missing -keepattributes *Annotation* in proguard-rules.pro.',
        );

        expect(
          content.contains('com.google.gson.**'),
          isTrue,
          reason:
              'Missing keep rule for com.google.gson.** in proguard-rules.pro.',
        );

        // This one is specific to the plugin likely causing issues, though generic Gson rules might cover it.
        // But adding it explicitly is safer.
        expect(
          content.contains('com.dexterous.flutterlocalnotifications.**'),
          isTrue,
          reason:
              'Missing keep rule for com.dexterous.flutterlocalnotifications.** in proguard-rules.pro.',
        );
      },
    );
  });
}
