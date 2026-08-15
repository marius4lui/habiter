abstract interface class PlatformGateway {
  bool get isSupported;

  Future<T?> invoke<T>(
    String method, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]);
}
