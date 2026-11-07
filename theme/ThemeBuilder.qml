pragma Singleton
import QtQuick
import Quickshell

// Turns a theme into the full palette the bar draws with.
//
// A theme is a few choices: tone (dark or light), accent, alert, tint (the
// glass color), bar glass and menu glass (opacity percents), and optional
// `colors` that replace single palette entries. build() derives every
// other color from those, so a theme stays small and one edit (a new
// accent) restyles hovers, borders, and the active workspace together.
//
// Colors in a theme file are "#rrggbb", "#rrggbbaa" (alpha last, as in
// CSS), or { hex, alpha }.
Singleton {
    id: root

    // Palette entries a theme's `colors` may replace.
    readonly property var colorKeys: [
        "colBar", "colBarBorder", "colGlassHighlight", "colBg", "colPage", "colSection",
        "colSurface", "colField", "colHover", "colFg", "colFgMuted", "colAccent",
        "colAccentDim", "colBorder", "colOk", "colDanger", "colWsActive", "colWsActiveFg",
        "colWsIdleFg", "colWeekday", "colStatTempCool", "colStatTempWarm", "colStatTempHot",
        "colStatSeparator", "colStatDivider", "colStatTrack"
    ]

    readonly property string darkTint: "#17120a"
    readonly property string lightTint: "#f6f1e7"

    function clamp01(n) {
        const x = Number(n)
        return x > 0 ? Math.min(1, x) : 0
    }

    function byte(channel) {
        const hex = Math.round(root.clamp01(channel) * 255).toString(16)
        return hex.length < 2 ? "0" + hex : hex
    }

    // A color from any accepted form, or null.
    function parse(value) {
        if (value === undefined || value === null)
            return null
        if (typeof value === "object" && value.hex !== undefined) {
            const base = root.parse(value.hex)
            if (!base)
                return null
            const a = value.alpha === undefined ? 1 : Number(value.alpha)
            return Qt.rgba(base.r, base.g, base.b, a >= 0 ? Math.min(1, a) : 1)
        }
        const text = String(value).trim()
        let m = /^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/.exec(text)
        if (m) {
            const n = parseInt(m[1], 16)
            const a = m[2] === undefined ? 1 : parseInt(m[2], 16) / 255
            return Qt.rgba(((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, a)
        }
        m = /^#([0-9a-fA-F]{3})$/.exec(text)
        if (m) {
            const h = m[1]
            return root.parse("#" + h[0] + h[0] + h[1] + h[1] + h[2] + h[2])
        }
        return null
    }

    // "#rrggbb", or "#rrggbbaa" when not opaque.
    function text(color) {
        const c = typeof color === "string" ? root.parse(color) : color
        if (!c)
            return ""
        const rgb = "#" + root.byte(c.r) + root.byte(c.g) + root.byte(c.b)
        return c.a >= 0.998 ? rgb : rgb + root.byte(c.a)
    }

    // Opaque "#rrggbb" for a picker or an input that has no alpha.
    function rgbText(color) {
        const c = typeof color === "string" ? root.parse(color) : color
        return c ? "#" + root.byte(c.r) + root.byte(c.g) + root.byte(c.b) : ""
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, root.clamp01(a))
    }

    // Opaque blend from a toward b.
    function mix(a, b, t) {
        const k = root.clamp01(t)
        return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1)
    }

    function shade(c, factor) {
        return Qt.rgba(root.clamp01(c.r * factor), root.clamp01(c.g * factor), root.clamp01(c.b * factor), 1)
    }

    function lift(c, step) {
        return Qt.rgba(root.clamp01(c.r + step), root.clamp01(c.g + step), root.clamp01(c.b + step), 1)
    }

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    }

    function percent(value, fallback, low) {
        const n = Math.round(Number(value))
        return n >= low && n <= 100 ? n : fallback
    }

    function labelNorm(value) {
        const text = String(value || "").replace(/[\u0000-\u001f]/g, " ").trim()
        return text.length ? text.substring(0, 48) : "Custom"
    }

    // A clean theme: known fields only, valid colors, percents in range.
    function normalize(src) {
        const s = src && typeof src === "object" ? src : {}
        const light = s.tone === "light"
        const colors = {}
        const extra = s.colors && typeof s.colors === "object" ? s.colors : {}
        for (let i = 0; i < root.colorKeys.length; i++) {
            const key = root.colorKeys[i]
            const c = root.parse(extra[key])
            if (c)
                colors[key] = root.text(c)
        }
        const temp = s.temp && typeof s.temp === "object" ? s.temp : {}
        let warm = Math.round(Number(temp.warmAt))
        let hot = Math.round(Number(temp.hotAt))
        if (!(warm >= 30 && warm <= 110))
            warm = DefaultTheme.statTempWarmAt
        if (!(hot > warm && hot <= 120))
            hot = Math.max(warm + 5, DefaultTheme.statTempHotAt)
        return {
            name: root.labelNorm(s.name),
            tone: light ? "light" : "dark",
            accent: root.rgbText(root.parse(s.accent)) || (light ? "#8a5a2a" : "#fbbf24"),
            alert: root.rgbText(root.parse(s.alert)) || (light ? "#a15c4a" : "#fb7185"),
            tint: root.rgbText(root.parse(s.tint)) || (light ? root.lightTint : root.darkTint),
            glass: root.percent(s.glass, light ? 100 : 56, 0),
            menu: root.percent(s.menu, light ? 100 : 90, 50),
            colors: colors,
            temp: { warmAt: warm, hotAt: hot }
        }
    }

    // Every palette entry for a theme (already normalized or not).
    function build(theme) {
        const t = theme || {}
        const light = t.tone === "light"
        const tint = root.parse(t.tint) || root.parse(light ? root.lightTint : root.darkTint)
        const accent = root.parse(t.accent) || root.parse(light ? "#8a5a2a" : "#fbbf24")
        const alert = root.parse(t.alert) || root.parse(light ? "#a15c4a" : "#fb7185")
        const glass = root.percent(t.glass, light ? 100 : 56, 0) / 100
        const menu = root.percent(t.menu, light ? 100 : 90, 50) / 100
        const white = Qt.rgba(1, 1, 1, 1)
        let p

        if (light) {
            const ink = root.parse("#1c1917")
            const body = root.parse("#44403c")
            p = {
                colBar: root.withAlpha(tint, glass),
                colBarBorder: root.withAlpha(accent, 0.35),
                colGlassHighlight: root.withAlpha(accent, 0.22),
                colBg: root.withAlpha(root.lift(tint, 0.01), menu),
                colPage: root.withAlpha(tint, menu),
                colSection: root.mix(tint, accent, 0.10),
                colSurface: root.withAlpha(root.lift(tint, -0.015), Math.min(1, glass + 0.16)),
                colField: root.lift(tint, 0.03),
                colHover: root.mix(tint, accent, 0.16),
                colFg: ink,
                colFgMuted: body,
                colAccent: accent,
                colAccentDim: root.mix(tint, accent, 0.30),
                colBorder: root.withAlpha(ink, 0.16),
                colOk: root.parse("#047857"),
                colDanger: alert,
                colWsActive: root.withAlpha(accent, 0.20),
                colWsActiveFg: ink,
                colWsIdleFg: body,
                colWeekday: alert,
                colStatTempCool: body,
                colStatTempWarm: root.parse("#b45309"),
                colStatTempHot: alert,
                colStatSeparator: root.parse("#78716c"),
                colStatDivider: root.withAlpha(ink, 0.12),
                colStatTrack: root.withAlpha(ink, 0.10)
            }
        } else {
            const fg = root.parse("#f0f4fc")
            p = {
                colBar: root.withAlpha(tint, glass),
                colBarBorder: root.withAlpha(accent, 0.14),
                colGlassHighlight: root.withAlpha(white, 0.08),
                colBg: root.withAlpha(tint, menu),
                colPage: root.withAlpha(tint, menu),
                colSection: root.mix(tint, fg, 0.08),
                colSurface: root.withAlpha(tint, Math.min(1, glass + 0.16)),
                colField: root.shade(tint, 0.78),
                colHover: root.mix(tint, accent, 0.20),
                colFg: fg,
                colFgMuted: root.parse("#a8b4c8"),
                colAccent: accent,
                colAccentDim: root.mix(tint, accent, 0.32),
                colBorder: root.withAlpha(white, 0.10),
                colOk: root.parse("#10b981"),
                colDanger: alert,
                colWsActive: root.withAlpha(accent, 0.26),
                colWsActiveFg: root.parse("#e6fffc"),
                colWsIdleFg: white,
                colWeekday: alert,
                colStatTempCool: fg,
                colStatTempWarm: root.parse("#f0d060"),
                colStatTempHot: alert,
                colStatSeparator: root.parse("#6e7a90"),
                colStatDivider: root.withAlpha(white, 0.12),
                colStatTrack: root.withAlpha(white, 0.10)
            }
        }

        const extra = t.colors && typeof t.colors === "object" ? t.colors : {}
        for (let i = 0; i < root.colorKeys.length; i++) {
            const key = root.colorKeys[i]
            const c = root.parse(extra[key])
            if (c)
                p[key] = c
        }
        return p
    }
}
