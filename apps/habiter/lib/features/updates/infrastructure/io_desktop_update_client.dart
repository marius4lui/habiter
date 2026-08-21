import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../domain/update_models.dart';
import '../domain/update_platform_gateway.dart';
import 'desktop_update_client.dart';

DesktopUpdateClient createDesktopUpdateClient() => _defaultClient;

final DesktopUpdateClient _defaultClient = IoDesktopUpdateClient();

final class IoDesktopUpdateClient implements DesktopUpdateClient {
  IoDesktopUpdateClient({
    Directory? root,
    http.Client Function()? httpClientFactory,
  }) : _root = root ?? Directory(_defaultRootPath()),
       _httpClientFactory = httpClientFactory ?? http.Client.new;

  final Directory _root;
  final http.Client Function() _httpClientFactory;
  final Map<String, _DownloadTask> _tasks = {};

  static final RegExp _idPattern = RegExp(
    r'^desktop-(windows|linux|macos)-[1-9][0-9]*-[a-f0-9]{16}$',
  );

  @override
  bool canSelfUpdate(String platform) =>
      const {'windows', 'linux', 'macos'}.contains(platform);

  @override
  Future<String> enqueueDownload(UpdateCandidate candidate) async {
    final record = _DesktopDownloadRecord.fromCandidate(candidate);
    await _root.create(recursive: true);
    final current = await _readRecord(record.id);
    if (current != null && current != record) {
      await removeDownload(record.id);
    }
    await _writeRecord(record);
    await _errorFile(record.id).deleteIfExists();
    _start(record);
    return record.id;
  }

  @override
  Future<UpdateDownloadStatus> downloadStatus(String downloadId) async {
    _requireId(downloadId);
    final record = await _readRecord(downloadId);
    if (record == null) {
      return const UpdateDownloadStatus(
        phase: UpdateDownloadPhase.missing,
        downloadedBytes: 0,
        totalBytes: 0,
      );
    }
    final error = await _readError(downloadId);
    if (error != null) {
      return UpdateDownloadStatus(
        phase: UpdateDownloadPhase.failed,
        downloadedBytes: await _safeLength(_partFile(downloadId)),
        totalBytes: record.size,
        failureCode: error,
      );
    }
    final payload = _payloadFile(record);
    if (await payload.exists()) {
      return UpdateDownloadStatus(
        phase: UpdateDownloadPhase.complete,
        downloadedBytes: await _safeLength(payload),
        totalBytes: record.size,
      );
    }
    _start(record);
    return UpdateDownloadStatus(
      phase: UpdateDownloadPhase.running,
      downloadedBytes: await _safeLength(_partFile(downloadId)),
      totalBytes: record.size,
    );
  }

  @override
  Future<UpdateVerificationResult> verifyDownload(
    String downloadId,
    UpdateCandidate candidate,
  ) async {
    _requireId(downloadId);
    final expected = _DesktopDownloadRecord.fromCandidate(candidate);
    final record = await _readRecord(downloadId);
    if (record != expected || record?.id != downloadId) {
      return const UpdateVerificationResult.invalid('metadata_mismatch');
    }
    final payload = _payloadFile(expected);
    if (!await payload.exists() || await payload.length() != expected.size) {
      return const UpdateVerificationResult.invalid('size_mismatch');
    }
    final actual = (await sha256.bind(payload.openRead()).first).toString();
    if (actual != expected.sha256) {
      await _verifiedFile(downloadId).deleteIfExists();
      return const UpdateVerificationResult.invalid('checksum_mismatch');
    }
    await _verifiedFile(downloadId).writeAsString('$actual\n', flush: true);
    return const UpdateVerificationResult.valid();
  }

  @override
  Future<void> removeDownload(String downloadId) async {
    _requireId(downloadId);
    final task = _tasks.remove(downloadId);
    if (task != null) {
      task.client.close();
      await task.future;
    }
    final record = await _readRecord(downloadId);
    for (final file in [
      _metadataFile(downloadId),
      File('${_metadataFile(downloadId).path}.new'),
      _partFile(downloadId),
      _errorFile(downloadId),
      _verifiedFile(downloadId),
      if (record != null) _payloadFile(record),
      File('${_root.path}/$downloadId.zip'),
      File('${_root.path}/$downloadId.AppImage'),
    ]) {
      await file.deleteIfExists();
    }
  }

  @override
  Future<void> clearDownloads() async {
    if (!await _root.exists()) return;
    final ids = <String>{};
    await for (final entity in _root.list(followLinks: false)) {
      final name = entity.uri.pathSegments.last;
      final match = RegExp(
        r'^(desktop-(?:windows|linux|macos)-[1-9][0-9]*-[a-f0-9]{16})\.',
      ).firstMatch(name);
      if (match != null) ids.add(match.group(1)!);
    }
    for (final id in ids) {
      await removeDownload(id);
    }
  }

  @override
  Future<UpdateInstallResult> install(
    String downloadId,
    UpdateCandidate candidate,
  ) async => UpdateInstallResult.unavailable;

  @override
  Future<int> storedDownloadBytes() async {
    if (!await _root.exists()) return 0;
    var total = 0;
    await for (final entity in _root.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.endsWith('.part') ||
          name.endsWith('.zip') ||
          name.endsWith('.AppImage')) {
        total += await _safeLength(entity);
      }
    }
    return total;
  }

  @override
  Future<void> cleanupAfterUpgrade(int currentBuild) => clearDownloads();

  void _start(_DesktopDownloadRecord record) {
    if (_tasks.containsKey(record.id)) return;
    final client = _httpClientFactory();
    final future = _download(record, client);
    _tasks[record.id] = _DownloadTask(client: client, future: future);
    unawaited(
      future.whenComplete(() {
        final task = _tasks[record.id];
        if (identical(task?.future, future)) {
          _tasks.remove(record.id)?.client.close();
        }
      }),
    );
  }

  Future<void> _download(
    _DesktopDownloadRecord record,
    http.Client client,
  ) async {
    try {
      final uri = Uri.parse(record.url);
      if (uri.scheme != 'https' || !uri.hasAuthority) {
        throw const _DownloadFailure('unsafe_url');
      }
      final part = _partFile(record.id);
      var offset = await _safeLength(part);
      if (offset > record.size) {
        await part.deleteIfExists();
        offset = 0;
      }
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..maxRedirects = 0;
      if (offset > 0) {
        request.headers[HttpHeaders.rangeHeader] = 'bytes=$offset-';
      }
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.isRedirect ||
          (response.statusCode >= 300 && response.statusCode < 400)) {
        throw const _DownloadFailure('unsafe_redirect');
      }
      final append =
          offset > 0 && response.statusCode == HttpStatus.partialContent;
      if (response.statusCode != HttpStatus.ok && !append) {
        throw const _DownloadFailure('download_http_error');
      }
      if (!append) offset = 0;
      final sink = part.openWrite(
        mode: append ? FileMode.append : FileMode.write,
      );
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          received += chunk.length;
          if (offset + received > record.size) {
            throw const _DownloadFailure('size_mismatch');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (await part.length() != record.size) {
        throw const _DownloadFailure('size_mismatch');
      }
      final payload = _payloadFile(record);
      await payload.deleteIfExists();
      await part.rename(payload.path);
      await _errorFile(record.id).deleteIfExists();
    } on _DownloadFailure catch (error) {
      await _writeError(record.id, error.code);
    } on Object {
      await _writeError(record.id, 'download_network_error');
    }
  }

  Future<_DesktopDownloadRecord?> _readRecord(String id) async {
    _requireId(id);
    final file = _metadataFile(id);
    if (!await file.exists()) return null;
    try {
      return _DesktopDownloadRecord.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } on Object {
      return null;
    }
  }

  Future<void> _writeRecord(_DesktopDownloadRecord record) async {
    final target = _metadataFile(record.id);
    final pending = File('${target.path}.new');
    await pending.writeAsString(jsonEncode(record.toJson()), flush: true);
    await target.deleteIfExists();
    await pending.rename(target.path);
  }

  Future<String?> _readError(String id) async {
    final file = _errorFile(id);
    if (!await file.exists()) return null;
    final code = (await file.readAsString()).trim();
    return RegExp(r'^[a-z0-9_]+$').hasMatch(code) ? code : 'download_failed';
  }

  Future<void> _writeError(String id, String code) =>
      _errorFile(id).writeAsString('$code\n', flush: true);

  File _metadataFile(String id) => File('${_root.path}/$id.json');
  File _partFile(String id) => File('${_root.path}/$id.part');
  File _errorFile(String id) => File('${_root.path}/$id.error');
  File _verifiedFile(String id) => File('${_root.path}/$id.verified');
  File _payloadFile(_DesktopDownloadRecord record) =>
      File('${_root.path}/${record.id}.${record.extension}');

  void _requireId(String id) {
    if (!_idPattern.hasMatch(id)) {
      throw const FormatException('Invalid desktop download identifier.');
    }
  }

  static Future<int> _safeLength(File file) async =>
      await file.exists() ? await file.length() : 0;
}

final class _DesktopDownloadRecord {
  const _DesktopDownloadRecord({
    required this.id,
    required this.platform,
    required this.buildNumber,
    required this.url,
    required this.fileName,
    required this.format,
    required this.sha256,
    required this.size,
    required this.signed,
  });

  factory _DesktopDownloadRecord.fromCandidate(UpdateCandidate candidate) {
    final artifact = candidate.artifact;
    final format = artifact.format;
    if (!const {'windows', 'linux', 'macos'}.contains(artifact.platform) ||
        format == null) {
      throw const FormatException('Unsupported desktop update artifact.');
    }
    return _DesktopDownloadRecord(
      id: 'desktop-${artifact.platform}-${candidate.release.buildNumber}-${artifact.sha256.substring(0, 16)}',
      platform: artifact.platform,
      buildNumber: candidate.release.buildNumber,
      url: artifact.url.toString(),
      fileName: artifact.fileName,
      format: format.name,
      sha256: artifact.sha256,
      size: artifact.size,
      signed: artifact.signed,
    );
  }

  factory _DesktopDownloadRecord.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid desktop update record.');
    }
    final record = _DesktopDownloadRecord(
      id: value['id'] as String,
      platform: value['platform'] as String,
      buildNumber: value['buildNumber'] as int,
      url: value['url'] as String,
      fileName: value['fileName'] as String,
      format: value['format'] as String,
      sha256: value['sha256'] as String,
      size: value['size'] as int,
      signed: value['signed'] as bool,
    );
    if (!IoDesktopUpdateClient._idPattern.hasMatch(record.id) ||
        Uri.tryParse(record.url)?.scheme != 'https' ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]+$').hasMatch(record.fileName) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(record.sha256) ||
        record.size < 1 ||
        !const {'zip', 'appImage'}.contains(record.format)) {
      throw const FormatException('Unsafe desktop update record.');
    }
    return record;
  }

  final String id;
  final String platform;
  final int buildNumber;
  final String url;
  final String fileName;
  final String format;
  final String sha256;
  final int size;
  final bool signed;

  String get extension => format == 'appImage' ? 'AppImage' : 'zip';

  Map<String, Object?> toJson() => {
    'id': id,
    'platform': platform,
    'buildNumber': buildNumber,
    'url': url,
    'fileName': fileName,
    'format': format,
    'sha256': sha256,
    'size': size,
    'signed': signed,
  };

  @override
  bool operator ==(Object other) =>
      other is _DesktopDownloadRecord &&
      id == other.id &&
      platform == other.platform &&
      buildNumber == other.buildNumber &&
      url == other.url &&
      fileName == other.fileName &&
      format == other.format &&
      sha256 == other.sha256 &&
      size == other.size &&
      signed == other.signed;

  @override
  int get hashCode => Object.hash(
    id,
    platform,
    buildNumber,
    url,
    fileName,
    format,
    sha256,
    size,
    signed,
  );
}

final class _DownloadTask {
  const _DownloadTask({required this.client, required this.future});

  final http.Client client;
  final Future<void> future;
}

final class _DownloadFailure implements Exception {
  const _DownloadFailure(this.code);

  final String code;
}

extension on File {
  Future<void> deleteIfExists() async {
    if (await exists()) await delete();
  }
}

String _defaultRootPath() {
  final environment = Platform.environment;
  if (Platform.isWindows) {
    final localAppData = environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      return '$localAppData\\Habiter\\updates';
    }
  }
  final home = environment['HOME'];
  if (Platform.isMacOS && home != null && home.isNotEmpty) {
    return '$home/Library/Caches/dev.habiter.Habiter/updates';
  }
  final xdgCache = environment['XDG_CACHE_HOME'];
  if (xdgCache != null && xdgCache.isNotEmpty) {
    return '$xdgCache/habiter/updates';
  }
  if (home != null && home.isNotEmpty) return '$home/.cache/habiter/updates';
  return '${Directory.systemTemp.path}/habiter-updates';
}
