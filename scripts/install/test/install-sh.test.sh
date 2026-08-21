#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd)
INSTALLER="$ROOT/scripts/install/install.sh"
FIXTURES="$ROOT/scripts/install/test/os-release"
HABITER_TEST_MODE=functions
export HABITER_TEST_MODE
# shellcheck source=scripts/install/install.sh
. "$INSTALLER"
unset HABITER_TEST_MODE

assert_eq() { [ "$1" = "$2" ] || { echo "expected '$2', got '$1'" >&2; exit 1; }; }
assert_eq "$(normalize_arch x86_64)" x64
assert_eq "$(normalize_arch aarch64)" arm64
assert_eq "$(normalize_distro ubuntu debian)" ubuntu
assert_eq "$(normalize_distro debian debian)" debian
assert_eq "$(normalize_distro fedora '')" fedora
assert_eq "$(normalize_distro arch '')" arch
assert_eq "$(normalize_distro opensuse-tumbleweed 'suse')" opensuse
assert_eq "$(normalize_distro gentoo '')" generic

manifest_root="${TMPDIR:-/tmp}/habiter-manifest-test-$$/Habiter custom"
mkdir -p "$manifest_root"
RELEASE_VERSION=1.6.0
INSTALL_ID=manifest-test-one
write_manifest "$manifest_root" "$manifest_root/Habiter.AppImage" user "$manifest_root/bin/habiter" "$manifest_root/dev.habiter.Habiter.desktop"
node -e '
  const fs = require("node:fs");
  const value = JSON.parse(fs.readFileSync(0, "utf8"));
  const root = value.canonicalInstallRoot;
  if (value.schemaVersion !== 1 || value.product !== "habiter" || value.applicationId !== "dev.habiter.Habiter") throw new Error("manifest identity mismatch");
  if (value.installId !== "manifest-test-one" || value.version !== "1.6.0" || value.scope !== "user") throw new Error("manifest lifecycle fields mismatch");
  if (!root.endsWith("/Habiter custom") || value.executable !== `${root}/Habiter.AppImage`) throw new Error("manifest root mismatch");
  if (value.integrationPaths.length !== 2 || value.pathEntry !== null || value.pathEntryAddedByInstaller !== false) throw new Error("manifest integration mismatch");
' < "$manifest_root/.habiter-install.json"
RELEASE_VERSION=1.7.1
INSTALL_ID=manifest-test-upgrade
write_manifest "$manifest_root" "$manifest_root/Habiter.AppImage" user
node -e '
  const fs = require("node:fs");
  const value = JSON.parse(fs.readFileSync(0, "utf8"));
  if (value.installId !== "manifest-test-upgrade" || value.version !== "1.7.1" || value.integrationPaths.length !== 0) throw new Error("manifest upgrade mismatch");
' < "$manifest_root/.habiter-install.json"
rm -rf "${TMPDIR:-/tmp}/habiter-manifest-test-$$"

for fixture in ubuntu debian fedora arch opensuse generic; do
  HABITER_UNAME_S=Linux HABITER_UNAME_M=x86_64 HABITER_OS_RELEASE_FILE="$FIXTURES/$fixture"
  export HABITER_UNAME_S HABITER_UNAME_M HABITER_OS_RELEASE_FILE
  detect_system
  assert_eq "$DISTRO" "$fixture"
done

"$INSTALLER" --help >/dev/null
error_file="${TMPDIR:-/tmp}/habiter-installer-error-$$"
trap 'rm -f "$error_file"; rm -rf "${TMPDIR:-/tmp}/habiter-manifest-test-$$"' EXIT
if "$INSTALLER" --channel nightly >/dev/null 2>"$error_file"; then echo "invalid channel accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-005' "$error_file" || { echo "missing invalid-channel error code" >&2; exit 1; }
grep -q 'Install ID:' "$error_file" || { echo "missing support correlation ID" >&2; exit 1; }
if HABITER_UNAME_S=Linux HABITER_UNAME_M=sparc HABITER_OS_RELEASE_FILE="$FIXTURES/generic" "$INSTALLER" --dry-run >/dev/null 2>"$error_file"; then echo "unsupported architecture accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-011' "$error_file" || { echo "missing architecture error code" >&2; exit 1; }
if HABITER_UNAME_S=Plan9 HABITER_UNAME_M=x86_64 "$INSTALLER" --dry-run >/dev/null 2>"$error_file"; then echo "unsupported OS accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-013' "$error_file" || { echo "missing OS error code" >&2; exit 1; }
echo "install.sh tests passed"
