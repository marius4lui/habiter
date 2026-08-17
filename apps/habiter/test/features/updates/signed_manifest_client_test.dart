import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/data/signed_manifest_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'update_test_data.dart';

void main() {
  Future<({String envelope, List<int> publicKey})> signedEnvelope({
    int build = 10500,
    List<int>? seed,
  }) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      seed ?? List<int>.generate(32, (index) => index),
    );
    final publicKey = await keyPair.extractPublicKey();
    final payload = manifestPayload([
      releaseJson(build: build, channel: 'stable'),
    ]);
    final signature = await algorithm.sign(payload, keyPair: keyPair);
    String encoded(List<int> bytes) =>
        base64UrlEncode(bytes).replaceAll('=', '');
    return (
      envelope: jsonEncode({
        'schemaVersion': 1,
        'keyId': 'release-key',
        'algorithm': 'ed25519',
        'payload': encoded(payload),
        'signature': encoded(signature.bytes),
      }),
      publicKey: publicKey.bytes,
    );
  }

  test('verifies the exact payload and detects manipulation', () async {
    final fixture = await signedEnvelope();
    final verifier = ManifestVerifier(
      publicKeyRing: {'release-key': fixture.publicKey},
    );
    final verified = await verifier.verify(fixture.envelope);
    expect(verified.manifest.releases.single.buildNumber, 10500);

    final tampered = jsonDecode(fixture.envelope) as Map<String, Object?>;
    tampered['payload'] = base64UrlEncode(
      manifestPayload([releaseJson(build: 10501, channel: 'stable')]),
    );
    expect(
      () => verifier.verify(jsonEncode(tampered)),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects unknown keys and accepts an explicit rotated key', () async {
    final old = await signedEnvelope(seed: List.filled(32, 1));
    final next = await signedEnvelope(seed: List.filled(32, 2));
    final oldOnly = ManifestVerifier(
      publicKeyRing: {'release-key': old.publicKey},
    );
    expect(
      () => oldOnly.verify(next.envelope),
      throwsA(isA<FormatException>()),
    );
    final rotated = ManifestVerifier(
      publicKeyRing: {'release-key': next.publicKey},
    );
    expect((await rotated.verify(next.envelope)).manifest.schemaVersion, 1);
  });

  test('uses ETag without sending any user identifier', () async {
    final fixture = await signedEnvelope();
    final client = SignedManifestClient(
      client: MockClient((request) async {
        expect(request.headers['if-none-match'], '"old"');
        expect(
          request.headers.keys.any(
            (key) => key.contains('user') || key.contains('device'),
          ),
          isFalse,
        );
        return http.Response(
          fixture.envelope,
          200,
          headers: {'etag': '"new"', 'content-type': 'application/json'},
        );
      }),
    );
    final result = await client.fetch(etag: '"old"');
    expect(result.etag, '"new"');
    expect(result.envelopeJson, fixture.envelope);
  });

  test('recognizes a not-modified response', () async {
    final client = SignedManifestClient(
      client: MockClient((_) async => http.Response('', 304)),
    );
    final result = await client.fetch(etag: '"same"');
    expect(result.isNotModified, isTrue);
    expect(result.etag, '"same"');
  });
}
