# Install Habiter on Debian

## Support status

Debian 12 (Bookworm) x86-64 is in the installer CI detection matrix. It is documented separately from Ubuntu because package names and release cadence differ. Habiter's preferred artifact is the x86-64 AppImage; ARM64 is not currently published. Debian compatibility is tested by Habiter CI while Flutter's general Linux desktop support remains upstream.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

The installer identifies Debian locally, resolves release metadata, verifies SHA-256, and installs under `~/.local` without root. Inspect without mutation:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --dry-run --verbose
```

## Dependencies

On Debian 12:

```sh
sudo apt update
sudo apt install libgtk-3-0 libwebkit2gtk-4.1-0 libsecret-1-0 libfuse2
```

Use `apt-cache policy` to confirm availability on your configured Debian suite. Do not substitute Ubuntu `t64` package names on Bookworm.

## Manual installation and verification

```sh
meta=$(curl -fsSL 'https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=debian')
url=$(printf '%s' "$meta" | jq -r '.artifact.url')
expected=$(printf '%s' "$meta" | jq -r '.artifact.sha256')
curl -fL --proto '=https' --tlsv1.2 -o Habiter.AppImage "$url"
printf '%s  %s\n' "$expected" Habiter.AppImage | sha256sum --check -
chmod 755 Habiter.AppImage
install -Dm755 Habiter.AppImage "$HOME/.local/opt/habiter/Habiter.AppImage"
```

The full Flutter `.tar.gz` bundle remains on GitHub Releases for advanced/manual use. Its `habiter`, `lib/`, and `data/` entries must stay together; copying only the executable is invalid.

## Update

Rerun the installer for an atomic, verified replacement. Manual updates must resolve fresh metadata and pass SHA-256 before replacing the stable AppImage path.

## Uninstall

```sh
rm -f "$HOME/.local/bin/habiter"
rm -f "$HOME/.local/share/applications/dev.habiter.Habiter.desktop"
rm -rf "$HOME/.local/opt/habiter"
```

User data is deliberately not removed by these commands.

## AppImage and FUSE troubleshooting

```sh
dpkg-query -W libfuse2
ls -l /dev/fuse
"$HOME/.local/opt/habiter/Habiter.AppImage" --appimage-version
```

If FUSE alone is failing, `--appimage-extract` can isolate the mount layer. If extracted `squashfs-root/AppRun` also fails, inspect runtime libraries instead of treating it as a FUSE problem.

## GTK, Wayland, and X11

```sh
echo "session=${XDG_SESSION_TYPE:-unknown}"
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
GDK_BACKEND=x11 habiter
```

The X11 environment override is only a diagnostic comparison. Keep your normal display-session settings unless a confirmed upstream/driver issue requires otherwise.

## Keyring and Secret Service

Install and use the keyring integration appropriate to your desktop. GNOME commonly provides `gnome-keyring`; KDE may use `kdewallet` with a Secret Service bridge. Confirm the D-Bus service:

```sh
dpkg-query -W libsecret-1-0
busctl --user list | grep -E 'org.freedesktop.secrets|org.gnome.keyring' || true
```

Headless sessions often have no unlocked Secret Service. Do not work around that by weakening credential storage.

## Safe diagnostics for an issue

```sh
uname -a
cat /etc/debian_version
cat /etc/os-release
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
```

Add Habiter version and installer `--verbose` output. Review before sharing. Never attach tokens, keyring contents, habit data, browser history, or a full environment dump.
