import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/home_widget_platform.dart';

void main() {
  test('home widgets are available only on Android and iOS native apps', () {
    for (final platform in TargetPlatform.values) {
      expect(homeWidgetSupportedFor(isWeb: true, platform: platform), isFalse);
      expect(
        homeWidgetSupportedFor(isWeb: false, platform: platform),
        platform == TargetPlatform.android || platform == TargetPlatform.iOS,
      );
    }
  });
}
