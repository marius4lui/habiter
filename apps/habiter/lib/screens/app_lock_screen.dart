import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../core/persistence/shared_preferences_key_value_store.dart';
import '../features/app_lock/application/app_block_onboarding_controller.dart';
import '../features/app_lock/infrastructure/app_block_onboarding_repository.dart';
import '../features/app_lock/infrastructure/local_distraction_catalog.dart';
import '../features/app_lock/infrastructure/method_channel_app_lock_gateway.dart';
import '../features/app_lock/presentation/onboarding/app_block_onboarding_flow.dart';
import '../l10n/l10n.dart';
import '../models/locked_app.dart';
import '../providers/app_lock_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<AppLockProvider>();
    await provider.load();
    if (provider.hasAllPermissions) await provider.loadInstalledApps();
  }

  Future<void> _openGuidedSetup() async {
    final provider = context.read<AppLockProvider>();
    final controller = AppBlockOnboardingController(
      repository: KeyValueAppBlockOnboardingRepository(
        SharedPreferencesKeyValueStore(),
      ),
      gateway: const MethodChannelAppLockGateway(),
      loadCatalog: LocalDistractionCatalog.load,
      activate: provider.configureRules,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => AppBlockOnboardingFlow(
          controller: controller,
          habits: provider.availableActiveHabits,
          onFinished: (_) => Navigator.of(routeContext).pop(),
        ),
      ),
    );
    controller.dispose();
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppLockProvider>();
    final query = _searchController.text.trim().toLowerCase();
    final visibleApps = provider.availableApps
        .where((app) {
          if (query.isEmpty) return true;
          return app.appName.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            HabiterContent(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HabiterPageIntro(
                    title: context.l10n.appLockTitle,
                    subtitle: context.l10n.appLockBody,
                  ),
                  const SizedBox(height: HabiterSpace.lg),
                  if (!provider.isSupported)
                    HabiterEmptyState(
                      icon: Icons.android_outlined,
                      title: context.l10n.androidOnly,
                      body: context.l10n.androidOnlyDesc,
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      key: const Key('open-app-block-onboarding'),
                      onPressed: _openGuidedSetup,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Guided App Block setup'),
                    ),
                    const SizedBox(height: HabiterSpace.lg),
                    _StatusOverview(provider: provider),
                    if (provider.error case final error?) ...[
                      const SizedBox(height: HabiterSpace.sm2),
                      _InfoCard(
                        icon: Icons.info_outline_rounded,
                        title: context.l10n.appLockRecovery,
                        body: error,
                      ),
                    ],
                    const SizedBox(height: HabiterSpace.lg),
                    _Permissions(provider: provider),
                    if (provider.hasAllPermissions) ...[
                      const SizedBox(height: HabiterSpace.lg),
                      HabiterSectionHeader(
                        title: context.l10n.selectAppsToLock(
                          provider.config.activelyLockedApps.length,
                        ),
                        subtitle: context.l10n.appLockSubtitle,
                      ),
                      const SizedBox(height: HabiterSpace.sm2),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchApps,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: context.l10n.cancel,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: HabiterSpace.sm2),
                      _AppList(provider: provider, apps: visibleApps),
                      if (provider.availableActiveHabits.isNotEmpty) ...[
                        const SizedBox(height: HabiterSpace.lg),
                        _UnlockRule(provider: provider),
                      ],
                    ],
                    const SizedBox(height: HabiterSpace.lg),
                    _InfoCard(
                      icon: Icons.health_and_safety_outlined,
                      title: context.l10n.recoveryAndReliability,
                      body: context.l10n.appLockReliabilityDescription,
                      action: provider.batteryOptimized == true
                          ? OutlinedButton.icon(
                              onPressed: provider.openBatterySettings,
                              icon: const Icon(Icons.battery_saver_outlined),
                              label: Text(context.l10n.batterySettings),
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = provider.isEnabled;
    return HabiterSurface(
      color: enabled ? theme.colorScheme.primaryContainer : null,
      padding: const EdgeInsets.all(HabiterSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(HabiterRadius.control),
                ),
                child: Icon(
                  enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: enabled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: HabiterSpace.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled
                          ? context.l10n.appLockStatusOn
                          : context.l10n.appLockStatusOff,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.selectAppsToLock(
                        provider.config.activelyLockedApps.length,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: provider.setEnabled),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: HabiterSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const Key('disable-app-lock'),
                onPressed: () => provider.setEnabled(false),
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(context.l10n.disableAppLock),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Permissions extends StatelessWidget {
  const _Permissions({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              provider.hasAllPermissions
                  ? Icons.verified_user_outlined
                  : Icons.shield_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: HabiterSpace.sm),
            Expanded(
              child: Text(
                provider.hasAllPermissions
                    ? context.l10n.permissionsReady
                    : context.l10n.permissionsRequired,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: HabiterSpace.sm),
        Text(
          context.l10n.appLockPermissionIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: HabiterSpace.md),
        _PermissionRow(
          title: context.l10n.usageAccess,
          body: context.l10n.usageAccessDesc,
          granted: provider.hasUsageStatsPermission,
          onGrant: provider.requestUsageStatsPermission,
        ),
        const Divider(),
        _PermissionRow(
          title: context.l10n.overlayPermission,
          body: context.l10n.overlayPermissionDesc,
          granted: provider.hasOverlayPermission,
          onGrant: provider.requestOverlayPermission,
        ),
        if (!provider.hasAllPermissions) ...[
          const SizedBox(height: HabiterSpace.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await provider.checkPermissions();
                if (provider.hasAllPermissions) {
                  await provider.loadInstalledApps();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.refreshPermissions),
            ),
          ),
        ],
      ],
    ),
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.body,
    required this.granted,
    required this.onGrant,
  });
  final String title;
  final String body;
  final bool granted;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 380 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
      final action = granted
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : OutlinedButton(onPressed: onGrant, child: Text(context.l10n.grant));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: HabiterSpace.sm),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: action),
                ],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 12),
                  action,
                ],
              ),
      );
    },
  );
}

class _AppList extends StatelessWidget {
  const _AppList({required this.provider, required this.apps});
  final AppLockProvider provider;
  final List<LockedApp> apps;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (apps.isEmpty) {
      return HabiterEmptyState(
        icon: Icons.search_off_rounded,
        title: context.l10n.noMatchingApps,
        body: provider.availableApps.isEmpty
            ? context.l10n.noAppsFound
            : context.l10n.searchApps,
        action: provider.availableApps.isEmpty
            ? OutlinedButton.icon(
                onPressed: provider.loadInstalledApps,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              )
            : null,
      );
    }
    return HabiterSurface(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: apps.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final app = apps[index];
            return CheckboxListTile(
              key: ValueKey('app-${app.packageName}'),
              value: app.isLocked,
              onChanged: (_) => provider.toggleAppLock(app.packageName),
              secondary: _AppIcon(bytes: app.iconBytes, name: app.appName),
              title: Text(
                app.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                app.isLocked
                    ? context.l10n.appSelected
                    : context.l10n.appNotSelected,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnlockRule extends StatelessWidget {
  const _UnlockRule({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) {
    final requireAll = provider.config.lockUntilAllHabitsComplete;
    final selected = provider.config.requiredHabitIds?.toSet() ?? <String>{};
    return HabiterSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              context.l10n.unlockRule,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile.adaptive(
            value: requireAll,
            title: Text(context.l10n.allHabitsRequired),
            subtitle: Text(
              requireAll
                  ? context.l10n.allHabitsRequiredBody
                  : context.l10n.specificHabitsRequiredBody,
            ),
            onChanged: provider.setLockUntilAllHabitsComplete,
          ),
          if (!requireAll) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                context.l10n.requiredHabits,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final habit in provider.availableActiveHabits)
              CheckboxListTile(
                value: selected.contains(habit.id),
                secondary: Text(
                  habit.icon,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(habit.name),
                onChanged: (_) {
                  final next = {...selected};
                  if (!next.add(habit.id)) next.remove(habit.id);
                  provider.setRequiredHabitIds(next.toList(growable: false));
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.bytes, required this.name});
  final Uint8List? bytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      child: Text(name.characters.firstOrNull?.toUpperCase() ?? '?'),
    );
    if (bytes == null || bytes!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes!,
        width: 44,
        height: 44,
        cacheWidth: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}
