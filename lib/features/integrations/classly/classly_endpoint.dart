final class ClasslyEndpoint {
  const ClasslyEndpoint._(this.origin);

  final Uri origin;

  factory ClasslyEndpoint.parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException('Enter a root HTTPS endpoint.');
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        _isPrivateAddress(host)) {
      throw const FormatException(
        'Local and private endpoints are not allowed.',
      );
    }
    if (uri.hasPort && uri.port != 443) {
      throw const FormatException('Only the standard HTTPS port is allowed.');
    }
    return ClasslyEndpoint._(Uri(scheme: 'https', host: host));
  }

  static bool _isPrivateAddress(String host) {
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final values = parts.cast<int>();
    return values[0] == 10 ||
        values[0] == 127 ||
        (values[0] == 169 && values[1] == 254) ||
        (values[0] == 172 && values[1] >= 16 && values[1] <= 31) ||
        (values[0] == 192 && values[1] == 168);
  }
}
