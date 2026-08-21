final class DesktopInstallRequest {
  const DesktopInstallRequest({
    required this.platform,
    required this.payloadPath,
    required this.sha256,
    required this.size,
    required this.version,
    required this.signed,
    required this.errorPath,
  });

  final String platform;
  final String payloadPath;
  final String sha256;
  final int size;
  final String version;
  final bool signed;
  final String errorPath;
}

abstract interface class DesktopUpdateInstaller {
  bool canInstall(String platform);

  Future<bool> launch(DesktopInstallRequest request);
}
