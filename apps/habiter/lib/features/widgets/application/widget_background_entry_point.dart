import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../app/bootstrap.dart';
import '../../../app/dependencies.dart';
import '../../../core/persistence/shared_preferences_key_value_store.dart';
import '../data/android_widget_bridge.dart';
import '../domain/widget_action.dart';
import 'widget_action_handler.dart';
import 'widget_app_lock_state_resolver.dart';
import 'widget_sync_controller.dart';

@pragma('vm:entry-point')
FutureOr<void> habiterWidgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri == null) return;
  final dependencies = AppDependencies.production();
  final bootstrap = await AppBootstrap(dependencies).run();
  if (!bootstrap.isReady) return;
  final action = WidgetAction.fromUri(uri);
  const bridge = AndroidWidgetBridge();
  final sync = WidgetSyncController(
    repository: dependencies.habitRepository,
    bridge: bridge,
    clock: dependencies.clock,
    appLockResolver: WidgetAppLockStateResolver(dependencies.store),
  );
  final handler = WidgetActionHandler(
    repository: dependencies.habitRepository,
    actionStore: SharedPreferencesKeyValueStore(),
    ids: dependencies.ids,
    clock: dependencies.clock,
    sync: sync,
  );
  await handler.handle(
    action,
    locale: PlatformDispatcher.instance.locale.languageCode,
  );
}
