#!/bin/sh
set -eu

DRY_RUN=0
VERBOSE=0
SYSTEM_ONLY=0
INSTALL_DIR=
CONFIRM_TARGET=
PHASE=startup
UNINSTALL_ID="$(date +%s 2>/dev/null || printf 0)-$$"
MANIFEST_NAME=.habiter-install.json
CANDIDATE_COUNT=0
SELECTED_ROOT=
SELECTED_EXECUTABLE=
SELECTED_SCOPE=
SELECTED_VERSION=unknown
SELECTED_LEGACY=0
SELECTED_INTEGRATIONS=
MISSING_INTEGRATIONS=
STAGED_COUNT=0
STAGED_ORIGINAL_1= STAGED_QUARANTINE_1=
STAGED_ORIGINAL_2= STAGED_QUARANTINE_2=
STAGED_ORIGINAL_3= STAGED_QUARANTINE_3=

say() { printf '%s\n' "$*"; }
debug() { [ "$VERBOSE" -eq 0 ] || printf '      %s\n' "$*"; }
fail() {
  code=$1 message=$2 hint=${3:-} status=${4:-1}
  printf '\nHabiter uninstaller stopped [%s]\n  Phase: %s\n  Error: %s\n' "$code" "$PHASE" "$message" >&2
  [ -z "$hint" ] || printf '  Recovery: %s\n' "$hint" >&2
  printf '  Uninstall ID: %s\n' "$UNINSTALL_ID" >&2
  exit "$status"
}

usage() {
  say 'Habiter desktop uninstaller'
  say 'Usage: uninstall.sh [--dry-run] [--verbose] [--no-color] [--system]'
  say '                    [--install-dir PATH] [--confirm-target CHALLENGE] [--help]'
  say ''
  say 'Download and review this repository-backed script before running it.'
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --verbose) VERBOSE=1; shift ;;
      --no-color) NO_COLOR=1; export NO_COLOR; shift ;;
      --system) SYSTEM_ONLY=1; shift ;;
      --install-dir) [ "$#" -ge 2 ] || fail HAB-UNIX-001 '--install-dir requires an exact path' 'Pass the selected installation root.' 2; INSTALL_DIR=$2; shift 2 ;;
      --confirm-target) [ "$#" -ge 2 ] || fail HAB-UNIX-004 '--confirm-target requires the full typed challenge' 'Pass the exact challenge printed by --dry-run.' 2; CONFIRM_TARGET=$2; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      *) fail HAB-UNIX-002 "unknown option: $1" 'Run with --help to list supported options.' 2 ;;
    esac
  done
  [ -z "$CONFIRM_TARGET" ] || [ -n "$INSTALL_DIR" ] || fail HAB-UNIX-005 '--confirm-target requires --install-dir' 'Automation must name one exact installation.' 2
}

detect_system() {
  PHASE=detect-system
  raw_os=${HABITER_UNINSTALL_OS:-$(uname -s)}
  case "$raw_os" in
    Linux) OS=linux ;;
    Darwin) OS=macos ;;
    *) fail HAB-UNIX-010 "unsupported operating system: $raw_os" 'Use uninstall.ps1 on Windows.' 10 ;;
  esac
  HOME_ROOT=${HABITER_TEST_HOME:-${HOME:-}}
  [ -n "$HOME_ROOT" ] || fail HAB-UNIX-011 'the user home directory is unresolved' 'Restore HOME or use a normal user session.' 10
  case "$OS" in
    linux)
      USER_ROOT=${HABITER_TEST_USER_INSTALL_ROOT:-$HOME_ROOT/.local/opt/habiter}
      SYSTEM_ROOT=${HABITER_TEST_SYSTEM_INSTALL_ROOT:-/opt/habiter}
      USER_WRAPPER=${HABITER_TEST_USER_WRAPPER:-$HOME_ROOT/.local/bin/habiter}
      SYSTEM_WRAPPER=${HABITER_TEST_SYSTEM_WRAPPER:-/usr/local/bin/habiter}
      USER_DESKTOP=${HABITER_TEST_USER_DESKTOP:-$HOME_ROOT/.local/share/applications/dev.habiter.Habiter.desktop}
      SYSTEM_DESKTOP=${HABITER_TEST_SYSTEM_DESKTOP:-/usr/local/share/applications/dev.habiter.Habiter.desktop}
      ;;
    macos)
      USER_ROOT=${HABITER_TEST_USER_INSTALL_ROOT:-$HOME_ROOT/Applications/Habiter.app}
      SYSTEM_ROOT=${HABITER_TEST_SYSTEM_INSTALL_ROOT:-/Applications/Habiter.app}
      USER_WRAPPER= SYSTEM_WRAPPER= USER_DESKTOP= SYSTEM_DESKTOP=
      ;;
  esac
}

absolute_lexical_path() {
  value=$1
  case "$value" in /*) ;; *) return 1 ;; esac
  parent=${value%/*}; base=${value##*/}; [ -n "$parent" ] || parent=/
  canonical_parent=$(CDPATH='' cd -- "$parent" 2>/dev/null && pwd -P) || return 1
  [ "$canonical_parent" = / ] && printf '/%s\n' "$base" || printf '%s/%s\n' "$canonical_parent" "$base"
}

assert_safe_root() {
  requested=$1
  [ -n "$requested" ] || fail HAB-UNIX-020 'empty installation target' 'Pass a non-empty absolute path.' 20
  while [ "$requested" != / ] && [ "${requested%/}" != "$requested" ]; do requested=${requested%/}; done
  case "$requested" in /*) ;; *) fail HAB-UNIX-021 "installation target is not absolute: $requested" 'Use an absolute path.' 20 ;; esac
  [ ! -L "$requested" ] || fail HAB-UNIX-022 "installation root is a symbolic link: $requested" 'Select the real installation root and review the link manually.' 20
  canonical=$(CDPATH='' cd -- "$requested" 2>/dev/null && pwd -P) || fail HAB-UNIX-023 "cannot canonicalize installation root: $requested" 'Check the exact path and permissions.' 20
  lexical=$(absolute_lexical_path "$requested") || fail HAB-UNIX-023 "cannot canonicalize installation root: $requested" 'Check the exact path and permissions.' 20
  [ "$canonical" = "$lexical" ] || fail HAB-UNIX-024 "installation root redirects outside its lexical path: $requested" 'Remove or review the redirect manually.' 20
  case "$canonical" in
    /|/opt|/usr|/usr/local|/Applications|"$HOME_ROOT") fail HAB-UNIX-025 "refusing broad target: $canonical" 'Select the exact Habiter installation root.' 20 ;;
  esac
  printf '%s\n' "$canonical"
}

json_strings() {
  awk '
    BEGIN { in_string=0; escaped=0; value=""; count=0 }
    {
      for (i=1; i<=length($0); i++) {
        c=substr($0,i,1)
        if (!in_string) { if (c=="\"") { in_string=1; value="" } ; continue }
        if (escaped) {
          if (c=="\"" || c=="\\" || c=="/") value=value c
          else exit 3
          escaped=0; continue
        }
        if (c=="\\") { escaped=1; continue }
        if (c=="\"") { print value; count++; in_string=0; continue }
        value=value c
      }
    }
    END { if (in_string || escaped || count==0) exit 4 }
  '
}

manifest_line() {
  key=$1 file=$2
  line=$(grep -E "^[[:space:]]*\"$key\"[[:space:]]*:" "$file" 2>/dev/null || true)
  [ "$(printf '%s\n' "$line" | sed '/^$/d' | wc -l | tr -d ' ')" = 1 ] || fail HAB-UNIX-031 "manifest field is missing or duplicated: $key" 'Do not edit the manifest; reinstall or use the documented legacy path.' 30
  printf '%s\n' "$line"
}

manifest_string() {
  key=$1 file=$2
  strings=$(manifest_line "$key" "$file" | json_strings) || fail HAB-UNIX-032 "manifest string is malformed: $key" 'Reinstall Habiter before uninstalling.' 30
  [ "$(printf '%s\n' "$strings" | wc -l | tr -d ' ')" = 2 ] || fail HAB-UNIX-032 "manifest string is malformed: $key" 'Reinstall Habiter before uninstalling.' 30
  printf '%s\n' "$strings" | sed -n '2p'
}

assert_regular_target() {
  target=$1 label=$2
  [ -e "$target" ] || fail HAB-UNIX-040 "$label is missing: $target" 'The installation is partial; reinstall to repair ownership evidence.' 40
  [ ! -L "$target" ] || fail HAB-UNIX-041 "$label is a symbolic link: $target" 'Refusing to follow it outside the selected installation.' 40
  [ -f "$target" ] || fail HAB-UNIX-042 "$label is not a regular file: $target" 'Review the target manually.' 40
  resolved=$(absolute_lexical_path "$target") || fail HAB-UNIX-041 "$label cannot be canonicalized: $target" 'Refusing an unresolved target.' 40
  [ "$resolved" = "$target" ] || fail HAB-UNIX-041 "$label redirects through a symbolic-link parent: $target" 'Refusing to follow it outside the selected installation.' 40
}

desktop_exec() { sed -n 's/^Exec=//p' "$1" | head -n 1; }

macos_bundle_id() {
  info=$1
  if command -v plutil >/dev/null 2>&1; then plutil -extract CFBundleIdentifier raw -o - "$info" 2>/dev/null || true
  else sed -n 's#.*<key>CFBundleIdentifier</key>[[:space:]]*<string>\([^<]*\)</string>.*#\1#p' "$info" | head -n 1; fi
}

classify_integration() {
  path=$1 executable=$2 scope=$3
  case "$OS:$scope:$path" in
    linux:user:"$USER_WRAPPER"|linux:system:"$SYSTEM_WRAPPER")
      [ -L "$path" ] || { [ ! -e "$path" ] && { printf 'MISSING:%s\n' "$path"; return 0; }; fail HAB-UNIX-043 "wrapper is not an owned symbolic link: $path" 'It will be preserved for manual review.' 40; }
      wrapper_parent=${path%/*}; canonical_wrapper_parent=$(CDPATH='' cd -- "$wrapper_parent" 2>/dev/null && pwd -P) || fail HAB-UNIX-049 "cannot canonicalize wrapper parent: $wrapper_parent" 'It will be preserved for manual review.' 40
      [ "$canonical_wrapper_parent" = "$wrapper_parent" ] || fail HAB-UNIX-049 "wrapper parent redirects to another directory: $wrapper_parent" 'It will be preserved for manual review.' 40
      target=$(CDPATH='' cd -- "${path%/*}" 2>/dev/null && readlink "$path") || fail HAB-UNIX-043 "cannot resolve wrapper: $path" 'It will be preserved for manual review.' 40
      case "$target" in /*) resolved=$target ;; *) resolved=${path%/*}/$target ;; esac
      resolved=$(absolute_lexical_path "$resolved") || fail HAB-UNIX-043 "cannot resolve wrapper: $path" 'It will be preserved for manual review.' 40
      [ "$resolved" = "$executable" ] || fail HAB-UNIX-044 "wrapper points to another target: $path" 'It will be preserved for manual review.' 40
      printf '%s\n' "$path"
      ;;
    linux:user:"$USER_DESKTOP"|linux:system:"$SYSTEM_DESKTOP")
      [ -e "$path" ] || { printf 'MISSING:%s\n' "$path"; return 0; }
      assert_regular_target "$path" 'desktop entry'
      [ "$(desktop_exec "$path")" = "$executable" ] || fail HAB-UNIX-045 "desktop entry points to another target: $path" 'It will be preserved for manual review.' 40
      printf '%s\n' "$path"
      ;;
    *) fail HAB-UNIX-046 "manifest contains a non-allow-listed integration path: $path" 'Reinstall Habiter or review this manifest manually.' 40 ;;
  esac
}

verify_manifest_candidate() {
  root=$1 scope=$2 manifest=$root/$MANIFEST_NAME
  [ ! -L "$manifest" ] || fail HAB-UNIX-030 "ownership manifest is a symbolic link: $manifest" 'Refusing redirected ownership evidence.' 30
  assert_regular_target "$manifest" 'ownership manifest'
  [ "$(wc -l < "$manifest" | tr -d ' ')" = 13 ] || fail HAB-UNIX-030 'ownership manifest shape is invalid' 'Reinstall Habiter before uninstalling.' 30
  [ "$(sed -n '1p' "$manifest")" = '{' ] && [ "$(sed -n '13p' "$manifest")" = '}' ] || fail HAB-UNIX-030 'ownership manifest delimiters are invalid' 'Reinstall Habiter before uninstalling.' 30
  [ "$(manifest_line schemaVersion "$manifest" | tr -cd '0-9')" = 1 ] || fail HAB-UNIX-033 'unsupported ownership manifest schema' 'Install a supported Habiter version before uninstalling.' 30
  [ "$(manifest_string product "$manifest")" = habiter ] || fail HAB-UNIX-034 'ownership manifest product mismatch' 'The selected target is not verified as Habiter.' 30
  [ "$(manifest_string applicationId "$manifest")" = dev.habiter.Habiter ] || fail HAB-UNIX-035 'ownership manifest application identity mismatch' 'The selected target is not verified as Habiter.' 30
  install_id=$(manifest_string installId "$manifest"); [ -n "$install_id" ] || fail HAB-UNIX-032 'ownership manifest install ID is empty' 'Reinstall Habiter before uninstalling.' 30
  [ "$(manifest_string scope "$manifest")" = "$scope" ] || fail HAB-UNIX-036 'ownership manifest scope mismatch' 'Select the matching user or system installation.' 30
  [ "$(manifest_string canonicalInstallRoot "$manifest")" = "$root" ] || fail HAB-UNIX-037 'ownership manifest root mismatch' 'Refusing a manifest that points outside the selected installation.' 30
  version=$(manifest_string version "$manifest")
  printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail HAB-UNIX-038 'ownership manifest version is malformed' 'Reinstall Habiter before uninstalling.' 30
  executable=$(manifest_string executable "$manifest")
  if [ "$OS" = linux ]; then expected=$root/Habiter.AppImage; else expected=$root/Contents/MacOS/habiter; fi
  [ "$executable" = "$expected" ] || fail HAB-UNIX-039 'ownership manifest executable escapes the selected installation' 'Refusing the target.' 30
  assert_regular_target "$executable" 'Habiter executable'
  if [ "$OS" = macos ]; then
    info=$root/Contents/Info.plist; assert_regular_target "$info" 'macOS bundle metadata'
    [ "$(macos_bundle_id "$info")" = dev.habiter.Habiter ] || fail HAB-UNIX-047 'macOS bundle identifier mismatch' 'The selected bundle is not verified as Habiter.' 40
  fi
  integration_strings=$(manifest_line integrationPaths "$manifest" | json_strings) || fail HAB-UNIX-048 'manifest integration list is malformed' 'Reinstall Habiter before uninstalling.' 40
  [ "$(printf '%s\n' "$integration_strings" | sed -n '1p')" = integrationPaths ] || fail HAB-UNIX-048 'manifest integration list is malformed' 'Reinstall Habiter before uninstalling.' 40
  printf '%s\n' "$(manifest_line pathEntry "$manifest")" | grep -Eq '"pathEntry"[[:space:]]*:[[:space:]]*null,' || fail HAB-UNIX-048 'POSIX manifest PATH ownership must be null' 'Reinstall Habiter before uninstalling.' 40
  printf '%s\n' "$(manifest_line pathEntryAddedByInstaller "$manifest")" | grep -Eq '"pathEntryAddedByInstaller"[[:space:]]*:[[:space:]]*false$' || fail HAB-UNIX-048 'POSIX manifest PATH ownership must be false' 'Reinstall Habiter before uninstalling.' 40
  integrations=
  old_ifs=$IFS; IFS='
'
  for path in $(printf '%s\n' "$integration_strings" | sed '1d'); do
    [ -n "$path" ] || continue
    owned=$(classify_integration "$path" "$executable" "$scope")
    case "$owned" in
      MISSING:*) missing=${owned#MISSING:}; MISSING_INTEGRATIONS="${MISSING_INTEGRATIONS}${MISSING_INTEGRATIONS:+
}$missing" ;;
      '') ;;
      *) integrations="${integrations}${integrations:+
}$owned" ;;
    esac
  done
  IFS=$old_ifs
  SELECTED_EXECUTABLE=$executable SELECTED_VERSION=$version SELECTED_INTEGRATIONS=$integrations SELECTED_LEGACY=0
}

verify_legacy_candidate() {
  root=$1 scope=$2
  if [ "$OS" = linux ]; then
    executable=$root/Habiter.AppImage; assert_regular_target "$executable" 'legacy Habiter executable'
    if [ "$scope" = user ]; then wrapper=$USER_WRAPPER desktop=$USER_DESKTOP; else wrapper=$SYSTEM_WRAPPER desktop=$SYSTEM_DESKTOP; fi
    [ -L "$wrapper" ] || fail HAB-UNIX-050 'legacy installation lacks a matching wrapper' 'Use --install-dir only after repairing ownership evidence.' 50
    integrations=$(classify_integration "$wrapper" "$executable" "$scope")
    desktop_owned=$(classify_integration "$desktop" "$executable" "$scope")
    case "$desktop_owned" in MISSING:*|'') fail HAB-UNIX-051 'legacy installation lacks a matching desktop entry' 'Reinstall Habiter to create a manifest.' 50 ;; esac
    integrations="$integrations
$desktop_owned"
  else
    executable=$root/Contents/MacOS/habiter; assert_regular_target "$executable" 'legacy Habiter executable'
    info=$root/Contents/Info.plist; assert_regular_target "$info" 'legacy macOS bundle metadata'
    [ "$(macos_bundle_id "$info")" = dev.habiter.Habiter ] || fail HAB-UNIX-052 'legacy macOS bundle identifier mismatch' 'The selected bundle is not verified as Habiter.' 50
    integrations=
  fi
  SELECTED_EXECUTABLE=$executable SELECTED_VERSION=legacy SELECTED_INTEGRATIONS=$integrations SELECTED_LEGACY=1
}

inspect_candidate() {
  requested=$1 scope=$2
  [ -e "$requested" ] || return 0
  root=$(assert_safe_root "$requested")
  CANDIDATE_COUNT=$((CANDIDATE_COUNT + 1))
  [ "$CANDIDATE_COUNT" -eq 1 ] || fail HAB-UNIX-061 "multiple Habiter installations were found: $SELECTED_ROOT and $root" 'Run again with --install-dir and one exact candidate.' 60
  SELECTED_ROOT=$root SELECTED_SCOPE=$scope
  if [ -e "$root/$MANIFEST_NAME" ] || [ -L "$root/$MANIFEST_NAME" ]; then verify_manifest_candidate "$root" "$scope"; else verify_legacy_candidate "$root" "$scope"; fi
  say "      Candidate: $root"
  say "      Scope: $scope"
  say "      Version: $SELECTED_VERSION"
  if [ "$SELECTED_LEGACY" -eq 1 ]; then say '      Evidence: conservative legacy identity + integration checks'; else say '      Evidence: ownership manifest + platform identity checks'; fi
}

discover() {
  PHASE=detect-installations
  if [ -n "$INSTALL_DIR" ]; then
    if [ "$SYSTEM_ONLY" -eq 1 ] || [ "$INSTALL_DIR" = "$SYSTEM_ROOT" ]; then scope=system; else scope=user; fi
    inspect_candidate "$INSTALL_DIR" "$scope"
  elif [ "$SYSTEM_ONLY" -eq 1 ]; then inspect_candidate "$SYSTEM_ROOT" system
  else inspect_candidate "$USER_ROOT" user; inspect_candidate "$SYSTEM_ROOT" system
  fi
  [ "$CANDIDATE_COUNT" -gt 0 ] || fail HAB-UNIX-060 'no verified Habiter installation was found' 'Use --install-dir with one exact custom installation root.' 60
}

print_plan() {
  PHASE=removal-plan
  say '[4/7] Removal plan'
  say "      Application: $SELECTED_ROOT"
  if [ -n "$SELECTED_INTEGRATIONS" ]; then
    old_ifs=$IFS; IFS='
'
    for path in $SELECTED_INTEGRATIONS; do say "      Integration: $path"; done
    IFS=$old_ifs
  else say '      Integration: none'; fi
  if [ -n "$MISSING_INTEGRATIONS" ]; then
    old_ifs=$IFS; IFS='
'
    for path in $MISSING_INTEGRATIONS; do say "      Missing optional integration: $path"; done
    IFS=$old_ifs
  fi
  say '      Application data: preserved'
  say '      Backups, exports, credentials, and OS backups: preserved'
  [ "$SELECTED_LEGACY" -eq 0 ] || say '      Warning: legacy installation without an ownership manifest'
  say "      Confirmation challenge: UNINSTALL HABITER $SELECTED_ROOT"
}

check_running() {
  PHASE=check-running-processes
  if [ "${HABITER_TEST_RUNNING:-0}" = 1 ]; then running=fixture
  else
    HABITER_PROCESS_TARGET=$SELECTED_EXECUTABLE; export HABITER_PROCESS_TARGET
    running=$(ps -ax -o pid= -o command= 2>/dev/null | awk 'index($0,ENVIRON["HABITER_PROCESS_TARGET"]) { print $1 }' || true)
    unset HABITER_PROCESS_TARGET
  fi
  [ -z "$running" ] || fail HAB-UNIX-071 'Habiter is still running' 'Close Habiter normally, then rerun the same reviewed plan.' 71
  say '      Not running'
}

confirm_removal() {
  PHASE=confirm-removal
  challenge="UNINSTALL HABITER $SELECTED_ROOT"
  if [ -n "$CONFIRM_TARGET" ]; then
    [ "$CONFIRM_TARGET" = "$challenge" ] || fail HAB-UNIX-072 'automation challenge does not match the canonical target' 'Copy the exact challenge from --dry-run.' 72
    say '      Exact non-interactive target and challenge accepted'
    return
  fi
  if [ "${HABITER_TEST_NO_TTY:-0}" = 1 ]; then
    [ "${HABITER_UNINSTALL_TEST:-0}" = 1 ] || fail HAB-UNIX-073 'test terminal override is disabled' 'Use an interactive terminal.' 73
    fail HAB-UNIX-073 'an interactive terminal is required' 'For automation, pass both --install-dir and --confirm-target.' 73
  elif [ -n "${HABITER_TEST_CONFIRM_FILE:-}" ]; then
    [ "${HABITER_UNINSTALL_TEST:-0}" = 1 ] || fail HAB-UNIX-073 'test confirmation input is disabled' 'Use an interactive terminal.' 73
    exec 3< "$HABITER_TEST_CONFIRM_FILE" || fail HAB-UNIX-073 'cannot open confirmation input' 'No files were changed.' 73
  else
    exec 3< /dev/tty 2>/dev/null || fail HAB-UNIX-073 'an interactive terminal is required' 'For automation, pass both --install-dir and --confirm-target.' 73
  fi
  printf 'Continue with this exact removal plan? [y/N] ' >&2
  IFS= read -r answer <&3 || fail HAB-UNIX-074 'confirmation input closed before approval' 'No files were changed.' 74
  case "$answer" in y|Y) ;; *) fail HAB-UNIX-075 'uninstall cancelled at the first confirmation' 'No files were changed.' 75 ;; esac
  printf 'Type %s: ' "$challenge" >&2
  IFS= read -r typed <&3 || fail HAB-UNIX-076 'confirmation input closed before the typed challenge' 'No files were changed.' 76
  [ "$typed" = "$challenge" ] || fail HAB-UNIX-077 'typed challenge did not match the canonical target' 'No files were changed.' 77
  exec 3<&-
}

remember_stage() {
  original=$1 quarantine=$2
  STAGED_COUNT=$((STAGED_COUNT + 1))
  case "$STAGED_COUNT" in
    1) STAGED_ORIGINAL_1=$original STAGED_QUARANTINE_1=$quarantine ;;
    2) STAGED_ORIGINAL_2=$original STAGED_QUARANTINE_2=$quarantine ;;
    3) STAGED_ORIGINAL_3=$original STAGED_QUARANTINE_3=$quarantine ;;
    *) fail HAB-UNIX-080 'removal plan exceeded the bounded staging ledger' 'No additional target was moved.' 80 ;;
  esac
}

stage_path() {
  original=$1
  quarantine=$original.habiter-uninstall-$UNINSTALL_ID
  [ ! -e "$quarantine" ] && [ ! -L "$quarantine" ] || fail HAB-UNIX-081 "quarantine already exists: $quarantine" 'Review the previous recovery state; nothing was overwritten.' 81
  next=$((STAGED_COUNT + 1))
  [ "${HABITER_TEST_FAIL_STAGE_AT:-0}" != "$next" ] || fail HAB-UNIX-082 "injected staging failure before: $original" 'The staged targets will be restored.' 82
  mv -- "$original" "$quarantine" || fail HAB-UNIX-083 "cannot move target to quarantine: $original" 'Check permissions; already staged targets will be restored.' 83
  remember_stage "$original" "$quarantine"
}

restore_one() {
  original=$1 quarantine=$2
  [ -n "$quarantine" ] || return 0
  if [ -e "$quarantine" ] || [ -L "$quarantine" ]; then
    if [ -e "$original" ] || [ -L "$original" ]; then printf '  Recovery warning: preserved quarantine because the original path reappeared: %s\n' "$quarantine" >&2
    elif mv -- "$quarantine" "$original"; then printf '  Restored: %s\n' "$original" >&2
    else printf '  Recovery warning: left in quarantine: %s\n' "$quarantine" >&2; fi
  else printf '  Already finalized: %s\n' "$original" >&2; fi
}

restore_staged() {
  [ "$STAGED_COUNT" -gt 0 ] || return 0
  printf 'Recovery summary:\n' >&2
  [ "$STAGED_COUNT" -lt 3 ] || restore_one "$STAGED_ORIGINAL_3" "$STAGED_QUARANTINE_3"
  [ "$STAGED_COUNT" -lt 2 ] || restore_one "$STAGED_ORIGINAL_2" "$STAGED_QUARANTINE_2"
  restore_one "$STAGED_ORIGINAL_1" "$STAGED_QUARANTINE_1"
}

cleanup_on_exit() {
  status=$?
  trap - EXIT HUP INT TERM
  [ "$status" -eq 0 ] || restore_staged
  exit "$status"
}

finalize_one() {
  quarantine=$1 original=$2
  [ "${HABITER_TEST_FAIL_FINALIZE_AT:-0}" != "$original" ] || fail HAB-UNIX-084 "injected finalization failure: $original" 'Recoverable quarantine paths are listed below.' 84
  rm -rf -- "$quarantine" || fail HAB-UNIX-085 "cannot finalize quarantined target: $quarantine" 'Recoverable quarantine paths are listed below.' 85
}

remove_selected() {
  PHASE=stage-removal
  old_ifs=$IFS; IFS='
'
  for path in $SELECTED_INTEGRATIONS; do [ -z "$path" ] || stage_path "$path"; done
  IFS=$old_ifs
  stage_path "$SELECTED_ROOT"
  PHASE=finalize-removal
  [ "$STAGED_COUNT" -lt 1 ] || finalize_one "$STAGED_QUARANTINE_1" "$STAGED_ORIGINAL_1"
  [ "$STAGED_COUNT" -lt 2 ] || finalize_one "$STAGED_QUARANTINE_2" "$STAGED_ORIGINAL_2"
  [ "$STAGED_COUNT" -lt 3 ] || finalize_one "$STAGED_QUARANTINE_3" "$STAGED_ORIGINAL_3"
  STAGED_COUNT=0
}

main() {
  parse_args "$@"
  say 'Habiter uninstaller'; say ''
  say '[1/7] Detecting installations'; detect_system; discover
  say '[2/7] Verifying ownership'; say "      Verified: $SELECTED_ROOT"
  say '[3/7] Checking running processes'; check_running
  print_plan
  if [ "$DRY_RUN" -eq 1 ]; then say '[5/7] Dry run'; say '      No files or settings were changed.'; say '[6/7] Removal skipped'; say '[7/7] Done'; exit 0; fi
  say '[5/7] Confirming removal'; confirm_removal
  say '[6/7] Removing and verifying'; remove_selected
  say '[7/7] Done'
  say "      Removed application: $SELECTED_ROOT"
  say '      Application data, backups, exports, credentials, and OS backups: preserved'
}

if [ "${HABITER_TEST_MODE:-}" != functions ]; then
  trap cleanup_on_exit EXIT
  trap 'exit 130' HUP INT TERM
  main "$@"
fi
