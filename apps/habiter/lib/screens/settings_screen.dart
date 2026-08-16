import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../features/reminders/application/reminder_permission_controller.dart';
import '../features/reminders/infrastructure/local_reminder_permission_gateway.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/classly_sync_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_manager.dart';
import '../widgets/ai_setup_dialog.dart';
import 'app_lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ReminderPermissionController _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = ReminderPermissionController(
      const LocalReminderPermissionGateway(),
    );
  }

  Future<void> _update(UserPreferences preferences) =>
      context.read<HabitProvider>().updatePreferences(preferences);

  Future<void> _chooseReminderTime(UserPreferences preferences) async {
    final parts = preferences.reminderTime.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 20,
        minute: int.tryParse(parts.last) ?? 0,
      ),
    );
    if (selected == null || !mounted) return;
    await _update(
      preferences.copyWith(
        reminderTime:
            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final preferences = habits.preferences;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: Navigator.of(context).canPop() ? AppBar() : null,
      body: ListView(
        key: const Key('progressive-settings'),
        children: [
          HabiterContent(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HabiterPageIntro(
                  title: context.l10n.settingsTitle,
                  subtitle: context.l10n.settingsBody,
                ),
                const SizedBox(height: HabiterSpace.lg),
                _SettingsSection(
                  icon: Icons.palette_outlined,
                  title: context.l10n.appearance,
                  children: [
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: settings.themeMode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.theme,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(context.l10n.themeSystem),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(context.l10n.themeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(context.l10n.themeDark),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.setThemeMode(value);
                      },
                    ),
                    const SizedBox(height: HabiterSpace.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxWidth < 360 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.3;
                        if (compact) {
                          return DropdownButtonFormField<String>(
                            initialValue: settings.locale.languageCode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.l10n.language,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'de',
                                child: Text(context.l10n.german),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(context.l10n.english),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                settings.setLocale(Locale(value));
                              }
                            },
                          );
                        }
                        return SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'de',
                              label: Text(context.l10n.german),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(context.l10n.english),
                            ),
                          ],
                          selected: {settings.locale.languageCode},
                          onSelectionChanged: (value) =>
                              settings.setLocale(Locale(value.single)),
                        );
                      },
                    ),
                  ],
                ),
                _SettingsSection(
                  icon: Icons.notifications_none_rounded,
                  title: context.l10n.notifications,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.dailyReminder),
                      subtitle: Text(
                        preferences.notifications
                            ? context.l10n.dailyReminderAt(
                                preferences.reminderTime,
                              )
                            : context.l10n.dailyReminderOff,
                      ),
                      value: preferences.notifications,
                      onChanged: (value) async {
                        if (value) {
                          final state = await _permissions
                              .requestAfterUserIntent();
                          if (!state.canSchedule || !mounted) return;
                        }
                        await _update(
                          preferences.copyWith(notifications: value),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: preferences.notifications,
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(context.l10n.reminderTime),
                      trailing: Text(preferences.reminderTime),
                      onTap: preferences.notifications
                          ? () => _chooseReminderTime(preferences)
                          : null,
                    ),
                  ],
                ),
                _SettingsSection(
                  icon: Icons.center_focus_strong_outlined,
                  title: context.l10n.focusAndAppLock,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: Text(context.l10n.configureAppLock),
                      subtitle: Text(context.l10n.configureAppLockBody),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AppLockScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  icon: Icons.shield_outlined,
                  title: context.l10n.privacyAndData,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.smartphone_outlined),
                      title: Text(context.l10n.localFirstTitle),
                      subtitle: Text(context.l10n.localFirstBody),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.recoverySupport),
                      subtitle: Text(context.l10n.recoverySupportBody),
                      value: preferences.showRecoverySupport,
                      onChanged: (value) => _update(
                        preferences.copyWith(showRecoverySupport: value),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.copy_all_outlined),
                      title: Text(context.l10n.exportData),
                      subtitle: Text(context.l10n.exportDataBody),
                      onTap: _exportData,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(context.l10n.importData),
                      subtitle: Text(context.l10n.importDataBody),
                      onTap: _importData,
                    ),
                  ],
                ),
                HabiterSurface(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    key: const Key('advanced-integrations'),
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(context.l10n.advancedIntegrations),
                    subtitle: Text(context.l10n.advancedIntegrationsBody),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.classlyImport),
                        subtitle: Text(context.l10n.trustedHttpsOnly),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _openClassly,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.experimentalAi),
                        subtitle: Text(
                          AIManager.isConfigured
                              ? context.l10n.remoteAiOn
                              : context.l10n.remoteAiOff,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => const AISetupDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final data = await context.read<HabitProvider>().exportData();
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.backupCopied)));
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.importData),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(hintText: context.l10n.pasteBackup),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.reviewImport),
          ),
        ],
      ),
    );
    controller.dispose();
    if (input == null || input.trim().isEmpty || !mounted) return;
    try {
      final preview = await context.read<HabitProvider>().previewImport(input);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.reviewImport),
          content: Text(
            context.l10n.importSummary(
              preview.habits,
              preview.entries,
              preview.collisions,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.importData),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final recoveryBackup = await context.read<HabitProvider>().importData(
        input,
      );
      await Clipboard.setData(ClipboardData(text: recoveryBackup));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.importComplete)));
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidBackup)));
    }
  }

  Future<void> _openClassly() => showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => ClasslySyncProvider()..load(),
      child: const _ClasslyDialog(),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: HabiterSpace.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: HabiterSpace.sm2),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: HabiterSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );
}

class _ClasslyDialog extends StatefulWidget {
  const _ClasslyDialog();

  @override
  State<_ClasslyDialog> createState() => _ClasslyDialogState();
}

class _ClasslyDialogState extends State<_ClasslyDialog> {
  final endpoint = TextEditingController();
  final token = TextEditingController();

  @override
  void dispose() {
    endpoint.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClasslySyncProvider>();
    if (endpoint.text.isEmpty && provider.baseUrl != null) {
      endpoint.text = provider.baseUrl!;
    }
    return AlertDialog(
      title: Text(context.l10n.classlyImport),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.trustedHttpsOnly),
            const SizedBox(height: 16),
            TextField(
              controller: endpoint,
              decoration: InputDecoration(
                labelText: context.l10n.httpsEndpoint,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: token,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.l10n.optionalAccessToken,
              ),
            ),
            if (provider.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (provider.isConnected)
          TextButton(
            onPressed: provider.disconnect,
            child: Text(context.l10n.disconnect),
          ),
        TextButton(
          onPressed: provider.isConnecting
              ? null
              : () => provider.connectWithOAuth(baseUrl: endpoint.text),
          child: Text(context.l10n.connectWithOauth),
        ),
        FilledButton(
          onPressed: token.text.trim().isEmpty
              ? null
              : () =>
                    provider.connect(baseUrl: endpoint.text, token: token.text),
          child: Text(context.l10n.useToken),
        ),
      ],
    );
  }
}
