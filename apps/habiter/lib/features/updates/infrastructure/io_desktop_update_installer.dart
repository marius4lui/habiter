import 'dart:convert';
import 'dart:io';

import 'desktop_update_installer.dart';

typedef DetachedProcessLauncher =
    Future<bool> Function(String executable, List<String> arguments);

final class IoDesktopUpdateInstaller implements DesktopUpdateInstaller {
  IoDesktopUpdateInstaller({
    required Directory helperDirectory,
    String? platformOverride,
    String? resolvedExecutable,
    Map<String, String>? environment,
    int? processIdOverride,
    DetachedProcessLauncher? launcher,
  }) : _helperDirectory = helperDirectory,
       _platform = platformOverride ?? _hostPlatform,
       _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable,
       _environment = environment ?? Platform.environment,
       _processId = processIdOverride ?? pid,
       _launcher = launcher ?? _launchDetached;

  final Directory _helperDirectory;
  final String _platform;
  final String _resolvedExecutable;
  final Map<String, String> _environment;
  final int _processId;
  final DetachedProcessLauncher _launcher;

  @override
  bool canInstall(String platform) =>
      platform == _platform && _detectContext(platform) != null;

  @override
  Future<bool> launch(DesktopInstallRequest request) async {
    if (request.platform != _platform ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(request.sha256) ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(request.version) ||
        request.size < 1 ||
        (const {'windows', 'macos'}.contains(request.platform) &&
            !request.signed)) {
      return false;
    }
    final context = _detectContext(request.platform);
    if (context == null) return false;
    final payload = File(request.payloadPath);
    if (!await payload.exists() || await payload.length() != request.size) {
      return false;
    }
    await _helperDirectory.create(recursive: true);
    return switch (request.platform) {
      'linux' => _launchPosix(context, request),
      'windows' => _launchWindows(context, request),
      'macos' => _launchMacos(context, request),
      _ => false,
    };
  }

  Future<bool> _launchPosix(
    _InstallContext context,
    DesktopInstallRequest request,
  ) async {
    final helper = File('${_helperDirectory.path}/desktop-update-helper-v1.sh');
    await helper.writeAsString(_linuxHelper, flush: true);
    return _launcher('/bin/sh', [
      helper.path,
      '$_processId',
      request.payloadPath,
      context.executable,
      context.root,
      request.sha256,
      '${request.size}',
      request.version,
      request.errorPath,
    ]);
  }

  Future<bool> _launchWindows(
    _InstallContext context,
    DesktopInstallRequest request,
  ) async {
    final helper = File(
      '${_helperDirectory.path}/desktop-update-helper-v1.ps1',
    );
    await helper.writeAsString(_windowsHelper, flush: true);
    return _launcher('powershell.exe', [
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'RemoteSigned',
      '-File',
      helper.path,
      '-ParentPid',
      '$_processId',
      '-Payload',
      request.payloadPath,
      '-TargetExecutable',
      context.executable,
      '-InstallRoot',
      context.root,
      '-Sha256',
      request.sha256,
      '-Size',
      '${request.size}',
      '-Version',
      request.version,
      '-SignedArtifact',
      request.signed ? 'true' : 'false',
      '-ErrorPath',
      request.errorPath,
    ]);
  }

  Future<bool> _launchMacos(
    _InstallContext context,
    DesktopInstallRequest request,
  ) async {
    final helper = File('${_helperDirectory.path}/desktop-update-helper-v1.sh');
    await helper.writeAsString(_macosHelper, flush: true);
    return _launcher('/bin/sh', [
      helper.path,
      '$_processId',
      request.payloadPath,
      context.root,
      context.executable,
      context.manifest,
      request.sha256,
      '${request.size}',
      request.version,
      request.errorPath,
    ]);
  }

  _InstallContext? _detectContext(String platform) {
    try {
      return switch (platform) {
        'linux' => _detectLinux(),
        'windows' => _detectWindows(),
        'macos' => _detectMacos(),
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  _InstallContext? _detectLinux() {
    final appImage = _environment['APPIMAGE'];
    if (appImage == null || appImage.isEmpty) return null;
    final executable = _canonicalFile(File(appImage));
    if (_leaf(executable).toLowerCase() != 'habiter.appimage') return null;
    final root = File(executable).parent.resolveSymbolicLinksSync();
    return _validatedContext(root: root, executable: executable);
  }

  _InstallContext? _detectWindows() {
    final executable = _canonicalFile(File(_resolvedExecutable));
    if (_leaf(executable).toLowerCase() != 'habiter.exe') return null;
    final root = File(executable).parent.resolveSymbolicLinksSync();
    return _validatedContext(root: root, executable: executable);
  }

  _InstallContext? _detectMacos() {
    final executable = _canonicalFile(File(_resolvedExecutable));
    if (_leaf(executable) != 'habiter') return null;
    final executableFile = File(executable);
    final macos = executableFile.parent;
    if (_leaf(macos.path) != 'MacOS') return null;
    final contents = macos.parent;
    if (_leaf(contents.path) != 'Contents') return null;
    final app = contents.parent;
    if (_leaf(app.path) != 'Habiter.app' ||
        app.statSync().type != FileSystemEntityType.directory) {
      return null;
    }
    final root = app.resolveSymbolicLinksSync();
    final homeValue = _environment['HOME'];
    if (homeValue == null || homeValue.isEmpty) return null;
    final home = Directory(homeValue).resolveSymbolicLinksSync();
    if (!_isStrictDescendant(root, home)) return null;
    return _validatedContext(
      root: root,
      executable: executable,
      manifestPath: '$root.habiter-install.json',
    );
  }

  _InstallContext? _validatedContext({
    required String root,
    required String executable,
    String? manifestPath,
  }) {
    final manifestFile = File(
      manifestPath ?? '$root${Platform.pathSeparator}.habiter-install.json',
    );
    if (FileSystemEntity.typeSync(manifestFile.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    final value = jsonDecode(manifestFile.readAsStringSync());
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['product'] != 'habiter' ||
        value['applicationId'] != 'dev.habiter.Habiter' ||
        value['scope'] != 'user') {
      return null;
    }
    final manifestRoot = value['canonicalInstallRoot'];
    final manifestExecutable = value['executable'];
    if (manifestRoot is! String || manifestExecutable is! String) return null;
    if (Directory(manifestRoot).resolveSymbolicLinksSync() != root ||
        _canonicalFile(File(manifestExecutable)) != executable) {
      return null;
    }
    return _InstallContext(
      root: root,
      executable: executable,
      manifest: manifestFile.resolveSymbolicLinksSync(),
    );
  }

  static bool _isStrictDescendant(String child, String parent) {
    final separator = Platform.pathSeparator;
    final prefix = parent.endsWith(separator) ? parent : '$parent$separator';
    return child.startsWith(prefix);
  }

  static String _canonicalFile(File file) {
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FileSystemException('Updater target is not a regular file.');
    }
    return file.resolveSymbolicLinksSync();
  }

  static String _leaf(String path) =>
      path.split(RegExp(r'[/\\]')).where((part) => part.isNotEmpty).last;

  static Future<bool> _launchDetached(
    String executable,
    List<String> arguments,
  ) async {
    await Process.start(executable, arguments, mode: ProcessStartMode.detached);
    return true;
  }

  static String get _hostPlatform {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'unsupported';
  }
}

final class _InstallContext {
  const _InstallContext({
    required this.root,
    required this.executable,
    required this.manifest,
  });

  final String root;
  final String executable;
  final String manifest;
}

const String _linuxHelper = r'''#!/bin/sh
set -eu

parent_pid=$1
payload=$2
target=$3
root=$4
expected_sha=$5
expected_size=$6
version=$7
error_path=$8
stage=
backup=
activated=0

fail() {
  printf '%s\n' install_failed > "$error_path" 2>/dev/null || true
  exit 1
}

rollback() {
  status=$?
  if [ "$status" -ne 0 ]; then
    if [ "$activated" -eq 1 ] && [ -n "$backup" ] && [ -f "$backup" ]; then
      rm -f -- "$target" || true
      mv -- "$backup" "$target" || true
    fi
    [ -z "$stage" ] || rm -f -- "$stage" || true
    printf '%s\n' install_failed > "$error_path" 2>/dev/null || true
  fi
  exit "$status"
}
trap rollback EXIT HUP INT TERM

case "$parent_pid:$expected_size:$version:$expected_sha" in
  *[!0-9.:a-f-]*|*::*|:*|*:) fail ;;
esac
[ "$(dirname -- "$target")" = "$root" ] || fail
[ "$(basename -- "$target")" = Habiter.AppImage ] || fail
[ -f "$target" ] && [ ! -L "$target" ] || fail
[ -f "$payload" ] && [ ! -L "$payload" ] || fail

count=0
while kill -0 "$parent_pid" 2>/dev/null; do
  [ "$count" -lt 120 ] || fail
  count=$((count + 1))
  sleep 1
done

actual_size=$(wc -c < "$payload" | tr -d ' ')
[ "$actual_size" = "$expected_size" ] || fail
if command -v sha256sum >/dev/null 2>&1; then
  actual_sha=$(sha256sum "$payload" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  actual_sha=$(shasum -a 256 "$payload" | awk '{print $1}')
else
  fail
fi
[ "$actual_sha" = "$expected_sha" ] || fail

stage="$root/.Habiter.AppImage.update-$$"
backup="$root/.Habiter.AppImage.backup-$$"
[ ! -e "$stage" ] && [ ! -e "$backup" ] || fail
cp -- "$payload" "$stage"
chmod 755 "$stage"
mv -- "$target" "$backup"
mv -- "$stage" "$target"
stage=
activated=1
"$target" >/dev/null 2>&1 &
new_pid=$!
sleep 2
kill -0 "$new_pid" 2>/dev/null || fail
rm -f -- "$backup"
backup=
activated=0
rm -f -- "$error_path" 2>/dev/null || true
trap - EXIT HUP INT TERM
exit 0
''';

const String _macosHelper = r'''#!/bin/sh
set -eu

parent_pid=$1
payload=$2
target=$3
target_executable=$4
manifest=$5
expected_sha=$6
expected_size=$7
version=$8
error_path=$9
extract=
stage=
backup=
manifest_next=
activated=0

fail() {
  printf '%s\n' install_failed > "$error_path" 2>/dev/null || true
  exit 1
}

rollback() {
  status=$?
  if [ "$status" -ne 0 ]; then
    if [ "$activated" -eq 1 ] && [ -n "$backup" ] && [ -d "$backup" ]; then
      rm -rf "$target" || true
      mv "$backup" "$target" || true
    fi
    [ -z "$stage" ] || rm -rf "$stage" || true
    [ -z "$extract" ] || rm -rf "$extract" || true
    [ -z "$manifest_next" ] || rm -f "$manifest_next" || true
    printf '%s\n' install_failed > "$error_path" 2>/dev/null || true
  fi
  exit "$status"
}
trap rollback EXIT HUP INT TERM

case "$parent_pid:$expected_size:$version:$expected_sha" in
  *[!0-9.:a-f-]*|*::*|:*|*:) fail ;;
esac
[ "$(basename "$target")" = Habiter.app ] || fail
[ "$target_executable" = "$target/Contents/MacOS/habiter" ] || fail
[ "$manifest" = "$target.habiter-install.json" ] || fail
case "$target" in "$HOME"/*) ;; *) fail ;; esac
[ -d "$target" ] && [ ! -L "$target" ] || fail
[ -f "$target_executable" ] && [ ! -L "$target_executable" ] || fail
[ -f "$manifest" ] && [ ! -L "$manifest" ] || fail
[ -f "$payload" ] && [ ! -L "$payload" ] || fail

manifest_value() {
  /usr/bin/plutil -extract "$1" raw -o - "$manifest" 2>/dev/null || fail
}
[ "$(manifest_value schemaVersion)" = 1 ] || fail
[ "$(manifest_value product)" = habiter ] || fail
[ "$(manifest_value applicationId)" = dev.habiter.Habiter ] || fail
[ "$(manifest_value scope)" = user ] || fail
[ "$(manifest_value canonicalInstallRoot)" = "$target" ] || fail
[ "$(manifest_value executable)" = "$target_executable" ] || fail

actual_size=$(wc -c < "$payload" | tr -d ' ')
[ "$actual_size" = "$expected_size" ] || fail
actual_sha=$(shasum -a 256 "$payload" | awk '{print $1}')
[ "$actual_sha" = "$expected_sha" ] || fail

parent=$(dirname "$target")
extract="$parent/.Habiter.extract-$$"
stage="$parent/.Habiter.app.update-$$"
backup="$parent/.Habiter.app.backup-$$"
manifest_next="$manifest.update-$$"
for path in "$extract" "$stage" "$backup" "$manifest_next"; do
  [ ! -e "$path" ] && [ ! -L "$path" ] || fail
done
mkdir "$extract"
listing="$extract/archive-list"
/usr/bin/unzip -Z1 "$payload" > "$listing" || fail
entry_count=0
while IFS= read -r entry; do
  [ -n "$entry" ] || fail
  case "$entry" in
    *\\*|/*|*:*) fail ;;
  esac
  normalized=${entry%/}
  case "$normalized" in
    Habiter.app|Habiter.app/*) ;;
    *) fail ;;
  esac
  old_ifs=$IFS
  IFS='/
'
  for component in $normalized; do
    case "$component" in ''|.|..) IFS=$old_ifs; fail ;; esac
  done
  IFS=$old_ifs
  entry_count=$((entry_count + 1))
done < "$listing"
[ "$entry_count" -gt 0 ] || fail
rm -f "$listing"
/usr/bin/ditto -x -k "$payload" "$extract" || fail
[ -d "$extract/Habiter.app" ] && [ ! -L "$extract/Habiter.app" ] || fail
[ -f "$extract/Habiter.app/Contents/MacOS/habiter" ] || fail
mv "$extract/Habiter.app" "$stage"
rm -rf "$extract"
extract=

bundle_id() {
  /usr/bin/plutil -extract CFBundleIdentifier raw -o - "$1/Contents/Info.plist" 2>/dev/null || fail
}
team_id() {
  /usr/bin/codesign -dv --verbose=4 "$1" 2>&1 | sed -n 's/^TeamIdentifier=//p'
}
[ "$(bundle_id "$target")" = dev.habiter.Habiter ] || fail
[ "$(bundle_id "$stage")" = dev.habiter.Habiter ] || fail
/usr/bin/codesign --verify --deep --strict --verbose=2 "$target" >/dev/null 2>&1 || fail
/usr/bin/codesign --verify --deep --strict --verbose=2 "$stage" >/dev/null 2>&1 || fail
/usr/sbin/spctl --assess --type execute --verbose=2 "$target" >/dev/null 2>&1 || fail
/usr/sbin/spctl --assess --type execute --verbose=2 "$stage" >/dev/null 2>&1 || fail
current_team=$(team_id "$target")
next_team=$(team_id "$stage")
[ -n "$current_team" ] && [ "$current_team" != "not set" ] || fail
[ "$current_team" = "$next_team" ] || fail

count=0
while kill -0 "$parent_pid" 2>/dev/null; do
  [ "$count" -lt 120 ] || fail
  count=$((count + 1))
  sleep 1
done

mv "$target" "$backup"
mv "$stage" "$target"
stage=
activated=1
"$target/Contents/MacOS/habiter" >/dev/null 2>&1 &
new_pid=$!
sleep 2
kill -0 "$new_pid" 2>/dev/null || fail
cp "$manifest" "$manifest_next"
/usr/bin/plutil -replace version -string "$version" "$manifest_next" || fail
mv "$manifest_next" "$manifest"
manifest_next=
rm -rf "$backup"
backup=
activated=0
rm -f "$error_path" 2>/dev/null || true
trap - EXIT HUP INT TERM
exit 0
''';

const String _windowsHelper = r'''param(
  [Parameter(Mandatory=$true)][int]$ParentPid,
  [Parameter(Mandatory=$true)][string]$Payload,
  [Parameter(Mandatory=$true)][string]$TargetExecutable,
  [Parameter(Mandatory=$true)][string]$InstallRoot,
  [Parameter(Mandatory=$true)][string]$Sha256,
  [Parameter(Mandatory=$true)][long]$Size,
  [Parameter(Mandatory=$true)][string]$Version,
  [Parameter(Mandatory=$true)][ValidateSet('true', 'false')][string]$SignedArtifact,
  [Parameter(Mandatory=$true)][string]$ErrorPath
)
$ErrorActionPreference = 'Stop'
$backup = $null
$activated = $false

function Fail-Update([string]$Message) { throw [InvalidOperationException]::new($Message) }
try {
  $root = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
  $target = [IO.Path]::GetFullPath($TargetExecutable)
  $archive = [IO.Path]::GetFullPath($Payload)
  if ((Split-Path $target -Parent) -ne $root -or (Split-Path $target -Leaf).ToLowerInvariant() -ne 'habiter.exe') { Fail-Update 'Unsafe target' }
  if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or -not (Test-Path -LiteralPath $archive -PathType Leaf)) { Fail-Update 'Missing target or archive' }
  if ((Get-Item -LiteralPath $archive).Length -ne $Size) { Fail-Update 'Size mismatch' }
  if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Sha256) { Fail-Update 'Checksum mismatch' }
  try { Wait-Process -Id $ParentPid -Timeout 120 -ErrorAction Stop } catch { if (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue) { Fail-Update 'Habiter did not exit' } }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($archive)
  try {
    foreach ($entry in $zip.Entries) {
      $name = $entry.FullName.Replace('\', '/')
      if ($name.StartsWith('/') -or $name.Contains(':') -or @($name.Split('/')) -contains '..') { Fail-Update 'Unsafe ZIP entry' }
    }
  } finally { $zip.Dispose() }

  $parent = Split-Path $root -Parent
  $extract = Join-Path $parent ('.Habiter.extract-' + $PID)
  $stage = Join-Path $parent ('.Habiter.update-' + $PID)
  $backup = Join-Path $parent ('.Habiter.backup-' + $PID)
  foreach ($path in @($extract, $stage, $backup)) { if (Test-Path -LiteralPath $path) { Fail-Update 'Updater staging path already exists' } }
  Expand-Archive -LiteralPath $archive -DestinationPath $extract
  if (@(Get-ChildItem -LiteralPath $extract -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count -gt 0) { Fail-Update 'Archive contains reparse points' }
  $executables = @(Get-ChildItem -LiteralPath $extract -Filter habiter.exe -Recurse -File)
  if ($executables.Count -ne 1) { Fail-Update 'Archive does not contain one Habiter bundle' }
  $bundle = $executables[0].Directory.FullName
  if ($SignedArtifact -eq 'true') {
    $currentSignature = Get-AuthenticodeSignature -LiteralPath $target
    $nextSignature = Get-AuthenticodeSignature -LiteralPath $executables[0].FullName
    if ($currentSignature.Status -ne 'Valid' -or $nextSignature.Status -ne 'Valid' -or $currentSignature.SignerCertificate.Thumbprint -ne $nextSignature.SignerCertificate.Thumbprint) { Fail-Update 'Publisher signature mismatch' }
  }
  Move-Item -LiteralPath $bundle -Destination $stage
  Move-Item -LiteralPath $root -Destination $backup
  Move-Item -LiteralPath $stage -Destination $root
  $activated = $true

  $manifestPath = Join-Path $backup '.habiter-install.json'
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  if ($manifest.schemaVersion -ne 1 -or $manifest.product -ne 'habiter' -or $manifest.scope -ne 'user') { Fail-Update 'Ownership manifest changed' }
  if ([IO.Path]::GetFullPath([string]$manifest.canonicalInstallRoot).TrimEnd('\') -ne $root -or [IO.Path]::GetFullPath([string]$manifest.executable) -ne $target) { Fail-Update 'Ownership target changed' }
  $manifest.version = $Version
  $manifest.canonicalInstallRoot = $root
  $manifest.executable = Join-Path $root 'habiter.exe'
  $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $root '.habiter-install.json') -Encoding UTF8
  $bin = Join-Path $root 'bin'
  New-Item -ItemType Directory -Path $bin -Force | Out-Null
  '@echo off' + [Environment]::NewLine + '"%~dp0..\habiter.exe" %*' | Set-Content -LiteralPath (Join-Path $bin 'habiter.cmd') -Encoding Ascii
  $process = Start-Process -FilePath (Join-Path $root 'habiter.exe') -PassThru
  Start-Sleep -Seconds 2
  if ($process.HasExited) { Fail-Update 'Updated application exited during startup' }
  Remove-Item -LiteralPath $backup -Recurse -Force
  $backup = $null
  $activated = $false
  Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $ErrorPath -Force -ErrorAction SilentlyContinue
  exit 0
} catch {
  if ($activated -and $backup -and (Test-Path -LiteralPath $backup)) {
    Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue
    Move-Item -LiteralPath $backup -Destination $InstallRoot -ErrorAction SilentlyContinue
  }
  try { Set-Content -LiteralPath $ErrorPath -Value 'install_failed' -Encoding Ascii } catch {}
  exit 1
}
''';
