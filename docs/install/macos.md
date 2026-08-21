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

## Uninstall safely

Download, inspect, syntax-check, and preview the maintained uninstaller:

```sh
curl -fL --proto '=https' --tlsv1.2 https://get.habiter.dev/uninstall.sh -o /tmp/habiter-uninstall.sh
less /tmp/habiter-uninstall.sh
sh -n /tmp/habiter-uninstall.sh
sh /tmp/habiter-uninstall.sh --dry-run --verbose
```

Run the same reviewed file without `--dry-run` only after its canonical bundle and removal list are correct. It requires `y` and then the printed `UNINSTALL HABITER <canonical-path>` challenge. Missing TTY input, EOF, mismatch, a running Habiter process, insufficient permissions, an unsupported manifest, a symlinked bundle/parent, or a bundle-identifier mismatch aborts without killing a process or invoking `sudo`.

Use `--system` for `/Applications/Habiter.app`, or `--install-dir '/exact/custom/Habiter.app'` for one explicit custom bundle. Zero and multiple candidates fail closed; multiple installs are removed one at a time. Legacy bundles require both the expected executable structure and `CFBundleIdentifier` evidence and are clearly warned.

Normal uninstall quarantines the verified bundle before final deletion and restores staged content if a later move fails. It preserves `~/Library` application support/preferences, Keychain entries, backups, exports, and operating-system backups. This version has no application-data deletion option.

For a manual fallback, first reject `/`, the home directory, `/Applications`, symlinks, and redirected parents; verify `.habiter-install.json`, `Contents/MacOS/habiter`, and the exact `CFBundleIdentifier` in `Contents/Info.plist`. Rename only the verified `.app` to a unique adjacent quarantine, then remove that literal quarantine after review. Never start with recursive deletion of a name-only match, never remove `/Applications`, and preserve all data locations outside the bundle.

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
