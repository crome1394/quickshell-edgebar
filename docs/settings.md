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
  opens on the monitor whose bar you clicked. **M** (left of L/C/R on each
  bar) puts that one bar on a monitor of its own, or back on every bar
  monitor; while its monitor is unplugged it shows on the main monitor.
  Apply saves it.
- **Active Window**: show it, corner, width, and classes to exclude.
  **Other** and **Layout** sit side by side. **Overrides** are below them.
  The pattern uses the words `icon`, `class`, `title`, and `pid`, with
  marks around a word drawn around that part (`icon [class] title (pid)`).
  Set keeps the pattern, and a preview shows it. Each layout row has a
  switch. Drag a row by || to reorder it. The first row is the leftmost.
  A part that is off, or that has nothing to show, is skipped.
- **System Stats**: one combined pill, or (with **Combine into one
  widget** off) CPU, Memory, GPU, and VRAM as separate widgets you turn on
  and place under Bars; which graphics card to read (Auto: the only one, or
  on a laptop the integrated one, so the discrete GPU can sleep; NVIDIA
  via `nvidia-smi`, AMD from `/sys`, Intel estimated from its clock), bar
  graph width, **Text Style** (pick All widgets or one metric, and Label,
  Percent, or Value, then font, bold, italic, size, and color; a metric
  follows All for anything it does not set, and **Use All** drops its own
  settings; Auto colors follow the theme, a picked color stays fixed), the threshold steps and colors
  (pick CPU, Memory, GPU, or VRAM from the Thresholds list), and the click commands
  (run directly or in your terminal, never through a shell).

## Appearance

- **Theme**: presets, colors, fonts and text size, saved themes, import
  and export. See [Themes](themes.md).
- **Wallpaper** (kept apart from the theme; switching themes never
  changes it):
  - **Monitor**: pick a monitor, see its wallpaper, and set its fit
    (Cover, Contain, Center, Fill). Each monitor keeps its own wallpaper and
    fit in `state/wallpapers.json`; setting one leaves the others alone.
    Wallpapers are set with awww; `awww-daemon` must be running.
  - **Wallpaper**: a folder of images; click one to set it on the monitor
    picked above. Rename (pencil) or delete (✕) files, and change the
    preview size.
  - **Picker**: the Ctrl+Super+Space strip (`qs ipc call wallpaper
    toggle`) on the focused monitor. ← → move, type to filter, Enter or a
    click sets it, Esc puts the old one back. **Live preview** shows each
    image as you rest on it (after **Preview after**, in ms); only Enter
    saves. Also **Thumbnail size**, **Close after setting**, and buttons for
    Previous and Next.

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

**Combine into one widget** (on by default; off makes Speaker and
Microphone separate widgets to turn on and place under Widgets → Bars,
each opening the audio menu from where it sits), scroll step, show
percent, volume limit, meters on/off, the speaker and
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

### On-Screen Display

Settings → Notifications → On-Screen Display. A popup for volume,
microphone, media, and brightness that replaces swayosd. Any change shows
it: your keys, the bar's own sliders, or another app. It watches PipeWire
and MPRIS by their change signals (nothing polls), and its window exists
only while it shows; clicks pass through it.

- **Show it for**: Volume (speaker level and mute, with the sound),
  Output device (the name of a new speaker or headset), Microphone,
  New track (title, artist, cover), Play and pause, and Brightness
  (laptops, when it changes through the bar). **Preview** buttons show
  the unsaved look.
- **Place and size**: top, middle, or bottom; left, center, or right;
  edge gap, width, how long it stays, and text size.
- **Look**: glass (or the same as menus), bar and text colors (Auto
  follows the theme; a picked color stays fixed in every theme), border,
  and cover art for media.
- **Symbols**: pick one (volume high, medium, low, muted, device,
  microphone, play, pause, track, brightness) and type its replacement,
  such as another Nerd Font glyph or an emoji. **Default** puts it back.
- **Sound**: the theme's volume-change sound (`canberra-gtk-play`), a sound
  file of your own (`pw-play`), or off, with its own volume and a **Test**
  button. It plays at most once every 120 ms, so held keys do not pile up.

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
  back. A green line marks where two monitors touch, and the text below
  says how long it is: the pointer can cross only there, so a shorter
  monitor beside a taller one leaves part of the taller one's edge closed.
- **Turn off / Turn on** (in Display, for the monitor picked at the top):
  stop using a second screen, as if it were unplugged, for a TV or
  monitor you use for other things. Its windows move to the other
  monitors and the pointer cannot go there. It stays off after a restart
  (written as disabled in the monitors file). Turning it on brings back
  its mode, place, and the workspaces that were on it. The main monitor
  and the last one on stay on. For a key: `qs ipc call display toggle`
  (every monitor but the main one).
- **Edges** (in Display, for the monitor picked at the top): for a TV that
  crops the edges of the picture (overscan). Best fixed on the TV itself
  (often Picture Size → Fit to Screen, or Just Scan, sometimes only with
  the input set to PC). Otherwise set how much to keep clear, on all edges
  or each one; **Show guide** draws a green frame on that monitor to match
  against what the TV shows, and **None** uses the whole screen again. The
  bars, popups, and windows on that monitor stay inside. It is plain
  window placement (invisible layer-shell strips), so it works on any
  computer and graphics card. Saves at once. In a narrow window the open Arrangement drops below. Saving for good needs the marker described in
  [Hyprland setup](hyprland.md#display).
- **Transparency**: the one place for everything see-through. The bar's
  Transparency menu sets the same bar glass, menu glass, all-applications
  level, and overrides, and saves at once. Unfocused levels are edited here.
  **Bar and menus**: **Bar glass** (All bars, or one bar with its own
  value; pills are a little more solid) and **Menu glass** (menus,
  Settings, the Inspector, readers, the clipboard viewer, the wallpaper
  picker, and popups that follow menu glass). They are the same for every
  theme. **Applications**: one opacity for every app, plus per-app overrides with
  focused and unfocused levels. Add an app from the open windows or by its
  class. The Settings and Inspector windows and Tack pins always stay
  solid. Needs one line in your Hyprland config; see
  [Hyprland setup](hyprland.md#transparency).
  Fullscreen windows are solid (so video and games are never see-through);
  an override's **Fullscreen: Same as windowed** keeps its own level
  fullscreen too, so a see-through terminal looks equally bright either
  way.

## Tools

- **Capture**: setup for `~/.local/bin/capture-screenshot` and
  `~/.local/bin/ocr-region` (folder, editor, freeze, OCR languages, a
  program for OCR text). Apply writes `~/.config/hypr/capture.conf`. Your
  capture keybinds are listed read-only.
- **Recording**: the folder (Browse or Default), codec (Auto, the default:
  the best one this GPU encodes in hardware, AV1, else HEVC, else H.264;
  the page lists what the GPU supports and marks the rest ✕), MP4
  or MKV, quality, frame rate, audio (system, microphone, both, none), the
  cursor, what a left click records (focused monitor or a region), and a
  notification when saved. Uses `gpu-screen-recorder`.
- **Night Light**: on/off now, warmth (2500–6500 K), and an optional
  schedule (from – to, crossing midnight is fine; a click on the widget
  holds until the next switch). Uses `hyprsunset`. The widget's right-click
  menu sets the same things and saves at once.
- **Screensaver**: the program run after idle, idle time, whether it
  starts over fullscreen video, the look, and brightness (dimming uses
  DDC/CI, for external monitors). The video defaults to
  `~/Videos/screensaver/screensaver.mp4`; until you add one, the text
  screensaver (in kitty) runs instead. Needs
  `~/.local/bin/screensaver-config.sh`.

## Where settings are saved

- `state/bar-layout.json`: everything set in Settings.
- `state/theme.json`: the active theme, its fonts, and the stat and audio
  thresholds.
- `~/.local/state/quickshell/notification-history.json`: notification
  history (every server mode).
- `~/.config/freshrss-quickshell/freshrss.env`: the FreshRSS server.

`state/` is ignored by git.
