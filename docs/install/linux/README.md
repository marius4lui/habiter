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
