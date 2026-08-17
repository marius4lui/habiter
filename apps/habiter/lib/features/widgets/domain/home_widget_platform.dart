import 'package:flutter/foundation.dart';

bool homeWidgetSupportedFor({
  required bool isWeb,
  required TargetPlatform platform,
}) =>
    !isWeb &&
    (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

bool get supportsHomeWidget =>
    homeWidgetSupportedFor(isWeb: kIsWeb, platform: defaultTargetPlatform);
