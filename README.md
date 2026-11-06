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

Each screen edge can show a bar. The widgets drawn today are workspaces, the clock, the settings button, the system tray, the power menu, transparency, network, Bluetooth, up to four app launchers, system stats, audio, notifications, and the active-window pill. Open Settings from the settings button. Network, Bluetooth, the app launchers, system stats, audio, and notifications stay off until you enable them under Widgets and press Apply. A magnifying glass to the left of the close button searches settings. Click it, or press Ctrl+F. Escape closes the search field first, then closes Settings.

- **Bar → Workspaces** sets the symbol, label, font, and size shown on each workspace number. Drag a row by `||` to move that face onto another number. Apply saves the faces. Hyprland's workspace order stays as it is.
- **Bar → Dock** sets the Mac-style hover. Effect is Off, Magnify, Jump, or Both. Apply to covers the Application Launcher, or every icon widget. Stats and volume stay still. Magnify amount, neighbor spread, and jump height are on that page, with the running-app dot color. Apply saves it. The bar keeps the last saved options until then.
- **Bar → Overview** sets the workspace overview: layout, strip, previews, motion, which workspaces appear, and input. Apply saves that page. The overlay is not a bar pill. Open it with `qs ipc call overview toggle`. `open` shows the workspace view. `desktop` shows windows in place. `all` shows every workspace. `next` and `prev` step cards. `close` dismisses it. The overlay loads only while it is open.
- **Widgets → Bars** turns each edge on, aligns it, and places widgets, including the clock, the system tray, the power menu, and transparency. Apply saves that page.
- **Widgets → Active Window** shows the focused window's icon, class, and title in a screen corner. The class name stays whole. The width in pixels sits between the − and + buttons. Apply saves the show switch, the corner, the width, and the excludes.
- **Region & Clock → Region** picks a city from the map or the search field. Apply region sits at the bottom of that page and sets the system time zone.
- **Region & Clock → Clock** sets the font, color, bold, italic, size, format, the first day of the week, and which click opens the calendar. The size sits between the − and + buttons. Apply saves that page. The calendar sits outside the bar. Its header shows the month, the arrows « ‹ › », and Today. The footer is one line.
- **Wallpaper** lists a folder of images and sets one with hyprpaper. The preview size is in pixels. A pencil renames a file, and ✕ deletes it.
- **Applications → App Launcher** keeps one to four app launchers. Each launcher is its own bar widget, and the bar shows its pinned icons together in one pill, with the same background as the other widgets. A hover paints a highlight on that icon. A slider sets how many exist. Installed apps can be searched and pinned, a custom command can be pinned, and a row moves by dragging `||`. Apply saves the count and the pins. On a left or right bar the icons turn 90° counter-clockwise so they stay upright. **Applications → Application Menu** puts an icon on the bar. The symbol is at most 3 characters. Color, bold, italic, and size sit on the same row as the font. A click runs the command you set. Apply saves that page.
- **Widgets → System Stats** shows CPU, memory, GPU, and VRAM on one pill. Each section has a bar, a percent, and a second value. Misc sets the pill font, bold, italic, and size. An empty font uses the bar font. Thresholds sets the CPU, memory, GPU, and VRAM steps. A color chip sits to the left of each step's buttons, and Above high sets the color past the last step. Apply stores those steps and colors in `theme/theme.json`. Reset returns that draft to the colors in `theme/DefaultTheme.qml`. CPU and Memory open btop. GPU and VRAM open nvtop. The widget stays off until you enable it under Bars and press Apply.
- **Connectivity** has Network and Bluetooth pages. Network chooses the address text on the pill (full IPv4, last octet, or adapter name) and lists active connections. Apply saves the address text. The connection list is a live read. Bluetooth sets how long a scan runs, then shows adapter power, devices that are not paired, and a Paired Devices section. Apply saves the scan length. Power, discovery, and connect still change immediately. The bar's Network menu is a left click. A connected Wi-Fi network stays at the top of the list. Connection editor, Refresh IP, and Flush DNS stay at the bottom. Right-click toggles Wi-Fi. The Bluetooth menu keeps Scan, Discoverable, and power at the bottom. Right-click toggles adapter power.
- **Audio** has On the bar, Thresholds, Output, and Input. On the bar sets the scroll step and whether the pill shows a percent. Thresholds sets the speaker and microphone color steps. A color chip sits to the left of each step's buttons. Apply stores the scroll step, the percent, and those steps and colors. The steps and colors go in `theme/theme.json`. Output and Input set the live device, mute, and volume. The bar pill shows a speaker, a level bar, a divider, a microphone, and a level bar. Both colors follow the level. Right-click mutes that side. The scroll wheel changes that side's volume and plays the same volume sound and swayOSD popup as the volume key. The pill stays off until you enable Audio under Widgets and press Apply.
- **Notifications** sets toast position and timeout, and the history options: keep expanded, stagger row colors, clear at boot, and show the counter. Apply saves that page and updates SwayNC when the corner or the timeout changes. The bell stays off until you enable Notifications under Widgets and press Apply. Left-click opens the history list beside the bar: under a top bar, over a bottom bar, and beside a side bar. Right-click toggles do not disturb. The badge counts saved messages. `qs ipc call notificationBell toggleHistory` opens that list while the shell is running. `showHistory`, `hideHistory`, and `toggleDoNotDisturb` are the other calls.
- **Transparency**, on the bar, overrides the Quickshell and Satty opacity numbers in `theme/DefaultTheme.qml`. Fullscreen windows and this Settings window stay solid.
- Bar tooltips open outside the bar: below a top widget, above a bottom widget, to the right of a left widget, and to the left of a right widget.
- **Applications → Application Menu** sets the menu icon: a symbol from a font, or an SVG or PNG image with an optional tint, plus its size, color, and the command a click runs.
- **System → Display** sets each monitor's resolution, refresh rate, and color depth from the modes the monitor reports. Apply tries the mode and asks you to keep it; with no answer in 15 seconds the old mode comes back. Keep saves to a monitors file only when it carries a `Managed by Quickshell` comment (`$XDG_CONFIG_HOME/hypr/config/monitors.lua` or `hypr/monitors.lua`); otherwise the change lasts until Hyprland restarts. A mode Hyprland will not keep at 10-bit is remembered and greyed out.
- The Settings search (magnifier or Ctrl+F) works from the keyboard: Tab or ↓ moves into the results, ↑/↓ pick one, Enter opens it, Tab goes back to the field, Esc closes.

Open Settings from a keybind or a script with `qs ipc call settings open`, `close`, or `toggle`. `qs ipc call settings openTab applications menu` jumps to a tab and section. Tab ids are `bar`, `widgets`, `wallpaper`, `applications`, `connectivity`, `audio`, `notifications`, `region`, and `system`; pass `""` for no section.

Settings are stored in `state/bar-layout.json`.

## License

MIT. See [LICENSE](LICENSE). The map pictures in `assets/gnome-tz` are GPL-2.0-or-later. See [assets/gnome-tz/README.md](assets/gnome-tz/README.md).
