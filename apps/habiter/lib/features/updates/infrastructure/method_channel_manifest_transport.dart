import 'package:flutter/services.dart';

import '../data/signed_manifest_client.dart';

final class MethodChannelManifestTransport implements ManifestTransport {
  const MethodChannelManifestTransport({
    MethodChannel channel = const MethodChannel('com.habiter.app/updates'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<ManifestTransportResponse> get(Uri endpoint, {String? etag}) async {
    final response = await _channel.invokeMapMethod<String, Object?>(
      'fetchManifest',
      {'url': endpoint.toString(), if (etag != null) 'etag': etag},
    );
    final statusCode = (response?['statusCode'] as num?)?.toInt();
    final body = response?['body'];
    if (statusCode == null || body is! String) {
      throw const FormatException('Invalid native manifest response.');
    }
    return ManifestTransportResponse(
      statusCode: statusCode,
      body: body,
      etag: response?['etag'] as String?,
    );
  }
}
