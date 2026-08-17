import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../domain/update_models.dart';

final class UpdateLocalState {
  const UpdateLocalState({
    this.track = UpdateTrack.stable,
    this.profile = UpdateProfile.balanced,
    this.cachedEnvelope,
    this.etag,
    this.lastCheckedAt,
    this.presentedBuilds = const {},
    this.readyNotifiedBuilds = const {},
    this.downloadId,
    this.downloadBuild,
    this.previousAppBuild,
  });

  factory UpdateLocalState.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid update state.');
    final json = value.map((key, value) => MapEntry(key.toString(), value));
    if (json['storageVersion'] != 1) {
      throw const FormatException('Unsupported update state version.');
    }
    return UpdateLocalState(
      track: switch (json['track']) {
        'beta' => UpdateTrack.beta,
        _ => UpdateTrack.stable,
      },
      profile: switch (json['profile']) {
        'immediate' => UpdateProfile.immediate,
        'saver' => UpdateProfile.saver,
        _ => UpdateProfile.balanced,
      },
      cachedEnvelope: _optionalString(json['cachedEnvelope']),
      etag: _optionalString(json['etag']),
      lastCheckedAt: _optionalDate(json['lastCheckedAt']),
      presentedBuilds: _intSet(json['presentedBuilds']),
      readyNotifiedBuilds: _intSet(json['readyNotifiedBuilds']),
      downloadId: _optionalString(json['downloadId']),
      downloadBuild: _optionalInt(json['downloadBuild']),
      previousAppBuild: _optionalInt(json['previousAppBuild']),
    );
  }

  final UpdateTrack track;
  final UpdateProfile profile;
  final String? cachedEnvelope;
  final String? etag;
  final DateTime? lastCheckedAt;
  final Set<int> presentedBuilds;
  final Set<int> readyNotifiedBuilds;
  final String? downloadId;
  final int? downloadBuild;
  final int? previousAppBuild;

  int get metadataBytes => utf8.encode(jsonEncode(toJson())).length;

  Map<String, Object?> toJson() => {
    'storageVersion': 1,
    'track': track.name,
    'profile': profile.name,
    if (cachedEnvelope != null) 'cachedEnvelope': cachedEnvelope,
    if (etag != null) 'etag': etag,
    if (lastCheckedAt != null)
      'lastCheckedAt': lastCheckedAt!.toUtc().toIso8601String(),
    'presentedBuilds': presentedBuilds.toList()..sort(),
    'readyNotifiedBuilds': readyNotifiedBuilds.toList()..sort(),
    if (downloadId != null) 'downloadId': downloadId,
    if (downloadBuild != null) 'downloadBuild': downloadBuild,
    if (previousAppBuild != null) 'previousAppBuild': previousAppBuild,
  };

  UpdateLocalState copyWith({
    UpdateTrack? track,
    UpdateProfile? profile,
    Object? cachedEnvelope = _unset,
    Object? etag = _unset,
    Object? lastCheckedAt = _unset,
    Set<int>? presentedBuilds,
    Set<int>? readyNotifiedBuilds,
    Object? downloadId = _unset,
    Object? downloadBuild = _unset,
    Object? previousAppBuild = _unset,
  }) => UpdateLocalState(
    track: track ?? this.track,
    profile: profile ?? this.profile,
    cachedEnvelope: identical(cachedEnvelope, _unset)
        ? this.cachedEnvelope
        : cachedEnvelope as String?,
    etag: identical(etag, _unset) ? this.etag : etag as String?,
    lastCheckedAt: identical(lastCheckedAt, _unset)
        ? this.lastCheckedAt
        : lastCheckedAt as DateTime?,
    presentedBuilds: Set.unmodifiable(presentedBuilds ?? this.presentedBuilds),
    readyNotifiedBuilds: Set.unmodifiable(
      readyNotifiedBuilds ?? this.readyNotifiedBuilds,
    ),
    downloadId: identical(downloadId, _unset)
        ? this.downloadId
        : downloadId as String?,
    downloadBuild: identical(downloadBuild, _unset)
        ? this.downloadBuild
        : downloadBuild as int?,
    previousAppBuild: identical(previousAppBuild, _unset)
        ? this.previousAppBuild
        : previousAppBuild as int?,
  );
}

final class UpdateLocalRepository {
  const UpdateLocalRepository(this._store);

  static const storageKey = 'updates_state_v1';
  final KeyValueStore _store;

  Future<UpdateLocalState> load() async {
    final encoded = await _store.read(storageKey);
    if (encoded == null) return const UpdateLocalState();
    if (encoded is! String) return const UpdateLocalState();
    try {
      return UpdateLocalState.fromJson(jsonDecode(encoded));
    } on FormatException {
      return const UpdateLocalState();
    }
  }

  Future<void> save(UpdateLocalState state) =>
      _store.write(storageKey, jsonEncode(state.toJson()));

  Future<void> clearCache(UpdateLocalState state) => save(
    state.copyWith(cachedEnvelope: null, etag: null, lastCheckedAt: null),
  );
}

const _unset = Object();

String? _optionalString(Object? value) => value is String ? value : null;

int? _optionalInt(Object? value) => value is int && value >= 0 ? value : null;

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Set<int> _intSet(Object? value) => value is List
    ? Set.unmodifiable(value.whereType<int>().where((item) => item > 0))
    : const {};
