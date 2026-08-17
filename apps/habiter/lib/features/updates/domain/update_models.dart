import 'dart:convert';
import 'dart:typed_data';

enum UpdateTrack { stable, beta }

enum UpdateProfile { immediate, balanced, saver }

enum ReleaseChannel { stable, beta }

enum AndroidDistribution { direct, play }

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  verifying,
  ready,
  installing,
  mandatory,
  error,
}

final class UpdateNotes {
  const UpdateNotes({
    required this.added,
    required this.changed,
    required this.fixed,
    required this.security,
  });

  factory UpdateNotes.fromJson(Object? value) {
    final json = _map(value, 'notes');
    return UpdateNotes(
      added: _strings(json['added'], 'notes.added'),
      changed: _strings(json['changed'], 'notes.changed'),
      fixed: _strings(json['fixed'], 'notes.fixed'),
      security: _strings(json['security'], 'notes.security'),
    );
  }

  final List<String> added;
  final List<String> changed;
  final List<String> fixed;
  final List<String> security;

  List<String> get all => [...added, ...changed, ...fixed, ...security];
}

final class UpdateHighlight {
  const UpdateHighlight({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.mediaId,
  });

  factory UpdateHighlight.fromJson(Object? value) {
    final json = _map(value, 'highlight');
    return UpdateHighlight(
      id: _string(json['id'], 'highlight.id'),
      title: _string(json['title'], 'highlight.title'),
      description: _string(json['description'], 'highlight.description'),
      icon: _string(json['icon'], 'highlight.icon'),
      mediaId: _optionalString(json['mediaId'], 'highlight.mediaId'),
    );
  }

  final String id;
  final String title;
  final String description;
  final String icon;
  final String? mediaId;
}

final class LocalizedReleasePresentation {
  const LocalizedReleasePresentation({
    required this.headline,
    required this.summary,
    required this.highlights,
    required this.changes,
  });

  factory LocalizedReleasePresentation.fromJson(Object? value) {
    final json = _map(value, 'presentation');
    final highlights = _list(
      json['highlights'],
      'presentation.highlights',
    ).map(UpdateHighlight.fromJson).toList(growable: false);
    if (highlights.length > 5) {
      throw const FormatException(
        'A release may contain at most five highlights.',
      );
    }
    return LocalizedReleasePresentation(
      headline: _string(json['headline'], 'presentation.headline'),
      summary: _string(json['summary'], 'presentation.summary'),
      highlights: highlights,
      changes: UpdateNotes.fromJson(json['changes']),
    );
  }

  final String headline;
  final String summary;
  final List<UpdateHighlight> highlights;
  final UpdateNotes changes;
}

final class ReleaseMedia {
  const ReleaseMedia({
    required this.id,
    required this.mimeType,
    required this.url,
    required this.sha256,
    required this.size,
  });

  factory ReleaseMedia.fromJson(Object? value) {
    final json = _map(value, 'media');
    final url = Uri.parse(_string(json['url'], 'media.url'));
    if (url.scheme != 'https' || !url.hasAuthority) {
      throw const FormatException('Release media must use HTTPS.');
    }
    return ReleaseMedia(
      id: _string(json['id'], 'media.id'),
      mimeType: _string(json['mimeType'], 'media.mimeType'),
      url: url,
      sha256: _sha256(json['sha256'], 'media.sha256'),
      size: _positiveInt(json['size'], 'media.size'),
    );
  }

  final String id;
  final String mimeType;
  final Uri url;
  final String sha256;
  final int size;
}

final class UpdateArtifact {
  const UpdateArtifact({
    required this.platform,
    required this.architecture,
    required this.fileName,
    required this.signed,
    required this.url,
    required this.sha256,
    required this.size,
    this.distribution,
  });

  factory UpdateArtifact.fromJson(Object? value) {
    final json = _map(value, 'artifact');
    final platform = _string(json['platform'], 'artifact.platform');
    final distribution = switch (json['distribution']) {
      'direct' => AndroidDistribution.direct,
      'play' => AndroidDistribution.play,
      null => null,
      _ => throw const FormatException('Unknown Android distribution.'),
    };
    if (platform == 'android' && distribution == null) {
      throw const FormatException('Android artifacts require a distribution.');
    }
    final url = Uri.parse(_string(json['url'], 'artifact.url'));
    if (url.scheme != 'https' || !url.hasAuthority) {
      throw const FormatException('Update artifacts must use HTTPS.');
    }
    return UpdateArtifact(
      platform: platform,
      architecture: _string(json['architecture'], 'artifact.architecture'),
      fileName: _string(json['fileName'], 'artifact.fileName'),
      signed: _bool(json['signed'], 'artifact.signed'),
      distribution: distribution,
      url: url,
      sha256: _sha256(json['sha256'], 'artifact.sha256'),
      size: _positiveInt(json['size'], 'artifact.size'),
    );
  }

  final String platform;
  final String architecture;
  final String fileName;
  final bool signed;
  final AndroidDistribution? distribution;
  final Uri url;
  final String sha256;
  final int size;
}

final class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.buildNumber,
    required this.channel,
    required this.publishedAt,
    required this.minimumSupportedVersion,
    required this.mandatoryAfter,
    required this.notes,
    required this.presentations,
    required this.media,
    required this.artifacts,
  });

  factory UpdateRelease.fromJson(Object? value) {
    final json = _map(value, 'release');
    if (json['status'] != 'published') {
      throw const FormatException(
        'Signed manifests may contain only published releases.',
      );
    }
    final presentationJson = json['presentation'];
    final presentations = <String, LocalizedReleasePresentation>{};
    if (presentationJson != null) {
      final localized = _map(presentationJson, 'release.presentation');
      for (final language in const ['de', 'en']) {
        presentations[language] = LocalizedReleasePresentation.fromJson(
          localized[language],
        );
      }
    }
    final media = {
      for (final item in _optionalList(json['media'], 'release.media'))
        _string(_map(item, 'media')['id'], 'media.id'): ReleaseMedia.fromJson(
          item,
        ),
    };
    for (final presentation in presentations.values) {
      for (final highlight in presentation.highlights) {
        if (highlight.mediaId != null &&
            !media.containsKey(highlight.mediaId)) {
          throw FormatException('Unknown release media: ${highlight.mediaId}');
        }
      }
    }
    return UpdateRelease(
      version: _semver(json['version'], 'release.version'),
      buildNumber: _positiveInt(json['buildNumber'], 'release.buildNumber'),
      channel: switch (json['channel']) {
        'stable' => ReleaseChannel.stable,
        'beta' => ReleaseChannel.beta,
        _ => throw const FormatException('Unknown release channel.'),
      },
      publishedAt: _date(json['publishedAt'], 'release.publishedAt'),
      minimumSupportedVersion: _semver(
        json['minimumSupportedVersion'],
        'release.minimumSupportedVersion',
      ),
      mandatoryAfter: json['mandatoryAfter'] == null
          ? null
          : _date(json['mandatoryAfter'], 'release.mandatoryAfter'),
      notes: UpdateNotes.fromJson(json['notes']),
      presentations: Map.unmodifiable(presentations),
      media: Map.unmodifiable(media),
      artifacts: _list(
        json['artifacts'],
        'release.artifacts',
      ).map(UpdateArtifact.fromJson).toList(growable: false),
    );
  }

  final String version;
  final int buildNumber;
  final ReleaseChannel channel;
  final DateTime publishedAt;
  final String minimumSupportedVersion;
  final DateTime? mandatoryAfter;
  final UpdateNotes notes;
  final Map<String, LocalizedReleasePresentation> presentations;
  final Map<String, ReleaseMedia> media;
  final List<UpdateArtifact> artifacts;

  LocalizedReleasePresentation? presentationFor(String languageCode) =>
      presentations[languageCode] ?? presentations['en'];

  bool isMandatoryAt(DateTime now) =>
      mandatoryAfter != null && !now.toUtc().isBefore(mandatoryAfter!.toUtc());
}

final class UpdateManifest {
  const UpdateManifest({required this.schemaVersion, required this.releases});

  factory UpdateManifest.fromPayloadBytes(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    final json = _map(decoded, 'manifest');
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported update manifest schema.');
    }
    final releases = _list(
      json['releases'],
      'manifest.releases',
    ).map(UpdateRelease.fromJson).toList(growable: false);
    final builds = <int>{};
    var previous = 1 << 62;
    for (final release in releases) {
      if (!builds.add(release.buildNumber)) {
        throw const FormatException('Duplicate release build number.');
      }
      if (release.buildNumber >= previous) {
        throw const FormatException('Releases must be ordered newest first.');
      }
      previous = release.buildNumber;
    }
    return UpdateManifest(schemaVersion: 1, releases: releases);
  }

  final int schemaVersion;
  final List<UpdateRelease> releases;
}

final class UpdateCandidate {
  const UpdateCandidate({required this.release, required this.artifact});

  final UpdateRelease release;
  final UpdateArtifact artifact;
}

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be an object.');
  return value.map(
    (key, value) => MapEntry(
      key is String
          ? key
          : throw FormatException('$field has a non-string key.'),
      value,
    ),
  );
}

List<Object?> _list(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list.');
  return List<Object?>.from(value);
}

List<Object?> _optionalList(Object? value, String field) =>
    value == null ? const [] : _list(value, field);

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

String? _optionalString(Object? value, String field) =>
    value == null ? null : _string(value, field);

String _semver(Object? value, String field) {
  final version = _string(value, field);
  if (!RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$',
  ).hasMatch(version)) {
    throw FormatException('$field must be semantic version.');
  }
  return version;
}

String _sha256(Object? value, String field) {
  final digest = _string(value, field);
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
    throw FormatException('$field must be a lowercase SHA-256 digest.');
  }
  return digest;
}

int _positiveInt(Object? value, String field) {
  if (value is! int || value < 1) {
    throw FormatException('$field must be a positive integer.');
  }
  return value;
}

bool _bool(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

DateTime _date(Object? value, String field) {
  final parsed = DateTime.tryParse(_string(value, field));
  if (parsed == null) throw FormatException('$field must be an ISO-8601 date.');
  return parsed.toUtc();
}

List<String> _strings(Object? value, String field) => _list(
  value,
  field,
).map((item) => _string(item, field)).toList(growable: false);
