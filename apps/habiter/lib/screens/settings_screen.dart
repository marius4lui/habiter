import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../app/navigation/app_route.dart';
import '../features/reminders/application/reminder_permission_controller.dart';
import '../features/reminders/application/reminder_diagnostics.dart';
import '../features/reminders/infrastructure/local_reminder_permission_gateway.dart';
import '../features/reminders/presentation/reminder_diagnostics_panel.dart';
import '../features/runtime/infrastructure/method_channel_background_runtime_gateway.dart';
import '../features/personal_sync/presentation/personal_sync_settings_card.dart';
import '../features/widgets/domain/widget_bridge.dart';
import '../features/widgets/application/widget_sync_controller.dart';
import '../features/widgets/presentation/widget_management_screen.dart';
import '../features/updates/application/update_controller.dart';
import '../features/updates/domain/update_models.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/classly_sync_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_manager.dart';
import '../services/notification_service.dart';
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

  Future<void> _syncWidgetPresentation(String locale) async {
    final sync = context.read<WidgetSyncController?>();
    await sync?.synchronize(locale: locale);
  }

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
    final updates = context.watch<UpdateController>();
    final widgetBridge = context.read<WidgetBridge?>();
    return Scaffold(
      appBar: Navigator.of(context).canPop() ? AppBar() : null,
      body: ListView(
        key: const Key('progressive-settings'),
        children: [
          HabiterContent(
            maxWidth: HabiterSize.wideContentMax,
            bottomPadding: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HabiterPageIntro(
                  title: context.l10n.settingsTitle,
                  subtitle: context.l10n.settingsBody,
                ),
                const SizedBox(height: HabiterSpace.lg),
                HabiterAdaptiveGrid(
                  key: const Key('settings-sections-grid'),
                  minimumColumnWidth: 300,
                  spacing: HabiterSpace.lg,
                  runSpacing: 0,
                  maxColumns: 2,
                  children: [
                    _SettingsSection(
                      key: const Key('settings-appearance-section'),
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
                          onChanged: (value) async {
                            if (value != null) {
                              await settings.setThemeMode(value);
                              await _syncWidgetPresentation(
                                settings.locale.languageCode,
                              );
                            }
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
                                onChanged: (value) async {
                                  if (value != null) {
                                    await settings.setLocale(Locale(value));
                                    await _syncWidgetPresentation(value);
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
                              onSelectionChanged: (value) async {
                                await settings.setLocale(Locale(value.single));
                                await _syncWidgetPresentation(value.single);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    _SettingsSection(
                      key: const Key('settings-notifications-section'),
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
                        ListTile(
                          key: const Key('reminder-diagnostics-entry'),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.monitor_heart_outlined),
                          title: Text(context.l10n.reminderDiagnostics),
                          subtitle: Text(
                            context.l10n.reminderDiagnosticsDescription,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _showReminderDiagnostics,
                        ),
                      ],
                    ),
                    _SettingsSection(
                      key: const Key('settings-widget-section'),
                      icon: Icons.widgets_outlined,
                      title: context.l10n.widgetSettingsTitle,
                      children: [
                        FutureBuilder<bool>(
                          future:
                              widgetBridge?.hasInstalledWidgets() ??
                              Future<bool>.value(false),
                          builder: (context, snapshot) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.add_to_home_screen_rounded,
                            ),
                            title: Text(context.l10n.widgetSettingsTitle),
                            subtitle: Text(
                              snapshot.data == true
                                  ? context.l10n.widgetStatusAdded
                                  : context.l10n.widgetStatusNotAdded,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: widgetBridge == null
                                ? null
                                : () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const WidgetManagementScreen(),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      key: const Key('settings-updates-section'),
                      icon: Icons.system_update_alt_rounded,
                      title: context.l10n.updateSettingsEntry,
                      children: [
                        ListTile(
                          key: const Key('update-center-entry'),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.rocket_launch_outlined),
                          title: Text(context.l10n.updateSettingsEntry),
                          subtitle: Text(_updateSummary(context, updates)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (updates.state.candidate != null)
                                const Badge(
                                  label: Text('1'),
                                  child: Icon(Icons.new_releases_outlined),
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRouteCodec.encode(AppRoute.updates)),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      key: const Key('settings-focus-section'),
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
                      icon: Icons.cloud_sync_outlined,
                      title: context.l10n.personalSyncBeta,
                      children: const [PersonalSyncSettingsCard()],
                    ),
                    _SettingsSection(
                      key: const Key('settings-privacy-section'),
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
                      key: const Key('settings-advanced-section'),
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        key: const Key('advanced-integrations'),
                        leading: const Icon(Icons.tune_rounded),
                        title: Text(context.l10n.advancedIntegrations),
                        subtitle: Text(context.l10n.advancedIntegrationsBody),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          12,
                        ),
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

  Future<void> _showReminderDiagnostics() async {
    final snapshot = await ReminderDiagnosticsController(
      notifications: NotificationService.instance,
      permissions: const LocalReminderPermissionGateway(),
      runtime: const MethodChannelBackgroundRuntimeGateway(),
    ).load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ReminderDiagnosticsPanel(
            snapshot: snapshot,
            onSendTest: NotificationService.instance.showTestNotification,
            onReschedule: context.read<HabitProvider>().reconcileReminders,
          ),
        ),
      ),
    );
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

String _updateSummary(BuildContext context, UpdateController controller) =>
    switch (controller.state.phase) {
      UpdatePhase.checking => context.l10n.updateStatusChecking,
      UpdatePhase.upToDate => context.l10n.updateStatusCurrent,
      UpdatePhase.available => context.l10n.updateStatusAvailable(
        controller.state.candidate?.release.version ?? '',
      ),
      UpdatePhase.downloading => context.l10n.updateStatusDownloading(
        (controller.state.progress * 100).round(),
      ),
      UpdatePhase.verifying => context.l10n.updateStatusVerifying,
      UpdatePhase.ready => context.l10n.updateStatusReady,
      UpdatePhase.restartRequired => context.l10n.updateStatusRestartRequired,
      UpdatePhase.installing => context.l10n.updateStatusInstalling,
      UpdatePhase.mandatory => context.l10n.updateStatusMandatory,
      UpdatePhase.unsupported => context.l10n.updateUnsupported,
      UpdatePhase.error => context.l10n.updateStatusError,
      UpdatePhase.idle => context.l10n.updateSettingsBody,
    };

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    super.key,
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
