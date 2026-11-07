pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Settings → Theme: the active theme (a Draft, so Apply/Undo/Reset work),
// your saved themes, and import/export.
//
// Draft value: { theme, stats, audio }. `theme` is a ThemeBuilder theme.
// `stats` and `audio` are threshold steps and colors carried by a saved or
// imported theme; null means "keep the current ones", which is what every
// built-in preset does.
//
// Saved themes live in Config.themeLibraryJson. A theme file is one saved
// theme plus `format` and `version`. Import also reads the old bar's theme
// files (themes/*.json and state/theme-colors.json).
Singleton {
    id: root

    readonly property string format: "quickshell-edgebar-theme"
    readonly property int version: 1

    readonly property Draft editor: Draft {
        owner: root
    }

    // ── Stats and audio carried by a theme ─────────────────────────────
    function statsNorm(visual) {
        if (!visual || typeof visual !== "object")
            return null
        const clean = JSON.parse(ThemeStore.statsText(visual))
        return ThemeStore.statsText(clean) === ThemeStore.statsText(ThemeStore.statVisual()) ? null : clean
    }

    function audioNorm(visual) {
        if (!visual || typeof visual !== "object")
            return null
        const clean = JSON.parse(ThemeStore.audioText(visual))
        return ThemeStore.audioText(clean) === ThemeStore.audioText(ThemeStore.audioVisual()) ? null : clean
    }

    // ── Draft ───────────────────────────────────────────────────────────
    function normalize(src) {
        const s = src || {}
        return {
            theme: ThemeBuilder.normalize(s.theme),
            stats: root.statsNorm(s.stats),
            audio: root.audioNorm(s.audio)
        }
    }

    function snapshot() {
        return { theme: ThemeStore.activeTheme, stats: null, audio: null }
    }

    // Reset drafts Liquid amber and keeps the thresholds.
    function defaults() {
        return root.normalize({ theme: ThemePresets.defaultTheme() })
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        ThemeStore.saveLook(clean.theme, clean.stats, clean.audio)
    }

    // Draft a preset or a saved theme. Saved ones bring their thresholds.
    function choose(entry) {
        if (!entry)
            return
        root.editor.edit({ theme: entry, stats: entry.stats || null, audio: entry.audio || null })
    }

    // One simple edit to the drafted theme (accent, alert, tint, glass,
    // menu). Switching tone drops the preset's text colors and picks a
    // tint that suits the tone.
    function setField(key, value) {
        if (["accent", "alert", "tint", "glass", "menu", "tone", "name"].indexOf(key) < 0)
            return
        const next = Object.assign({}, root.editor.value.theme)
        if (key === "tone") {
            if (next.tone === value)
                return
            next.tone = value === "light" ? "light" : "dark"
            next.colors = {}
            next.glass = next.tone === "light" ? 100 : 56
            next.menu = next.tone === "light" ? 100 : 90
            const tint = ThemeBuilder.parse(next.tint)
            const isLight = tint && ThemeBuilder.luminance(tint) > 0.5
            if (isLight !== (next.tone === "light"))
                next.tint = next.tone === "light" ? ThemeBuilder.lightTint : ThemeBuilder.darkTint
        } else if (key === "accent" || key === "alert" || key === "tint") {
            next[key] = ThemeBuilder.rgbText(value)
        } else {
            next[key] = value
        }
        root.editor.set("theme", next)
    }

    function setTemp(key, value) {
        if (key !== "warmAt" && key !== "hotAt")
            return
        const next = Object.assign({}, root.editor.value.theme)
        next.temp = Object.assign({}, next.temp)
        next.temp[key] = Math.round(Number(value))
        if (key === "warmAt" && next.temp.hotAt <= next.temp.warmAt)
            next.temp.hotAt = Math.min(Theme.themeTempMax, next.temp.warmAt + Theme.themeTempStep)
        if (key === "hotAt" && next.temp.warmAt >= next.temp.hotAt)
            next.temp.warmAt = Math.max(Theme.themeTempMin, next.temp.hotAt - Theme.themeTempStep)
        root.editor.set("theme", next)
    }

    // Drop the preset's single-color details, keeping the main choices.
    function clearDetails() {
        const next = Object.assign({}, root.editor.value.theme)
        next.colors = {}
        root.editor.set("theme", next)
    }

    // ── Saved themes ────────────────────────────────────────────────────
    function entryNorm(src) {
        if (!src || typeof src !== "object")
            return null
        const out = ThemeBuilder.normalize(src)
        out.stats = src.stats && typeof src.stats === "object" ? JSON.parse(ThemeStore.statsText(src.stats)) : null
        out.audio = src.audio && typeof src.audio === "object" ? JSON.parse(ThemeStore.audioText(src.audio)) : null
        return out
    }

    function library() {
        const text = String(Config.themeLibraryJson || "")
        if (!text.length)
            return []
        try {
            const list = JSON.parse(text)
            const out = []
            const seen = {}
            for (let i = 0; Array.isArray(list) && i < list.length && out.length < Theme.themeLibraryMax; i++) {
                const row = root.entryNorm(list[i])
                if (!row || seen[row.name])
                    continue
                seen[row.name] = true
                out.push(row)
            }
            return out
        } catch (e) {
            return []
        }
    }

    function indexIn(list, name) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].name === name)
                return i
        }
        return -1
    }

    function hasSaved(name) {
        return root.indexIn(root.library(), ThemeBuilder.labelNorm(name)) >= 0
    }

    // The look on the page now, with the thresholds it would apply.
    function current(name) {
        const v = root.editor.value
        const out = Object.assign({}, v.theme)
        out.name = ThemeBuilder.labelNorm(name === undefined ? v.theme.name : name)
        out.stats = v.stats || ThemeStore.statVisual()
        out.audio = v.audio || ThemeStore.audioVisual()
        return out
    }

    function writeLibrary(list) {
        Config.saveFields(() => {
            Config.themeLibraryJson = JSON.stringify(list)
        })
    }

    // Save (or replace) a theme under `name`. False when the list is full.
    function saveEntry(entry) {
        const row = root.entryNorm(entry)
        if (!row)
            return false
        const list = root.library()
        const at = root.indexIn(list, row.name)
        if (at >= 0)
            list[at] = row
        else if (list.length >= Theme.themeLibraryMax)
            return false
        else
            list.push(row)
        root.writeLibrary(list)
        return true
    }

    function saveCurrent(name) {
        return root.saveEntry(root.current(name))
    }

    function removeSaved(name) {
        const list = root.library()
        const at = root.indexIn(list, name)
        if (at < 0)
            return
        list.splice(at, 1)
        root.writeLibrary(list)
    }

    // A name not yet in the library: "Name", "Name (2)", …
    function freeName(name) {
        const base = ThemeBuilder.labelNorm(name)
        const list = root.library()
        if (root.indexIn(list, base) < 0)
            return base
        for (let n = 2; n < 100; n++) {
            const next = ThemeBuilder.labelNorm(base.substring(0, 42) + " (" + n + ")")
            if (root.indexIn(list, next) < 0)
                return next
        }
        return base
    }

    // A saved theme by name, else a preset, or null.
    function findNamed(name) {
        const key = String(name || "").trim()
        const list = root.library()
        const at = root.indexIn(list, key)
        return at >= 0 ? list[at] : ThemePresets.find(key)
    }

    // Draft a theme by name and apply it: the same path as clicking its
    // card, then Apply. False when no theme has that name.
    function applyNamed(name) {
        const entry = root.findNamed(name)
        if (!entry)
            return false
        root.editor.discard()
        root.choose(entry)
        root.editor.apply()
        return true
    }

    // qs ipc call theme apply "Nordic frost"   saved theme or preset; same as card + Apply
    // qs ipc call theme list                   every name, saved themes first
    // qs ipc call theme current                the applied theme's name
    IpcHandler {
        target: "theme"

        function apply(name: string): string {
            return root.applyNamed(name) ? "ok" : "unknown theme: " + String(name || "").substring(0, 60)
        }

        function list(): string {
            return root.library().map((t) => t.name).concat(ThemePresets.list.map((t) => t.name)).join("\n")
        }

        function current(): string {
            return ThemeStore.activeTheme.name
        }
    }

    // ── Export and import ───────────────────────────────────────────────
    function exportText() {
        const entry = root.current()
        return JSON.stringify(Object.assign({ format: root.format, version: root.version }, entry), null, 2) + "\n"
    }

    // An old-bar color entry ({ hex, alpha }) as a theme color, or "".
    function oldColor(colors, key) {
        const c = ThemeBuilder.parse(colors[key])
        return c ? ThemeBuilder.text(c) : ""
    }

    function oldAlpha(colors, key, fallback) {
        const c = ThemeBuilder.parse(colors[key])
        return c ? Math.round(c.a * 100) : fallback
    }

    // The old bar's theme export (name, colors, numbers, fonts).
    function fromOldBar(obj) {
        const c = obj.colors
        const n = obj.numbers && typeof obj.numbers === "object" ? obj.numbers : {}
        const tintColor = ThemeBuilder.parse(c.glassBg) || ThemeBuilder.parse(c.bg)
        const light = obj.tone === "light" || (obj.tone !== "dark" && tintColor && ThemeBuilder.luminance(tintColor) > 0.5)
        const pairs = [
            ["colFg", "text"], ["colFgMuted", "subtext"], ["colWeekday", "weekday"],
            ["colWsActive", "wsActiveBg"], ["colWsActiveFg", "wsActiveText"], ["colWsIdleFg", "wsInactiveText"],
            ["colStatTempCool", "statTempCool"], ["colStatTempWarm", "statTempWarm"], ["colStatTempHot", "statTempHot"],
            ["colGlassHighlight", "glassHighlight"], ["colSurface", "glassPillBg"], ["colBarBorder", "glassBorder"],
            ["colBorder", "pillBorder"]
        ]
        const colors = {}
        for (let i = 0; i < pairs.length; i++) {
            const value = root.oldColor(c, pairs[i][1])
            if (value.length)
                colors[pairs[i][0]] = value
        }
        const tiers = (prefix) => {
            const out = []
            for (let k = 1; k <= 4; k++)
                out.push(root.oldColor(c, prefix + k))
            return out.every((x) => x.length) ? out : null
        }
        const steps = (prefix) => {
            const out = [n[prefix + 1], n[prefix + 2], n[prefix + 3]]
            return out.every((x) => x !== undefined) ? out : [25, 50, 75]
        }
        const statSteps = steps("statUtilThreshold")
        const gpu = tiers("statGpuTier")
        const metrics = { cpu: tiers("statCpuTier"), mem: tiers("statMemTier"), gpu: gpu, vram: tiers("statVramTier") || gpu }
        let stats = null
        for (const key in metrics) {
            if (!metrics[key])
                continue
            stats = stats || ThemeStore.statVisual()
            stats[key] = { t: statSteps.slice(), c: metrics[key] }
        }
        const speaker = tiers("audioSpeakerTier")
        return {
            name: obj.name,
            tone: light ? "light" : "dark",
            accent: root.oldColor(c, "accent"),
            alert: root.oldColor(c, "muted"),
            tint: tintColor ? ThemeBuilder.rgbText(tintColor) : "",
            glass: root.oldAlpha(c, "glassBg", light ? 100 : 56),
            menu: Math.max(50, root.oldAlpha(c, "glassPopupBg", light ? 100 : 90)),
            colors: colors,
            temp: { warmAt: n.statTempWarmAt, hotAt: n.statTempHotAt },
            stats: stats,
            audio: speaker ? { t: steps("audioUtilThreshold"), c: speaker } : null
        }
    }

    // Read a theme file. Returns { entry } or { error }.
    function parseImport(text) {
        const body = String(text || "")
        if (!body.trim().length)
            return { error: "The file is empty." }
        if (body.length > Theme.themeImportMaxBytes)
            return { error: "The file is too large for a theme." }
        let obj = null
        try {
            obj = JSON.parse(body)
        } catch (e) {
            return { error: "The file is not valid JSON." }
        }
        if (obj && typeof obj.themeJson === "string") {
            try {
                obj = JSON.parse(obj.themeJson)
            } catch (e) {
                return { error: "The old bar's theme in this file is not valid JSON." }
            }
        }
        if (!obj || typeof obj !== "object" || Array.isArray(obj))
            return { error: "The file does not hold a theme." }
        if (obj.format === root.format || obj.accent !== undefined)
            return { entry: root.entryNorm(obj) }
        if (obj.colors && typeof obj.colors === "object" && obj.colors.accent !== undefined)
            return { entry: root.entryNorm(root.fromOldBar(obj)) }
        return { error: "The file does not hold a theme." }
    }

    // Import into the library under a free name and draft it. Returns an
    // error message, or "" on success.
    function importText(text) {
        const result = root.parseImport(text)
        if (result.error)
            return result.error
        const entry = result.entry
        entry.name = root.freeName(entry.name)
        if (!root.saveEntry(entry))
            return "No room for more saved themes (" + Theme.themeLibraryMax + " at most)."
        root.choose(entry)
        return ""
    }
}
