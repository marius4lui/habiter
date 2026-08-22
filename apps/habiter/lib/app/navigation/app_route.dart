enum AppRoute { today, analytics, rhythm, sync, settings, appLock, updates }

abstract final class AppRouteCodec {
  static AppRoute decode(String location) {
    final path = Uri.tryParse(location)?.path ?? '/';
    return switch (path) {
      '/analytics' => AppRoute.analytics,
      '/rhythm' => AppRoute.rhythm,
      '/sync' => AppRoute.sync,
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
    AppRoute.sync => '/sync',
    AppRoute.settings => '/settings',
    AppRoute.appLock => '/app-lock',
    AppRoute.updates => '/updates',
  };
}
