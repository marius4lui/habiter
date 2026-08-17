import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import '../domain/update_models.dart';

final class SignedManifestEnvelope {
  const SignedManifestEnvelope({
    required this.schemaVersion,
    required this.keyId,
    required this.algorithm,
    required this.payload,
    required this.signature,
  });

  factory SignedManifestEnvelope.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid manifest envelope.');
    }
    final json = value.map((key, value) => MapEntry(key.toString(), value));
    final schemaVersion = json['schemaVersion'];
    final keyId = json['keyId'];
    final algorithm = json['algorithm'];
    final payload = json['payload'];
    final signature = json['signature'];
    if (schemaVersion != 1 ||
        keyId is! String ||
        keyId.isEmpty ||
        algorithm != 'ed25519' ||
        payload is! String ||
        signature is! String) {
      throw const FormatException('Unsupported manifest envelope.');
    }
    final payloadBytes = _base64Url(payload, 'payload');
    final signatureBytes = _base64Url(signature, 'signature');
    if (payloadBytes.length > ManifestVerifier.maximumPayloadBytes) {
      throw const FormatException('Manifest payload is too large.');
    }
    if (signatureBytes.length != 64) {
      throw const FormatException('Invalid Ed25519 signature length.');
    }
    return SignedManifestEnvelope(
      schemaVersion: 1,
      keyId: keyId,
      algorithm: 'ed25519',
      payload: payloadBytes,
      signature: signatureBytes,
    );
  }

  final int schemaVersion;
  final String keyId;
  final String algorithm;
  final Uint8List payload;
  final Uint8List signature;
}

final class VerifiedManifest {
  const VerifiedManifest({required this.manifest, required this.envelopeJson});

  final UpdateManifest manifest;
  final String envelopeJson;
}

final class ManifestVerifier {
  ManifestVerifier({required Map<String, List<int>> publicKeyRing})
    : _publicKeyRing = Map.unmodifiable({
        for (final entry in publicKeyRing.entries)
          entry.key: SimplePublicKey(
            entry.value.length == 32
                ? entry.value
                : throw ArgumentError.value(
                    entry.value.length,
                    entry.key,
                    'Ed25519 public keys must contain exactly 32 bytes.',
                  ),
            type: KeyPairType.ed25519,
          ),
      });

  factory ManifestVerifier.fromEnvironment() {
    const encoded = String.fromEnvironment(
      'HABITER_UPDATE_PUBLIC_KEYS',
      defaultValue: '{}',
    );
    try {
      return ManifestVerifier.fromEncodedKeyRing(encoded);
    } on Object {
      return ManifestVerifier(publicKeyRing: const {});
    }
  }

  factory ManifestVerifier.fromEncodedKeyRing(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('HABITER_UPDATE_PUBLIC_KEYS must be JSON.');
    }
    return ManifestVerifier(
      publicKeyRing: decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          _base64Url(value.toString(), 'public key'),
        ),
      ),
    );
  }

  static const maximumPayloadBytes = 2 * 1024 * 1024;
  final Map<String, SimplePublicKey> _publicKeyRing;
  final Ed25519 _algorithm = Ed25519();

  Future<VerifiedManifest> verify(String envelopeJson) async {
    final envelope = SignedManifestEnvelope.fromJson(jsonDecode(envelopeJson));
    final publicKey = _publicKeyRing[envelope.keyId];
    if (publicKey == null) {
      throw const FormatException('Unknown manifest signing key.');
    }
    final valid = await _algorithm.verify(
      envelope.payload,
      signature: Signature(envelope.signature, publicKey: publicKey),
    );
    if (!valid) throw const FormatException('Manifest signature is invalid.');
    return VerifiedManifest(
      manifest: UpdateManifest.fromPayloadBytes(envelope.payload),
      envelopeJson: envelopeJson,
    );
  }
}

final class ManifestFetchResult {
  const ManifestFetchResult.notModified({required this.etag})
    : envelopeJson = null;

  const ManifestFetchResult.updated({
    required this.envelopeJson,
    required this.etag,
  });

  final String? envelopeJson;
  final String? etag;
  bool get isNotModified => envelopeJson == null;
}

final class SignedManifestClient {
  SignedManifestClient({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      endpoint =
          endpoint ??
          Uri.parse(
            const String.fromEnvironment(
              'HABITER_UPDATE_MANIFEST_URL',
              defaultValue: 'https://get.habiter.dev/api/v1/manifest',
            ),
          );

  final http.Client _client;
  final Uri endpoint;

  Future<ManifestFetchResult> fetch({String? etag}) async {
    if (endpoint.scheme != 'https' || !endpoint.hasAuthority) {
      throw const FormatException('Manifest endpoint must use HTTPS.');
    }
    final response = await _client.get(
      endpoint,
      headers: {
        'accept': 'application/json',
        if (etag != null) 'if-none-match': etag,
      },
    );
    if (response.statusCode == 304) {
      return ManifestFetchResult.notModified(
        etag: response.headers['etag'] ?? etag,
      );
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Manifest request failed with ${response.statusCode}.',
        endpoint,
      );
    }
    if (response.bodyBytes.length > ManifestVerifier.maximumPayloadBytes * 2) {
      throw const FormatException('Manifest envelope is too large.');
    }
    return ManifestFetchResult.updated(
      envelopeJson: utf8.decode(response.bodyBytes),
      etag: response.headers['etag'],
    );
  }
}

Uint8List _base64Url(String value, String field) {
  try {
    return base64Url.decode(base64Url.normalize(value));
  } on FormatException {
    throw FormatException('Invalid Base64URL $field.');
  }
}
