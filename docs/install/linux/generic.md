# Install Habiter on another Linux distribution

## Support status

Unknown distributions deliberately normalize to `generic`; Habiter does not guess a distro from a browser or force it into an unrelated package family. The x86-64 AppImage is the portable fallback. A distribution not listed in the CI matrix is community/untested until its runtime dependencies and installer behavior are added to CI and a dedicated guide.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

First run `sh -s -- --dry-run --verbose`. Confirm the detected result is `generic`, the architecture is `x64`, and destinations are user-scoped.

## Runtime dependencies

Habiter needs a GTK 3 desktop runtime, WebKitGTK 4.1, Secret Service/libsecret, and AppImage FUSE support (or a distribution-supported alternative). Package names vary; use the distribution's official package search. Do not paste a command from another distro or weaken security controls to satisfy a dependency.

## Manual install and verification

Query `https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=generic`. Validate that the artifact URL is HTTPS and the checksum is 64 lowercase hex characters. Download to a temporary file, compare SHA-256 with the resolver response, make it executable only after a match, and place it at `~/.local/opt/habiter/Habiter.AppImage`.

The advanced `.tar.gz` release is a complete Flutter bundle: `habiter`, `lib/`, and `data/` are inseparable.

## Update and uninstall

Rerun the installer to update. To uninstall, download and review `https://get.habiter.dev/uninstall.sh`, run `sh /tmp/habiter-uninstall.sh --dry-run --verbose`, then run the same reviewed file without `--dry-run` only after its exact plan is correct. Use `--system` or one exact `--install-dir` when applicable.

The uninstaller requires two confirmations, refuses ambiguous, malformed, redirected, unowned, broad, or running targets, stages removal for recovery, and preserves all application data. See the [complete Linux uninstall, automation, failure, and manual fallback contract](/install/linux/#uninstall-safely).

## Troubleshooting

Distinguish layers in order:

1. Run `Habiter.AppImage --appimage-version` and inspect `/dev/fuse`.
2. Use `--appimage-extract` and `squashfs-root/AppRun` only to isolate mounting.
3. Inspect `ldd` output for missing GTK/WebKitGTK/libsecret libraries.
4. Record `${XDG_SESSION_TYPE:-unknown}` and compare one launch with `GDK_BACKEND=x11` if using Wayland.
5. Confirm a user-session `org.freedesktop.secrets` service exists; never replace secure storage with plaintext.

## Safe diagnostics

Include Habiter version, `uname -a`, `/etc/os-release`, session type, missing-library lines, and reviewed `--verbose` installer output. Identify your distro/version and package names so support can become reproducible. Never post tokens, keyring contents, habits, browser history, or unrelated environment variables.
