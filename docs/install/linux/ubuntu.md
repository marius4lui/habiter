# Install Habiter on Ubuntu

## Support status

Ubuntu 24.04 LTS x86-64 is in the installer CI detection matrix and is the maintained Ubuntu reference. Flutter supports Linux desktop on current Ubuntu LTS releases; Habiter distributes an x86-64 AppImage. ARM64 is not published yet. The AppImage still relies on the host GTK, WebKitGTK, Secret Service, and display stack.

## Recommended installation

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

The installer detects Ubuntu from `/etc/os-release`, resolves the current primary AppImage, downloads to a unique temporary directory, verifies SHA-256, then replaces the user-scoped application and launcher. Preview changes with:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --dry-run --verbose
```

## Dependencies

Ubuntu 24.04 uses the `t64` GTK/FUSE transition names:

```sh
sudo apt update
sudo apt install libgtk-3-0t64 libwebkit2gtk-4.1-0 libsecret-1-0 libfuse2t64
```

These packages are host runtime prerequisites, not files silently installed by the Habiter installer. Check an individual package before changing the system with `apt-cache policy PACKAGE`.

## Manual installation and verification

Install `curl` and `jq`, request the resolver, then verify exactly the returned file:

```sh
meta=$(curl -fsSL 'https://get.habiter.dev/api/v1/install/linux/x64?channel=stable&distro=ubuntu')
url=$(printf '%s' "$meta" | jq -r '.artifact.url')
expected=$(printf '%s' "$meta" | jq -r '.artifact.sha256')
curl -fL --proto '=https' --tlsv1.2 -o Habiter.AppImage "$url"
printf '%s  %s\n' "$expected" Habiter.AppImage | sha256sum --check -
chmod 755 Habiter.AppImage
install -Dm755 Habiter.AppImage "$HOME/.local/opt/habiter/Habiter.AppImage"
```

Only create `~/.local/bin/habiter` and a desktop entry after the checksum succeeds. The repository installer performs those steps consistently.

## Update

Rerun the recommended installer. It stages and verifies the new AppImage before replacing the existing file. For a manual update, repeat the resolver/download/checksum sequence and replace `~/.local/opt/habiter/Habiter.AppImage` only after verification.

## Uninstall safely

Download and review `https://get.habiter.dev/uninstall.sh`, run `sh /tmp/habiter-uninstall.sh --dry-run --verbose`, then run the same reviewed file without `--dry-run` only after its exact plan is correct. Use `--system` for `/opt/habiter` or `--install-dir '/exact/custom/habiter'` for one custom root.

The uninstaller requires two confirmations, refuses ambiguous, malformed, redirected, unowned, broad, or running targets, stages removal for recovery, and preserves all application data. See the [complete Linux uninstall, automation, failure, and manual fallback contract](/install/linux/#uninstall-safely).

## AppImage and FUSE troubleshooting

If launch reports a FUSE mount error, confirm `libfuse2t64` is installed and inspect `/dev/fuse`:

```sh
dpkg-query -W libfuse2t64
ls -l /dev/fuse
```

To distinguish mounting from an application-runtime failure, use AppImage extraction temporarily:

```sh
"$HOME/.local/opt/habiter/Habiter.AppImage" --appimage-extract
./squashfs-root/AppRun
```

Extraction is a diagnostic fallback, not the maintained install layout.

## GTK, Wayland, and X11

Run from a terminal and inspect missing libraries:

```sh
echo "session=${XDG_SESSION_TYPE:-unknown}"
ldd "$HOME/.local/opt/habiter/Habiter.AppImage" | grep 'not found' || true
GDK_BACKEND=x11 habiter
```

`GDK_BACKEND=x11` is a one-run comparison for a Wayland-specific failure, not a global desktop change. Headless/SSH sessions need a display and are not a supported interactive environment.

## Keyring and Secret Service

Habiter uses the desktop Secret Service through `libsecret`. Confirm the library and a session service are available:

```sh
dpkg-query -W libsecret-1-0
busctl --user list | grep -E 'org.freedesktop.secrets|org.gnome.keyring' || true
```

Unlock the normal desktop keyring through Ubuntu's supported UI. Do not disable encryption or store credentials in plaintext.

## Safe diagnostics for an issue

```sh
uname -a
cat /etc/os-release
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
sha256sum "$HOME/.local/opt/habiter/Habiter.AppImage"
```

Also include the installer `--verbose` output and Habiter version. These commands do not include habit data or tokens. Review output before attaching it; do not paste unrelated environment variables, keyring contents, or application data.
