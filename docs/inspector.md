# Inspector

A floating window with two tabs. Open it from the Inspector widget on the
bar, or with a keybind:

```lua
hl.bind("SUPER + SLASH", hl.dsp.exec_cmd("qs ipc call inspector toggle"))
```

`qs ipc call inspector openTab bindings` (or `system`) opens a tab
directly. The window exists only while open.

## Bindings

Lists the `hl.bind(...)` lines in `~/.config/hypr/config/keybindings.lua`
(or `hypr/hyprland.lua`) that end in a `--#` comment. Group them with
`--#Category# description`:

```lua
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs ipc call overview toggle")) --#Overview# Toggle the workspace overview
```

- Groups collapse from their titles (Expand all / Collapse all at the bottom).
- Keys show as colored chips: SUPER, ALT, SHIFT, CTRL, mouse, and others.
- **Click** a binding to run it; the Inspector closes first so it acts on
  the window you had focused. **Right-click** copies its keys.
- Commented-out binds are skipped. The list updates when the file changes.

## System Info

`fastfetch` output as rows. Click a row to copy it; Refresh and Copy all
are at the bottom right.

## Keys

`Ctrl+F` filters the open tab, `Esc` clears the filter or closes,
`Ctrl+Tab` switches tabs.

## Window rule

To size or place it:

```lua
match = { title = "^(Inspector)$", class = "^(org.quickshell)$" }
```
