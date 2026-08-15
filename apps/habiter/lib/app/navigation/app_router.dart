import 'package:flutter/material.dart';

import 'app_route.dart';

typedef PrimaryRouteBuilder = Widget Function(BuildContext, AppRoute);

final class AppRouter {
  const AppRouter({
    required this.primaryBuilder,
    required this.settingsBuilder,
    required this.appLockBuilder,
  });

  final PrimaryRouteBuilder primaryBuilder;
  final WidgetBuilder settingsBuilder;
  final WidgetBuilder appLockBuilder;

  List<Route<void>> initialRoutes(String location) => <Route<void>>[
    routeFor(RouteSettings(name: location)),
  ];

  Route<void> routeFor(RouteSettings settings) {
    final route = AppRouteCodec.decode(settings.name ?? '/');
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: AppRouteCodec.encode(route)),
      builder: (context) => switch (route) {
        AppRoute.settings => settingsBuilder(context),
        AppRoute.appLock => appLockBuilder(context),
        _ => primaryBuilder(context, route),
      },
    );
  }
}
