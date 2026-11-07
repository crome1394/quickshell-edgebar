# Hyprland setup

What to add to your Hyprland config (Lua, Hyprland 0.57+). Only the first
item is needed to run the bar; the rest turn on optional features.

## Start the bar

In your autostart:

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("qs -d")
end)
```

## Transparency

Settings → System → Transparency writes `~/.config/hypr/opacity.lua` and
applies it live. For it to apply when Hyprland starts too, load it **last**
in `hyprland.lua`, after your own window rules, so its levels win:

```lua
-- Quickshell transparency. Last so these named rules win.
require("opacity")
```

While "All applications" is below 100%, these rules replace opacity from
your own rules (for example HyprGlass's `opacity = 0.90`). To keep one app
at its own level, add it as an override. Old `opacity.state` and
`opacity.lock` files next to it are no longer used and can be deleted.

## Display

Settings → System → Display saves a kept mode only to
`~/.config/hypr/config/monitors.lua` or `~/.config/hypr/monitors.lua`, and
only when that file contains this line:

```lua
-- Managed by Quickshell
```

Load the file from `hyprland.lua`, for example
`require("config.monitors")`. Without the marker, mode changes last until
Hyprland restarts.

## Notifications

Nothing is needed with **Auto** (the default): if a notification daemon
starts at login (SwayNC, dunst, mako), the bar uses it; if none does, the
bar is the server itself. A notification daemon is therefore optional.

With **Built-in**, make sure no other daemon starts first. Remove its line
from your autostart, for example:

```lua
-- hl.exec_cmd("systemctl --user start swaync.service")
```

A daemon that is installed can also be started by D-Bus on its own when a
notification arrives while the bar is restarting, so uninstall it if you
use Built-in for good (`sudo pacman -Rns swaync`).

With **SwayNC**, keep SwayNC in your autostart.

## Window rules

The bar's windows have the class `org.quickshell` and these titles:
`Settings`, `Inspector`, `FreshRSS`. They float on their own; add rules to
size or place them:

```lua
hl.window_rule({
    name   = "Quickshell Settings",
    match  = { title = "^(Settings)$", class = "^(org.quickshell)$" },
    float  = true,
    center = true,
    size   = { 1136, 874 },
})
```

The same pattern works for `Inspector` and `FreshRSS`.

## Blur and glass

The bar draws its own glass. If you use a blur or glass plugin, exclude
the bar's layers so they are not processed twice. With HyprGlass:

```lua
hg.layer("quickshell", { exclude = true })
hg.layer("quickshell-overview", { exclude = true })
hg.layer("quickshell-notifications", { exclude = true })  -- built-in popups
```

## Keybinds

See [IPC calls](ipc.md#example-keybinds). For the
[Inspector](inspector.md) to list a bind, end the line with a
`--#Category# description` comment.
