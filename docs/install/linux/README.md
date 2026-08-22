# Install Habiter on Linux

The portable Linux release is an AppImage containing the complete Flutter bundle. The installer reads `/etc/os-release` locally; a browser User-Agent is intentionally never used to guess a distribution.

## Choose your distribution

- [Ubuntu](./ubuntu.md)
- [Debian](./debian.md)
- [Fedora](./fedora.md)
- [Arch Linux](./arch.md)
- [openSUSE](./opensuse.md)
- [Generic or another distribution](./generic.md)

## Quick install

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Default files:

```text
~/.local/opt/habiter/Habiter.AppImage
~/.local/bin/habiter
~/.local/share/applications/dev.habiter.Habiter.desktop
```

The script prints detected distribution/architecture, selected release, artifact, byte size, checksum, destination, desktop integration, and launch command. It never invokes `sudo` in the default mode.

## Options

When piping a script, pass options after `sh -s --`:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --dry-run --verbose
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --channel beta
```

Use `--verbose` when troubleshooting. Failures include the active phase, a stable `HAB-POSIX-NNN` code, a recovery hint and a short Install ID. Verbose diagnostics are intentionally limited to platform, architecture, channel, destination and install mode; the installer never dumps the full environment, tokens, habit data, keyring contents or browser history.

Code families identify argument errors (`00x`), platform detection (`01x`), resolver/metadata (`02x`), temporary storage/download (`03x`), checksum (`04x`), archive validation (`05x`), installation/permissions (`06x`) and unexpected errors (`999`). Do not bypass HTTPS, artifact-size or checksum checks.

Use `--help` for the complete option list. `--system` is explicit and may require permissions for `/opt` and `/usr/local`; it never elevates privileges itself.

## Update

The Update Center can replace only the maintained user-scoped `Habiter.AppImage` identified by `APPIMAGE` and a matching schema-1 ownership manifest. Habiter downloads the one primary AppImage into its bounded per-user cache, supports safe HTTP Range resume, and checks exact size plus SHA-256. A detached shell helper rechecks the payload after Habiter exits, stages it beside the exact owned AppImage, preserves executable permissions, relaunches, and restores the adjacent backup if the new process exits during startup.

System-scoped installs, supplemental tar bundles, unknown/custom bundles, Flatpak/Snap/distro packages, and installations without exact ownership evidence are never overwritten. The Update Center opens the verified external route so the original package manager or administrator remains authoritative. The helper never calls `sudo`, kills the running process, rewrites a desktop entry it does not own, or scans for similarly named files. Direct transfers remain visible, cancelable, and retryable.

## Uninstall safely

Download and review the destructive workflow before executing it:

```sh
curl -fL --proto '=https' --tlsv1.2 https://get.habiter.dev/uninstall.sh -o /tmp/habiter-uninstall.sh
less /tmp/habiter-uninstall.sh
sh -n /tmp/habiter-uninstall.sh
sh /tmp/habiter-uninstall.sh --dry-run --verbose
```

The dry-run checks only the user and system defaults plus direct integration references; it never scans a home directory or system tree. It prints every candidate, canonical root, scope, version, ownership evidence, literal application/integration target, missing optional integration, and confirms that application data is preserved. Run without `--dry-run` only after reviewing that plan. Two confirmations are mandatory: `y`, followed by `UNINSTALL HABITER <canonical-path>`.

Use `--system` for `/opt/habiter`, or `--install-dir '/exact/custom/habiter'` for one custom installation. Zero candidates exit unchanged. Multiple candidates list both roots and abort until an exact target is selected. Unknown/malformed manifests, path escapes, symlinked roots or parents, broad targets, mismatched wrapper/desktop entries, a running process, or insufficient permissions fail closed. A pre-manifest installation needs matching AppImage, wrapper target, and desktop `Exec=` evidence and carries an additional legacy warning.

Non-interactive use requires both `--install-dir` and the exact `--confirm-target 'UNINSTALL HABITER /canonical/path'`; there is no generic `--yes`. Verified targets are moved to unique adjacent quarantine paths first. Staging failures restore earlier moves; later failures report what was restored, finalized, or left in quarantine with a stable `HAB-UNIX-NNN` code and Uninstall ID.

Normal uninstall preserves databases, preferences, reminders, keyring items, backups, exports, clipboard history, and operating-system backups. This version exposes no data-removal flag.

### Manual fallback after script failure

Do not fall back to a name-only recursive delete. Resolve the exact root with `cd -- "$root" && pwd -P`; reject `/`, the home directory, `/opt`, `/usr`, `/usr/local`, `/Applications`, symlinks, and redirected parents. Verify `.habiter-install.json`, the exact `Habiter.AppImage`, the wrapper's `readlink` target, and the desktop entry's exact `Exec=` value. Preserve every mismatch. Rename each verified literal target to a unique adjacent quarantine first, and remove only those literal quarantines after all moves succeed. Never remove shared parents or application data. Reinstalling Habiter to recreate ownership evidence is safer than guessing.
