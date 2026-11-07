# IPC calls

Control the bar from keybinds and scripts with `qs ipc call <target>
<function> [args]`. `qs ipc show` lists every target while the bar runs.
Some targets exist only while their widget is on a bar (noted below).

Bind one in Hyprland's Lua config:

```lua
hl.bind("SUPER + R", hl.dsp.exec_cmd("qs ipc call freshRss toggle"))
```

## Windows and overlays

| Call | Does |
|---|---|
| `settings open` · `close` · `toggle` | Settings window |
| `settings openTab <tab> <section>` | Jump to a page, e.g. `openTab applications freshrss`. Use `""` for no section |
| `inspector toggle` · `open` · `close` | [Inspector](inspector.md) |
| `inspector openTab bindings\|system` | Inspector on a tab |
| `freshRss toggle` · `open` · `close` | [FreshRSS](freshrss.md) reader |
| `freshRss refresh` | Check the unread count now |
| `overview toggle` · `open` · `close` | Workspace overview |
| `overview desktop` · `all` | Windows in place / every workspace |
| `overview next` · `prev` | Step cards while it is open |

Settings tab ids: `bar`, `widgets`, `appearance`, `applications`,
`connectivity`, `audio`, `notifications`, `region`, `system`, `tools`.
`theme` and `wallpaper` still work and open those sections of Appearance.

## Menus (while the widget is on a bar)

Opened from a keybind, a menu appears on the main monitor (see
[Settings → Widgets → Bars → Monitors](settings.md#widgets)).

| Call | Does |
|---|---|
| `audioMenu toggle` · `open` · `close` | Audio menu |
| `opacityMenu toggle` · `open` · `close` | Transparency menu |
| `notificationBell toggleHistory` · `showHistory` · `hideHistory` | Notification history |
| `notificationBell toggleDoNotDisturb` | Do not disturb (works with either server) |

## Themes

| Call | Does |
|---|---|
| `theme apply "<name>"` | Apply a preset or saved theme |
| `theme list` | Every theme name |
| `theme current` | The applied theme |

## Shell

Workspace switches, for scripts:

| Call | Does |
|---|---|
| `shell setShowMagicWorkspacePill true\|false` · `toggleShowMagicWorkspacePill` | Show the special (magic) workspace pill |
| `shell setWsShowNumbers true\|false` | Workspace numbers |
| `shell setWsShowOnlyActive true\|false` | Only workspaces with windows |
| `shell setWsMinimumShown <n>` | Always show at least n workspaces |
| `shell setWsStartupWorkspace <n>` · `setWsStartupCloseMagic true\|false` | Startup behavior |

## Example keybinds

Pick keys that are free in your config.

```lua
hl.bind("SUPER + TAB",         hl.dsp.exec_cmd("qs ipc call overview toggle"))
hl.bind("SUPER + SLASH",       hl.dsp.exec_cmd("qs ipc call inspector toggle"))
hl.bind("SUPER + R",           hl.dsp.exec_cmd("qs ipc call freshRss toggle"))
hl.bind("SUPER + COMMA",       hl.dsp.exec_cmd("qs ipc call settings toggle"))
hl.bind("SUPER + N",           hl.dsp.exec_cmd("qs ipc call notificationBell toggleHistory"))
```
