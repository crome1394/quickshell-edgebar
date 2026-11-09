# Themes

**Settings → Appearance → Theme** restyles the bar, its menus, and Settings at once.

## Presets

28 presets in four groups:

- **Liquid**: Liquid amber (the default), glass, mint, violet, rose, ice,
  aurora, Ink, Cocoa, Graphite
- **Classic**: Solid dark, Soft grey, Nordic frost, Warm ember, Deep ocean,
  Lavender dusk, Forest moss
- **Light**: Paper, Daylight, Mist, Blossom, Sage, Porcelain (solid, so
  dark text reads over any wallpaper)
- **New**: Midnight, Velvet, Dune, Evergreen, Copper

Click a card to preview it on the page, then **Apply**. Presets change
colors only; your fonts and stat and audio thresholds stay.

## Simple edits

- **Tone**: Dark or Light
- **Colors**: accent (hovers, borders, active workspace), alert (errors,
  hot temperatures, weekdays), and tint (the glass color)
- **Glass** is not part of a theme: bar and menu glass are set in
  System → Transparency and stay the same whichever theme you pick.
- **CPU warm at / hot at**: the temperature steps in System Stats
- **UI font** and **Bar font** (Default uses Inter and MesloLGS Nerd Font)
- **Text size**: 80 to 130%, for text and icons everywhere
- **Use derived colors**: drop a preset's own text colors and derive
  everything from the three colors above

Workspace pills follow the theme unless you choose My colors under Bar →
Workspaces → Colors.

## Settings window

The tabs along the bottom of Settings are **Index dividers** by default:
colored tabs hanging from the page like a binder's, the active one raised
with its color along the page edge. The section tabs along the top of a
page stand on it the same way, in shades of that page's divider color.
**Tab colors** are Rainbow (a fixed color per section) or From accent
(hues spread around the theme's accent). **Flat** gives plain chips in the
theme's colors at both levels. These save at once.

Changing the accent also restyles hovers, borders, and the active
workspace, because those are derived from it.

## My themes, import, export

- **Save** stores the look under a name, together with its fonts and your
  stat and audio thresholds and colors. ✕ on a card deletes it.
- **Export…** writes the look to a `.json` theme file.
- **Import…** reads a theme file from this bar or from the old bar (its
  `themes/*.json` or `state/theme-colors.json`) and adds it to My themes.

## From a keybind

```sh
qs ipc call theme apply "Nordic frost"   # a preset or a saved theme
qs ipc call theme list                   # every name
qs ipc call theme current                # the applied one
```

## Theme file format

```json
{
  "format": "quickshell-edgebar-theme",
  "version": 1,
  "name": "My theme",
  "tone": "dark",
  "accent": "#88c0d0",
  "alert": "#bf616a",
  "tint": "#1a1e26",
  "glass": 62,
  "menu": 92,
  "colors": { "colWeekday": "#b48ead" },
  "temp": { "warmAt": 70, "hotAt": 85 },
  "fonts": { "ui": "Inter", "bar": "", "size": 100 },
  "stats": { "cpu": { "t": [25, 50, 75], "c": ["#…", "#…", "#…", "#…"] } },
  "audio": { "t": [25, 50, 75], "c": ["#…", "#…", "#…", "#…"] }
}
```

Only `accent`, `alert`, and `tint` matter for a basic theme; everything
else has a default. `glass` and `menu` are read from older files but not
used: glass is set in System → Transparency. Colors are `#rrggbb` or `#rrggbbaa` (alpha last).
`colors` can override any single palette entry (see
`theme/ThemeBuilder.qml` for the names).
