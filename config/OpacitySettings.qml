pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// System → Transparency, and the Transparency pill: one level for every
// application plus per-application overrides (focused and unfocused).
// Levels are percents; 100 is solid. The Settings and Inspector windows and Tack pins always stay
// solid, and so do fullscreen windows (video, games), except an override with fullSolid off: it
// keeps its own level fullscreen too, so a see-through terminal looks the same either way.
//
// The overrides are saved as JSON in opacityOverridesJson. An empty field
// means "never saved", and starts with Satty at the old Satty level, so
// the earlier two-slider setup carries over.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    // A window class as Hyprland reports it. No brackets, quotes, or spaces,
    // so it is safe inside a Lua long string and easy to escape as a regex.
    function classOk(text) {
        return /^[A-Za-z0-9._+-]{1,128}$/.test(String(text || ""))
    }

    function clamp(value) {
        let n = Math.round(Number(value) / Theme.opacityStep) * Theme.opacityStep
        if (!(n >= Theme.opacityMin))
            return Theme.opacityMax
        return Math.min(Theme.opacityMax, n)
    }

    function savedLevel(stored, fallback) {
        const n = Math.round(Number(stored))
        return n >= Theme.opacityMin && n <= Theme.opacityMax ? n : root.clamp(fallback)
    }

    // Saved level for every application.
    function allValue() {
        return root.savedLevel(Config.opacityQuickshell, DefaultTheme.opacityQuickshell)
    }

    function labelNorm(text, cls) {
        let label = String(text || "").replace(/[\r\n\t]/g, " ").trim()
        if (label.length > 60)
            label = label.substring(0, 60)
        return label.length ? label : String(cls || "")
    }

    // One clean override, or null when its class is not allowed.
    function overrideNorm(src) {
        const cls = String((src && src.cls) || "").trim()
        if (!root.classOk(cls))
            return null
        return {
            cls: cls,
            label: root.labelNorm(src.label, cls),
            active: root.clamp(src.active),
            inactive: root.clamp(src.inactive === undefined ? src.active : src.inactive),
            on: src.on !== false,
            fullSolid: src.fullSolid !== false
        }
    }

    // A clean list: allowed classes only, each class once.
    function overridesNorm(list) {
        const out = []
        const seen = {}
        const src = Array.isArray(list) ? list : []
        for (let i = 0; i < src.length && out.length < Theme.opacityOverrideMax; i++) {
            const row = root.overrideNorm(src[i])
            if (!row || seen[row.cls])
                continue
            seen[row.cls] = true
            out.push(row)
        }
        return out
    }

    function savedOverrides() {
        const text = String(Config.opacityOverridesJson || "")
        if (!text.length) {
            const satty = root.savedLevel(Config.opacitySatty, DefaultTheme.opacitySatty)
            return [{ cls: "com.gabm.satty", label: "Satty", active: satty, inactive: satty, on: true }]
        }
        try {
            return root.overridesNorm(JSON.parse(text))
        } catch (e) {
            return []
        }
    }

    // ── Draft for Settings → System → Transparency ──────────────────────
    // glass: the bar and menu glass ({ bar, menu, bars }), saved apart from
    // the theme by ThemeStore so switching themes never changes it.
    function normalize(src) {
        return { all: root.clamp(src.all), overrides: root.overridesNorm(src.overrides), glass: ThemeBuilder.glassNorm(src.glass) }
    }

    function snapshot() {
        return root.normalize({ all: root.allValue(), overrides: root.savedOverrides(), glass: ThemeStore.glass })
    }

    // Everything solid.
    function defaults() {
        return root.normalize({
            all: DefaultTheme.opacityQuickshell,
            overrides: [{ cls: "io.github.crome1394.Tack", label: "Tack", active: DefaultTheme.opacitySatty, inactive: DefaultTheme.opacitySatty, on: true }],
            glass: {}
        })
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.opacityQuickshell = clean.all
            Config.opacityOverridesJson = JSON.stringify(clean.overrides)
        })
        ThemeStore.saveGlass(clean.glass)
    }

    // Draft glass for the page. edge "" is all bars; an edge with no glass
    // of its own reads as all bars. key is "bar" or "menu".
    function draftGlass(key, edge) {
        const g = root.editor.value.glass
        if (key === "menu")
            return g.menu
        const own = edge ? Number(g.bars[edge]) : -1
        return own >= 0 ? own : g.bar
    }

    function draftOwnGlass(edge) {
        return edge ? Number(root.editor.value.glass.bars[edge]) >= 0 : false
    }

    // value -1 on a bar drops its own glass, so it follows all bars.
    function setDraftGlass(key, edge, value) {
        const g = JSON.parse(JSON.stringify(root.editor.value.glass))
        if (key === "menu")
            g.menu = value
        else if (edge)
            g.bars[edge] = value
        else
            g.bar = value
        root.editor.set("glass", g)
    }

    // The Transparency pill's sliders, saved at once.
    function setGlassLive(key, value) {
        const g = JSON.parse(JSON.stringify(ThemeStore.glass))
        if (key === "menu")
            g.menu = value
        else
            g.bar = value
        ThemeStore.saveGlass(g)
    }

    function indexOf(list, cls) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].cls === cls)
                return i
        }
        return -1
    }

    // Draft edits. Each returns false when nothing changed or input is off.
    function addOverride(cls, label) {
        const clean = String(cls || "").trim()
        const list = root.overridesNorm(root.editor.value.overrides)
        if (!root.classOk(clean) || root.indexOf(list, clean) >= 0 || list.length >= Theme.opacityOverrideMax)
            return false
        const level = root.clamp(Theme.opacityOverrideDefault)
        list.push({ cls: clean, label: root.labelNorm(label, clean), active: level, inactive: level, on: true })
        root.editor.set("overrides", list)
        return true
    }

    function removeOverride(cls) {
        const list = root.overridesNorm(root.editor.value.overrides)
        const at = root.indexOf(list, cls)
        if (at < 0)
            return
        list.splice(at, 1)
        root.editor.set("overrides", list)
    }

    function setOverride(cls, field, value) {
        const list = root.overridesNorm(root.editor.value.overrides)
        const at = root.indexOf(list, cls)
        if (at < 0 || ["active", "inactive", "on", "label", "fullSolid"].indexOf(field) < 0)
            return
        list[at][field] = value
        root.editor.set("overrides", list)
    }

    // ── Live changes from the pill (saved at once) ──────────────────────
    function setAllLive(value) {
        const next = root.clamp(value)
        if (next === root.allValue() && Config.opacityQuickshell === next)
            return
        Config.saveFields(() => {
            Config.opacityQuickshell = next
        })
    }

    // The pill's slider moves the focused level, and the unfocused one too
    // while the two are the same.
    function setOverrideLive(cls, value) {
        const list = root.savedOverrides()
        const at = root.indexOf(list, cls)
        if (at < 0)
            return
        const next = root.clamp(value)
        const linked = list[at].active === list[at].inactive
        list[at].active = next
        if (linked)
            list[at].inactive = next
        Config.saveFields(() => {
            Config.opacityOverridesJson = JSON.stringify(list)
        })
    }

    // Add an override from the pill and save it at once. Starts at the
    // same level as one added in Settings. False when the class is not
    // allowed, already has an override, or the list is full.
    function addOverrideLive(cls, label) {
        const clean = String(cls || "").trim()
        const list = root.savedOverrides()
        if (!root.classOk(clean) || root.indexOf(list, clean) >= 0 || list.length >= Theme.opacityOverrideMax)
            return false
        const level = root.clamp(Theme.opacityOverrideDefault)
        list.push({ cls: clean, label: root.labelNorm(label, clean), active: level, inactive: level, on: true })
        Config.saveFields(() => {
            Config.opacityOverridesJson = JSON.stringify(list)
        })
        return true
    }

    // Remove an override from the pill and save at once.
    function removeOverrideLive(cls) {
        const list = root.savedOverrides()
        const at = root.indexOf(list, String(cls || ""))
        if (at < 0)
            return
        list.splice(at, 1)
        Config.saveFields(() => {
            Config.opacityOverridesJson = JSON.stringify(list)
        })
    }

    function hasOverride(cls) {
        return root.indexOf(root.savedOverrides(), String(cls || "")) >= 0
    }

    function useTheme() {
        Config.saveFields(() => {
            Config.opacityQuickshell = 0
        })
    }

    // ── Hyprland rules ──────────────────────────────────────────────────
    function level(pct) {
        return (root.clamp(pct) / 100).toFixed(2)
    }

    function regexFor(cls) {
        return "^" + String(cls).replace(/[.+\-]/g, (c) => "\\" + c) + "$"
    }

    // Lua for opacity.lua. Later rules win, so the order is: every app,
    // then each override, then the windows that always stay solid, then
    // the overrides that keep their level fullscreen. The third opacity
    // value is the fullscreen one.
    function luaText(all, overrides) {
        const lines = [
            "-- Generated by Quickshell (Settings → System → Transparency).",
            "-- Rewritten on every change; edit levels in the bar, not here.",
            "-- Loaded last from hyprland.lua with require(\"opacity\").",
            "_G.QS_OPACITY = _G.QS_OPACITY or {}",
            "local function add(spec)",
            "    _G.QS_OPACITY[#_G.QS_OPACITY + 1] = hl.window_rule(spec)",
            "end"
        ]
        const level = root.clamp(all)
        // Every enabled override is written, 100% too: a solid override must
        // beat opacity from the user's own rules (HyprGlass sets 0.90).
        const rows = root.overridesNorm(overrides).filter((r) => r.on)
        if (level < 100)
            lines.push("add({ name = 'qs-opacity-apps', match = { class = [[.*]] }, opacity = '"
                + root.level(level) + " override " + root.level(level) + " override' })")
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            lines.push("add({ name = 'qs-opacity-app-" + (i + 1) + "', match = { class = [[" + root.regexFor(r.cls) + "]] }, opacity = '"
                + root.level(r.active) + " override " + root.level(r.inactive) + " override' })")
        }
        if (level < 100 || rows.length) {
            lines.push("add({ name = 'qs-opacity-settings', match = { class = [[^org\\.quickshell$]], title = [[^(Settings|Inspector)$]] }, opacity = '1 override 1 override 1 override' })")
            // Tack pins show a screenshot as it is.
            lines.push("add({ name = 'qs-opacity-tack-pins', match = { class = [[^io\\.github\\.crome1394\\.Tack\\.Pins$]] }, opacity = '1 override 1 override 1 override' })")
            lines.push("add({ name = 'qs-opacity-fullscreen', match = { fullscreen = true }, opacity = '1 override 1 override 1 override' })")
        }
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            if (r.fullSolid)
                continue
            lines.push("add({ name = 'qs-opacity-app-" + (i + 1) + "-fullscreen', match = { class = [[" + root.regexFor(r.cls) + "]], fullscreen = true }, opacity = '"
                + root.level(r.active) + " override " + root.level(r.inactive) + " override " + root.level(r.active) + " override' })")
        }
        lines.push("")
        return lines.join("\n")
    }
}
