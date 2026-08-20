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

Use `--help` for the complete option list. `--system` is explicit and may require permissions for `/opt` and `/usr/local`; it never elevates privileges itself.
