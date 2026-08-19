#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../../.." && pwd)
INSTALLER="$ROOT/scripts/install/install.sh"
FIXTURES="$ROOT/scripts/install/test/os-release"
HABITER_TEST_MODE=functions . "$INSTALLER"

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
if "$INSTALLER" --channel nightly >/dev/null 2>&1; then echo "invalid channel accepted" >&2; exit 1; fi
if HABITER_UNAME_S=Linux HABITER_UNAME_M=sparc HABITER_OS_RELEASE_FILE="$FIXTURES/generic" "$INSTALLER" --dry-run >/dev/null 2>&1; then echo "unsupported architecture accepted" >&2; exit 1; fi
echo "install.sh tests passed"
