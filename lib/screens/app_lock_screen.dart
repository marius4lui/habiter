import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../models/locked_app.dart';
import '../providers/app_lock_provider.dart';
import '../theme/app_theme.dart';

/// Screen for configuring app lock settings - Matches settings screen design
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppGradientsDark.appShell : AppGradients.appShell;

    return Consumer<AppLockProvider>(
      builder: (context, provider, _) {
        if (!provider.isSupported) {
          return _buildUnsupportedPlatform(isDark);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(context.l10n.appLock, style: Theme.of(context).textTheme.displayMedium),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildHeroCard(context, provider, isDark),
                  const SizedBox(height: AppSpacing.md),
                  if (!provider.hasAllPermissions)
                    _buildPermissionsSection(context, provider, isDark),
                  if (!provider.hasAllPermissions)
                    const SizedBox(height: AppSpacing.md),
                  if (provider.isLoading)
                    _buildLoadingSection(isDark)
                  else
                    _buildAppsSection(context, provider, isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnsupportedPlatform(bool isDark) {
    final l = context.l10n;
    final gradient = isDark ? AppGradientsDark.appShell : AppGradients.appShell;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final captionColor = isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.appLock, style: Theme.of(context).textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_android, size: 64, color: captionColor),
                        const SizedBox(height: AppSpacing.md),
                        Text(l.androidOnly, style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l.androidOnlyDesc,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, AppLockProvider provider, bool isDark) {
    final l = context.l10n;
    final lockedCount = provider.config.activelyLockedApps.length;
    final heroGradient = isDark ? AppGradientsDark.hero : AppGradients.hero;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.2),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: heroGradient,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.2),
          boxShadow: AppShadows.glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appLock,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.appLockSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: provider.isEnabled,
                  onChanged: provider.hasAllPermissions
                      ? (value) => provider.setEnabled(value)
                      : null,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildStatChip(
                  l.locked,
                  '$lockedCount',
                  Icons.lock,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildStatChip(
                  l.status,
                  provider.isEnabled ? l.statusActive : l.statusInactive,
                  provider.isEnabled ? Icons.shield : Icons.shield_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(BuildContext context, AppLockProvider provider, bool isDark) {
    final l = context.l10n;
    final warningColor = isDark ? AppColorsDark.warning : AppColors.warning;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: warningColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l.permissionsRequired, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16)),
                  ],
                ),
              ),
              Divider(height: 1, color: warningColor.withOpacity(0.2)),
              if (!provider.hasUsageStatsPermission)
                _buildPermissionTile(
                  l.usageAccess,
                  l.usageAccessDesc,
                  Icons.analytics_outlined,
                  isDark,
                  () async {
                    await provider.requestUsageStatsPermission();
                    await Future.delayed(const Duration(seconds: 1));
                    await provider.checkPermissions();
                  },
                ),
              if (!provider.hasOverlayPermission)
                _buildPermissionTile(
                  l.overlayPermission,
                  l.overlayPermissionDesc,
                  Icons.layers_outlined,
                  isDark,
                  () async {
                    await provider.requestOverlayPermission();
                    await Future.delayed(const Duration(seconds: 1));
                    await provider.checkPermissions();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, IconData icon, bool isDark, VoidCallback onTap) {
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(context.l10n.allow),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLoadingSection(bool isDark) {
    final l = context.l10n;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: AppSpacing.md),
              Text(l.loadingApps, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppsSection(BuildContext context, AppLockProvider provider, bool isDark) {
    final l = context.l10n;
    final apps = provider.availableApps;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    if (apps.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.apps, size: 48, color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary),
                const SizedBox(height: AppSpacing.sm),
                Text(l.noAppsFound, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.apps, color: primaryColor, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.selectAppsToLock(provider.config.activelyLockedApps.length),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              ...apps.asMap().entries.map((entry) =>
                _buildAppTile(entry.value, provider, entry.key, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppTile(LockedApp app, AppLockProvider provider, int index, bool isDark) {
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final surfaceMuted = isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final textColor = isDark ? AppColorsDark.text : AppColors.text;
    final captionColor = isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.toggleAppLock(app.packageName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: app.isLocked ? primaryColor.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: app.iconBytes != null
                    ? Image.memory(app.iconBytes!, width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                        width: 44,
                        height: 44,
                        color: surfaceMuted,
                        child: Icon(Icons.android, color: captionColor),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: app.isLocked ? FontWeight.w700 : FontWeight.w500,
                        color: app.isLocked ? primaryColor : textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      app.packageName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: captionColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: app.isLocked ? primaryColor.withOpacity(0.2) : surfaceMuted,
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                child: Icon(
                  app.isLocked ? Icons.lock : Icons.lock_open_outlined,
                  color: app.isLocked ? primaryColor : captionColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (20 * index).ms).fadeIn(duration: 150.ms);
  }
}
