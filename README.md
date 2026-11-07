# Quickshell bar

A light, themeable Hyprland bar. Pick your widgets, put them on any screen
edge, done. Widgets you turn off use nothing.

## Needs

- **Hyprland** 0.57+ and **Quickshell** 0.3.2+
- An Arch-based distro for the install script (others work, install by hand)
- Everything else is installed for you. The full list is in
  [`config/dependencies.json`](config/dependencies.json).

## Install

```sh
git clone https://github.com/crome1394/quickshell-edgebar ~/.config/quickshell
~/.config/quickshell/scripts/install-deps.sh
qs -d
```

`install-deps.sh` installs whatever is missing (pacman, plus paru or yay
for AUR packages) and starts the services the bar uses. It asks before
each step; `--dry-run` just shows the plan.

Then click the spanner on the bar to open **Settings** and turn on widgets.

## Learn more

[Widgets](docs/widgets.md) ·
[Settings](docs/settings.md) ·
[Themes](docs/themes.md) ·
[FreshRSS](docs/freshrss.md) ·
[Inspector](docs/inspector.md) ·
[IPC calls](docs/ipc.md) ·
[Hyprland setup](docs/hyprland.md) ·
[Architecture](ARCHITECTURE.md) ·
[Changelog](CHANGELOG.md)

MIT licensed ([LICENSE](LICENSE)).
