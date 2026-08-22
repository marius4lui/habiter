import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'layout.dart';
import 'tokens.dart';

/// Presents an editor as a full-width sheet on compact/medium layouts and as
/// a bounded dialog on expanded/large layouts.
Future<T?> showHabiterAdaptivePane<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 720,
  double maxHeight = 800,
  bool frameSheet = true,
}) {
  final layout = HabiterLayout.of(context);
  if (layout.atLeast(HabiterLayoutClass.expanded)) {
    return showDialog<T>(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) => _HabiterDialogFrame(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        child: builder(dialogContext),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (sheetContext) {
      final child = builder(sheetContext);
      return frameSheet ? _HabiterSheetFrame(child: child) : child;
    },
  );
}

class _HabiterSheetFrame extends StatelessWidget {
  const _HabiterSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = HabiterLayout.of(context);
    final height = layout.isShort
        ? layout.viewport.height
        : layout.viewport.height * .96;
    return SizedBox(
      key: const Key('habiter-adaptive-sheet'),
      width: double.infinity,
      height: height,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HabiterRadius.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _HabiterDialogFrame extends StatelessWidget {
  const _HabiterDialogFrame({
    required this.child,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final height = math
        .min(maxHeight, math.max(0.0, viewport.height - 48))
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(HabiterSpace.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HabiterRadius.prominent),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        key: const Key('habiter-adaptive-dialog'),
        width: maxWidth,
        height: height,
        child: child,
      ),
    );
  }
}
