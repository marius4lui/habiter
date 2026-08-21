import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/adaptive_presentation.dart';

void main() {
  testWidgets('compact and medium layouts use a full-width sheet', (
    tester,
  ) async {
    for (final size in <Size>[const Size(320, 480), const Size(700, 900)]) {
      await _pumpLauncher(tester, size);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habiter-adaptive-sheet')), findsOneWidget);
      expect(find.byKey(const Key('habiter-adaptive-dialog')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('habiter-adaptive-sheet'))).width,
        size.width,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('expanded and large layouts use a bounded dialog', (
    tester,
  ) async {
    for (final size in <Size>[const Size(840, 700), const Size(1440, 900)]) {
      await _pumpLauncher(tester, size);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dialog = find.byKey(const Key('habiter-adaptive-dialog'));
      expect(dialog, findsOneWidget);
      expect(find.byKey(const Key('habiter-adaptive-sheet')), findsNothing);
      expect(tester.getSize(dialog).width, 720);
      expect(tester.getSize(dialog).height, lessThanOrEqualTo(800));
      final rect = tester.getRect(dialog);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('short compact viewport remains fully operable at 200% text', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      const Size(480, 320),
      textScaler: const TextScaler.linear(2),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('habiter-adaptive-sheet'));
    expect(tester.getSize(sheet), const Size(480, 320));
    expect(find.text('Adaptive editor'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showHabiterAdaptivePane<void>(
                context: context,
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Adaptive editor')),
                  body: Center(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}
