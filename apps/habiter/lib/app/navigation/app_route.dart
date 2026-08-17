enum AppRoute { today, analytics, rhythm, settings, appLock, updates }

abstract final class AppRouteCodec {
  static AppRoute decode(String location) {
    final path = Uri.tryParse(location)?.path ?? '/';
    return switch (path) {
      '/analytics' => AppRoute.analytics,
      '/rhythm' => AppRoute.rhythm,
      '/settings' => AppRoute.settings,
      '/app-lock' => AppRoute.appLock,
      '/updates' => AppRoute.updates,
      _ => AppRoute.today,
    };
  }

  static String encode(AppRoute route) => switch (route) {
    AppRoute.today => '/today',
    AppRoute.analytics => '/analytics',
    AppRoute.rhythm => '/rhythm',
    AppRoute.settings => '/settings',
    AppRoute.appLock => '/app-lock',
    AppRoute.updates => '/updates',
  };
}
