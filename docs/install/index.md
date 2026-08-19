# Install Habiter

Choose a maintained installation path:

- [Linux](/install/linux/) — AppImage with distribution-specific guidance.
- [Windows](/install/windows) — verified PowerShell or ZIP installation.
- [macOS](/install/macos) — verified shell or application ZIP installation.
- [Android](https://get.habiter.dev/download?platform=android) — signed direct APK or configured store.

Linux or macOS:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://get.habiter.dev/install.ps1 | iex
```

The installers are repository-backed, user-scoped by default, transparent about every change, and require an HTTPS artifact plus matching SHA-256 before replacement. See the platform pages for manual verification, signing status, updates, uninstall, and troubleshooting.
