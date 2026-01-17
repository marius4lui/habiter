import 'package:flutter/material.dart';

/// Responsive breakpoint definitions for Habiter.
///
/// Mobile: < 600px
/// Tablet: 600-1023px
/// Desktop: >= 1024px
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  /// Maximum content width for zen layout
  static const double maxContentWidth = 1200;

  /// Check if current screen is mobile sized
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  /// Check if current screen is tablet sized
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < tablet;

  /// Check if current screen is desktop sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Get number of grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 5;
    if (width >= 1200) return 4;
    if (width >= tablet) return 3;
    if (width >= mobile) return 3;
    return 2;
  }

  /// Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  }
}

/// A widget that centers its child with a maximum width constraint.
/// Perfect for the zen layout on wide screens.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
