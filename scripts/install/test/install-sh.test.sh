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

for fixture in ubuntu debian fedora arch opensuse generic; do
  HABITER_UNAME_S=Linux HABITER_UNAME_M=x86_64 HABITER_OS_RELEASE_FILE="$FIXTURES/$fixture"
  export HABITER_UNAME_S HABITER_UNAME_M HABITER_OS_RELEASE_FILE
  detect_system
  assert_eq "$DISTRO" "$fixture"
done

"$INSTALLER" --help >/dev/null
error_file="${TMPDIR:-/tmp}/habiter-installer-error-$$"
trap 'rm -f "$error_file"' EXIT
if "$INSTALLER" --channel nightly >/dev/null 2>"$error_file"; then echo "invalid channel accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-005' "$error_file" || { echo "missing invalid-channel error code" >&2; exit 1; }
grep -q 'Install ID:' "$error_file" || { echo "missing support correlation ID" >&2; exit 1; }
if HABITER_UNAME_S=Linux HABITER_UNAME_M=sparc HABITER_OS_RELEASE_FILE="$FIXTURES/generic" "$INSTALLER" --dry-run >/dev/null 2>"$error_file"; then echo "unsupported architecture accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-011' "$error_file" || { echo "missing architecture error code" >&2; exit 1; }
if HABITER_UNAME_S=Plan9 HABITER_UNAME_M=x86_64 "$INSTALLER" --dry-run >/dev/null 2>"$error_file"; then echo "unsupported OS accepted" >&2; exit 1; fi
grep -q 'HAB-POSIX-013' "$error_file" || { echo "missing OS error code" >&2; exit 1; }
echo "install.sh tests passed"
