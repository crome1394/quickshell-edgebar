# Changelog

## 0.1.4 — 2026-11-05

- The Mac-style dock hover now covers every bar widget. Clock and Audio grow as one pill; System Stats grows only the section under the pointer.
- `config/Config.qml` is split by feature: it went from 3,735 to about 550 lines and now holds only the saved store, the save timer, shared validators, and the shell IPC target. Bluetooth, Network, Notifications, Active Window, Application Menu, Clock, Audio, System Stats, Dock, Overview, App Launcher, Opacity, Wallpaper, Workspaces, and the bar widget flags each have a `*Settings.qml` singleton in `config/`.
- Every settings page uses one shared draft (`config/Draft.qml`) for Apply, Undo, and Reset. Reading a draft never writes, so a binding cannot undo an edit.
- `state/bar-layout.json` keeps the same fields, so saved settings carry over.
- About 45 unused functions are gone. One table maps bar widgets to their saved flags.

## 0.1.3 — 2026-11-05

- Applications → App Launcher: dragging a pin onto another launcher works. A first edit on a clean page was undone as the page redrew.
- Applications → App Launcher: Installed apps shows 80 at a time with a Show more button, so the whole list is reachable.
- System Stats reads CPU, memory, and CPU temperature from `/proc` and `/sys`, and keeps one `nvidia-smi` running in loop mode for the GPU. `scripts/bar-stats.sh` is gone.
- The notification bell follows `swaync-client --subscribe` instead of polling every few seconds. `scripts/notification-sync.sh` is gone.
- The network menu reads link speed from `/sys/class/net` instead of running a script.
- A bar edge that is turned off is not created, so its widgets do not load.
- The clock ticks on the second only when its format shows seconds, otherwise on the minute.
- Workspaces follow window moves, renames, and Hyprland config reloads from events. The background check runs once a minute.
- The notification watcher and its `dbus-monitor` exit with the bar instead of outliving a reload.
- Scripts save through a unique temp file, flushed and renamed. Icon paths with `#`, `%`, or spaces load.
- Timer intervals come from `Theme`. Icon lookup is shared through `IconService`.

## 0.1.2 — 2026-11-05

- Widgets → System Stats drafts the pill font, bold, italic, and size with the other System Stats options. An empty font uses the bar font. Apply saves them.
- Widgets → System Stats adds Thresholds for CPU, Memory, GPU, and VRAM. Each step has a color chip to the left of the buttons, and Above high sets the color past the last step. Apply stores the steps and colors in `theme/theme.json`. Reset returns the draft to `theme/DefaultTheme.qml`.
- Settings search sits to the left of the close button. Click the magnifying glass, or press Ctrl+F. Escape closes the search field before it closes Settings. A result opens that settings page.
- Audio is a bar pill: speaker, level bar, divider, microphone, level bar. The speaker and microphone colors follow the level. Right-click mutes that side. The scroll wheel changes that side's volume from the current level, plays the volume sound, and shows swayOSD. Settings → Audio has On the bar, Thresholds, Output, and Input. Thresholds sets the shared steps and colors, with a color chip to the left of the buttons. Apply stores those steps and colors in `theme/theme.json`. Scroll step and Show percent wait for Apply. Device volume, mute, and the default device stay live. The pill stays off until Widgets → Apply.
- Settings → Bar → Dock sets the hover effect: Off, Magnify, Jump, or Both. Apply to is the Application Launcher or every icon widget. Stats and volume stay still. Magnify amount, neighbor spread, jump height, and the running-app dot color are on that page. Apply saves them. The bar keeps the last saved options until then.
- Notifications is a bottom settings tab. Toasts sets the SwayNC corner and how long a popup stays. History sets keep expanded, stagger, clear at boot, and the counter. Apply writes the corner and the timeout into the SwayNC config when either value changes. The bell stays off until Widgets → Apply. Left-click opens history outside the bar: under a top bar, over a bottom bar, and beside a side bar. Right-click toggles do not disturb. The badge is the saved history length. `qs ipc call notificationBell toggleHistory`, `showHistory`, `hideHistory`, and `toggleDoNotDisturb` work while the shell is running. The history watcher runs only while the bell is on the bar or the history window is open.

## 0.1.1 — 2026-11-05

- Widgets → Active Window, Widgets → System Stats, Connectivity → Network, and Connectivity → Bluetooth pin Apply, Undo, and Reset along the bottom. Each page keeps a draft until Apply. The pills keep the last saved options.
- Active Window drafts the show switch, the corner, the width, and the excludes. System Stats drafts which sections are drawn, the bars, the terminal, and the click. Turning that pill on stays on Widgets → Bars.
- Network drafts full IP, the last octet, and the device name. The connection list still reads NetworkManager when the page opens or Refresh is pressed. Bluetooth drafts the scan length. Adapter power, discovery, and device connect still change immediately.
- Bar → Overview holds the overview layout, strip, previews, motion, workspaces, and input, with the same Apply, Undo, and Reset footer.
- The workspace overview opens from IPC: `qs ipc call overview toggle`, `open`, `desktop`, `all`, `next`, `prev`, and `close`. It is not a bar pill. The overlay loads only while it is open. With dynamic workspaces, Hide emptied workspaces drops empty cards that are not persistent slots.

## 0.1.0 — 2026-11-04

- Bars on the top, bottom, left, and right edges.
- Workspace pills with per-number symbols, labels, fonts, and sizes.
- Settings button that opens the settings window.
- Widget placement across the four edges, with apply and undo.
- Active-window pill in a screen corner. The width cap cuts a long title, and the class name stays whole. Excludes are marked class or title.
- Clock on the bar. Region & Clock → Clock uses Apply and Undo for the face, the week start, and which click opens the calendar. The calendar sits outside the bar, and the weekday letters are red. Apply region is pinned under the map. The map pictures in `assets/gnome-tz` are GPL-2.0-or-later.
- Every settings slider has decrease and increase buttons beside the track.
- System tray, power menu, and a transparency menu on the bar. Transparency defaults live in `theme/DefaultTheme.qml`.
- Settings pages for Wallpaper, Applications, Connectivity, and Audio.
- Calendar header arrows, a wider workspace font field, and the clock size slider beside the italic button.
- Bar tooltips sit outside the bar. Wallpaper previews resize, and each image can be renamed or deleted. Connectivity is split into Network and Bluetooth. Audio output and input sit side by side. The clock size is shown between its − and + buttons.
- Transparency's Quickshell slider writes Hyprland rules with Lua long strings, so a window class with a dot does not abort the rule file.
- Network and Bluetooth are bar widgets. Left click opens the menu. Right click toggles Wi-Fi or adapter power. Connectivity → Network sets the address text on the pill. Connectivity → Bluetooth sets the scan length. The active-window width sits between the − and + buttons. Close special on startup sits in the left column of Workspace options.
- The network pill shows the IPv4 address, so full IP and the last octet follow that address. A connected Wi-Fi network stays at the top of the list. Network details open from a control on the right. Connection editor, Refresh IP, and Flush DNS stay at the bottom of the network menu, and the list scrolls beside them. Scan, Discoverable, and power stay at the bottom of the Bluetooth menu. BT · Audio is no longer in the widget list.
- The calendar popup is wide enough for the month, the arrows « ‹ › », and Today. The footer is one wrapping line.
- Connectivity → Bluetooth lists paired devices under Paired Devices. Other known devices stay in the Bluetooth section.
- The bar, widgets, and Settings use the Liquid Amber palette: warm translucent glass, amber accent, and rose for warnings and weekday letters.
- Applications → App Launcher and Applications → Application Menu keep Apply, Undo, and Reset along the bottom. Application Menu is a bar icon. Its symbol, font, size, bold, italic, color, and command are saved with Apply. Color, bold, italic, and size sit on the font row. A click runs that command. The Application Menu widget is not drawn until you enable it under Widgets and press Apply.
- Widgets → System Stats draws CPU, memory, GPU, and VRAM on one pill. Threshold colors live in the theme. Show toggles, the bar graphs, the terminal, and the click side apply immediately. CPU and Memory open btop. GPU and VRAM open nvtop. The pill polls about every two seconds, and only while it is on the bar. The widget stays off until you enable it under Bars and press Apply.
- Applications → App Launcher keeps up to four app launchers, a search of installed apps, custom commands, and drag-and-drop pins. Each launcher can sit on its own bar edge, and an empty launcher draws nothing. Pinned icons share one pill, with the same background as the other widgets, and a hover paints a highlight on that icon. On a left or right bar the icons turn 90° counter-clockwise so they stay upright. The Application Menu widget is not drawn.
