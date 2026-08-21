#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd)
UNINSTALLER=$ROOT/scripts/install/uninstall.sh
TEST_ROOT=${TMPDIR:-/tmp}/habiter-uninstall-test-$$
HOME_FIXTURE=$TEST_ROOT/home
SYSTEM_FIXTURE=$TEST_ROOT/system/habiter
SYSTEM_WRAPPER=$TEST_ROOT/system-bin/habiter
SYSTEM_DESKTOP=$TEST_ROOT/system-share/dev.habiter.Habiter.desktop
OUTPUT=$TEST_ROOT/output

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$HOME_FIXTURE" "$TEST_ROOT/system-bin" "$TEST_ROOT/system-share"

export HABITER_TEST_HOME=$HOME_FIXTURE
export HABITER_TEST_SYSTEM_INSTALL_ROOT=$SYSTEM_FIXTURE
export HABITER_TEST_SYSTEM_WRAPPER=$SYSTEM_WRAPPER
export HABITER_TEST_SYSTEM_DESKTOP=$SYSTEM_DESKTOP
export HABITER_UNINSTALL_OS=Linux

write_manifest() {
  root=$1 executable=$2 scope=$3 version=$4 integrations=${5:-} manifest=${6:-$1/.habiter-install.json}
  if [ -n "$integrations" ]; then integration_json=$integrations; else integration_json=; fi
  printf '%s\n' \
    '{' \
    '  "schemaVersion": 1,' \
    '  "product": "habiter",' \
    '  "applicationId": "dev.habiter.Habiter",' \
    '  "installId": "fixture-install",' \
    "  \"version\": \"$version\"," \
    "  \"scope\": \"$scope\"," \
    "  \"canonicalInstallRoot\": \"$root\"," \
    "  \"executable\": \"$executable\"," \
    "  \"integrationPaths\": [$integration_json]," \
    '  "pathEntry": null,' \
    '  "pathEntryAddedByInstaller": false' \
    '}' > "$manifest"
}

make_linux_install() {
  root=$1 scope=$2 integration=${3:-yes}
  executable=$root/Habiter.AppImage
  mkdir -p "$root"
  printf '#!/bin/sh\n' > "$executable"
  chmod 755 "$executable"
  integrations=
  if [ "$integration" = yes ]; then
    if [ "$scope" = user ]; then
      wrapper=$HOME_FIXTURE/.local/bin/habiter
      desktop=$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop
    else wrapper=$SYSTEM_WRAPPER; desktop=$SYSTEM_DESKTOP; fi
    mkdir -p "${wrapper%/*}" "${desktop%/*}"
    ln -s "$executable" "$wrapper"
    printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Habiter' "Exec=$executable" > "$desktop"
    integrations="\"$wrapper\",\"$desktop\""
  fi
  write_manifest "$root" "$executable" "$scope" 1.7.1 "$integrations"
}

reset_fixtures() {
  rm -rf "$HOME_FIXTURE" "$TEST_ROOT/system" "$TEST_ROOT/system-bin" "$TEST_ROOT/system-share"
  mkdir -p "$HOME_FIXTURE" "$TEST_ROOT/system-bin" "$TEST_ROOT/system-share"
}

expect_failure() {
  expected=$1; shift
  if "$@" >"$OUTPUT" 2>&1; then echo "expected failure $expected" >&2; exit 1; fi
  grep -q "$expected" "$OUTPUT" || { cat "$OUTPUT" >&2; echo "missing failure $expected" >&2; exit 1; }
}

"$UNINSTALLER" --help >/dev/null

user_root=$HOME_FIXTURE/.local/opt/habiter
make_linux_install "$user_root" user
"$UNINSTALLER" --dry-run >"$OUTPUT"
grep -q "Application: $user_root" "$OUTPUT"
grep -q 'Application data: preserved' "$OUTPUT"
grep -q 'No files or settings were changed' "$OUTPUT"
[ -f "$user_root/Habiter.AppImage" ] && [ -L "$HOME_FIXTURE/.local/bin/habiter" ]
rm "$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop"
"$UNINSTALLER" --dry-run >"$OUTPUT"
grep -q 'Missing optional integration:' "$OUTPUT"

reset_fixtures
custom_root=$TEST_ROOT/custom/Habiter
make_linux_install "$custom_root" user no
"$UNINSTALLER" --dry-run --install-dir "$custom_root" >"$OUTPUT"
grep -q "Candidate: $custom_root" "$OUTPUT"
"$UNINSTALLER" --dry-run --install-dir "$custom_root/" >"$OUTPUT"
grep -q "Candidate: $custom_root" "$OUTPUT"

reset_fixtures
make_linux_install "$SYSTEM_FIXTURE" system no
"$UNINSTALLER" --dry-run --system >"$OUTPUT"
grep -q 'Scope: system' "$OUTPUT"

reset_fixtures
expect_failure HAB-UNIX-060 "$UNINSTALLER" --dry-run

reset_fixtures
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user no
make_linux_install "$SYSTEM_FIXTURE" system no
expect_failure HAB-UNIX-061 "$UNINSTALLER" --dry-run

reset_fixtures
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user no
sed 's/"schemaVersion": 1/"schemaVersion": 99/' "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json" > "$TEST_ROOT/tampered"
mv "$TEST_ROOT/tampered" "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json"
expect_failure HAB-UNIX-033 "$UNINSTALLER" --dry-run

reset_fixtures
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user no
sed 's/"version": "1.7.1"/"version": "1..7"/' "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json" > "$TEST_ROOT/tampered"
mv "$TEST_ROOT/tampered" "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json"
expect_failure HAB-UNIX-038 "$UNINSTALLER" --dry-run

reset_fixtures
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user no
sed 's#"executable": ".*"#"executable": "/tmp/unowned"#' "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json" > "$TEST_ROOT/tampered"
mv "$TEST_ROOT/tampered" "$HOME_FIXTURE/.local/opt/habiter/.habiter-install.json"
expect_failure HAB-UNIX-039 "$UNINSTALLER" --dry-run

reset_fixtures
real_root=$TEST_ROOT/real-habiter
make_linux_install "$real_root" user no
mkdir -p "$HOME_FIXTURE/.local/opt"
ln -s "$real_root" "$HOME_FIXTURE/.local/opt/habiter"
expect_failure HAB-UNIX-022 "$UNINSTALLER" --dry-run

reset_fixtures
legacy_root=$HOME_FIXTURE/.local/opt/habiter
mkdir -p "$legacy_root" "$HOME_FIXTURE/.local/bin" "$HOME_FIXTURE/.local/share/applications"
printf '#!/bin/sh\n' > "$legacy_root/Habiter.AppImage"; chmod 755 "$legacy_root/Habiter.AppImage"
ln -s "$legacy_root/Habiter.AppImage" "$HOME_FIXTURE/.local/bin/habiter"
printf '%s\n' '[Desktop Entry]' "Exec=$legacy_root/Habiter.AppImage" > "$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop"
"$UNINSTALLER" --dry-run >"$OUTPUT"
grep -q 'conservative legacy identity' "$OUTPUT"
grep -q 'Warning: legacy installation' "$OUTPUT"

reset_fixtures
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user
rm "$HOME_FIXTURE/.local/bin/habiter"
ln -s "$TEST_ROOT/not-habiter" "$HOME_FIXTURE/.local/bin/habiter"
expect_failure HAB-UNIX-044 "$UNINSTALLER" --dry-run

reset_fixtures
redirect_root=$TEST_ROOT/redirected-bin
make_linux_install "$HOME_FIXTURE/.local/opt/habiter" user no
mkdir -p "$HOME_FIXTURE/.local" "$redirect_root" "$HOME_FIXTURE/.local/share/applications"
ln -s "$redirect_root" "$HOME_FIXTURE/.local/bin"
ln -s "$HOME_FIXTURE/.local/opt/habiter/Habiter.AppImage" "$redirect_root/habiter"
printf '%s\n' '[Desktop Entry]' "Exec=$HOME_FIXTURE/.local/opt/habiter/Habiter.AppImage" > "$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop"
write_manifest "$HOME_FIXTURE/.local/opt/habiter" "$HOME_FIXTURE/.local/opt/habiter/Habiter.AppImage" user 1.7.1 "\"$HOME_FIXTURE/.local/bin/habiter\",\"$HOME_FIXTURE/.local/share/applications/dev.habiter.Habiter.desktop\""
expect_failure HAB-UNIX-049 "$UNINSTALLER" --dry-run

reset_fixtures
mkdir -p "$HOME_FIXTURE/Applications/Habiter.app/Contents/MacOS"
mac_root=$HOME_FIXTURE/Applications/Habiter.app
printf '#!/bin/sh\n' > "$mac_root/Contents/MacOS/habiter"; chmod 755 "$mac_root/Contents/MacOS/habiter"
printf '%s\n' '<plist><dict><key>CFBundleIdentifier</key><string>dev.habiter.Habiter</string></dict></plist>' > "$mac_root/Contents/Info.plist"
write_manifest "$mac_root" "$mac_root/Contents/MacOS/habiter" user 1.7.1 '' "$mac_root.habiter-install.json"
HABITER_UNINSTALL_OS=Darwin "$UNINSTALLER" --dry-run >"$OUTPUT"
grep -q "Candidate: $mac_root" "$OUTPUT"
grep -q "Ownership evidence: $mac_root.habiter-install.json" "$OUTPUT"
printf '%s\n' '<plist><dict><key>CFBundleIdentifier</key><string>dev.example.Other</string></dict></plist>' > "$mac_root/Contents/Info.plist"
HABITER_UNINSTALL_OS=Darwin expect_failure HAB-UNIX-047 "$UNINSTALLER" --dry-run

reset_fixtures
mkdir -p "$HOME_FIXTURE/Applications/Habiter.app/Contents/MacOS"
mac_root=$HOME_FIXTURE/Applications/Habiter.app
printf '#!/bin/sh\n' > "$mac_root/Contents/MacOS/habiter"; chmod 755 "$mac_root/Contents/MacOS/habiter"
printf '%s\n' '<plist><dict><key>CFBundleIdentifier</key><string>dev.habiter.Habiter</string></dict></plist>' > "$mac_root/Contents/Info.plist"
write_manifest "$mac_root" "$mac_root/Contents/MacOS/habiter" user 1.7.1 '' "$mac_root.habiter-install.json"
cp "$mac_root.habiter-install.json" "$mac_root/.habiter-install.json"
HABITER_UNINSTALL_OS=Darwin expect_failure HAB-UNIX-062 "$UNINSTALLER" --dry-run

reset_fixtures
expect_failure HAB-UNIX-025 "$UNINSTALLER" --dry-run --install-dir "$HOME_FIXTURE"

echo 'uninstall.sh discovery tests passed'
