import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/personal_sync_connection_controller.dart';
import '../domain/personal_sync_connection.dart';
import 'personal_sync_settings_card.dart';

class PersonalSyncScreen extends StatelessWidget {
  const PersonalSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<PersonalSyncConnectionController>();
    final busy =
        connection.phase == PersonalSyncConnectionPhase.checking ||
        connection.phase == PersonalSyncConnectionPhase.authorizing;
    return ListView(
      key: const Key('personal-sync-screen'),
      padding: const EdgeInsets.all(HabiterSpace.lg),
      children: [
        HabiterPageIntro(
          title: context.l10n.personalSyncBeta,
          subtitle: context.l10n.personalSyncSetupBody,
        ),
        const SizedBox(height: HabiterSpace.lg),
        HabiterSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_done_rounded),
                title: Text(
                  connection.instanceName ?? context.l10n.personalSyncConnected,
                ),
                subtitle: Text(connection.instanceOrigin ?? ''),
              ),
              if (connection.lastSuccessAt case final last?)
                Text(
                  context.l10n.personalSyncLastSuccess(
                    MaterialLocalizations.of(context).formatFullDate(last),
                  ),
                ),
              if (connection.problem case final problem?) ...[
                const SizedBox(height: 8),
                Text(
                  personalSyncProblemMessage(context, problem),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('personal-sync-now'),
                    onPressed: busy ? null : connection.syncNow,
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(context.l10n.personalSyncSyncNow),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => connection.reconnect(
                            language: Localizations.localeOf(
                              context,
                            ).languageCode,
                          ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(context.l10n.personalSyncReconnect),
                  ),
                ],
              ),
              const Divider(height: 32),
              TextButton.icon(
                key: const Key('personal-sync-disconnect'),
                onPressed: busy
                    ? null
                    : () => _confirm(
                        context,
                        title: context.l10n.personalSyncDisconnect,
                        body: context.l10n.personalSyncDisconnectBody,
                        action: connection.disconnect,
                      ),
                icon: const Icon(Icons.link_off_rounded),
                label: Text(context.l10n.personalSyncDisconnect),
              ),
              TextButton.icon(
                key: const Key('personal-sync-revoke-all'),
                onPressed: busy
                    ? null
                    : () => _confirm(
                        context,
                        title: context.l10n.personalSyncRevokeAll,
                        body: context.l10n.personalSyncRevokeBody,
                        action: connection.revokeAll,
                      ),
                icon: const Icon(Icons.phonelink_erase_rounded),
                label: Text(context.l10n.personalSyncRevokeAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
        HabiterSurface(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.l10n.personalSyncTroubleshooting),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(context.l10n.personalSyncTroubleshootingBody),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required Future<dynamic> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(title),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }
}
