# Install Habiter on Linux

The installer detects a distribution locally from `/etc/os-release`; browser requests never guess it.

- [Ubuntu](/install/linux/ubuntu)
- [Debian](/install/linux/debian)
- [Fedora](/install/linux/fedora)
- [Arch Linux](/install/linux/arch)
- [openSUSE](/install/linux/opensuse)
- [Generic Linux](/install/linux/generic)

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh
```

Preview without mutation:

```sh
curl -fsSL https://get.habiter.dev/install.sh | sh -s -- --dry-run --verbose
```

The default x86-64 AppImage is installed below `~/.local`; the complete Flutter tar bundle remains available for advanced manual use.
