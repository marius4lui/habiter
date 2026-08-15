enum AppRoute { today, analytics, settings, appLock }

abstract final class AppRouteCodec {
  static AppRoute decode(String location) {
    final path = Uri.tryParse(location)?.path ?? '/';
    return switch (path) {
      '/analytics' => AppRoute.analytics,
      '/settings' => AppRoute.settings,
      '/app-lock' => AppRoute.appLock,
      _ => AppRoute.today,
    };
  }

  static String encode(AppRoute route) => switch (route) {
    AppRoute.today => '/today',
    AppRoute.analytics => '/analytics',
    AppRoute.settings => '/settings',
    AppRoute.appLock => '/app-lock',
  };
}
