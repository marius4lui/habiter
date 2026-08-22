import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../application/personal_sync_connection_controller.dart';
import '../domain/personal_sync_connection.dart';

class PersonalSyncSettingsCard extends StatefulWidget {
  const PersonalSyncSettingsCard({super.key});

  @override
  State<PersonalSyncSettingsCard> createState() =>
      _PersonalSyncSettingsCardState();
}

class _PersonalSyncSettingsCardState extends State<PersonalSyncSettingsCard> {
  final _origin = TextEditingController();

  @override
  void dispose() {
    _origin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<PersonalSyncConnectionController?>();
    if (connection == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.personalSyncSetupBody),
          const SizedBox(height: 8),
          Text(
            context.l10n.personalSyncSelfHosted,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    final busy =
        connection.phase == PersonalSyncConnectionPhase.authorizing ||
        connection.phase == PersonalSyncConnectionPhase.checking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.personalSyncSetupBody),
        const SizedBox(height: 8),
        Text(
          context.l10n.personalSyncSelfHosted,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (connection.isConnected)
          ListTile(
            key: const Key('personal-sync-settings-connected'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_done_outlined),
            title: Text(
              connection.instanceName ?? context.l10n.personalSyncConnected,
            ),
            subtitle: Text(connection.instanceOrigin ?? ''),
          )
        else ...[
          TextField(
            key: const Key('personal-sync-origin'),
            controller: _origin,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: context.l10n.personalSyncServer,
              hintText: context.l10n.personalSyncServerHint,
            ),
            onSubmitted: busy ? null : (_) => _connect(connection),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.personalSyncHttpsOnly,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('personal-sync-connect'),
            onPressed: busy || !connection.supported
                ? null
                : () => _connect(connection),
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_browser_rounded),
            label: Text(
              busy
                  ? context.l10n.personalSyncConnecting
                  : context.l10n.personalSyncConnect,
            ),
          ),
          if (connection.hasPendingAuthorization) ...[
            const SizedBox(height: 8),
            Text(context.l10n.personalSyncPending),
            TextButton(
              onPressed: connection.cancelConnection,
              child: Text(context.l10n.personalSyncCancelPending),
            ),
          ],
        ],
        if (connection.problem case final problem?) ...[
          const SizedBox(height: 8),
          Text(
            personalSyncProblemMessage(context, problem),
            key: const Key('personal-sync-problem'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _connect(PersonalSyncConnectionController controller) =>
      controller.beginConnection(
        serverOrigin: _origin.text,
        language: Localizations.localeOf(context).languageCode,
      );
}

String personalSyncProblemMessage(
  BuildContext context,
  PersonalSyncConnectionProblem problem,
) => switch (problem) {
  PersonalSyncConnectionProblem.invalidOrigin =>
    context.l10n.personalSyncInvalidOrigin,
  PersonalSyncConnectionProblem.unavailable =>
    context.l10n.personalSyncUnavailable,
  PersonalSyncConnectionProblem.incompatible =>
    context.l10n.personalSyncIncompatible,
  PersonalSyncConnectionProblem.callbackRejected =>
    context.l10n.personalSyncCallbackRejected,
  PersonalSyncConnectionProblem.callbackExpired =>
    context.l10n.personalSyncCallbackExpired,
  PersonalSyncConnectionProblem.browserCanceled =>
    context.l10n.personalSyncBrowserCanceled,
  PersonalSyncConnectionProblem.authorizationFailed =>
    context.l10n.personalSyncAuthFailed,
  PersonalSyncConnectionProblem.credentialStorageFailed =>
    context.l10n.personalSyncStorageFailed,
  PersonalSyncConnectionProblem.authenticationRequired =>
    context.l10n.personalSyncAuthRequired,
  PersonalSyncConnectionProblem.actionRequired =>
    context.l10n.personalSyncStatusAction,
  PersonalSyncConnectionProblem.network =>
    context.l10n.personalSyncNetworkError,
};
