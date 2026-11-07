# Themes

**Settings → Theme** restyles the bar, its menus, and Settings at once.

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
colors only; your stat and audio thresholds stay.

## Simple edits

- **Tone**: Dark or Light
- **Colors**: accent (hovers, borders, active workspace), alert (errors,
  hot temperatures, weekdays), and tint (the glass color)
- **Bar glass** and **Menu glass**: how solid they are
- **CPU warm at / hot at**: the temperature steps in System Stats
- **Use derived colors**: drop a preset's own text colors and derive
  everything from the three colors above

Changing the accent also restyles hovers, borders, and the active
workspace, because those are derived from it.

## My themes, import, export

- **Save** stores the look under a name, together with your stat and audio
  thresholds and colors. ✕ on a card deletes it.
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
  "stats": { "cpu": { "t": [25, 50, 75], "c": ["#…", "#…", "#…", "#…"] } },
  "audio": { "t": [25, 50, 75], "c": ["#…", "#…", "#…", "#…"] }
}
```

Only `accent`, `alert`, and `tint` matter for a basic theme; everything
else has a default. Colors are `#rrggbb` or `#rrggbbaa` (alpha last).
`colors` can override any single palette entry (see
`theme/ThemeBuilder.qml` for the names).
