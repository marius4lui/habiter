#!/bin/sh
set -eu

API_BASE=${HABITER_API_BASE:-https://get.habiter.dev}
CHANNEL=stable
VERSION=
DRY_RUN=0
VERBOSE=0
NO_DESKTOP=0
SYSTEM=0
INSTALL_DIR=
TMP_DIR=
BACKUP_PATH=
FINAL_PATH=
PHASE=startup
INSTALL_ID="$(date +%s 2>/dev/null || say 0)-$$"
MANIFEST_NAME=.habiter-install.json

say() { printf '%s\n' "$*"; }
fail() {
  code=$1; message=$2; hint=${3:-}; status=${4:-1}
  printf '\nHabiter installer failed [%s]\n  Phase: %s\n  Error: %s\n' "$code" "$PHASE" "$message" >&2
  [ -z "$hint" ] || printf '  Fix: %s\n' "$hint" >&2
  printf '  Install ID: %s\n' "$INSTALL_ID" >&2
  if [ "$VERBOSE" -eq 1 ]; then
    printf 'Diagnostics:\n  os=%s arch=%s channel=%s version=%s system=%s dryRun=%s\n  installDir=%s\n' \
      "${OS:-unknown}" "${ARCH:-unknown}" "$CHANNEL" "${VERSION:-latest}" "$SYSTEM" "$DRY_RUN" "${FINAL_PATH:-${INSTALL_DIR:-not-resolved}}" >&2
  fi
  exit "$status"
}
die() { fail HAB-POSIX-999 "$*" "Retry with --verbose and report the Install ID if the error persists." 1; }
debug() { [ "$VERBOSE" -eq 0 ] || printf '      %s\n' "$*"; }
cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ -n "$BACKUP_PATH" ] && [ -e "$BACKUP_PATH" ] && [ -n "$FINAL_PATH" ]; then
    rm -rf -- "$FINAL_PATH" || printf 'Rollback warning: could not remove failed installation.\n' >&2
    mv -- "$BACKUP_PATH" "$FINAL_PATH" || printf 'Rollback warning: could not restore %s.\n' "$BACKUP_PATH" >&2
  fi
  [ -z "$TMP_DIR" ] || rm -rf -- "$TMP_DIR" || printf 'Cleanup warning: could not remove %s.\n' "$TMP_DIR" >&2
  exit "$status"
}
trap cleanup EXIT HUP INT TERM

usage() {
  say "Habiter desktop installer"
  say "Usage: install.sh [--channel stable|beta] [--version X.Y.Z] [--install-dir PATH]"
  say "                  [--dry-run] [--verbose] [--no-color] [--system] [--no-desktop-integration]"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --channel) [ "$#" -ge 2 ] || fail HAB-POSIX-001 "--channel requires a value" "Use stable or beta." 2; CHANNEL=$2; shift 2 ;;
      --version) [ "$#" -ge 2 ] || fail HAB-POSIX-002 "--version requires a value" "Use X.Y.Z." 2; VERSION=$2; shift 2 ;;
      --install-dir) [ "$#" -ge 2 ] || fail HAB-POSIX-003 "--install-dir requires a value" "Provide an absolute writable path." 2; INSTALL_DIR=$2; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --verbose) VERBOSE=1; shift ;;
      --no-color) NO_COLOR=1; export NO_COLOR; shift ;;
      --system) SYSTEM=1; shift ;;
      --no-desktop-integration) NO_DESKTOP=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) fail HAB-POSIX-004 "unknown option: $1" "Run with --help to list supported options." 2 ;;
    esac
  done
  case "$CHANNEL" in stable|beta) ;; *) fail HAB-POSIX-005 "channel must be stable or beta" "Use --channel stable or --channel beta." 2 ;; esac
  [ -z "$VERSION" ] || printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail HAB-POSIX-006 "version must use X.Y.Z" "Example: --version 1.6.0" 2
}

normalize_arch() {
  case "$1" in x86_64|amd64) say x64 ;; arm64|aarch64) say arm64 ;; *) return 1 ;; esac
}

normalize_distro() {
  id=$1; like=$2
  case "$id" in
    ubuntu|linuxmint|pop|debian)
      if [ "$id" = debian ]; then say debian; else say ubuntu; fi
      return
      ;;
    fedora|rhel|centos) say fedora; return ;;
    arch|manjaro|endeavouros) say arch; return ;;
    opensuse*|sles) say opensuse; return ;;
  esac
  case " $like " in *" debian "*) say debian ;; *" fedora "*|*" rhel "*) say fedora ;; *" arch "*) say arch ;; *" suse "*) say opensuse ;; *) say generic ;; esac
}

detect_system() {
  PHASE=detect-system
  command -v uname >/dev/null 2>&1 || fail HAB-POSIX-010 "uname is required" "Install the operating-system core utilities." 10
  raw_os=${HABITER_UNAME_S:-$(uname -s)}
  raw_arch=${HABITER_UNAME_M:-$(uname -m)}
  ARCH=$(normalize_arch "$raw_arch") || fail HAB-POSIX-011 "unsupported architecture: $raw_arch" "Use a supported x64 or arm64 machine; Linux artifacts currently require x64." 10
  DISTRO=
  case "$raw_os" in
    Linux)
      OS=linux
      release_file=${HABITER_OS_RELEASE_FILE:-/etc/os-release}
      [ -r "$release_file" ] || fail HAB-POSIX-012 "cannot read OS release file: $release_file" "Check the file path and permissions, or set HABITER_OS_RELEASE_FILE." 10
      id=$(sed -n 's/^ID=//p' "$release_file" | head -n 1 | tr -d '"')
      like=$(sed -n 's/^ID_LIKE=//p' "$release_file" | head -n 1 | tr -d '"')
      DISTRO=$(normalize_distro "$id" "$like")
      ;;
    Darwin) OS=macos ;;
    *) fail HAB-POSIX-013 "unsupported operating system: $raw_os" "Use Linux or macOS." 10 ;;
  esac
  if [ "$OS" = macos ]; then
    if [ "$ARCH" = arm64 ]; then ARCH=arm64; else ARCH=x64; fi
  fi
}

json_string() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
json_number() { printf '%s' "$1" | sed -n "s/.*\"$2\":\([0-9][0-9]*\).*/\1/p"; }

resolve_release() {
  PHASE=resolve-release
  command -v curl >/dev/null 2>&1 || fail HAB-POSIX-020 "curl is required" "Install curl and retry." 20
  query="channel=$CHANNEL"
  [ -z "$VERSION" ] || query="$query&version=$VERSION"
  [ -z "$DISTRO" ] || query="$query&distro=$DISTRO"
  endpoint="$API_BASE/api/v1/install/$OS/$ARCH?$query"
  debug "Resolver: $endpoint"
  RESPONSE=$(curl -fsSL --connect-timeout 15 --max-time 60 --retry 2 --retry-all-errors --proto '=https' --tlsv1.2 "$endpoint") || fail HAB-POSIX-021 "release resolver request failed" "Check DNS, internet, proxy, TLS and get.habiter.dev; retry with --verbose." 20
  RELEASE_VERSION=$(json_string "$RESPONSE" version)
  FORMAT=$(json_string "$RESPONSE" format)
  FILE_NAME=$(json_string "$RESPONSE" fileName)
  DOWNLOAD_URL=$(json_string "$RESPONSE" url)
  SHA256=$(json_string "$RESPONSE" sha256)
  SIZE=$(json_number "$RESPONSE" size)
  printf '%s' "$RELEASE_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail HAB-POSIX-022 "resolver returned an invalid version" "Do not install this artifact; report the Install ID." 22
  printf '%s' "$FILE_NAME" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]+$' || fail HAB-POSIX-023 "resolver returned an invalid file name" "Do not install this artifact; report the Install ID." 22
  printf '%s' "$SHA256" | grep -Eq '^[a-f0-9]{64}$' || fail HAB-POSIX-024 "resolver returned an invalid checksum" "Do not install this artifact; report the Install ID." 22
  printf '%s' "$SIZE" | grep -Eq '^[1-9][0-9]*$' || fail HAB-POSIX-025 "resolver returned an invalid size" "Do not install this artifact; report the Install ID." 22
  case "$DOWNLOAD_URL" in https://*) ;; *) fail HAB-POSIX-026 "resolver returned a non-HTTPS URL" "Never bypass HTTPS validation." 22 ;; esac
  case "$OS:$FORMAT" in linux:appimage|macos:zip) ;; *) fail HAB-POSIX-027 "unsupported installer artifact: $FORMAT" "Use a published primary artifact for this platform." 22 ;; esac
}

verify_sha256() {
  file=$1
  if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$file" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then actual=$(shasum -a 256 "$file" | awk '{print $1}')
  else fail HAB-POSIX-040 "sha256sum or shasum is required" "Install coreutils or a SHA-256 capable shasum." 40; fi
  [ "$actual" = "$SHA256" ] || fail HAB-POSIX-041 "SHA-256 mismatch" "Delete the download and retry; never bypass checksum verification." 40
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_manifest() {
  root=$1 executable=$2 scope=$3 integration_a=${4:-} integration_b=${5:-}
  manifest=$root/$MANIFEST_NAME
  escaped_root=$(json_escape "$root")
  escaped_executable=$(json_escape "$executable")
  escaped_a=$(json_escape "$integration_a")
  escaped_b=$(json_escape "$integration_b")
  integrations=
  [ -z "$integration_a" ] || integrations="\"$escaped_a\""
  [ -z "$integration_b" ] || integrations="${integrations:+$integrations,}\"$escaped_b\""
  umask 022
  printf '%s\n' \
    '{' \
    '  "schemaVersion": 1,' \
    '  "product": "habiter",' \
    '  "applicationId": "dev.habiter.Habiter",' \
    "  \"installId\": \"$(json_escape "$INSTALL_ID")\"," \
    "  \"version\": \"$(json_escape "$RELEASE_VERSION")\"," \
    "  \"scope\": \"$scope\"," \
    "  \"canonicalInstallRoot\": \"$escaped_root\"," \
    "  \"executable\": \"$escaped_executable\"," \
    "  \"integrationPaths\": [$integrations]," \
    '  "pathEntry": null,' \
    '  "pathEntryAddedByInstaller": false' \
    '}' > "$manifest" || fail HAB-POSIX-071 "cannot write the ownership manifest" "The installation was not finalized; check destination permissions." 70
}

install_linux() {
  PHASE=install-linux
  root=${INSTALL_DIR:-${HOME}/.local/opt/habiter}
  FINAL_PATH="$root/Habiter.AppImage"
  bin_dir=${HOME}/.local/bin
  desktop_dir=${HOME}/.local/share/applications
  [ "$SYSTEM" -eq 0 ] || { root=/opt/habiter; FINAL_PATH=$root/Habiter.AppImage; bin_dir=/usr/local/bin; desktop_dir=/usr/local/share/applications; }
  say "[5/7] Installing application"; say "      $FINAL_PATH"
  if [ "$DRY_RUN" -eq 1 ]; then return; fi
  mkdir -p "$root" "$bin_dir" "$desktop_dir" || fail HAB-POSIX-060 "cannot create installation directories" "Check permissions and free disk space; use a user-scoped install if possible." 60
  staged="$root/.Habiter.AppImage.new"; cp "$TMP_DIR/$FILE_NAME" "$staged" || fail HAB-POSIX-061 "cannot stage AppImage" "Check destination permissions and free disk space." 60
  chmod 755 "$staged" || fail HAB-POSIX-062 "cannot make AppImage executable" "Check filesystem mount options and permissions." 60
  if [ -e "$FINAL_PATH" ]; then BACKUP_PATH="$root/.Habiter.AppImage.backup"; rm -f "$BACKUP_PATH"; mv "$FINAL_PATH" "$BACKUP_PATH"; fi
  mv "$staged" "$FINAL_PATH"
  if [ "$NO_DESKTOP" -eq 0 ]; then
    ln -sfn "$FINAL_PATH" "$bin_dir/habiter"
    printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Habiter' "Exec=$FINAL_PATH" 'Icon=dev.habiter.Habiter' 'Terminal=false' 'Categories=Utility;' > "$desktop_dir/dev.habiter.Habiter.desktop"
  fi
  canonical_root=$(CDPATH='' cd -- "$root" && pwd -P) || fail HAB-POSIX-063 "cannot canonicalize installation root" "Check the installation path and links." 60
  integration_a= integration_b=
  if [ "$NO_DESKTOP" -eq 0 ]; then integration_a=$bin_dir/habiter; integration_b=$desktop_dir/dev.habiter.Habiter.desktop; fi
  write_manifest "$canonical_root" "$canonical_root/Habiter.AppImage" "$(if [ "$SYSTEM" -eq 1 ]; then say system; else say user; fi)" "$integration_a" "$integration_b"
  [ -z "$BACKUP_PATH" ] || rm -f "$BACKUP_PATH"; BACKUP_PATH=
}

install_macos() {
  PHASE=install-macos
  root=${INSTALL_DIR:-${HOME}/Applications}; [ "$SYSTEM" -eq 0 ] || root=/Applications
  FINAL_PATH="$root/Habiter.app"
  say "[5/7] Installing application"; say "      $FINAL_PATH"
  [ "$DRY_RUN" -eq 1 ] && return
  mkdir -p "$TMP_DIR/extracted" "$root"
  command -v ditto >/dev/null 2>&1 || fail HAB-POSIX-050 "ditto is required on macOS" "Restore the standard macOS command-line tools." 50
  ditto -x -k "$TMP_DIR/$FILE_NAME" "$TMP_DIR/extracted" || fail HAB-POSIX-051 "archive extraction failed" "Check disk space and retry with a fresh download." 50
  [ -d "$TMP_DIR/extracted/Habiter.app/Contents/MacOS" ] || fail HAB-POSIX-052 "archive does not contain a valid Habiter.app" "Do not install this archive; report the Install ID." 50
  staged="$root/.Habiter.app.new"; rm -rf "$staged"; mv "$TMP_DIR/extracted/Habiter.app" "$staged"
  if [ -e "$FINAL_PATH" ]; then BACKUP_PATH="$root/.Habiter.app.backup"; rm -rf "$BACKUP_PATH"; mv "$FINAL_PATH" "$BACKUP_PATH"; fi
  mv "$staged" "$FINAL_PATH"
  canonical_app=$(CDPATH='' cd -- "$FINAL_PATH" && pwd -P) || fail HAB-POSIX-053 "cannot canonicalize application bundle" "Check the destination path and links." 50
  mkdir -p "$canonical_app/Contents/Resources"
  write_manifest "$canonical_app" "$canonical_app/Contents/MacOS/habiter" "$(if [ "$SYSTEM" -eq 1 ]; then say system; else say user; fi)"
  [ -z "$BACKUP_PATH" ] || rm -rf "$BACKUP_PATH"; BACKUP_PATH=
}

main() {
  parse_args "$@"
  say "Habiter installer"; say ""
  say "[1/7] Detecting system"; detect_system; say "      $OS${DISTRO:+ · $DISTRO} · $ARCH"
  say "[2/7] Resolving release"; resolve_release; say "      $CHANNEL · $RELEASE_VERSION · $FORMAT"
  destination=${INSTALL_DIR:-user-scoped default}
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[3/7] Dry run"; say "      Would download $FILE_NAME ($SIZE bytes)"; say "[4/7] SHA-256 verification"; say "      Would verify $SHA256"
  else
    PHASE=prepare-temporary-directory
    TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/habiter.XXXXXX") || fail HAB-POSIX-030 "cannot create a temporary directory" "Check TMPDIR permissions and free disk space." 30
    say "[3/7] Downloading"; say "      $FILE_NAME ($SIZE bytes)"
    PHASE=download-artifact
    curl -fL --connect-timeout 15 --max-time 1800 --retry 2 --retry-all-errors --proto '=https' --tlsv1.2 -o "$TMP_DIR/$FILE_NAME" "$DOWNLOAD_URL" || fail HAB-POSIX-031 "artifact download failed" "Check internet, proxy, disk space and the release URL." 30
    actual_size=$(wc -c < "$TMP_DIR/$FILE_NAME" | tr -d ' ')
    [ "$actual_size" = "$SIZE" ] || fail HAB-POSIX-032 "downloaded size does not match release metadata" "Delete the download and retry; do not install it." 30
    PHASE=verify-checksum
    say "[4/7] Verifying SHA-256"; verify_sha256 "$TMP_DIR/$FILE_NAME"; say "      OK  $SHA256"
  fi
  if [ "$OS" = linux ]; then install_linux; else install_macos; fi
  say "[6/7] Desktop integration"
  if [ "$NO_DESKTOP" -eq 0 ]; then say "      enabled"; else say "      skipped"; fi
  say "[7/7] Done"; say "      Version: $RELEASE_VERSION"; say "      Destination: ${FINAL_PATH:-$destination}"; say "      Run: habiter"
}

[ "${HABITER_TEST_MODE:-}" = functions ] || main "$@"
