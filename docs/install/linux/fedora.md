# Install Habiter on Fedora

## Support status

Fedora 42 x86-64 is in the installer CI detection matrix. Habiter uses the portable x86-64 AppImage; ARM64 is not published. Fedora's default Wayland and SELinux configuration remain enabled. The installer never changes either policy.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Preview detection, resolver output, checksum, and destinations with `sh -s -- --dry-run --verbose`. Installation stays under `~/.local` and needs no `sudo`.

## Dependencies

```sh
sudo dnf install gtk3 webkit2gtk4.1 libsecret fuse-libs
```

Confirm names against the enabled Fedora repositories with `dnf info PACKAGE`. Habiter does not install these system packages automatically.

## Manual install, update, and uninstall

Resolve `https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=fedora`, download the returned HTTPS URL, and compare `sha256sum FILE` with `.artifact.sha256` before making the AppImage executable. Keep it at `~/.local/opt/habiter/Habiter.AppImage`; the complete tar bundle is an advanced alternative and its `lib/` and `data/` directories must stay beside `habiter`.

Rerun the installer to update. To uninstall, download and review `https://get.habiter.dev/uninstall.sh`, run `sh /tmp/habiter-uninstall.sh --dry-run --verbose`, then run the same reviewed file without `--dry-run` only after its exact plan is correct. Use `--system` or one exact `--install-dir` when applicable.

The uninstaller requires two confirmations, refuses ambiguous, malformed, redirected, unowned, broad, or running targets, stages removal for recovery, and preserves all application data. See the [complete Linux uninstall, automation, failure, and manual fallback contract](/install/linux/#uninstall-safely).

## AppImage/FUSE and runtime debugging

```sh
rpm -q fuse-libs gtk3 webkit2gtk4.1 libsecret
ls -l /dev/fuse
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
```

Use `--appimage-extract` followed by `./squashfs-root/AppRun` only to distinguish a FUSE mount failure from a GTK/runtime failure.

## Wayland, X11, and SELinux

```sh
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
GDK_BACKEND=x11 habiter
ausearch -m avc -ts recent | tail -n 50
```

The X11 command is a one-run comparison. An AVC record is evidence to investigate; do not disable SELinux or generate a broad allow policy as a first fix. Report the denial with sensitive paths reviewed/redacted.

## Keyring and safe diagnostics

Confirm `libsecret` and the session Secret Service instead of weakening storage:

```sh
rpm -q libsecret
busctl --user list | grep -E 'org.freedesktop.secrets|org.gnome.keyring' || true
uname -a
cat /etc/os-release
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
```

Attach Habiter version and installer `--verbose` output after review. Never attach tokens, keyring contents, habit data, browser history, or a full environment dump.
