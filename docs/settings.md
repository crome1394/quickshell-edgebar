# Settings

Open Settings from the spanner on the bar, or `qs ipc call settings open`.
The tabs along the bottom are colored index dividers (or flat chips; see
[Themes](themes.md#settings-window)).
Most pages have **Apply**, **Undo** (drop the draft, or put back the last
applied values), and **Reset** (draft the defaults) along the bottom.
Nothing on those pages is saved until Apply.

**Search**: the magnifier or `Ctrl+F`. Tab or ↓ moves into the results,
↑/↓ pick one, Enter opens it, Esc closes. Escape again closes Settings.

## Bar

- **Workspaces**: symbol, label, font, and size for each workspace number.
  Drag a row by `||` to move a face to another number. **Colors**: Theme
  (pills follow the theme, so they read on light and dark themes) or My
  colors (each workspace's label color, plus optional active pill, active
  text, idle text, and hover text colors; an empty swatch uses the theme).
- **Dock**: hover effect (Off, Magnify, Jump, Both), what it applies to,
  magnify amount, spread, jump height, running-app dot color.
- **Overview**: layout, strip, previews, motion, which workspaces appear,
  and input for the overview overlay.

## Widgets

- **Bars**: turn each edge on, align it, place widgets, auto-hide (H) and
  its delays. **Monitors**: bars on the main monitor (the default), every
  monitor, or monitors you pick, and which monitor is the main one (the
  Active Window popup and menus opened from a keybind go there). A menu
  opens on the monitor whose bar you clicked.
- **Active Window**: show it, corner, width, and classes to exclude.
- **System Stats**: font, bold, italic, size, bar graph width, the CPU,
  memory, GPU, and VRAM threshold steps and colors, and the click commands
  (run directly or in your terminal, never through a shell).

## Appearance

- **Theme**: presets, colors, fonts and text size, saved themes, import
  and export. See [Themes](themes.md).
- **Wallpaper**: a folder of images; click one to set it with hyprpaper.
  Rename (pencil) or delete (✕) files, and change the preview size.

## Applications

- **App Launcher**: one to four launchers on the left; **Installed apps**
  (search and pin) on the right, folding sideways to its title bar when
  you click it (remembered). The launcher columns use whatever width is
  left: two side by side when they fit, else one. **Custom** below pins a
  command. Drag `||` to reorder or move pins between launchers.
- **Application Menu**: the menu icon (a font symbol, or an SVG/PNG with an
  optional tint), its size and color, and the command a click runs.
- **FreshRSS**: server and reader options. See [FreshRSS](freshrss.md).

## Connectivity

- **Network**: what the pill shows (full IPv4, last octet, or adapter
  name) and the active connections.
- **Bluetooth**: scan length, adapter power, new devices, and paired
  devices.

## Audio

Scroll step, show percent, volume limit, meters on/off, the speaker and
microphone threshold steps and colors, and the live output and input
devices.

## Notifications

- **Server**:
  - **Auto** (the default) uses the notification daemon that is running
    (SwayNC, dunst, mako, …) and keeps the history; with none, the bar
    becomes the server itself. At start it waits a few seconds for a daemon
    launched at login before taking over.
  - **Built-in** always makes the bar the server: its own popups, Do Not
    Disturb, and history, with no extra processes. If another daemon holds
    notifications, the page names it and offers to stop it. To keep
    Built-in after a restart, don't start another daemon at login (see
    [Hyprland setup](hyprland.md#notifications)).

  The status line shows what is in use right now. History carries over
  when you switch.
- **Toasts**: popup corner and timeout (0 keeps a popup until dismissed).
- **History**: keep expanded, stagger row colors, clear at boot, show the
  counter.
- **Popups** (built-in server):
  - **Style**: Compact (one line), Standard, or Large (images big on top,
    more body text).
  - **Motion**: slide, fade, or none.
  - **Width**, **Shown at once**, **Icon size**, **Body lines**, **Edge
    gap**, and **Glass** (or the same as menus).
  - **Progress bar** for the time left (pauses while hovered), **Group by
    app** (one card with a +N count), **Big image previews** for
    screenshots and album art, and an **App color stripe**.
  - **App colors**: give an app its own color by the name shown on its
    popups.
  - **Send a test** shows a popup with the applied look.

## Region & Clock

- **Clock**: font, color, bold, italic, size, format, first day of the
  week, and which click opens the calendar.
- **Region**: pick a city on the map or search; Apply sets the system time
  zone. The map pictures come from GNOME and are GPL-2.0-or-later
  ([details](../assets/gnome-tz/README.md)).

## System

- **Dependencies**: checks every program, font, and service the bar uses
  and gives one `pacman -S` line for what is missing. The same list drives
  `scripts/install-deps.sh`.
- **Display**: resolution, refresh rate, and 8/10-bit color per monitor,
  from the modes the monitor reports. Apply closes Settings and tries the
  mode; a small window in the middle of that monitor asks **Keep** or **Go
  back** (Enter or Escape), and with no answer it goes back after 15
  seconds. Either way Settings reopens on Display with the mode in use
  selected. The resolution tiles size themselves to fill their column.
  **Arrangement** sits to the right, with its title down the left side:
  click the title bar to fold it sideways or open it (folded by default
  with one monitor). It shows the monitors to scale: drag one next to
  another and it snaps to the nearest side (left, right, above, below),
  edges lined up when close; Apply arrangement asks the same Keep or Go
  back. In a narrow window the open Arrangement drops below. Saving for good needs the marker described in
  [Hyprland setup](hyprland.md#display).
- **Transparency**: one opacity for every app, plus per-app overrides with
  focused and unfocused levels. Add an app from the open windows or by its
  class. The Settings and Inspector windows, Tack pins, and fullscreen
  windows always stay solid. Needs one line in your Hyprland config; see
  [Hyprland setup](hyprland.md#transparency).

## Tools

- **Capture**: setup for `~/.local/bin/capture-screenshot` and
  `~/.local/bin/ocr-region` (folder, editor, freeze, OCR languages, a
  program for OCR text). Apply writes `~/.config/hypr/capture.conf`. Your
  capture keybinds are listed read-only.
- **Recording**: the folder (Browse or Default), codec (AV1, the default:
  smallest files for the quality, encoded on the GPU; HEVC; H.264), MP4
  or MKV, quality, frame rate, audio (system, microphone, both, none), the
  cursor, what a left click records (focused monitor or a region), and a
  notification when saved. Uses `gpu-screen-recorder`.
- **Night Light**: on/off now, warmth (2500–6500 K), and an optional
  schedule (from – to, crossing midnight is fine; a click on the widget
  holds until the next switch). Uses `hyprsunset`.
- **Screensaver**: the program run after idle, idle time, whether it
  starts over fullscreen video, the look, and brightness. Needs
  `~/.local/bin/screensaver-config.sh`.

## Where settings are saved

- `state/bar-layout.json`: everything set in Settings.
- `state/theme.json`: the active theme, its fonts, and the stat and audio
  thresholds.
- `~/.local/state/quickshell/notification-history.json`: notification
  history (every server mode).
- `~/.config/freshrss-quickshell/freshrss.env`: the FreshRSS server.

`state/` is ignored by git.
