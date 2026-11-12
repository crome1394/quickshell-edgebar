# Widgets

Each screen edge can have a bar. Turn widgets on and place them under
**Settings → Widgets → Bars**, then press Apply. A widget that is off is
not loaded at all. Tooltips open outside the bar, away from the edge.

| Widget | Shows | Click |
|---|---|---|
| **Workspaces** | Each workspace with its symbol, label, and font; theme colors or your own | Switch to it |
| **Clock** | Time in your format and font | Opens the calendar (the click is configurable) |
| **Config Menu Icon** | A spanner | Opens Settings |
| **System Tray** | App tray icons | As each app defines |
| **Power** | Power icon | Menu: Lock, Logout, Reboot, Shutdown |
| **Transparency** | Opacity icon | Menu with sliders (see below) |
| **Network** | Address or adapter name | Left: menu. Right: Wi-Fi on/off |
| **Bluetooth** | Icon, plus the lowest battery of connected devices | Left: menu. Right: adapter power |
| **App Launcher** (up to 4) | Your pinned apps in one pill | Launch; a dot marks running apps |
| **Application Menu** | A symbol or an SVG/PNG image | Runs your command |
| **System Stats** | CPU, memory, GPU, VRAM: bar, percent, second value. One pill, or one widget per metric (Widgets → System Stats → Combine into one widget). NVIDIA, AMD, or Intel (load estimated from the clock, no VRAM) | Each group runs a command (btop, nvtop by default) |
| **Audio** | Speaker and microphone levels. One pill, or separate Speaker and Microphone widgets (Audio → Combine into one widget) | Left: menu. Right: mute that side. Wheel: volume |
| **Notifications** | Bell with a count | Left: history. Right: do not disturb |
| **Tailscale** | The Tailscale mark (dim when off) | Left: menu. Right: on/off |
| **Inspector** | A search icon | Opens the [Inspector](inspector.md) |
| **FreshRSS** | Unread count | Opens the [reader](freshrss.md) |
| **Clipboard** | Clipboard icon (dim while no history is kept) | Opens the [clipboard viewer](clipboard.md) |
| **Caffeine** | A tea cup, filled while on | Left: keep the screen awake (no screensaver or idle lock). Right: 30 min → 1 h → 2 h → until off |
| **Night Light** | A moon | Left: on or off (needs `hyprsunset`). Right: menu with on/off, warmth, and schedule. Wheel: warmer or cooler |
| **Battery** (laptops) | Level glyph and percent; red when low, a bolt while charging | Left: next power profile. The tip shows time left and the profile |
| **Brightness** (laptops) | A sun | Wheel: brighter or dimmer. Left: 25, 50, 75, 100 % |
| **Firewall** | A shield, checked while on, crossed out in red while off | Left: menu with on/off, default policies, the rules, and Add a rule. Right: turn the firewall on or off. Changes ask for your password |
| **Screen Recorder** | A record button; a red mark and the time while recording | Left: record (focused monitor or a region, per Settings) or stop. Right: record a region. Middle: open the folder |

Caffeine holds a standard Wayland idle inhibitor, and the screensaver's
idle check also asks the bar, so it works even though the screensaver
ignores other apps' inhibitors (so tab video does not block it). Caffeine
wins over "Always start after idle" too.

**Active Window** is not a bar pill: it shows the focused window's icon,
class, and title in a screen corner (Widgets → Active Window).

## Menus

- **Audio**: Active Streams (each app's volume, mute, and level), Playback
  and Recording (device, sound profile, volume, left/right levels), and
  pw-top and Restart Audio at the bottom. Playback and Recording collapse
  to one line. Optional volume limit of 100%.
- **Network**: the connected Wi-Fi network on top, then the rest; Connection
  editor, Refresh IP, and Flush DNS at the bottom.
- **Bluetooth**: devices, Scan, Discoverable, and power. Pairing trusts and
  connects the device, so headsets reconnect on their own.
- **Night Light**: on/off, warmth (2500–6500 K, with − and +), and a schedule
  (from – to; crossing midnight is fine; a left click holds until the next
  switch). Same values as Settings → Tools → Night Light, saved at once.
  Escape or ✕ closes it.
- **Tailscale**: on/off, this device's addresses with copy buttons, exit
  node (searchable), options (DNS, subnet routes, Shields up, SSH, …), and
  the machines on the tailnet with Taildrop send. Checks every 30 seconds,
  every 3 while the menu is open.
- **Transparency**: glass (Bar and Menus), one slider for every app, and
  a slider per override with ✕ to remove it. The list scrolls when it is
  taller than the screen. Along the bottom, **Use theme** sets every app
  back to the theme default, and **Add override** (to its right) picks an
  open window. Changes save at once. Unfocused levels stay in Settings.
  See [Settings → Transparency](settings.md#system).
- **Notifications**: the history list beside the bar, with copy, dismiss,
  and clear.
- **Firewall** (UFW): on or off with a switch; the incoming, outgoing, and
  routed defaults; the rules (IPv4 and IPv6 copies shown once, with the
  rule's comment when it has one) with ✕ to
  delete; and Add a rule: Allow, Deny, or Limit (blocks an address that
  connects 6 times in 30 seconds, for SSH), TCP, UDP, or both, a port or
  range, and optionally where from. Reading needs no password (UFW's files
  are readable, and watched); every change runs `pkexec ufw …`, so your
  polkit agent asks.

## Bar behavior

- **Several monitors**: bars on the main monitor, every monitor, or the
  ones you pick (Widgets → Bars → Monitors). Each bar has the same widgets.
  A single bar can go on a monitor of its own with its **M** button.

- **Auto-hide** (the H chip on a bar in Widgets → Bars): the bar slides off
  its edge and gives the space back to windows. Touch the edge to bring it
  back. It stays out while hovered or while one of its menus is open.
- **Dock hover** (Bar → Dock): Mac-style magnify, jump, or both, on the app
  launchers or every icon widget.
- **Side bars** turn launcher icons 90° so they stay upright. A menu on a
  side bar opens on the screen side of the bar and is centered on the bar,
  so a tall menu stays on the monitor when its widget sits low. A menu on
  a top or bottom bar stays over its widget. Tooltips stay next to the icon.
- **Overview**: a workspace overview overlay, opened with
  `qs ipc call overview toggle` (see [IPC calls](ipc.md)). Set up under
  Bar → Overview.
