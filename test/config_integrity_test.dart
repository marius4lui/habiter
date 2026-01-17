import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Configuration Integrity Tests', () {
    test('AndroidManifest.xml should contain SCHEDULE_EXACT_ALARM permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml not found');

      final content = manifestFile.readAsStringSync();
      expect(
        content.contains('android.permission.SCHEDULE_EXACT_ALARM'),
        isTrue,
        reason: 'Missing SCHEDULE_EXACT_ALARM permission in AndroidManifest.xml. '
            'This is required for exact alarms on Android 12+.',
      );
    });

    test('proguard-rules.pro should exist and contain Gson and Local Notifications rules', () {
      final proguardFile = File('android/app/proguard-rules.pro');
      expect(proguardFile.existsSync(), isTrue, reason: 'proguard-rules.pro not found');

      final content = proguardFile.readAsStringSync();

      expect(
        content.contains('-keepattributes Signature'),
        isTrue,
        reason: 'Missing -keepattributes Signature in proguard-rules.pro. '
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
        reason: 'Missing keep rule for com.google.gson.** in proguard-rules.pro.',
      );

      // This one is specific to the plugin likely causing issues, though generic Gson rules might cover it.
      // But adding it explicitly is safer.
      expect(
        content.contains('com.dexterous.flutterlocalnotifications.**'),
        isTrue,
        reason: 'Missing keep rule for com.dexterous.flutterlocalnotifications.** in proguard-rules.pro.',
      );
    });
  });
}
