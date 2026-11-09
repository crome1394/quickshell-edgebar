import QtQuick
import Quickshell
import qs.theme
import "tests"

// ThemeBuilder: color parsing, the derived palette, and normalize().
ShellRoot {
    Check { id: t }

    function near(a, b) {
        return Math.abs(a.r - b.r) < 0.01 && Math.abs(a.g - b.g) < 0.01 && Math.abs(a.b - b.b) < 0.01 && Math.abs(a.a - b.a) < 0.01
    }

    Component.onCompleted: {
        const B = ThemeBuilder
        t.eq("parse #rgb", B.text(B.parse("#fa0")), "#ffaa00")
        t.eq("parse #rrggbbaa keeps alpha", B.text(B.parse("#11223380")), "#11223380")
        t.eq("parse {hex, alpha}", B.text(B.parse({ hex: "#112233", alpha: 0.5 })), "#11223380")
        t.eq("parse rejects junk", B.parse("red; rm -rf"), null)
        t.eq("rgbText drops alpha", B.rgbText("#11223380"), "#112233")

        // Liquid amber must rebuild DefaultTheme's colors.
        const p = B.build(ThemePresets.defaultTheme())
        const keys = ["colBar", "colBg", "colSurface", "colHover", "colAccent", "colAccentDim", "colDanger", "colWsActive", "colWeekday", "colField"]
        for (let i = 0; i < keys.length; i++)
            t.ok("default palette " + keys[i], near(p[keys[i]], DefaultTheme[keys[i]]), B.text(p[keys[i]]) + " vs " + B.text(DefaultTheme[keys[i]]))

        // One accent change moves everything derived from it.
        const blue = B.build({ accent: "#3b82f6" })
        t.eq("accent sets colAccent", B.rgbText(blue.colAccent), "#3b82f6")
        t.ok("accent moves hover", !near(blue.colHover, p.colHover))

        // Overrides: only known keys, only valid colors.
        const n = B.normalize({ name: "x", colors: { colFg: "#123456", evil: "#000000", colBg: "nope" } })
        t.eq("overrides keep known keys", Object.keys(n.colors), ["colFg"])
        t.eq("glass clamps", B.normalize({ glass: 400 }).glass, 56)
        t.eq("menu has a floor", B.normalize({ menu: 10 }).menu, 90)
        t.eq("temp keeps hot above warm", B.normalize({ temp: { warmAt: 90, hotAt: 60 } }).temp.hotAt > 90, true)
        t.eq("name strips control chars", B.normalize({ name: "a\u0007b" }).name, "a b")
        t.eq("light tone defaults", B.normalize({ tone: "light" }).tint, B.lightTint)
        t.ok("light text is dark", B.luminance(B.build({ tone: "light" }).colFg) < 0.2)

        // Fonts: names cleaned, size on a 5% step inside 80..130.
        t.eq("fonts default", B.normalize({}).fonts, { ui: "", bar: "", size: 100 })
        t.eq("fonts keep names", B.normalize({ fonts: { ui: "Inter", bar: "JetBrains Mono", size: 112 } }).fonts, { ui: "Inter", bar: "JetBrains Mono", size: 110 })
        t.eq("fonts size clamps", B.normalize({ fonts: { size: 300 } }).fonts.size, 100)
        t.eq("fonts strip control chars", B.normalize({ fonts: { ui: "In\nter" } }).fonts.ui, "Inter")

        // Every preset builds a full palette.
        for (let k = 0; k < ThemePresets.list.length; k++) {
            const pal = B.build(ThemePresets.list[k])
            t.ok("preset builds: " + ThemePresets.list[k].name, B.colorKeys.every((c) => pal[c] !== undefined))
        }

        // Glass lives apart from the theme (System → Transparency).
        t.eq("solid by default", B.glassNorm({}), { bar: 100, menu: 100, bars: { top: -1, bottom: -1, left: -1, right: -1 } })
        t.eq("bad values fall back", B.glassNorm({ bar: 400, menu: 10, bars: { top: "x", right: 30 } }), { bar: 100, menu: 100, bars: { top: -1, bottom: -1, left: -1, right: 30 } })
        const dark = B.normalize({ tone: "dark", glass: 40 })
        const g = { bar: 56, menu: 90, bars: { top: 20 } }
        t.eq("the theme's own glass is not used", B.withGlass(dark, g, "").glass, 56)
        t.eq("a bar's own glass", B.withGlass(dark, g, "top").glass, 20)
        t.eq("other bars follow bar glass", B.withGlass(dark, g, "bottom").glass, 56)
        t.ok("its bar and pills get thinner", B.build(B.withGlass(dark, g, "top")).colBar.a < B.build(B.withGlass(dark, g, "")).colBar.a
            && B.build(B.withGlass(dark, g, "top")).colSurface.a < B.build(B.withGlass(dark, g, "")).colSurface.a)
        t.eq("menus keep menu glass", B.build(B.withGlass(dark, g, "top")).colBg, B.build(B.withGlass(dark, g, "")).colBg)
        t.eq("solid glass is solid", [B.build(B.withGlass(dark, {}, "")).colBar.a, B.build(B.withGlass(dark, {}, "")).colBg.a], [1, 1])
        t.done()
    }
}
