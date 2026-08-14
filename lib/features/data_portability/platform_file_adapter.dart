abstract interface class PlatformFileAdapter {
  Future<String?> openText();
  Future<bool> saveText({required String suggestedName, required String contents});
}

final class UnsupportedPlatformFileAdapter implements PlatformFileAdapter {
  const UnsupportedPlatformFileAdapter();

  @override
  Future<String?> openText() async => null;

  @override
  Future<bool> saveText({required String suggestedName, required String contents}) async => false;
}
