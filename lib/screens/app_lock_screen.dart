import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/locked_app.dart';
import '../providers/app_lock_provider.dart';
import '../services/app_lock_service.dart';
import '../theme/app_theme.dart';

/// Screen for configuring app lock settings
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppLockProvider>();
      provider.load();
      provider.loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, provider, _) {
        if (!provider.isSupported) {
          return _buildUnsupportedPlatform();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildHeader(context),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _buildPermissionsSection(context, provider),
                  _buildEnableToggle(context, provider),
                  if (provider.isEnabled) ...[
                    _buildAppsList(context, provider),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnsupportedPlatform() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_android, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'Android Only',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'App Lock is only available on Android devices.',
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            const Text(
              '🔒 App Lock',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(BuildContext context, AppLockProvider provider) {
    final needsUsageStats = !provider.hasUsageStatsPermission;
    final needsOverlay = !provider.hasOverlayPermission;

    if (!needsUsageStats && !needsOverlay) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning),
                      const SizedBox(width: 8),
                      const Text(
                        'Permissions Required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (needsUsageStats) ...[
                    _buildPermissionRow(
                      'Usage Access',
                      'Detect which app is open',
                      () async {
                        await provider.requestUsageStatsPermission();
                        await Future.delayed(const Duration(seconds: 1));
                        await provider.checkPermissions();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (needsOverlay) ...[
                    _buildPermissionRow(
                      'Display Over Apps',
                      'Show blocking screen',
                      () async {
                        await provider.requestOverlayPermission();
                        await Future.delayed(const Duration(seconds: 1));
                        await provider.checkPermissions();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Grant',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle(BuildContext context, AppLockProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enable App Lock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lock selected apps until habits are complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: provider.isEnabled,
                    onChanged: provider.hasAllPermissions
                        ? (value) => provider.setEnabled(value)
                        : null,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppsList(BuildContext context, AppLockProvider provider) {
    final apps = provider.availableApps;

    if (apps.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.apps, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(
                  'No apps found',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Select apps to lock (${provider.config.activelyLockedApps.length} selected)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              );
            }

            final app = apps[index - 1];
            return _buildAppTile(app, provider);
          },
          childCount: apps.length + 1,
        ),
      ),
    );
  }

  Widget _buildAppTile(LockedApp app, AppLockProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: app.isLocked
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: app.isLocked
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.borderLight,
              ),
            ),
            child: ListTile(
              onTap: () => provider.toggleAppLock(app.packageName),
              leading: app.iconBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        app.iconBytes!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.android, color: AppColors.textMuted),
                    ),
              title: Text(
                app.appName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: app.isLocked ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.text,
                ),
              ),
              subtitle: Text(
                app.packageName,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: app.isLocked
                  ? const Icon(Icons.lock, color: AppColors.primary)
                  : const Icon(Icons.lock_open, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
