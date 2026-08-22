#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd)
UNINSTALLER=$ROOT/scripts/install/uninstall.sh
TEMP_ROOT=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$TEMP_ROOT/habiter-uninstall-lifecycle-$$
HOME_FIXTURE=$TEST_ROOT/home
SYSTEM_FIXTURE=$TEST_ROOT/system/habiter
OUTPUT=$TEST_ROOT/output
USER_ROOT=$HOME_FIXTURE/.local/opt/habiter
WRAPPER=$HOME_FIXTURE/.local/bin/habiter
DESKTOP=$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$USER_ROOT" "${WRAPPER%/*}" "${DESKTOP%/*}" "$TEST_ROOT/system-bin" "$TEST_ROOT/system-share"
printf '#!/bin/sh\n' > "$USER_ROOT/Habiter.AppImage"; chmod 755 "$USER_ROOT/Habiter.AppImage"
ln -s "$USER_ROOT/Habiter.AppImage" "$WRAPPER"
printf '%s\n' '[Desktop Entry]' "Exec=$USER_ROOT/Habiter.AppImage" > "$DESKTOP"
printf '%s\n' \
  '{' \
  '  "schemaVersion": 1,' \
  '  "product": "habiter",' \
  '  "applicationId": "dev.habiter.Habiter",' \
  '  "installId": "lifecycle-fixture",' \
  '  "version": "1.7.1",' \
  '  "scope": "user",' \
  "  \"canonicalInstallRoot\": \"$USER_ROOT\"," \
  "  \"executable\": \"$USER_ROOT/Habiter.AppImage\"," \
  "  \"integrationPaths\": [\"$WRAPPER\",\"$DESKTOP\"]," \
  '  "pathEntry": null,' \
  '  "pathEntryAddedByInstaller": false' \
  '}' > "$USER_ROOT/.habiter-install.json"

export HABITER_TEST_HOME="$HOME_FIXTURE"
export HABITER_TEST_SYSTEM_INSTALL_ROOT="$SYSTEM_FIXTURE"
export HABITER_TEST_SYSTEM_WRAPPER="$TEST_ROOT/system-bin/habiter"
export HABITER_TEST_SYSTEM_DESKTOP="$TEST_ROOT/system-share/dev.habiter.Habiter.desktop"
export HABITER_UNINSTALL_OS=Linux
export HABITER_UNINSTALL_TEST=1

expect_failure() {
  expected=$1; shift
  if "$@" >"$OUTPUT" 2>&1; then echo "expected failure $expected" >&2; exit 1; fi
  grep -q "$expected" "$OUTPUT" || { cat "$OUTPUT" >&2; echo "missing failure $expected" >&2; exit 1; }
}

export HABITER_TEST_RUNNING=1
expect_failure HAB-UNIX-071 "$UNINSTALLER" --dry-run --install-dir "$USER_ROOT"
unset HABITER_TEST_RUNNING

CHALLENGE="UNINSTALL HABITER $USER_ROOT"
export HABITER_TEST_NO_TTY=1
expect_failure HAB-UNIX-073 "$UNINSTALLER" --install-dir "$USER_ROOT"
unset HABITER_TEST_NO_TTY
expect_failure HAB-UNIX-072 "$UNINSTALLER" --install-dir "$USER_ROOT" --confirm-target 'UNINSTALL HABITER /wrong'

printf 'n\n' > "$TEST_ROOT/confirm"
export HABITER_TEST_CONFIRM_FILE="$TEST_ROOT/confirm"
expect_failure HAB-UNIX-075 "$UNINSTALLER" --install-dir "$USER_ROOT"
printf 'y\nwrong\n' > "$TEST_ROOT/confirm"
expect_failure HAB-UNIX-077 "$UNINSTALLER" --install-dir "$USER_ROOT"
printf 'y\n' > "$TEST_ROOT/confirm"
expect_failure HAB-UNIX-076 "$UNINSTALLER" --install-dir "$USER_ROOT"
unset HABITER_TEST_CONFIRM_FILE

export HABITER_TEST_FAIL_STAGE_AT=2
expect_failure HAB-UNIX-082 "$UNINSTALLER" --install-dir "$USER_ROOT" --confirm-target "$CHALLENGE"
unset HABITER_TEST_FAIL_STAGE_AT
[ -d "$USER_ROOT" ] && [ -L "$WRAPPER" ] && [ -f "$DESKTOP" ]

export HABITER_TEST_FAIL_FINALIZE_AT="$WRAPPER"
expect_failure HAB-UNIX-084 "$UNINSTALLER" --install-dir "$USER_ROOT" --confirm-target "$CHALLENGE"
unset HABITER_TEST_FAIL_FINALIZE_AT
[ -d "$USER_ROOT" ] && [ -L "$WRAPPER" ] && [ -f "$DESKTOP" ]

DATA_ROOT=$HOME_FIXTURE/.local/share/dev.habiter.Habiter
mkdir -p "$DATA_ROOT"; printf 'preserve me\n' > "$DATA_ROOT/preferences"
printf 'y\n%s\n' "$CHALLENGE" > "$TEST_ROOT/confirm"
HABITER_TEST_CONFIRM_FILE=$TEST_ROOT/confirm "$UNINSTALLER" --install-dir "$USER_ROOT" >"$OUTPUT"
[ ! -e "$USER_ROOT" ] && [ ! -L "$WRAPPER" ] && [ -f "$DATA_ROOT/preferences" ]
grep -q 'Application data, backups, exports, credentials, and OS backups: preserved' "$OUTPUT"
expect_failure HAB-UNIX-060 "$UNINSTALLER" --dry-run --install-dir "$USER_ROOT"

echo 'uninstall.sh lifecycle tests passed'
