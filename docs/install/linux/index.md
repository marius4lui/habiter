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

## Uninstall safely

Download and review the repository-backed uninstaller, then preview its exact plan:

```sh
curl -fL --proto '=https' --tlsv1.2 https://get.habiter.dev/uninstall.sh -o /tmp/habiter-uninstall.sh
less /tmp/habiter-uninstall.sh
sh -n /tmp/habiter-uninstall.sh
sh /tmp/habiter-uninstall.sh --dry-run --verbose
```

Run the same file without `--dry-run` only after the candidate and every literal target are correct. It requires two confirmations and preserves all application data. Use `--system` or one exact `--install-dir` when needed; zero, multiple, legacy, malformed-manifest, symlink, process, ownership, and permission states fail closed or show an explicit warning. See the [complete Linux uninstall and recovery contract](/install/linux/#uninstall-safely) before using non-interactive confirmation or a validated manual quarantine fallback.
