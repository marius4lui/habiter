#!/bin/sh
set -eu

[ "$#" -eq 3 ] || { echo "usage: package-linux-appimage.sh BUNDLE_DIR VERSION OUTPUT_DIR" >&2; exit 2; }
BUNDLE_DIR=$1
VERSION=$2
OUTPUT_DIR=$3
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
APPIMAGETOOL=${APPIMAGETOOL:-appimagetool}

printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo "invalid version" >&2; exit 2; }
[ -x "$BUNDLE_DIR/habiter" ] || { echo "Linux bundle is missing executable habiter" >&2; exit 1; }
[ -d "$BUNDLE_DIR/data/flutter_assets" ] || { echo "Linux bundle is missing Flutter assets" >&2; exit 1; }
[ -d "$BUNDLE_DIR/lib" ] || { echo "Linux bundle is missing libraries" >&2; exit 1; }
command -v "$APPIMAGETOOL" >/dev/null 2>&1 || { echo "appimagetool is required" >&2; exit 1; }

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/habiter-appimage.XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM
APP_DIR="$WORK_DIR/Habiter.AppDir"
mkdir -p "$APP_DIR/usr/bin" "$APP_DIR/usr/lib/habiter" "$APP_DIR/usr/share/applications" "$APP_DIR/usr/share/metainfo" "$APP_DIR/usr/share/icons/hicolor/512x512/apps" "$OUTPUT_DIR"
cp -R "$BUNDLE_DIR/." "$APP_DIR/usr/lib/habiter/"
cp "$ROOT/packaging/linux/dev.habiter.Habiter.desktop" "$APP_DIR/dev.habiter.Habiter.desktop"
cp "$ROOT/packaging/linux/dev.habiter.Habiter.desktop" "$APP_DIR/usr/share/applications/dev.habiter.Habiter.desktop"
cp "$ROOT/packaging/linux/dev.habiter.Habiter.appdata.xml" "$APP_DIR/usr/share/metainfo/dev.habiter.Habiter.appdata.xml"
cp "$ROOT/apps/habiter/assets/images/app_icon.png" "$APP_DIR/dev.habiter.Habiter.png"
cp "$ROOT/apps/habiter/assets/images/app_icon.png" "$APP_DIR/usr/share/icons/hicolor/512x512/apps/dev.habiter.Habiter.png"
printf '%s\n' '#!/bin/sh' 'HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)' 'exec "$HERE/usr/lib/habiter/habiter" "$@"' > "$APP_DIR/AppRun"
chmod 755 "$APP_DIR/AppRun" "$APP_DIR/usr/lib/habiter/habiter"
ln -s ../lib/habiter/habiter "$APP_DIR/usr/bin/habiter"

ARCH=x86_64 VERSION="$VERSION" "$APPIMAGETOOL" "$APP_DIR" "$OUTPUT_DIR/Habiter-$VERSION-x86_64.AppImage"
[ -s "$OUTPUT_DIR/Habiter-$VERSION-x86_64.AppImage" ] || { echo "AppImage was not produced" >&2; exit 1; }
