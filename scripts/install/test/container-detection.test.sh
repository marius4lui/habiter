#!/bin/sh
set -eu
[ "$#" -eq 1 ] || { echo "expected normalized distro argument" >&2; exit 2; }
EXPECTED=$1
HABITER_TEST_MODE=functions . scripts/install/install.sh
HABITER_UNAME_S=Linux
HABITER_UNAME_M=x86_64
HABITER_OS_RELEASE_FILE=/etc/os-release
export HABITER_UNAME_S HABITER_UNAME_M HABITER_OS_RELEASE_FILE
detect_system
[ "$DISTRO" = "$EXPECTED" ] || { echo "expected $EXPECTED, detected $DISTRO" >&2; exit 1; }
printf 'detected %s as %s\n' "$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release | tr -d '"')" "$DISTRO"
