#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: verify-update-flavors.sh <merged-manifest-root> <direct-variant> <store-variant>" >&2
  exit 2
fi

manifest_root="$1"
direct_variant="$2"
store_variant="$3"

manifest_for() {
  local variant="$1"
  local matches=()
  mapfile -t matches < <(find "$manifest_root/$variant" -type f -name AndroidManifest.xml -print)
  if [ "${#matches[@]}" -ne 1 ]; then
    echo "Expected exactly one merged manifest for $variant, found ${#matches[@]}" >&2
    exit 1
  fi
  printf '%s\n' "${matches[0]}"
}

direct_manifest="$(manifest_for "$direct_variant")"
store_manifest="$(manifest_for "$store_variant")"

for manifest in "$direct_manifest" "$store_manifest"; do
  grep -Fq 'package="com.habiter.app"' "$manifest" || {
    echo "Unexpected application ID in $manifest" >&2
    exit 1
  }
done

grep -Fq 'android.permission.REQUEST_INSTALL_PACKAGES' "$direct_manifest"
grep -Fq 'androidx.core.content.FileProvider' "$direct_manifest"
grep -Fq 'android:authorities="com.habiter.app.updates"' "$direct_manifest"

if grep -Fq 'android.permission.REQUEST_INSTALL_PACKAGES' "$store_manifest"; then
  echo "Store manifest must not request installer access" >&2
  exit 1
fi
if grep -Fq 'androidx.core.content.FileProvider' "$store_manifest"; then
  echo "Store manifest must not contain the update FileProvider" >&2
  exit 1
fi
if grep -Fq 'android:authorities="com.habiter.app.updates"' "$store_manifest"; then
  echo "Store manifest must not expose the update authority" >&2
  exit 1
fi

echo "Verified $direct_variant and $store_variant update manifest isolation."
