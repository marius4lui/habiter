import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/locked_app.dart';
import '../providers/app_lock_provider.dart';
import '../theme/app_theme.dart';

/// Screen for configuring app lock settings - Matches app design language
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
                _buildHeroHeader(context, provider),
                if (provider.isLoading)
                  SliverToBoxAdapter(child: _buildLoadingState())
                else ...[
                  if (!provider.hasAllPermissions)
                    _buildPermissionsCard(context, provider),
                  _buildAppsList(context, provider),
                ],
                // Bottom padding for safe area
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildBackButton(),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppGradients.cardSheen,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.2),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.full),
                          ),
                          child: const Icon(Icons.phone_android, size: 40, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Android Only', style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'App Lock ist nur auf Android Geräten verfügbar.',
                          style: AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppLockProvider provider) {
    final lockedCount = provider.config.activelyLockedApps.length;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.md),
            // Hero Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.6),
                boxShadow: AppShadows.glow,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: AppGradients.halo),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🔒 App Lock',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sperre Apps bis deine Habits erledigt sind',
                                  style: AppTextStyles.bodySecondary.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Toggle Switch
                          _GlassSwitch(
                            value: provider.isEnabled,
                            onChanged: provider.hasAllPermissions
                                ? (value) => provider.setEnabled(value)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Stats row
                      Row(
                        children: [
                          _HeroStat(
                            title: 'Gesperrt',
                            value: '$lockedCount',
                            icon: Icons.lock,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _HeroStat(
                            title: 'Status',
                            value: provider.isEnabled ? 'Aktiv' : 'Inaktiv',
                            icon: provider.isEnabled ? Icons.shield : Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: AppGradients.cardSheen,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Apps werden geladen...',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Skeleton items
            ...List.generate(4, (i) => _buildSkeletonTile(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTile(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100 + (index * 20.0),
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 140,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (100 * index).ms).fadeIn(duration: 300.ms).shimmer(
      duration: 1500.ms,
      color: AppColors.surface,
    );
  }

  Widget _buildPermissionsCard(BuildContext context, AppLockProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Berechtigungen erforderlich',
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (!provider.hasUsageStatsPermission)
                _buildPermissionButton(
                  'Usage Access',
                  'Erkennen welche App geöffnet ist',
                  Icons.analytics_outlined,
                  () async {
                    await provider.requestUsageStatsPermission();
                    await Future.delayed(const Duration(seconds: 1));
                    await provider.checkPermissions();
                  },
                ),
              if (!provider.hasOverlayPermission) ...[
                if (!provider.hasUsageStatsPermission) const SizedBox(height: AppSpacing.sm),
                _buildPermissionButton(
                  'Über anderen Apps anzeigen',
                  'Sperrbildschirm anzeigen',
                  Icons.layers_outlined,
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
    );
  }

  Widget _buildPermissionButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                child: Text(
                  'Erlauben',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
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
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppGradients.cardSheen,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.apps, size: 48, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.sm),
                Text('Keine Apps gefunden', style: AppTextStyles.bodySecondary),
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
                padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
                child: Text(
                  'Apps zum Sperren auswählen (${provider.config.activelyLockedApps.length})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }

            final app = apps[index - 1];
            return _buildAppTile(app, provider, index - 1);
          },
          childCount: apps.length + 1,
        ),
      ),
    );
  }

  Widget _buildAppTile(LockedApp app, AppLockProvider provider, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.toggleAppLock(app.packageName),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: app.isLocked ? AppGradients.primary : AppGradients.cardSheen,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: app.isLocked ? AppColors.primary.withOpacity(0.5) : AppColors.borderLight,
                width: app.isLocked ? 2 : 1,
              ),
              boxShadow: app.isLocked ? AppShadows.soft : null,
            ),
            child: Row(
              children: [
                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: app.iconBytes != null
                      ? Image.memory(
                          app.iconBytes!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: AppColors.surfaceMuted,
                          child: const Icon(Icons.android, color: AppColors.textMuted),
                        ),
                ),
                const SizedBox(width: 14),
                // App Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: app.isLocked ? FontWeight.w700 : FontWeight.w500,
                          color: app.isLocked ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        style: TextStyle(
                          fontSize: 11,
                          color: app.isLocked ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Lock Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: app.isLocked ? Colors.white.withOpacity(0.2) : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Icon(
                    app.isLocked ? Icons.lock : Icons.lock_open_outlined,
                    color: app.isLocked ? Colors.white : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (30 * index).ms).fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0);
  }
}

// Custom glass-style switch for hero section
class _GlassSwitch extends StatelessWidget {
  const _GlassSwitch({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              value ? Icons.check : Icons.close,
              size: 14,
              color: value ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 18),
                ),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
