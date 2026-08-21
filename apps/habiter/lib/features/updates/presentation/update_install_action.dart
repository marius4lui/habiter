import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../application/update_controller.dart';
import '../domain/update_platform_gateway.dart';

Future<void> requestUpdateInstall(
  BuildContext context,
  UpdateController controller,
) async {
  final result = await controller.install();
  if (result != UpdateInstallResult.permissionRequired || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.updateInstallerPermissionTitle),
      content: Text(context.l10n.updateInstallerPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.updateNotNow),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            final permission = await controller.openInstallerPermission();
            if (!context.mounted) return;
            if (permission == InstallerPermissionResult.granted) {
              final retry = await controller.install();
              if (retry == UpdateInstallResult.launched || !context.mounted) {
                return;
              }
            }
            await showDialog<void>(
              context: context,
              builder: (helpContext) => AlertDialog(
                title: Text(context.l10n.updateInstallerPermissionHelpTitle),
                content: Text(
                  permission == InstallerPermissionResult.unavailable
                      ? context.l10n.updateInstallerPermissionUnavailableBody
                      : context.l10n.updateInstallerPermissionDeniedBody,
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(helpContext),
                    child: Text(context.l10n.updateInstallerPermissionGotIt),
                  ),
                ],
              ),
            );
          },
          child: Text(context.l10n.updateOpenSettings),
        ),
      ],
    ),
  );
}
