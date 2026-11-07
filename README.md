# Quickshell bar

A Hyprland bar for [Quickshell](https://quickshell.org/) on Wayland.

## Requirements

- Quickshell 0.3.2 or newer
- Hyprland

## Run

This directory is the Quickshell config. Start it with:

```
qs -p /path/to/this/directory
```

Quickshell also loads `~/.config/quickshell` when you run `qs` with no path.

## Bar

Each screen edge can show a bar. The widgets drawn today are workspaces, the clock, the settings button, the system tray, the power menu, transparency, network, Bluetooth, up to four app launchers, system stats, audio, notifications, Tailscale, the Inspector, FreshRSS, and the active-window pill. Open Settings from the settings button. Network, Bluetooth, the app launchers, system stats, audio, and notifications stay off until you enable them under Widgets and press Apply. A magnifying glass to the left of the close button searches settings. Click it, or press Ctrl+F. Escape closes the search field first, then closes Settings.

- **Bar → Workspaces** sets the symbol, label, font, and size shown on each workspace number. Drag a row by `||` to move that face onto another number. Apply saves the faces. Hyprland's workspace order stays as it is.
- **Bar → Dock** sets the Mac-style hover. Effect is Off, Magnify, Jump, or Both. Apply to covers the Application Launcher, or every icon widget. Stats and volume stay still. Magnify amount, neighbor spread, and jump height are on that page, with the running-app dot color. Apply saves it. The bar keeps the last saved options until then.
- **Bar → Overview** sets the workspace overview: layout, strip, previews, motion, which workspaces appear, and input. Apply saves that page. The overlay is not a bar pill. Open it with `qs ipc call overview toggle`. `open` shows the workspace view. `desktop` shows windows in place. `all` shows every workspace. `next` and `prev` step cards. `close` dismisses it. The overlay loads only while it is open.
- **Widgets → Bars** turns each edge on, aligns it, and places widgets, including the clock, the system tray, the power menu, and transparency. Apply saves that page.
- **Widgets → Bars → H** turns auto-hide on for that bar. A hidden bar slides off its edge and gives its space back to windows; touch the edge to bring it back. It stays out while you hover it or one of its menus is open. The Auto-hide section on the same page sets how long it waits before hiding and before showing. Apply saves it with the rest of the page.
- **Widgets → Active Window** shows the focused window's icon, class, and title in a screen corner. The class name stays whole. The width in pixels sits between the − and + buttons. Apply saves the show switch, the corner, the width, and the excludes.
- **Region & Clock → Region** picks a city from the map or the search field. Apply region sits at the bottom of that page and sets the system time zone.
- **Region & Clock → Clock** sets the font, color, bold, italic, size, format, the first day of the week, and which click opens the calendar. The size sits between the − and + buttons. Apply saves that page. The calendar sits outside the bar. Its header shows the month, the arrows « ‹ › », and Today. The footer is one line.
- **Wallpaper** lists a folder of images and sets one with hyprpaper. The preview size is in pixels. A pencil renames a file, and ✕ deletes it.
- **Theme** restyles the bar, its menus, and Settings. Pick one of 28 presets: the old bar's Liquid, Classic, and Light themes, adapted, plus five new ones. Then adjust it: Dark or Light tone, the accent, alert, and tint colors, how solid the bar and menus are, and the CPU temperature steps. Apply makes it live; Undo and Reset (Liquid amber) work as on other pages. Presets change colors only, so your stat and audio thresholds stay. **My themes** saves the look under a name together with your stat and audio thresholds and colors; ✕ on a card deletes it. **Export…** writes a theme file and **Import…** reads one, either from this bar or from the old bar (`themes/*.json` or `state/theme-colors.json`), and adds it to My themes. Switch themes from a keybind with `qs ipc call theme apply "Nordic frost"`; `qs ipc call theme list` prints every name and `current` the applied one.
- **Applications → App Launcher** keeps one to four app launchers. Each launcher is its own bar widget, and the bar shows its pinned icons together in one pill, with the same background as the other widgets. A hover paints a highlight on that icon. A slider sets how many exist. Installed apps can be searched and pinned, a custom command can be pinned, and a row moves by dragging `||`. Apply saves the count and the pins. On a left or right bar the icons turn 90° counter-clockwise so they stay upright. **Applications → Application Menu** puts an icon on the bar. The symbol is at most 3 characters. Color, bold, italic, and size sit on the same row as the font. A click runs the command you set. Apply saves that page.
- **Widgets → System Stats** shows CPU, memory, GPU, and VRAM on one pill. Each section has a bar, a percent, and a second value. Misc sets the pill font, bold, italic, and size. An empty font uses the bar font. Thresholds sets the CPU, memory, GPU, and VRAM steps. A color chip sits to the left of each step's buttons, and Above high sets the color past the last step. Apply stores those steps and colors in `state/theme.json`. Reset returns that draft to the colors in `theme/DefaultTheme.qml`. CPU and Memory open btop. GPU and VRAM open nvtop. The widget stays off until you enable it under Bars and press Apply.
- **Connectivity** has Network and Bluetooth pages. Network chooses the address text on the pill (full IPv4, last octet, or adapter name) and lists active connections. Apply saves the address text. The connection list is a live read. Bluetooth sets how long a scan runs, then shows adapter power, devices that are not paired, and a Paired Devices section. Apply saves the scan length. Power, discovery, and connect still change immediately. The bar's Network menu is a left click. A connected Wi-Fi network stays at the top of the list. Connection editor, Refresh IP, and Flush DNS stay at the bottom. Right-click toggles Wi-Fi. The Bluetooth menu keeps Scan, Discoverable, and power at the bottom. Right-click toggles adapter power.
- **Audio** has On the bar, Thresholds, Output, and Input. On the bar sets the scroll step and whether the pill shows a percent. Thresholds sets the speaker and microphone color steps. A color chip sits to the left of each step's buttons. Apply stores the scroll step, the percent, and those steps and colors. The steps and colors go in `state/theme.json`. Output and Input set the live device, mute, and volume. The bar pill shows a speaker, a level bar, a divider, a microphone, and a level bar. Both colors follow the level. Right-click mutes that side. The scroll wheel changes that side's volume and plays the same volume sound and swayOSD popup as the volume key. The pill stays off until you enable Audio under Widgets and press Apply.
- **Notifications** sets toast position and timeout, and the history options: keep expanded, stagger row colors, clear at boot, and show the counter. Apply saves that page and updates SwayNC when the corner or the timeout changes. The bell stays off until you enable Notifications under Widgets and press Apply. Left-click opens the history list beside the bar: under a top bar, over a bottom bar, and beside a side bar. Right-click toggles do not disturb. The badge counts saved messages. `qs ipc call notificationBell toggleHistory` opens that list while the shell is running. `showHistory`, `hideHistory`, and `toggleDoNotDisturb` are the other calls.
- **System → Transparency** sets one opacity for every application and per-application overrides, each with a focused and an unfocused level. Add an app from the open windows or by typing its window class (as `hyprctl clients` shows it). The Transparency pill on the bar has quick sliders for All applications and each override, a ✕ beside each override to remove it, and Add override to pick from the open windows. Its changes save at once. `qs ipc call opacityMenu toggle`, `open`, or `close` opens the menu while the pill is on the bar. Fullscreen windows, Tack pins, and the Settings and Inspector windows always stay solid. The default All applications level is `opacityQuickshell` in `theme/DefaultTheme.qml`.
- **Applications → FreshRSS** connects a [FreshRSS](https://freshrss.org/) server: address, user, and the API password from FreshRSS Profile → API password (not the login password). Test logs in without saving; Save server writes `~/.config/freshrss-quickshell/freshrss.env` (mode 600, outside git; the file is read as text, never run). The Reader section sets how often the unread count is checked (only while the pill is on a bar or the reader is open), max days, articles per feed, max items, and whether Filters start open. Turn the widget on under Widgets. The pill shows the unread count; a click opens the reader window: date chips (All dates, Today, 7 days), scope (Unread, All, Read, Starred), type (Any, Video), Collapse/Expand all, and Filters (search, max days, per feed or max items). Feeds are listed A–Z with their unread count; open one for its days and articles. The right pane shows the article (images become links, so nothing loads from the network) with Open in browser, Copy link, Play in mpv (video only; YouTube needs `yt-dlp`), Mark read, Star, and Mark feed read/unread. Keys, when not typing in search: `w`/`s` or `↑`/`↓` move, `Space`/`a`/`←` open or close a feed or day, `Enter`/`d`/`→` open, `j`/`k` next/previous article, `/` or `Ctrl+F` search, `b` browser, `c` copy link, `v` mpv, `m` read/unread, `Shift+S` star, `Shift+R`/`Shift+U` feed read/unread, `r` or `Ctrl+R` reload, `Esc` leaves search, clears it, then closes. Double-click an article to play its video or open it. `qs ipc call freshRss toggle`, `open`, `close`, and `refresh` work from a keybind, for example `hl.bind("SUPER + R", hl.dsp.exec_cmd("qs ipc call freshRss toggle"))`.
- Bar tooltips open outside the bar: below a top widget, above a bottom widget, to the right of a left widget, and to the left of a right widget.
- **Applications → Application Menu** sets the menu icon: a symbol from a font, or an SVG or PNG image with an optional tint, plus its size, color, and the command a click runs.
- **System → Display** sets each monitor's resolution, refresh rate, and color depth from the modes the monitor reports. Apply tries the mode and asks you to keep it; with no answer in 15 seconds the old mode comes back. Keep saves to a monitors file only when it carries a `Managed by Quickshell` comment (`$XDG_CONFIG_HOME/hypr/config/monitors.lua` or `hypr/monitors.lua`); otherwise the change lasts until Hyprland restarts. A mode Hyprland will not keep at 10-bit is remembered and greyed out.
- **Tools → Capture** sets up `~/.local/bin/capture-screenshot` and `~/.local/bin/ocr-region`: the screenshot folder and editor, freezing the screen while you select, OCR languages, and a program that receives OCR text. Apply writes `~/.config/hypr/capture.conf`, which both scripts read on every run. The capture keybinds from your Hyprland config are listed there, read-only.
- **Tools → Screensaver** picks the program that runs after idle, the idle time, and whether it starts even over fullscreen video and idle-inhibits. The Look and Brightness sections drive the built-in `screensaver.sh`. The page needs `~/.local/bin/screensaver-config.sh`, which saves `~/.config/hypr/screensaver.conf` and the hypridle listener. The program is run as `<program> start` and `<program> stop`.
- **System → Dependencies** checks every program, font, and service in `config/dependencies.json`. `scripts/install-deps.sh` reads the same list, installs missing packages with pacman (or an AUR helper for the rest), and enables and starts stopped services with `systemctl`. It asks before each step; `--dry-run` only looks, `--required` skips optional items, `--yes` skips the questions.
- The Settings search (magnifier or Ctrl+F) works from the keyboard: Tab or ↓ moves into the results, ↑/↓ pick one, Enter opens it, Tab goes back to the field, Esc closes.

Open Settings from a keybind or a script with `qs ipc call settings open`, `close`, or `toggle`. `qs ipc call settings openTab applications menu` jumps to a tab and section. Tab ids are `bar`, `widgets`, `wallpaper`, `theme`, `applications`, `connectivity`, `audio`, `notifications`, `region`, `system`, and `tools`; pass `""` for no section.

Settings are stored in `state/bar-layout.json`. The active theme and the stat and audio thresholds are in `state/theme.json` (older versions kept the thresholds in `theme/theme.json`; they are copied over on first start). See [ARCHITECTURE.md](ARCHITECTURE.md) for how the code is laid out.

## Inspector

A floating window titled `Inspector` with two tabs. Open it from the Inspector widget on the bar (turn it on under Widgets), with `qs ipc call inspector toggle` (bind it to a key, for example `hl.bind("SUPER + SLASH", hl.dsp.exec_cmd("qs ipc call inspector toggle"))`), or a tab directly with `qs ipc call inspector openTab bindings|system`. It exists only while open.

- **Bindings** lists `hl.bind(...)` lines from `$XDG_CONFIG_HOME/hypr/config/keybindings.lua` (or `hypr/hyprland.lua`) that end in a `--#` description, grouped by `--#Category# description`. Commented-out binds are skipped, and the list updates when the file changes. Groups collapse from their titles. Click a binding to run it (the Inspector closes first, so it acts on the window you had focused); right-click copies its keys.
- **System Info** shows `fastfetch` output as rows; click a row to copy its value. fastfetch runs when the tab opens and on Refresh (bottom right, with Copy all).

The search box (Ctrl+F) filters the open tab, Escape clears it or closes the window, and Ctrl+Tab switches tabs. To size or place the window, match the title in a window rule: `match = { title = "^(Inspector)$", class = "^(org.quickshell)$" }`.

## License

MIT. See [LICENSE](LICENSE). The map pictures in `assets/gnome-tz` are GPL-2.0-or-later. See [assets/gnome-tz/README.md](assets/gnome-tz/README.md).

## Hyprland setup

The bar changes two Hyprland files and reloads them live. Neither needs editing by hand.

**Transparency: `$XDG_CONFIG_HOME/hypr/opacity.lua`** (usually `~/.config/hypr/opacity.lua`). The bar rewrites it on every change and swaps the live rules with `hyprctl repl`. Hyprland only reads it at startup if `hyprland.lua` loads it. Put this line last, after your own window rules, so the bar's levels win:

```lua
-- Quickshell transparency. Last so these named rules win.
require("opacity")
```

The rules use `override`, so while All applications is below 100% it replaces opacity from your own rules (for example HyprGlass's `opacity = 0.90`). To keep an app at its own level, add it as an override. The file `opacity.state` and `opacity.lock` next to it came from the old `scripts/opacity.py`; nothing reads them now, and they can be deleted.

**Display: a monitors file with the `Managed by Quickshell` marker.** System → Display saves a kept mode only to `$XDG_CONFIG_HOME/hypr/config/monitors.lua` or `$XDG_CONFIG_HOME/hypr/monitors.lua`, and only when that file already contains the comment `-- Managed by Quickshell`. Load it from `hyprland.lua`, for example `require("config.monitors")`. Without it, display changes last until Hyprland restarts.

New files the bar adds are picked up by a full restart of the bar (`qs kill; qs -d -n`), not always by a hot reload.

