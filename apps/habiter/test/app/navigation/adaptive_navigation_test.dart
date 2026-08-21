import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/app/navigation/app_route.dart';
import 'package:habiter/app/navigation/app_router.dart';
import 'package:habiter/app/shell/adaptive_app_shell.dart';
import 'package:habiter/core/design_system/layout.dart';
import 'package:habiter/core/design_system/tokens.dart';

void main() {
  test('route codec handles deep links and canonical restoration', () {
    expect(AppRouteCodec.decode('/'), AppRoute.today);
    expect(AppRouteCodec.decode('/analytics?range=week'), AppRoute.analytics);
    expect(AppRouteCodec.decode('/rhythm'), AppRoute.rhythm);
    expect(AppRouteCodec.decode('/settings'), AppRoute.settings);
    expect(AppRouteCodec.decode('/unknown'), AppRoute.today);
    expect(AppRouteCodec.encode(AppRoute.appLock), '/app-lock');
    expect(AppRouteCodec.encode(AppRoute.rhythm), '/rhythm');
  });

  testWidgets('shell stays adaptive from 320px through desktop', (
    tester,
  ) async {
    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_fixture());
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpAt(const Size(320, 720));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.pumpWidget(_fixture(selected: AppRoute.analytics));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);

    await pumpAt(const Size(HabiterLayout.expandedMinWidth - 1, 800));
    await tester.pumpWidget(_fixture(selected: AppRoute.analytics));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await pumpAt(const Size(HabiterLayout.expandedMinWidth, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    await pumpAt(const Size(HabiterLayout.largeMinWidth, 800));
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    expect(find.text('Habiter'), findsOneWidget);
  });

  testWidgets('content state survives bottom-navigation and rail changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _fixture(selected: AppRoute.analytics, child: const _StatefulCounter()),
    );

    await tester.tap(find.text('Count 0'));
    await tester.pump();
    expect(find.text('Count 1'), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 700);
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Count 1'), findsOneWidget);

    tester.view.physicalSize = const Size(700, 1000);
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Count 1'), findsOneWidget);
  });

  testWidgets('keyboard shortcuts select primary destinations', (tester) async {
    var selected = AppRoute.today;
    await tester.pumpWidget(
      _fixture(
        selected: AppRoute.analytics,
        onSelected: (route) => selected = route,
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(selected, AppRoute.analytics);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(selected, AppRoute.rhythm);
  });

  testWidgets('compact pill navigation selects a different page on tap', (
    tester,
  ) async {
    var selected = AppRoute.today;
    await tester.pumpWidget(
      _fixture(
        selected: AppRoute.analytics,
        onSelected: (route) => selected = route,
      ),
    );

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.height, 60);
    expect(
      tester
          .widget<ClipRRect>(
            find.ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(ClipRRect),
            ),
          )
          .borderRadius,
      BorderRadius.circular(HabiterRadius.pill),
    );

    await tester.tap(find.text('Today'));
    await tester.pump();

    expect(selected, AppRoute.today);

    await tester.tap(find.text('Rhythm'));
    await tester.pump();

    expect(selected, AppRoute.rhythm);
  });

  testWidgets('primary shell never implies a back button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => _fixtureShell())),
            child: const Text('Open shell'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open shell'));
    await tester.pumpAndSettle();

    expect(
      Navigator.of(tester.element(find.byType(AdaptiveAppShell))).canPop(),
      isTrue,
    );
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('secondary routes pop back to the primary shell', (tester) async {
    final router = AppRouter(
      primaryBuilder: (_, _) => Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          child: const Text('Open settings'),
        ),
      ),
      settingsBuilder: (_) => const Scaffold(body: Text('Settings page')),
      appLockBuilder: (_) => const Scaffold(body: Text('App lock page')),
      updatesBuilder: (_) => const Scaffold(body: Text('Updates page')),
    );
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: router.initialRoutes,
        onGenerateRoute: router.routeFor,
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open settings'), findsOneWidget);
  });
}

Widget _fixture({
  AppRoute selected = AppRoute.today,
  ValueChanged<AppRoute>? onSelected,
  Widget child = const ColoredBox(color: Colors.white),
}) => MaterialApp(
  home: _fixtureShell(selected: selected, onSelected: onSelected, child: child),
);

Widget _fixtureShell({
  AppRoute selected = AppRoute.today,
  ValueChanged<AppRoute>? onSelected,
  Widget child = const ColoredBox(color: Colors.white),
}) => AdaptiveAppShell(
  selected: selected,
  onSelected: onSelected ?? (_) {},
  onOpenSettings: () {},
  onOpenAppLock: () {},
  child: child,
);

class _StatefulCounter extends StatefulWidget {
  const _StatefulCounter();

  @override
  State<_StatefulCounter> createState() => _StatefulCounterState();
}

class _StatefulCounterState extends State<_StatefulCounter> {
  var count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => setState(() => count += 1),
      child: Text('Count $count'),
    ),
  );
}
