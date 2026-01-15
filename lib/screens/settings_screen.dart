import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/classly_sync_provider.dart';
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
  final _classlyUrlController = TextEditingController();
  final _classlyEmailController = TextEditingController();
  final _classlyPasswordController = TextEditingController();
  final _classlyTokenController = TextEditingController();
  bool _showTokenField = false;

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
      final granted =
          await NotificationService.instance.areNotificationsEnabled();
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
      theme:
          settingsProvider.preferenceFromThemeMode(settingsProvider.themeMode),
      notifications: _notificationsEnabled,
      reminderTime:
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
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
                ? const ColorScheme.dark(
                    primary: AppColorsDark.primary,
                    onPrimary: AppColorsDark.background,
                    surface: AppColorsDark.surface,
                    onSurface: AppColorsDark.text,
                  )
                : const ColorScheme.light(
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
    final classlySync = context.watch<ClasslySyncProvider>();
    // Pre-fill controllers once data is loaded
    if (classlySync.baseUrl != null && _classlyUrlController.text.isEmpty) {
      _classlyUrlController.text = classlySync.baseUrl!;
    }
    if (classlySync.token != null &&
        _classlyTokenController.text.isEmpty &&
        _showTokenField) {
      _classlyTokenController.text = classlySync.token!;
    }
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppGradientsDark.appShell : AppGradients.appShell;

    final captionColor =
        isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            Text(l.settings, style: Theme.of(context).textTheme.displayMedium),
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
                  if (!_permissionGranted &&
                      (Platform.isAndroid || Platform.isIOS))
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
                      DropdownMenuItem(
                          value: ThemeMode.light, child: Text(l.themeLight)),
                      DropdownMenuItem(
                          value: ThemeMode.dark, child: Text(l.themeDark)),
                      DropdownMenuItem(
                          value: ThemeMode.system, child: Text(l.themeSystem)),
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
                title: 'Classly Sync',
                icon: Icons.sync,
                isDark: isDark,
                children: [
                  _buildClasslyConnectionForm(isDark, classlySync),
                  _buildClasslyStatus(isDark, classlySync),
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.testNotificationSent)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  l.version('1.2.0'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: captionColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classlyUrlController.dispose();
    _classlyEmailController.dispose();
    _classlyPasswordController.dispose();
    _classlyTokenController.dispose();
    super.dispose();
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor =
        isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.9),
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
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 16)),
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

  Widget _buildClasslyConnectionForm(
      bool isDark, ClasslySyncProvider provider) {
    final borderColor =
        isDark ? AppColorsDark.borderLight : AppColors.borderLight;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Classly verbinden',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isConnecting
                  ? null
                  : () async {
                      final url = _classlyUrlController.text.trim().isEmpty 
                        ? ClasslySyncProvider.defaultBaseUrl 
                        : _classlyUrlController.text.trim();
                      
                      _classlyUrlController.text = url; // Update UI if empty

                      await provider.connectWithOAuth(baseUrl: url);
                      
                      if (!mounted) return;
                      if (provider.lastError == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erfolgreich eingeloggt!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login fehlgeschlagen: ${provider.lastError}')),
                        );
                      }
                    },
              icon: const Icon(Icons.login),
              label: Text(provider.isConnecting ? 'Verbinden...' : 'Mit Classly anmelden (OAuth)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF5865F2) : const Color(0xFF5865F2), // Classly/Discord Blue-ish
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('ODER manuell', style: Theme.of(context).textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _classlyUrlController,
            decoration: InputDecoration(
              labelText: 'Classly Basis-URL',
              hintText: 'https://classly.site',
              filled: true,
              fillColor: surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _classlyEmailController,
            decoration: InputDecoration(
              labelText: 'E-Mail',
              hintText: 'name@beispiel.de',
              filled: true,
              fillColor: surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _classlyPasswordController,
            decoration: InputDecoration(
              labelText: 'Passwort',
              filled: true,
              fillColor: surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isConnecting
                    ? null
                    : () async {
                        final url = _classlyUrlController.text.trim();
                        final email = _classlyEmailController.text.trim();
                        final password = _classlyPasswordController.text;
                        if (url.isEmpty || email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Bitte URL, E-Mail und Passwort ausfüllen')),
                          );
                          return;
                        }
                        await provider.connectWithCredentials(
                          baseUrl: url,
                          email: email,
                          password: password,
                        );
                        if (!mounted) return;
                        if (provider.lastError == null) {
                          _classlyPasswordController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Classly verbunden')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.lastError!)),
                          );
                        }
                      },
                icon: provider.isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(provider.isConnecting
                    ? 'Verbinden...'
                    : 'Einloggen'),
              ),
              OutlinedButton.icon(
                onPressed: provider.isSyncing
                    ? null
                    : () async {
                        await provider.sync();
                        if (!mounted) return;
                        if (provider.lastError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.lastError!)),
                          );
                          return;
                        }
                        // Import events as habits
                        final habitProvider = context.read<HabitProvider>();
                        final imported = await habitProvider.importFromClasslyEvents(provider.events);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync: $imported Habits importiert')),
                        );
                      },
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(provider.isSyncing ? 'Sync...' : 'Sync'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                ),
              ),
              TextButton.icon(
                onPressed: provider.baseUrl == null && provider.token == null
                    ? null
                    : () async {
                        await provider.disconnect();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Classly getrennt')),
                          );
                        }
                      },
                icon: const Icon(Icons.link_off),
                label: const Text('Trennen'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              setState(() => _showTokenField = !_showTokenField);
            },
            child: Text(
              _showTokenField
                  ? 'Token manuell ausblenden'
                  : 'Token manuell eingeben',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (_showTokenField) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _classlyTokenController,
              decoration: InputDecoration(
                labelText: 'API Token (Bearer)',
                hintText: 'pat_xxx',
                filled: true,
                fillColor: surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = _classlyUrlController.text.trim();
                  final token = _classlyTokenController.text.trim();
                  if (url.isEmpty || token.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Bitte URL und Token ausfüllen')),
                    );
                    return;
                  }
                  await provider.connect(baseUrl: url, token: token);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token gespeichert')),
                    );
                  }
                },
                icon: const Icon(Icons.vpn_key),
                label: const Text('Token speichern'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClasslyStatus(bool isDark, ClasslySyncProvider provider) {
    final captionColor =
        isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;
    final lastSync = provider.lastSync != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(provider.lastSync!.toLocal())
        : 'Nie';
    final status = provider.baseUrl != null && provider.token != null
        ? 'Verbunden'
        : 'Nicht verbunden';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: $status',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Letzter Sync: $lastSync',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: captionColor)),
          Text('Empfangene Events: ${provider.events.length}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: captionColor)),
          if (provider.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Fehler: ${provider.lastError}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.redAccent),
              ),
            ),
        ],
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
        color: warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: warningColor.withValues(alpha: 0.3)),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
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
        activeTrackColor: primaryColor,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final borderColor =
        isDark ? AppColorsDark.borderLight : AppColors.borderLight;
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
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColors.surfaceMuted;
    final borderColor =
        isDark ? AppColorsDark.borderLight : AppColors.borderLight;
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
