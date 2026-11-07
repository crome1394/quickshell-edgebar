# Architecture

How this Quickshell bar is put together, for anyone changing it. The rules
it follows (lint-clean, one component per file, no shell injection) are in
[AGENTS.md](AGENTS.md); what each feature does is in [README.md](README.md).

## Goals, in order

1. **Lean at runtime.** Nothing loads, polls, or runs a process for a widget
   that is off or a window that is closed.
2. **Easy to change.** Small files with one job each. Data flows down as
   properties; events flow up as signals.
3. **Correct and safe.** qmllint-clean, atomic writes, no commands built
   from untrusted text, and graceful when a program or device is missing.

## Folders

| Folder | Holds | Suffix |
|---|---|---|
| `shell.qml` | The root. Creates one bar per enabled edge and the top-level windows. | |
| `bar/` | `EdgeBar` (one bar on one edge) and `BarSlot` (one layout entry, which loads one pill). | |
| `pills/` | Bar items and the menus they open (`AudioMenu`, `NetworkMenu`, …). | `Pill`, `Menu` |
| `panels/` | Floating windows and overlays: Settings, Inspector, overview, notification history, the active-window popup. | `Panel` |
| `settings/` | Settings pages and the controls they share (`IntSlider`, `ChipButton`, `DraftFooter`, …). | `Tab` |
| `inspector/` | The Inspector's two views. | `View` |
| `freshrss/` | The FreshRSS reader's model (filters, rows, cursor) and its views. | `Reader…` |
| `components/` | Small drawing pieces shared by pills (`BarTip`, `DockFace`, `LevelMeter`, …). | |
| `services/` | Runtime singletons: talk to Hyprland, PipeWire, BlueZ, NetworkManager, D-Bus, files, and the few processes the bar runs. | `Service` |
| `config/` | Saved settings: `Config` (the store) and one `<Feature>Settings` singleton per feature. | `Settings` |
| `theme/` | `Theme` (sizes, timings, the live palette), `DefaultTheme`, and the theme builder and presets. | |
| `scripts/` | The last few helper scripts (Python or shell), each run with fixed arguments. | |
| `assets/` | Pictures (the region map). | |
| `state/` | Personal saved state. Ignored by git. | |

Every folder has a hand-written `qmldir`. A new file must be listed there
(`Name 1.0 Name.qml`, or `singleton Name 1.0 Name.qml`) or it fails at
runtime with "X is not a type". A hot reload does not pick up new files;
restart the bar.

## How a widget gets on the bar

```
shell.qml
 └─ Variants over ScreenService.barScreens (the monitors that get bars)
     └─ ScreenBars  one monitor
         └─ Loader (only while that edge is on)
             └─ EdgeBar  edge, theme, screen
         └─ Repeater over WidgetService's layout for that edge
             └─ BarSlot  widgetId, theme
                 └─ Loader → pills/<Name>Pill.qml  (only while the widget is on)
                     └─ PopupWindow menu  (visible only while open)
```

- **WidgetService** keeps the layout: which widgets exist (the catalog, with
  their Settings labels), which edge and zone each sits in, and whether it
  is turned on. `isImplemented()` lists the ids that have a pill.
- **BarSlot** maps a widget id to its pill file. Most pills are loaded by
  URL, so a widget that is off never creates its component.
- Every pill takes `theme` (the live palette) and `edge` as properties, and
  reports `menuOpen` so an auto-hide bar stays out while a menu is open.
- **Tooltips**: a pill puts a `BarTip` inside itself; after the hover delay
  it asks `TipService` for the one shared tooltip, which `BarTipHost` (in
  `shell.qml`) draws outside the bar. No pill owns a window for its tip.
- **Monitors**: `ScreenService` decides which monitors get bars and which
  is main. Menus with shared state (Audio, Transparency, notification
  history) record the monitor that opened them, and each pill shows the
  menu only when it is on that monitor (`ScreenService.owns()`).
- A menu that can be opened from a keybind has a tiny `<Name>MenuService`
  with `open`, `toggle()`, `show()`, `hide()`, and an `IpcHandler`. The
  pill's click and IPC call the same functions. The service loads with the
  pill, so its IPC target exists only while the pill is on the bar.

## Saved settings

```
state/bar-layout.json ── Config (FileView + JsonAdapter, one save timer)
                           ▲ saveFields()          │ properties
                           │                       ▼
                  <Feature>Settings  ── editor: Draft ── <Feature>Tab
                   (validators,         value, set(),     (reads editor.value,
                    snapshot, commit)   apply/undo/reset   wires DraftFooter)
```

- **Config** is only the store: one property per saved field, a save timer,
  and shared validators. A change made while a save is being written is
  saved again when it ends, and the file watcher does not reload over it.
- **`<Feature>Settings`** holds a feature's helpers: clamping, defaults, and
  `snapshot()`, `normalize()`, `commit()`, `defaults()` for its Draft.
- **Draft** (`config/Draft.qml`) is the unsaved copy behind a page. Reading
  `editor.value` never writes, so it is safe in bindings. Apply commits,
  Undo drops the draft or restores the last applied values, Reset drafts
  the defaults.
- Changes that should take effect at once (the Transparency menu sliders,
  saving a theme to My themes) call `Config.saveFields()` directly.

`state/theme.json` is a second store, owned by `ThemeStore`: the active
theme (with its fonts) and the stat and audio thresholds. It is written in
one go when a theme is applied.

## Theme

```
ThemePresets / My themes / theme file
        │  a theme: tone, accent, alert, tint, glass, menu, colors, temp
        ▼
ThemeSettings.editor (Draft) ── Apply ──▶ ThemeStore.saveLook() ──▶ state/theme.json
                                                                        │
ThemeStore.activeTheme ◀────────────────────────────────────────────────┘
        │
ThemeBuilder.build()  →  ThemePalette (Theme.palette)  →  every pill's `theme`,
                                                          and Theme.accent, Theme.text, …
```

- A **theme** is a handful of choices. `ThemeBuilder.build()` derives the
  full palette from them (hover = 20% accent over the tint, active
  workspace = accent at 26%, and so on), then applies the theme's own
  `colors` on top. One new accent restyles everything that should follow it.
- **ThemePalette** has the same property names as `DefaultTheme`, so pills
  read `theme.colAccent` without caring where it came from. The theme's
  fonts and text size flow through it too; the default stat and audio
  colors still come from `DefaultTheme`.
- Presets carry colors only. Saved and imported themes also carry the stat
  and audio thresholds and colors, which Apply writes with the theme.
- Import accepts this bar's theme files and the old bar's exports, mapping
  the old color names onto this palette.

## Lean loading

- A bar edge that is off, a widget that is off, and a closed window or menu
  are not created (`Loader { active: … }`). The Inspector, overview capture,
  and settings pages exist only while open.
- Services start work only when something reads them. Pollers run at slow
  rates (`Theme.*Ms` intervals) and faster only while their menu is open.
- Long-running processes are kept to a few watchers: `nvidia-smi` in loop
  mode for the GPU, and, only when another notification daemon is in use,
  the history watcher (plus `swaync-client --subscribe` for SwayNC).
  Everything else is read from `/proc`, `/sys`, D-Bus, or Hyprland's
  socket through Quickshell's native modules.
- `shell.qml` reads a property from a few services (`OpacityService`,
  `OverviewService`, `NotificationService`, `ThemeSettings`, `FreshRssService`) so they load at
  start and register their IPC targets. Add to that list only when a
  feature has to work before any pill touches it.

## Outside the bar

- **Notifications**: `NotificationDaemon` decides the mode. Auto asks
  D-Bus who owns `org.freedesktop.Notifications` at start, and if nobody
  does, once more after `Theme.notificationClaimDelayMs` so a daemon
  launched at login wins; after that only while the Notifications page is
  open. Built-in mode:
  `BuiltinNotifications` owns the name (Quickshell's `NotificationServer`),
  `NotificationToasts` draws the popups (look from `PopupSettings`), and
  nothing else runs. SwayNC or another daemon: `NotificationService` runs
  the history watcher (plus `swaync-client --subscribe` for SwayNC) while
  the bell is shown. Every mode keeps history in
  `~/.local/state/quickshell/notification-history.json`.
- **Fonts**: `FontService` reads `fc-list` once per session for every font
  picker.

- **Hyprland**: `services/OpacityService` writes `~/.config/hypr/opacity.lua`
  and swaps the live rules with `hyprctl repl`; `DisplayService` changes
  monitor modes; `CaptureService` and `ScreensaverService` write their
  `.conf` files for the helper scripts in `~/.local/bin`.
- **FreshRSS**: `services/FreshRssService` talks to the server's Google
  Reader API with QML's `XMLHttpRequest` (no curl, no scripts). The login
  token stays in memory; parallel requests share one login; requests past
  `Theme.freshRssRequestMs` are aborted. Article HTML is cleaned before it
  is shown: no scripts, frames, forms, or styles, and images become links.
  The credentials file is read as shell-style text without running it and
  written by a fixed script (path as an argument, text on stdin) with mode
  600. The reader window (`panels/FreshRssPanel`) exists only while open.
- **Files are written atomically** (FileView `atomicWrites`, or write-then-
  rename in scripts). Programs are run with argument lists, never through a
  shell with user text in it.

## IPC targets

`qs ipc show` lists them while the bar runs: `settings` (open, close,
toggle, openTab), `theme` (apply, list, current), `freshRss` (toggle, open,
close, refresh), `inspector`, `overview`, `notificationBell`, `audioMenu`,
`opacityMenu`, and `shell`. Avoid naming a function `show`: `qs ipc show`
is a command of its own. Each handler
calls the same function as its button and validates its arguments; the
calls are listed in a comment beside the handler.

## Tests

`tests/run.sh` first starts the real `shell.qml` from a temporary copy
(bars off) and fails if Quickshell cannot load it, which catches errors
lint misses. Then it runs the logic tests: the theme builder and import, the
FreshRSS env reader and HTML cleaning, the reader's grouping and cursor,
the settings Draft, and the tooltip service. Each `tests/*Test.qml` is a
small Quickshell config run against a temporary copy of the bar with a
throwaway HOME, printing PASS/FAIL lines (`tests/Check.qml`). Add a test
when you change logic that has no UI.

## Adding things

- **A widget**: add it to `WidgetService`'s catalog and `isImplemented()`,
  give it a saved on/off field in `Config` and map it in `BarSettings`, make
  `pills/<Name>Pill.qml` (required `theme`, `edge`; `widthFactor`, `dockHot`
  like the others), map the id in `BarSlot`, and list the file in
  `pills/qmldir`.
- **A settings page**: add the fields to `Config`, a `<Feature>Settings`
  with a Draft, a `settings/<Feature>Tab.qml` with a `DraftFooter`, a Loader
  and tab entry in `SettingsPanel` (or a section in an existing tab), and a
  line in `SettingsSearch`.
- **A theme preset**: one line in `theme/ThemePresets.qml`. Use `colors`
  only where the preset should differ from what the builder derives.
- Sizes, colors, and intervals go in `Theme` (or come from the palette),
  never inline in a widget.
