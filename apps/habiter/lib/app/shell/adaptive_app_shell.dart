import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/layout.dart';
import '../../core/design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/app_route.dart';

final class _SelectRouteIntent extends Intent {
  const _SelectRouteIntent(this.route);
  final AppRoute route;
}

class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onOpenSettings,
    required this.onOpenAppLock,
    required this.child,
  });

  final AppRoute selected;
  final ValueChanged<AppRoute> onSelected;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAppLock;
  final Widget child;

  int get _selectedIndex => switch (selected) {
    AppRoute.analytics => 1,
    AppRoute.rhythm => 2,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _SelectRouteIntent(AppRoute.today),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _SelectRouteIntent(AppRoute.analytics),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _SelectRouteIntent(AppRoute.rhythm),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SelectRouteIntent: CallbackAction<_SelectRouteIntent>(
            onInvoke: (intent) {
              onSelected(intent.route);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: HabiterLayoutBuilder(
            builder: (context, layout) => _shell(context, layout),
          ),
        ),
      ),
    );
  }

  Widget _shell(BuildContext context, HabiterLayout layout) {
    final usesRail = layout.atLeast(HabiterLayoutClass.expanded);
    final showsCompactNavigation = !usesRail && selected != AppRoute.today;
    return Scaffold(
      backgroundColor: !usesRail && selected == AppRoute.today
          ? Colors.transparent
          : null,
      appBar: showsCompactNavigation ? _compactAppBar(context) : null,
      body: Row(
        children: <Widget>[
          if (usesRail) ...[
            _rail(context, extended: layout.isLarge),
            const VerticalDivider(width: 1),
          ],
          Expanded(key: const ValueKey('habiter-shell-content'), child: child),
        ],
      ),
      bottomNavigationBar: showsCompactNavigation
          ? _bottomNavigation(context)
          : null,
    );
  }

  PreferredSizeWidget _compactAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appLockLabel = l10n?.appLock ?? 'App lock';
    final settingsLabel = l10n?.settings ?? 'Settings';
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Habiter'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: appLockLabel,
          onPressed: onOpenAppLock,
          icon: const Icon(Icons.lock_outline_rounded),
        ),
        IconButton(
          tooltip: settingsLabel,
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final todayLabel = l10n?.today ?? 'Today';
    final analyticsLabel = l10n?.analytics ?? 'Analytics';
    final rhythmLabel = l10n?.habitSchedule ?? 'Rhythm';
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Align(
        heightFactor: 1,
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HabiterRadius.pill),
            child: NavigationBar(
              height: 60,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectIndex,
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.today_outlined, size: 22),
                  selectedIcon: const Icon(Icons.today_rounded, size: 22),
                  label: todayLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined, size: 22),
                  selectedIcon: const Icon(Icons.insights_rounded, size: 22),
                  label: analyticsLabel,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.schedule_outlined, size: 22),
                  selectedIcon: const Icon(Icons.schedule_rounded, size: 22),
                  label: rhythmLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rail(BuildContext context, {required bool extended}) {
    final l10n = AppLocalizations.of(context);
    final todayLabel = l10n?.today ?? 'Today';
    final analyticsLabel = l10n?.analytics ?? 'Analytics';
    final rhythmLabel = l10n?.habitSchedule ?? 'Rhythm';
    final appLockLabel = l10n?.appLock ?? 'App lock';
    final settingsLabel = l10n?.settings ?? 'Settings';
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 220,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectIndex,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: HabiterSpace.lg),
        child: extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: HabiterSpace.sm),
                  Text(
                    'Habiter',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              )
            : Icon(
                Icons.eco_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
      destinations: <NavigationRailDestination>[
        NavigationRailDestination(
          icon: const Icon(Icons.today_outlined),
          selectedIcon: const Icon(Icons.today_rounded),
          label: Text(todayLabel),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.insights_outlined),
          selectedIcon: const Icon(Icons.insights_rounded),
          label: Text(analyticsLabel),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.schedule_outlined),
          selectedIcon: const Icon(Icons.schedule_rounded),
          label: Text(rhythmLabel),
        ),
      ],
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (extended) ...[
              SizedBox(
                width: 204,
                child: TextButton.icon(
                  onPressed: onOpenAppLock,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(appLockLabel),
                  style: const ButtonStyle(
                    alignment: Alignment.centerLeft,
                    minimumSize: WidgetStatePropertyAll(
                      Size.fromHeight(HabiterState.minimumTarget),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 204,
                child: TextButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(settingsLabel),
                  style: const ButtonStyle(
                    alignment: Alignment.centerLeft,
                    minimumSize: WidgetStatePropertyAll(
                      Size.fromHeight(HabiterState.minimumTarget),
                    ),
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                tooltip: appLockLabel,
                onPressed: onOpenAppLock,
                icon: const Icon(Icons.lock_outline),
              ),
              IconButton(
                tooltip: settingsLabel,
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            const SizedBox(height: HabiterSpace.md),
          ],
        ),
      ),
    );
  }

  void _selectIndex(int index) {
    onSelected(switch (index) {
      1 => AppRoute.analytics,
      2 => AppRoute.rhythm,
      _ => AppRoute.today,
    });
  }
}
