# Install Habiter on Arch Linux

## Support status

The current `archlinux:latest` image is in installer CI for distro detection. Arch is rolling release, so compatibility reflects current packages rather than a frozen OS version. Habiter publishes an x86-64 AppImage; ARM64 and an AUR package are not currently provided.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Use `sh -s -- --dry-run --verbose` to inspect every planned step. The default does not use root.

## Dependencies

```sh
sudo pacman -S --needed gtk3 webkit2gtk-4.1 libsecret fuse2
```

Review current package metadata with `pacman -Si PACKAGE`. Avoid replacing official libraries with unrelated AUR variants merely to run the AppImage.

## Manual install, update, and uninstall

Query `https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=arch`, download only its HTTPS artifact URL, compare the response SHA-256 with `sha256sum`, then install the executable AppImage to `~/.local/opt/habiter/Habiter.AppImage`. Rerun the repository installer to update atomically.

For uninstall, download and review `https://get.habiter.dev/uninstall.sh`, run `sh /tmp/habiter-uninstall.sh --dry-run --verbose`, then run the same reviewed file without `--dry-run` only after its exact plan is correct. Use `--system` or one exact `--install-dir` when applicable.

The uninstaller requires two confirmations, refuses ambiguous, malformed, redirected, unowned, broad, or running targets, stages removal for recovery, and preserves all application data. See the [complete Linux uninstall, automation, failure, and manual fallback contract](/install/linux/#uninstall-safely).

## AppImage/FUSE and dynamic libraries

```sh
pacman -Q fuse2 gtk3 webkit2gtk-4.1 libsecret
ls -l /dev/fuse
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
```

If mounting fails, `--appimage-extract` is a diagnostic fallback. If `squashfs-root/AppRun` also fails, investigate the rolling runtime/library change rather than FUSE.

## Wayland, X11, and keyring

```sh
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
GDK_BACKEND=x11 habiter
busctl --user list | grep -E 'org.freedesktop.secrets|org.gnome.keyring|org.kde.kwallet' || true
```

GNOME commonly supplies `gnome-keyring`; KDE may need its supported Secret Service integration. Do not store Habiter secrets unencrypted as a workaround.

## Safe diagnostics

Share `uname -a`, `/etc/os-release`, `pacman -Q` output for the four runtime packages, session type, missing `ldd` entries, Habiter version, and reviewed installer `--verbose` output. Do not share tokens, keyring data, habits, browser history, or unrelated environment variables.
