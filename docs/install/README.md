# Install Habiter

Habiter publishes checksummed desktop bundles through [GitHub Releases](https://github.com/marius4lui/habiter/releases). The recommended installers resolve the current release through `get.habiter.dev`, print every system change, verify SHA-256 before installation, and install into your user profile by default.

## Choose your platform

- [Linux](/install/linux/) — AppImage installer plus distro-specific dependencies and troubleshooting.
- [Windows](/install/windows) — PowerShell installer or verified ZIP bundle.
- [macOS](/install/macos) — shell installer or verified application ZIP.
- **Android** — use the [smart download](https://get-the.habiter.dev/?platform=android) for the signed direct APK or your configured store.

## Installer commands

Linux or macOS:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://get.habiter.dev/install.ps1 | iex
```

Read the script before running it if your environment requires review:

```sh
curl -fsSL https://get.habiter.dev/install.sh | less
```

```powershell
irm https://get.habiter.dev/install.ps1
```

The public endpoints proxy the allow-listed files in `scripts/install/` from this repository. They are not a separate copy of the installer logic.

## Uninstaller commands

Because uninstall is destructive, download and inspect the repository-backed script instead of piping it directly into a shell. Start with a dry-run; the final plan requires two confirmations and preserves all Habiter application data by default.

Linux or macOS:

```sh
curl -fL --proto '=https' --tlsv1.2 https://get.habiter.dev/uninstall.sh -o /tmp/habiter-uninstall.sh
less /tmp/habiter-uninstall.sh
sh -n /tmp/habiter-uninstall.sh
sh /tmp/habiter-uninstall.sh --dry-run --verbose
```

Windows PowerShell:

```powershell
$script = Join-Path $env:TEMP 'habiter-uninstall.ps1'
Invoke-WebRequest https://get.habiter.dev/uninstall.ps1 -OutFile $script
Get-Content $script
powershell.exe -NoProfile -File $script -DryRun -VerboseOutput
```

Continue with the reviewed script only after its canonical target and exact integration list are correct. See the platform pages for system/custom targets, legacy installs, conflicts, recovery, and the deliberately separate application-data decision.

## Integrity and signing

Every installer download requires HTTPS and a SHA-256 value returned by the release resolver. A mismatch stops before the installed application is replaced. Android releases are signed. Desktop checksum verification is available now; Windows signing and macOS signing/notarization are not claimed until their release metadata says otherwise.

## Build from source

See [Getting started](/guide/getting-started#build-from-source) for the Flutter development path. Building from source is separate from the supported binary installer flow.
