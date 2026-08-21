# Install Habiter

Choose a maintained installation path:

- [Linux](/install/linux/) — AppImage with distribution-specific guidance.
- [Windows](/install/windows) — verified PowerShell or ZIP installation.
- [macOS](/install/macos) — verified shell or application ZIP installation.
- [Android](https://get-the.habiter.dev/?platform=android) — signed direct APK or configured store.

Linux or macOS:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://get.habiter.dev/install.ps1 | iex
```

The installers are repository-backed, user-scoped by default, transparent about every change, and require an HTTPS artifact plus matching SHA-256 before replacement. See the platform pages for manual verification, signing status, updates, uninstall, and troubleshooting.

## Uninstall safely

Habiter also publishes repository-backed uninstallers at `https://get.habiter.dev/uninstall.sh` and `https://get.habiter.dev/uninstall.ps1`. Download and review the matching script, run its dry-run, and only then start the interactive uninstall. It discovers bounded known locations, verifies the installer ownership manifest and platform identity, prints every literal removal target, requires two confirmations, and preserves application data by default.

Use the [Linux](/install/linux/#uninstall-safely), [Windows](/install/windows#uninstall-safely), or [macOS](/install/macos#uninstall-safely) instructions. Android uninstallation remains owned by the operating system.
