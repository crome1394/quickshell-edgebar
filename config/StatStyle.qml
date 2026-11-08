pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Text style rules for System Stats (Widgets → System Stats → Text Style).
//
// A style is { all: { label, percent, value }, cpu: {...}, mem: {...},
// gpu: {...}, vram: {...} }. Each part under `all` is complete:
// { font, bold, italic, size, color }. Each part under a metric holds only
// the fields that metric overrides; the rest follow `all`.
//
// font "" is the bar font. size is a percent of the bar text size. color
// is "auto" (the theme's color: text for labels, temperature steps for a
// temperature) or "#rrggbb". Percent text always takes its threshold
// color, so its color field is kept at "auto".
Singleton {
    id: root

    readonly property var targets: ["all", "cpu", "mem", "gpu", "vram"]
    readonly property var parts: ["label", "percent", "value"]
    readonly property var fields: ["font", "bold", "italic", "size", "color"]

    function fieldNorm(field, value) {
        if (field === "font")
            return Config.fontClamp(value)
        if (field === "bold" || field === "italic")
            return !!value
        if (field === "size")
            return Config.fontPercentNorm(value)
        // A name Qt cannot read throws; it falls back to auto.
        let hex = ""
        if (String(value) !== "auto") {
            try {
                hex = ThemeStore.colorHex(value)
            } catch (e) {
                hex = ""
            }
        }
        return hex.length ? hex : "auto"
    }

    // One part. With fill, every field is present (missing ones from fill);
    // without, only the fields raw has.
    function partNorm(raw, part, fill) {
        const src = raw && typeof raw === "object" ? raw : {}
        const out = {}
        for (let i = 0; i < root.fields.length; i++) {
            const field = root.fields[i]
            if (src[field] !== undefined)
                out[field] = root.fieldNorm(field, src[field])
            else if (fill)
                out[field] = fill[field]
        }
        if (part === "percent" && out.color !== undefined)
            out.color = "auto"
        return out
    }

    // base fills any field `all` is missing, e.g. from older settings.
    function norm(raw, base) {
        const src = raw && typeof raw === "object" ? raw : {}
        const out = {}
        for (let t = 0; t < root.targets.length; t++) {
            const target = root.targets[t]
            const from = src[target] && typeof src[target] === "object" ? src[target] : {}
            const parts = {}
            for (let p = 0; p < root.parts.length; p++) {
                const part = root.parts[p]
                parts[part] = root.partNorm(from[part], part, target === "all" ? base : null)
            }
            out[target] = parts
        }
        return out
    }

    function plainBase() {
        return { font: "", bold: true, italic: false, size: Theme.clockFontDefault, color: "auto" }
    }

    function defaults() {
        return root.norm({}, root.plainBase())
    }

    // What a metric's part draws with: `all`, then that metric's overrides.
    function effective(style, target, part) {
        const s = style || {}
        const all = s.all && s.all[part] ? s.all[part] : root.plainBase()
        if (target === "all")
            return Object.assign({}, all)
        const own = s[target] && s[target][part] ? s[target][part] : {}
        return Object.assign({}, all, own)
    }

    // A copy of style with one field set (or, with value undefined, the
    // whole part's overrides dropped).
    function edited(style, target, part, field, value) {
        if (root.targets.indexOf(target) < 0 || root.parts.indexOf(part) < 0)
            return style
        const next = JSON.parse(JSON.stringify(style || {}))
        if (!next[target])
            next[target] = {}
        if (field === undefined) {
            if (target !== "all")
                next[target][part] = {}
            return next
        }
        if (root.fields.indexOf(field) < 0)
            return style
        const own = Object.assign({}, next[target][part] || {})
        own[field] = root.fieldNorm(field, value)
        next[target][part] = own
        return next
    }

    // Field names a metric's part overrides, in a fixed order.
    function overrides(style, target, part) {
        if (target === "all" || !style || !style[target] || !style[target][part])
            return []
        const own = style[target][part]
        return root.fields.filter(f => own[f] !== undefined && !(part === "percent" && f === "color"))
    }
}
