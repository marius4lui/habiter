import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _aiInsights = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkPermissions();
  }

  void _loadPreferences() {
    final provider = context.read<HabitProvider>();
    final prefs = provider.preferences;
    
    setState(() {
      _notificationsEnabled = prefs.notifications;
      _aiInsights = prefs.aiInsights;
      
      // Parse reminder time
      final parts = prefs.reminderTime.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    });
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final granted = await NotificationService.instance.areNotificationsEnabled();
      setState(() => _permissionGranted = granted);
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService.instance.requestPermissions();
    setState(() => _permissionGranted = granted);
    
    if (granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsEnabled)),
      );
    }
  }

  Future<void> _savePreferences() async {
    final provider = context.read<HabitProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    
    final newPrefs = UserPreferences(
      theme: settingsProvider.preferenceFromThemeMode(settingsProvider.themeMode),
      notifications: _notificationsEnabled,
      reminderTime: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      aiInsights: _aiInsights,
      language: settingsProvider.locale.languageCode,
    );
    
    await provider.updatePreferences(newPrefs);
  }

  Future<void> _selectTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColorsDark.primary,
                    onPrimary: AppColorsDark.background,
                    surface: AppColorsDark.surface,
                    onSurface: AppColorsDark.text,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surface,
                    onSurface: AppColors.text,
                  ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppGradientsDark.appShell : AppGradients.appShell;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final textColor = isDark ? AppColorsDark.text : AppColors.text;
    final captionColor = isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.settings, style: Theme.of(context).textTheme.displayMedium),
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
              _buildSection(
                title: l.notifications,
                icon: Icons.notifications_outlined,
                isDark: isDark,
                children: [
                  if (!_permissionGranted && (Platform.isAndroid || Platform.isIOS))
                    _buildPermissionBanner(isDark),
                  _buildSwitchTile(
                    title: l.dailyReminder,
                    subtitle: l.dailyReminderDesc,
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      if (value && !_permissionGranted) {
                        await _requestPermissions();
                      }
                      await _savePreferences();
                    },
                  ),
                  if (_notificationsEnabled)
                    _buildTimeTile(
                      title: l.reminderTime,
                      time: _reminderTime,
                      onTap: _selectTime,
                      isDark: isDark,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l.appearance,
                icon: Icons.palette_outlined,
                isDark: isDark,
                children: [
                  _buildDropdownTile<ThemeMode>(
                    title: l.theme,
                    value: settingsProvider.themeMode,
                    isDark: isDark,
                    items: [
                      DropdownMenuItem(value: ThemeMode.light, child: Text(l.themeLight)),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text(l.themeDark)),
                      DropdownMenuItem(value: ThemeMode.system, child: Text(l.themeSystem)),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await settingsProvider.setThemeMode(value);
                        await _savePreferences();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l.aiFeatures,
                icon: Icons.auto_awesome_outlined,
                isDark: isDark,
                children: [
                  _buildSwitchTile(
                    title: l.aiInsights,
                    subtitle: l.aiInsightsDesc,
                    value: _aiInsights,
                    isDark: isDark,
                    onChanged: (value) async {
                      setState(() => _aiInsights = value);
                      await _savePreferences();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l.language,
                icon: Icons.language_outlined,
                isDark: isDark,
                children: [
                  _buildDropdownTile<String>(
                    title: l.appLanguage,
                    value: settingsProvider.locale.languageCode,
                    isDark: isDark,
                    items: [
                      DropdownMenuItem(value: 'de', child: Text(l.german)),
                      DropdownMenuItem(value: 'en', child: Text(l.english)),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await settingsProvider.setLocale(Locale(value));
                        await _savePreferences();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l.advanced,
                icon: Icons.tune_outlined,
                isDark: isDark,
                children: [
                  _buildActionTile(
                    title: l.testNotification,
                    subtitle: l.testNotificationDesc,
                    icon: Icons.send_outlined,
                    isDark: isDark,
                    onTap: () async {
                      await NotificationService.instance.showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.testNotificationSent)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  l.version('1.2.0'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: captionColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    
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
                    Icon(icon, color: primaryColor, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 16)),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(bool isDark) {
    final l = context.l10n;
    final warningColor = isDark ? AppColorsDark.warning : AppColors.warning;
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: warningColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.permissionRequired,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  l.permissionRequiredDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestPermissions,
            child: Text(l.allow),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final surfaceMuted = isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: surfaceMuted,
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 18, color: primaryColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                time.format(context),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    final surfaceMuted = isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final borderColor = isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surfaceMuted,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(color: borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyLarge,
            dropdownColor: surfaceColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: IconButton(
        icon: Icon(icon, color: primaryColor),
        onPressed: onTap,
      ),
      onTap: onTap,
    );
  }
}
