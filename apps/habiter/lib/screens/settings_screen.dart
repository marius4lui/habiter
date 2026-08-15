import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/reminders/application/reminder_permission_controller.dart';
import '../features/reminders/infrastructure/local_reminder_permission_gateway.dart';
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

  Future<void> _openClassly() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider(
        create: (_) => ClasslySyncProvider()..load(),
        child: const _ClasslyDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final preferences = habits.preferences;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        key: const Key('progressive-settings'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _Section(
            title: 'Appearance',
            children: [
              DropdownButtonFormField<ThemeMode>(
                initialValue: settings.themeMode,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) settings.setThemeMode(value);
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'de', label: Text('Deutsch')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: <String>{settings.locale.languageCode},
                onSelectionChanged: (value) =>
                    settings.setLocale(Locale(value.single)),
              ),
            ],
          ),
          _Section(
            title: 'Reminders',
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily reminder'),
                subtitle: Text(
                  preferences.notifications
                      ? 'Scheduled at ${preferences.reminderTime}'
                      : 'Off — permission is requested only after you enable it.',
                ),
                value: preferences.notifications,
                onChanged: (value) async {
                  if (value) {
                    final state = await _permissions.requestAfterUserIntent();
                    if (!state.canSchedule || !mounted) return;
                  }
                  await _update(preferences.copyWith(notifications: value));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: preferences.notifications,
                title: const Text('Reminder time'),
                trailing: Text(preferences.reminderTime),
                onTap: preferences.notifications
                    ? () => _chooseReminderTime(preferences)
                    : null,
              ),
            ],
          ),
          _Section(
            title: 'Privacy & data',
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recovery support'),
                subtitle: const Text('Show non-punitive restart suggestions.'),
                value: preferences.showRecoverySupport,
                onChanged: (value) =>
                    _update(preferences.copyWith(showRecoverySupport: value)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phonelink_lock_outlined),
                title: Text('Local-first data'),
                subtitle: Text(
                  'Habit data stays on this device unless you explicitly export or connect an integration.',
                ),
              ),
            ],
          ),
          _Section(
            title: 'App lock',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: const Text('Configure app lock'),
                subtitle: const Text(
                  'Android only. Review permissions and recovery before enabling.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppLockScreen(),
                  ),
                ),
              ),
            ],
          ),
          Card(
            child: ExpansionTile(
              key: const Key('advanced-integrations'),
              title: const Text('Advanced integrations'),
              subtitle: const Text('Optional, disabled by default'),
              children: [
                ListTile(
                  title: const Text('Classly-compatible import'),
                  subtitle: const Text(
                    'OAuth or a manually supplied token; HTTPS endpoints only.',
                  ),
                  onTap: _openClassly,
                ),
                ListTile(
                  title: const Text('Experimental remote AI'),
                  subtitle: Text(
                    AIManager.isConfigured
                        ? 'Enabled. Provider requests may share data and incur costs.'
                        : 'Off. Local coaching does not require an API key.',
                  ),
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
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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
      title: const Text('Classly-compatible import'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Only connect a trusted public HTTPS server. Disconnecting clears all stored credentials.',
            ),
            TextField(
              controller: endpoint,
              decoration: const InputDecoration(labelText: 'HTTPS endpoint'),
              keyboardType: TextInputType.url,
            ),
            TextField(
              controller: token,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Optional access token',
              ),
            ),
            if (provider.lastError != null)
              Text(
                provider.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        if (provider.isConnected)
          TextButton(
            onPressed: provider.disconnect,
            child: const Text('Disconnect'),
          ),
        TextButton(
          onPressed: provider.isConnecting
              ? null
              : () => provider.connectWithOAuth(baseUrl: endpoint.text),
          child: const Text('Connect with OAuth'),
        ),
        FilledButton(
          onPressed: token.text.trim().isEmpty
              ? null
              : () =>
                    provider.connect(baseUrl: endpoint.text, token: token.text),
          child: const Text('Use token'),
        ),
      ],
    );
  }
}
