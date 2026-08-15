import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const desktopBreakpoint = 1024.0;

  final AppRoute selected;
  final ValueChanged<AppRoute> onSelected;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAppLock;
  final Widget child;

  int get _selectedIndex => selected == AppRoute.analytics ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _SelectRouteIntent(AppRoute.today),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _SelectRouteIntent(AppRoute.analytics),
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
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= desktopBreakpoint
                ? _desktop(context)
                : _compact(context),
          ),
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: Wrap(
        spacing: 8,
        children: <Widget>[
          IconButton.filledTonal(
            tooltip: 'App lock',
            onPressed: onOpenAppLock,
            icon: const Icon(Icons.lock_outline),
          ),
          IconButton.filledTonal(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  Widget _desktop(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectIndex,
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.checklist_rtl_outlined),
                selectedIcon: Icon(Icons.checklist_rtl),
                label: Text('Today'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.query_stats_outlined),
                selectedIcon: Icon(Icons.query_stats),
                label: Text('Analytics'),
              ),
            ],
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    tooltip: 'App lock',
                    onPressed: onOpenAppLock,
                    icon: const Icon(Icons.lock_outline),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _selectIndex(int index) {
    onSelected(index == 0 ? AppRoute.today : AppRoute.analytics);
  }
}
