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
| `clipboard toggle` · `open` · `close` | [Clipboard](clipboard.md) viewer |
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
| `notificationBell toggleDoNotDisturb` | Do not disturb (built-in, SwayNC, dunst, or mako) |

## Caffeine, Night Light, recorder, firewall, battery, brightness

| Call | Does |
|---|---|
| `caffeine toggle` · `on` · `off` | Keep the screen awake |
| `caffeine forMinutes <n>` | Awake for n minutes (0 = until off) |
| `caffeine status` | On or off, and the time left |
| `nightLight toggle` · `on` · `off` | Warm the screen |
| `nightLight temperature <K>` | Set the warmth, 2500 to 6500 |
| `nightLight status` | On or off, warmth, schedule |
| `recorder toggle` | Start or stop recording, like a left click |
| `recorder start` · `startRegion` · `stop` | Record per Settings, record a region, stop and save |
| `recorder status` | Recording time and file, or the last file saved |
| `firewall status` | On or off, default policies, rule count |
| `firewall enable` · `disable` · `toggle` | Change the firewall (asks for your password) |
| `battery status` | Level, charging, time left, power profile |
| `battery setProfile <name>` · `cycleProfile` | Power profile: `power-saver`, `balanced`, `performance` |
| `brightness status` · `set <percent>` · `up` · `down` | Built-in screen brightness (good for the brightness keys) |

These work whether or not the widgets are on a bar.

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
hl.bind("SUPER + V",           hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind("SUPER + COMMA",       hl.dsp.exec_cmd("qs ipc call settings toggle"))
hl.bind("SUPER + N",           hl.dsp.exec_cmd("qs ipc call notificationBell toggleHistory"))
hl.bind("SUPER + SHIFT + R",   hl.dsp.exec_cmd("qs ipc call recorder toggle"))
hl.bind("SUPER + SHIFT + C",   hl.dsp.exec_cmd("qs ipc call caffeine toggle"))
```

On a laptop, the brightness keys:

```lua
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("qs ipc call brightness up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call brightness down"))
```
