import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/app/navigation/app_route.dart';
import 'package:habiter/app/navigation/app_router.dart';
import 'package:habiter/app/shell/adaptive_app_shell.dart';

void main() {
  test('route codec handles deep links and canonical restoration', () {
    expect(AppRouteCodec.decode('/'), AppRoute.today);
    expect(AppRouteCodec.decode('/analytics?range=week'), AppRoute.analytics);
    expect(AppRouteCodec.decode('/settings'), AppRoute.settings);
    expect(AppRouteCodec.decode('/unknown'), AppRoute.today);
    expect(AppRouteCodec.encode(AppRoute.appLock), '/app-lock');
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await pumpAt(const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('keyboard shortcuts select primary destinations', (tester) async {
    var selected = AppRoute.today;
    await tester.pumpWidget(_fixture(onSelected: (route) => selected = route));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(selected, AppRoute.analytics);
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

Widget _fixture({ValueChanged<AppRoute>? onSelected}) => MaterialApp(
  home: AdaptiveAppShell(
    selected: AppRoute.today,
    onSelected: onSelected ?? (_) {},
    onOpenSettings: () {},
    onOpenAppLock: () {},
    child: const ColoredBox(color: Colors.white),
  ),
);
