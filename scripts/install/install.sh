#!/bin/sh
set -eu

PROGRAM=habiter-installer
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

say() { printf '%s\n' "$*"; }
die() { printf '%s: %s\n' "$PROGRAM" "$*" >&2; exit 1; }
debug() { [ "$VERBOSE" -eq 0 ] || printf '      %s\n' "$*"; }
cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ -n "$BACKUP_PATH" ] && [ -e "$BACKUP_PATH" ] && [ -n "$FINAL_PATH" ]; then
    rm -rf -- "$FINAL_PATH"
    mv -- "$BACKUP_PATH" "$FINAL_PATH"
  fi
  [ -z "$TMP_DIR" ] || rm -rf -- "$TMP_DIR"
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
      --channel) [ "$#" -ge 2 ] || die "--channel requires a value"; CHANNEL=$2; shift 2 ;;
      --version) [ "$#" -ge 2 ] || die "--version requires a value"; VERSION=$2; shift 2 ;;
      --install-dir) [ "$#" -ge 2 ] || die "--install-dir requires a value"; INSTALL_DIR=$2; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --verbose) VERBOSE=1; shift ;;
      --no-color) NO_COLOR=1; export NO_COLOR; shift ;;
      --system) SYSTEM=1; shift ;;
      --no-desktop-integration) NO_DESKTOP=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  case "$CHANNEL" in stable|beta) ;; *) die "channel must be stable or beta" ;; esac
  [ -z "$VERSION" ] || printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || die "version must use X.Y.Z"
}

normalize_arch() {
  case "$1" in x86_64|amd64) say x64 ;; arm64|aarch64) say arm64 ;; *) return 1 ;; esac
}

normalize_distro() {
  id=$1; like=$2
  case "$id" in
    ubuntu|linuxmint|pop|debian) say "$( [ "$id" = debian ] && say debian || say ubuntu )"; return ;;
    fedora|rhel|centos) say fedora; return ;;
    arch|manjaro|endeavouros) say arch; return ;;
    opensuse*|sles) say opensuse; return ;;
  esac
  case " $like " in *" debian "*) say debian ;; *" fedora "*|*" rhel "*) say fedora ;; *" arch "*) say arch ;; *" suse "*) say opensuse ;; *) say generic ;; esac
}

detect_system() {
  raw_os=${HABITER_UNAME_S:-$(uname -s)}
  raw_arch=${HABITER_UNAME_M:-$(uname -m)}
  ARCH=$(normalize_arch "$raw_arch") || die "unsupported architecture: $raw_arch"
  DISTRO=
  case "$raw_os" in
    Linux)
      OS=linux
      release_file=${HABITER_OS_RELEASE_FILE:-/etc/os-release}
      id=$(sed -n 's/^ID=//p' "$release_file" | head -n 1 | tr -d '"')
      like=$(sed -n 's/^ID_LIKE=//p' "$release_file" | head -n 1 | tr -d '"')
      DISTRO=$(normalize_distro "$id" "$like")
      ;;
    Darwin) OS=macos ;;
    *) die "unsupported operating system: $raw_os" ;;
  esac
  [ "$OS" != macos ] || ARCH=$( [ "$ARCH" = arm64 ] && say arm64 || say x64 )
}

json_string() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
json_number() { printf '%s' "$1" | sed -n "s/.*\"$2\":\([0-9][0-9]*\).*/\1/p"; }

resolve_release() {
  query="channel=$CHANNEL"
  [ -z "$VERSION" ] || query="$query&version=$VERSION"
  [ -z "$DISTRO" ] || query="$query&distro=$DISTRO"
  endpoint="$API_BASE/api/v1/install/$OS/$ARCH?$query"
  debug "Resolver: $endpoint"
  RESPONSE=$(curl -fsSL --proto '=https' --tlsv1.2 "$endpoint") || die "release resolver failed"
  RELEASE_VERSION=$(json_string "$RESPONSE" version)
  FORMAT=$(json_string "$RESPONSE" format)
  FILE_NAME=$(json_string "$RESPONSE" fileName)
  DOWNLOAD_URL=$(json_string "$RESPONSE" url)
  SHA256=$(json_string "$RESPONSE" sha256)
  SIZE=$(json_number "$RESPONSE" size)
  printf '%s' "$RELEASE_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || die "resolver returned an invalid version"
  printf '%s' "$FILE_NAME" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]+$' || die "resolver returned an invalid file name"
  printf '%s' "$SHA256" | grep -Eq '^[a-f0-9]{64}$' || die "resolver returned an invalid checksum"
  printf '%s' "$SIZE" | grep -Eq '^[1-9][0-9]*$' || die "resolver returned an invalid size"
  case "$DOWNLOAD_URL" in https://*) ;; *) die "resolver returned a non-HTTPS URL" ;; esac
  case "$OS:$FORMAT" in linux:appimage|macos:zip) ;; *) die "unsupported installer artifact: $FORMAT" ;; esac
}

verify_sha256() {
  file=$1
  if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$file" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then actual=$(shasum -a 256 "$file" | awk '{print $1}')
  else die "sha256sum or shasum is required"; fi
  [ "$actual" = "$SHA256" ] || die "SHA-256 mismatch"
}

install_linux() {
  root=${INSTALL_DIR:-${HOME}/.local/opt/habiter}
  FINAL_PATH="$root/Habiter.AppImage"
  bin_dir=${HOME}/.local/bin
  desktop_dir=${HOME}/.local/share/applications
  [ "$SYSTEM" -eq 0 ] || { root=/opt/habiter; FINAL_PATH=$root/Habiter.AppImage; bin_dir=/usr/local/bin; desktop_dir=/usr/local/share/applications; }
  say "[5/7] Installing application"; say "      $FINAL_PATH"
  if [ "$DRY_RUN" -eq 1 ]; then return; fi
  mkdir -p "$root" "$bin_dir" "$desktop_dir"
  staged="$root/.Habiter.AppImage.new"; cp "$TMP_DIR/$FILE_NAME" "$staged"; chmod 755 "$staged"
  if [ -e "$FINAL_PATH" ]; then BACKUP_PATH="$root/.Habiter.AppImage.backup"; rm -f "$BACKUP_PATH"; mv "$FINAL_PATH" "$BACKUP_PATH"; fi
  mv "$staged" "$FINAL_PATH"
  if [ "$NO_DESKTOP" -eq 0 ]; then
    ln -sfn "$FINAL_PATH" "$bin_dir/habiter"
    printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Habiter' "Exec=$FINAL_PATH" 'Icon=dev.habiter.Habiter' 'Terminal=false' 'Categories=Utility;' > "$desktop_dir/dev.habiter.Habiter.desktop"
  fi
  [ -z "$BACKUP_PATH" ] || rm -f "$BACKUP_PATH"; BACKUP_PATH=
}

install_macos() {
  root=${INSTALL_DIR:-${HOME}/Applications}; [ "$SYSTEM" -eq 0 ] || root=/Applications
  FINAL_PATH="$root/Habiter.app"
  say "[5/7] Installing application"; say "      $FINAL_PATH"
  [ "$DRY_RUN" -eq 1 ] && return
  mkdir -p "$TMP_DIR/extracted" "$root"
  ditto -x -k "$TMP_DIR/$FILE_NAME" "$TMP_DIR/extracted"
  [ -d "$TMP_DIR/extracted/Habiter.app/Contents/MacOS" ] || die "archive does not contain a valid Habiter.app"
  staged="$root/.Habiter.app.new"; rm -rf "$staged"; mv "$TMP_DIR/extracted/Habiter.app" "$staged"
  if [ -e "$FINAL_PATH" ]; then BACKUP_PATH="$root/.Habiter.app.backup"; rm -rf "$BACKUP_PATH"; mv "$FINAL_PATH" "$BACKUP_PATH"; fi
  mv "$staged" "$FINAL_PATH"; [ -z "$BACKUP_PATH" ] || rm -rf "$BACKUP_PATH"; BACKUP_PATH=
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
    TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/habiter.XXXXXX")
    say "[3/7] Downloading"; say "      $FILE_NAME ($SIZE bytes)"
    curl -fL --proto '=https' --tlsv1.2 -o "$TMP_DIR/$FILE_NAME" "$DOWNLOAD_URL"
    say "[4/7] Verifying SHA-256"; verify_sha256 "$TMP_DIR/$FILE_NAME"; say "      OK  $SHA256"
  fi
  [ "$OS" = linux ] && install_linux || install_macos
  say "[6/7] Desktop integration"; [ "$NO_DESKTOP" -eq 0 ] && say "      enabled" || say "      skipped"
  say "[7/7] Done"; say "      Version: $RELEASE_VERSION"; say "      Destination: ${FINAL_PATH:-$destination}"; say "      Run: habiter"
}

[ "${HABITER_TEST_MODE:-}" = functions ] || main "$@"
