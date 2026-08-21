import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/components.dart';
import 'package:habiter/core/design_system/layout.dart';

void main() {
  test('canonical breakpoints resolve every boundary exactly once', () {
    expect(HabiterLayout.classForWidth(0), HabiterLayoutClass.compact);
    expect(HabiterLayout.classForWidth(599), HabiterLayoutClass.compact);
    expect(HabiterLayout.classForWidth(600), HabiterLayoutClass.medium);
    expect(HabiterLayout.classForWidth(839), HabiterLayoutClass.medium);
    expect(HabiterLayout.classForWidth(840), HabiterLayoutClass.expanded);
    expect(HabiterLayout.classForWidth(1199), HabiterLayoutClass.expanded);
    expect(HabiterLayout.classForWidth(1200), HabiterLayoutClass.large);
  });

  test('layout exposes orientation, short height, and ordering semantics', () {
    final compactDisplay = HabiterLayout.fromSize(const Size(480, 320));
    expect(compactDisplay.layoutClass, HabiterLayoutClass.compact);
    expect(compactDisplay.orientation, Orientation.landscape);
    expect(compactDisplay.isShort, isTrue);
    expect(compactDisplay.atLeast(HabiterLayoutClass.medium), isFalse);

    final desktop = HabiterLayout.fromSize(const Size(1440, 900));
    expect(desktop.isLarge, isTrue);
    expect(desktop.isShort, isFalse);
    expect(desktop.atLeast(HabiterLayoutClass.expanded), isTrue);
  });

  test('grid columns honor class limits and minimum card width', () {
    expect(
      HabiterLayout.fromSize(
        const Size(320, 600),
      ).columnCount(availableWidth: 320, minimumColumnWidth: 240),
      1,
    );
    expect(
      HabiterLayout.fromSize(
        const Size(700, 900),
      ).columnCount(availableWidth: 700, minimumColumnWidth: 260),
      2,
    );
    expect(
      HabiterLayout.fromSize(
        const Size(1000, 800),
      ).columnCount(availableWidth: 500, minimumColumnWidth: 260),
      1,
    );
    expect(
      HabiterLayout.fromSize(const Size(1440, 900)).columnCount(
        availableWidth: 1200,
        minimumColumnWidth: 260,
        maxColumns: 2,
      ),
      2,
    );
  });

  testWidgets('content padding follows the allocated layout class', (
    tester,
  ) async {
    Future<EdgeInsets> paddingAt(double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HabiterContent(child: Text('Content'))),
        ),
      );
      final padding = tester.widget<Padding>(
        find.ancestor(of: find.text('Content'), matching: find.byType(Padding)),
      );
      return padding.padding.resolve(TextDirection.ltr);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect((await paddingAt(320)).left, 16);
    expect((await paddingAt(700)).left, 24);
    expect((await paddingAt(1000)).left, 32);
    expect((await paddingAt(1440)).left, 48);
  });

  testWidgets('adaptive grid uses one, two, and three columns', (tester) async {
    Future<List<double>> cardWidthsAt(double width) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabiterAdaptiveGrid(
              minimumColumnWidth: 240,
              children: [
                for (var index = 0; index < 3; index++)
                  SizedBox(key: ValueKey('card-$index'), height: 40),
              ],
            ),
          ),
        ),
      );
      return [
        for (var index = 0; index < 3; index++)
          tester.getSize(find.byKey(ValueKey('card-$index'))).width,
      ];
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(await cardWidthsAt(320), everyElement(320));
    expect(await cardWidthsAt(700), everyElement(342));
    expect(await cardWidthsAt(1200), everyElement(389.3333333333333));
  });
}
