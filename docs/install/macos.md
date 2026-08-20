# Install Habiter on macOS

## Support status

The release workflow builds and installer CI tests macOS on `macos-latest`. The published ZIP contains the complete `Habiter.app`; the resolver currently exposes the architecture declared by release metadata. The user-scoped default is `~/Applications/Habiter.app`. macOS signing/notarization is not claimed for an artifact unless release metadata explicitly marks it signed.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

The installer detects Apple Silicon or Intel, resolves the release, downloads through HTTPS, checks SHA-256, verifies the expected `.app/Contents/MacOS` structure, and stages replacement. Preview with:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --dry-run --verbose
```

The default needs no administrator access. `--system` targets `/Applications` explicitly and does not invoke `sudo`.

## Manual ZIP installation and checksum

Install `jq` or inspect the resolver JSON manually, then:

```sh
arch=$(uname -m)
case "$arch" in arm64) api_arch=arm64 ;; x86_64) api_arch=x64 ;; *) exit 1 ;; esac
meta=$(curl -fsSL "https://get.habiter.dev/api/v1/install/macos/$api_arch?channel=stable")
url=$(printf '%s' "$meta" | jq -r '.artifact.url')
expected=$(printf '%s' "$meta" | jq -r '.artifact.sha256')
curl -fL --proto '=https' --tlsv1.2 -o Habiter.zip "$url"
actual=$(shasum -a 256 Habiter.zip | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo 'SHA-256 mismatch' >&2; exit 1; }
mkdir -p "$HOME/Applications"
ditto -x -k Habiter.zip "$HOME/Applications"
```

Confirm `~/Applications/Habiter.app/Contents/MacOS` exists. Do not replace an existing app until the checksum and structure both pass.

## Update

Quit Habiter and rerun the installer. The new app is verified and staged before the previous bundle is moved aside. Manual updates repeat the resolver and checksum flow.

## Uninstall

```sh
rm -rf "$HOME/Applications/Habiter.app"
```

For an explicit system install, remove `/Applications/Habiter.app` with appropriate authorization. Application data remains and must be reviewed/exported separately.

## Gatekeeper and signing

The installer never disables Gatekeeper and never removes quarantine metadata. For an unsigned current build, first confirm the resolver URL and SHA-256. Then use Finder's **Open** action or the macOS **Privacy & Security** panel if your policy offers an explicit approval. Do not run broad `xattr` removal or disable Gatekeeper. Managed Macs may require administrator approval.

When notarized/signing metadata becomes available, verification with `codesign` and `spctl` will be additive to SHA-256:

```sh
codesign --display --verbose=4 "$HOME/Applications/Habiter.app"
spctl --assess --type execute --verbose=4 "$HOME/Applications/Habiter.app"
```

Unsigned status is expected to fail signature assessment; it is not presented as signed.

## Architecture and runtime troubleshooting

```sh
uname -m
file "$HOME/Applications/Habiter.app/Contents/MacOS/habiter"
otool -L "$HOME/Applications/Habiter.app/Contents/MacOS/habiter"
log show --last 10m --predicate 'process == "habiter"' --style compact
```

Use the architecture declared by the resolver. Do not bypass TLS or download missing libraries from third-party sites. Include only relevant, reviewed log lines.

## Safe diagnostics

Share macOS version (`sw_vers`), architecture, Habiter version, checksum result, `codesign`/`spctl` status, exact error, and reviewed installer `--verbose` output. Never share tokens, keychain contents, habit data, browser history, or unrelated environment variables.
