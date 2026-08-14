import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/app_lock_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppLockProvider>();
      await provider.load();
      if (provider.hasAllPermissions) await provider.loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.appLock)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!provider.isSupported)
                _StatusCard(
                  icon: Icons.phone_android_outlined,
                  title: context.l10n.androidOnly,
                  body: context.l10n.androidOnlyDesc,
                )
              else ...[
                _EnableCard(provider: provider),
                const SizedBox(height: 12),
                if (provider.error case final String error)
                  _StatusCard(
                    icon: Icons.info_outline,
                    title: context.l10n.appLockRecovery,
                    body: error,
                  ),
                if (!provider.hasAllPermissions) ...[
                  const SizedBox(height: 12),
                  _PermissionCard(provider: provider),
                ] else ...[
                  const SizedBox(height: 12),
                  _AppSelection(provider: provider),
                ],
                const SizedBox(height: 12),
                _StatusCard(
                  icon: Icons.battery_saver_outlined,
                  title: context.l10n.appLockReliability,
                  body: context.l10n.appLockReliabilityDescription,
                  action: provider.batteryOptimized == true
                      ? OutlinedButton(
                          onPressed: provider.openBatterySettings,
                          child: Text(context.l10n.batterySettings),
                        )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnableCard extends StatelessWidget {
  const _EnableCard({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.appLock),
              subtitle: Text(context.l10n.appLockSubtitle),
              value: provider.isEnabled,
              onChanged: provider.setEnabled,
            ),
            if (provider.isEnabled)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const Key('disable-app-lock'),
                  onPressed: () => provider.setEnabled(false),
                  icon: const Icon(Icons.lock_open),
                  label: Text(context.l10n.disableAppLock),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.permissionsRequired,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.usageAccess),
              subtitle: Text(context.l10n.usageAccessDesc),
              trailing: provider.hasUsageStatsPermission
                  ? const Icon(Icons.check_circle)
                  : OutlinedButton(
                      onPressed: provider.requestUsageStatsPermission,
                      child: Text(context.l10n.grant),
                    ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.overlayPermission),
              subtitle: Text(context.l10n.overlayPermissionDesc),
              trailing: provider.hasOverlayPermission
                  ? const Icon(Icons.check_circle)
                  : OutlinedButton(
                      onPressed: provider.requestOverlayPermission,
                      child: Text(context.l10n.grant),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await provider.checkPermissions();
                  if (provider.hasAllPermissions) {
                    await provider.loadInstalledApps();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.refreshPermissions),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSelection extends StatelessWidget {
  const _AppSelection({required this.provider});
  final AppLockProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.selectAppsToLock(
                provider.config.activelyLockedApps.length,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (provider.availableApps.isEmpty) ...[
              const SizedBox(height: 8),
              Text(context.l10n.noAppsFound),
              OutlinedButton.icon(
                onPressed: provider.loadInstalledApps,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ] else
              for (final app in provider.availableApps)
                CheckboxListTile(
                  value: app.isLocked,
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                  onChanged: (_) => provider.toggleAppLock(app.packageName),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
