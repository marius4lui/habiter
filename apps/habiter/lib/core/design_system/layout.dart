import 'package:flutter/material.dart';

/// Semantic viewport classes used by every Habiter presentation layer.
///
/// Layout decisions should depend on these classes and available content space,
/// not on device names or duplicated width comparisons in individual screens.
enum HabiterLayoutClass { compact, medium, expanded, large }

/// Canonical responsive-layout information for the current viewport.
@immutable
final class HabiterLayout {
  const HabiterLayout._({required this.viewport, required this.layoutClass});

  factory HabiterLayout.fromSize(Size viewport) {
    assert(viewport.width >= 0);
    assert(viewport.height >= 0);
    return HabiterLayout._(
      viewport: viewport,
      layoutClass: classForWidth(viewport.width),
    );
  }

  factory HabiterLayout.of(BuildContext context) =>
      HabiterLayout.fromSize(MediaQuery.sizeOf(context));

  static const mediumMinWidth = 600.0;
  static const expandedMinWidth = 840.0;
  static const largeMinWidth = 1200.0;
  static const shortHeight = 600.0;

  final Size viewport;
  final HabiterLayoutClass layoutClass;

  static HabiterLayoutClass classForWidth(double width) {
    assert(width >= 0);
    if (width < mediumMinWidth) return HabiterLayoutClass.compact;
    if (width < expandedMinWidth) return HabiterLayoutClass.medium;
    if (width < largeMinWidth) return HabiterLayoutClass.expanded;
    return HabiterLayoutClass.large;
  }

  bool get isCompact => layoutClass == HabiterLayoutClass.compact;
  bool get isMedium => layoutClass == HabiterLayoutClass.medium;
  bool get isExpanded => layoutClass == HabiterLayoutClass.expanded;
  bool get isLarge => layoutClass == HabiterLayoutClass.large;

  bool atLeast(HabiterLayoutClass minimum) =>
      layoutClass.index >= minimum.index;

  bool get isShort => viewport.height < shortHeight;

  Orientation get orientation => viewport.width > viewport.height
      ? Orientation.landscape
      : Orientation.portrait;

  double get horizontalPagePadding => switch (layoutClass) {
    HabiterLayoutClass.compact => 16,
    HabiterLayoutClass.medium => 24,
    HabiterLayoutClass.expanded => 32,
    HabiterLayoutClass.large => 48,
  };

  /// Returns the largest useful column count for the layout class while still
  /// honoring a caller-provided minimum card width.
  int columnCount({
    required double availableWidth,
    required double minimumColumnWidth,
    double spacing = 16,
    int? maxColumns,
  }) {
    assert(availableWidth >= 0);
    assert(minimumColumnWidth > 0);
    assert(spacing >= 0);
    final classLimit = switch (layoutClass) {
      HabiterLayoutClass.compact => 1,
      HabiterLayoutClass.medium => 2,
      HabiterLayoutClass.expanded => 2,
      HabiterLayoutClass.large => 3,
    };
    final widthLimited =
        ((availableWidth + spacing) / (minimumColumnWidth + spacing))
            .floor()
            .clamp(1, classLimit);
    return maxColumns == null
        ? widthLimited
        : widthLimited.clamp(1, maxColumns);
  }
}

extension HabiterLayoutContext on BuildContext {
  HabiterLayout get habiterLayout => HabiterLayout.of(this);
}

typedef HabiterLayoutWidgetBuilder =
    Widget Function(BuildContext context, HabiterLayout layout);

/// Supplies semantic layout information based on the space allocated locally
/// to a subtree, rather than assuming the entire window is available to it.
class HabiterLayoutBuilder extends StatelessWidget {
  const HabiterLayoutBuilder({super.key, required this.builder});

  final HabiterLayoutWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = MediaQuery.sizeOf(context);
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : viewport.width;
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : viewport.height;
      return builder(context, HabiterLayout.fromSize(Size(width, height)));
    },
  );
}
