# Install Habiter on openSUSE

## Support status

openSUSE Leap 15 is in the installer CI detection matrix. Tumbleweed uses the same normalization but is a rolling community-compatibility target until a dedicated matrix entry is added. The supported portable artifact is the x86-64 AppImage; ARM64 is not published.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

The installer recognizes `opensuse-*` and `sles` locally, uses the generic portable artifact, verifies SHA-256, and installs into `~/.local`. Preview with `sh -s -- --dry-run --verbose`.

## Dependencies

Package naming differs between Leap/Tumbleweed snapshots. Search first, then install the matching runtime packages:

```sh
zypper search -s 'libgtk-3-0' 'libwebkit2gtk-4_1-0' 'libsecret-1-0' 'libfuse2'
sudo zypper install libgtk-3-0 libwebkit2gtk-4_1-0 libsecret-1-0 libfuse2
```

Habiter does not change system packages automatically.

## Manual install, update, and uninstall

Resolve `https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=opensuse`, download its HTTPS URL, verify `.artifact.sha256` with `sha256sum`, then place the executable AppImage at `~/.local/opt/habiter/Habiter.AppImage`. Rerun the installer for a staged update.

```sh
rm -f "$HOME/.local/bin/habiter"
rm -f "$HOME/.local/share/applications/dev.habiter.Habiter.desktop"
rm -rf "$HOME/.local/opt/habiter"
```

Local application data remains.

## AppImage, display, and libraries

```sh
rpm -q libgtk-3-0 libwebkit2gtk-4_1-0 libsecret-1-0 libfuse2
ls -l /dev/fuse
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
GDK_BACKEND=x11 habiter
```

Use AppImage extraction only to isolate a FUSE mount problem. Use the X11 override for one diagnostic launch, not as a global session modification.

## Keyring and safe diagnostics

```sh
busctl --user list | grep -E 'org.freedesktop.secrets|org.gnome.keyring|org.kde.kwallet' || true
uname -a
cat /etc/os-release
```

Use the desktop's supported keyring integration and keep credentials encrypted. A safe issue report includes reviewed package versions, session type, missing-library lines, Habiter version, and installer `--verbose` output—never tokens, keyring contents, habits, or a full environment dump.
