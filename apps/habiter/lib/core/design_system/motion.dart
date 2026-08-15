import 'package:flutter/material.dart';

final class MotionToken {
  const MotionToken(this.normal, this.curve);

  final Duration normal;
  final Curve curve;

  Duration duration({required bool reduced}) =>
      reduced ? Duration.zero : normal;
}

abstract final class HabiterMotion {
  static const quick = MotionToken(Duration(milliseconds: 120), Curves.easeOut);
  static const standard = MotionToken(
    Duration(milliseconds: 220),
    Curves.easeOutCubic,
  );
  static const emphasized = MotionToken(
    Duration(milliseconds: 420),
    Curves.easeInOutCubic,
  );

  static int particleBudget({required bool reduced}) => reduced ? 0 : 12;
}

extension MotionMediaQuery on BuildContext {
  bool get reduceMotion {
    final media = MediaQuery.maybeOf(this);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }
}
