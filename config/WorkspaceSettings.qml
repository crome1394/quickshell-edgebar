pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.theme

// Workspace pills: per-slot faces, the special (magic) workspace face,
// and the startup options. The cycle script reads wsSpecialNameCustom and
// wsSlotsJson from state/bar-layout.json, so those names stay as they are.
Singleton {
    id: root

    readonly property string defaultSpecialName: "magic"
    readonly property string icon1: ""
    readonly property string icon2: ""
    readonly property string icon3: "🕹"
    readonly property string icon4: ""
    readonly property string icon5: ""
    readonly property string icon6: ""
    readonly property string icon7: ""
    readonly property string icon8: "󰈸"
    readonly property string icon9: "󰈸"
    readonly property string icon10: "󰈸"
    readonly property string iconDefault: "󰈸"
    readonly property string iconSpecial: "🪄"

    function iconForId(id) {
        switch (Math.round(Number(id))) {
        case 1: return root.icon1
        case 2: return root.icon2
        case 3: return root.icon3
        case 4: return root.icon4
        case 5: return root.icon5
        case 6: return root.icon6
        case 7: return root.icon7
        case 8: return root.icon8
        case 9: return root.icon9
        case 10: return root.icon10
        default: return root.iconDefault
        }
    }

    function clampCount(value) {
        let n = Math.round(Number(value))
        if (!(n >= 1))
            n = 1
        if (n > 10)
            n = 10
        return n
    }

    function clampStartup(value) {
        let n = Math.round(Number(value))
        if (!(n >= 0))
            n = 0
        if (n > 10)
            n = 10
        return n
    }

    function nameNorm(value) {
        let s = String(value || "").trim()
        while (s.length >= 8 && s.substring(0, 8).toLowerCase() === "special:")
            s = s.substring(8).trim()
        s = s.replace(/[^A-Za-z0-9_.-]/g, "")
        if (s.length > 32)
            s = s.substring(0, 32)
        if (!s.length || s === root.defaultSpecialName)
            return ""
        return s
    }

    function resolvedSpecialName() {
        const custom = String(Config.specialNameCustom || "")
        return custom.length ? custom : root.defaultSpecialName
    }

    function isSpecialName(name) {
        const n = String(name || "")
        if (!n.length)
            return false
        const special = root.resolvedSpecialName()
        return n === special || n === ("special:" + special)
    }

    function blankSlot(id, label) {
        return {
            id: id,
            label: Config.symbolClamp(label),
            font: "",
            fontPx: 0,
            text: "",
            bold: true,
            italic: false,
            color: ""
        }
    }

    function copySlot(raw) {
        const src = raw || {}
        return {
            id: Math.round(Number(src.id)) || 0,
            label: Config.symbolClamp(src.label),
            font: Config.fontClamp(src.font),
            fontPx: Config.fontPxClamp(src.fontPx),
            text: Config.textClamp(src.text),
            bold: src.bold === undefined ? true : !!src.bold,
            italic: !!src.italic,
            color: Config.colorNorm(src.color)
        }
    }

    function sanitizeSlots(slots) {
        const used = {}
        const out = []
        const list = slots || []
        for (let i = 0; i < list.length && out.length < 10; i++) {
            const slot = root.copySlot(list[i])
            if (!(slot.id >= 1) || slot.id > 10 || used[slot.id])
                continue
            used[slot.id] = true
            out.push(slot)
        }
        return out
    }

    function sortSlots(slots) {
        const clean = root.sanitizeSlots(slots)
        clean.sort(function(a, b) { return a.id - b.id })
        return clean
    }

    function defaultSlots(count) {
        const n = root.clampCount(count)
        const out = []
        for (let i = 1; i <= n; i++)
            out.push(root.blankSlot(i, root.iconForId(i)))
        return out
    }

    function effectiveSlots() {
        void Config.revision
        if (!Config.hasSlots)
            return root.defaultSlots(Config.minimumShown)
        const clean = root.sortSlots(Config.slotsJson)
        if (!clean.length)
            return root.defaultSlots(Config.minimumShown)
        return clean
    }

    function nextFreeId(slots) {
        const used = {}
        const list = slots || []
        for (let i = 0; i < list.length; i++)
            used[Math.round(Number(list[i].id))] = true
        for (let id = 1; id <= 10; id++) {
            if (!used[id])
                return id
        }
        return -1
    }

    function faceForId(id) {
        const n = Math.round(Number(id))
        const slots = root.effectiveSlots()
        for (let i = 0; i < slots.length; i++) {
            if (slots[i].id === n)
                return slots[i]
        }
        return root.blankSlot(n, "")
    }

    function specialObject() {
        void Config.revision
        return {
            name: String(Config.specialNameCustom || ""),
            label: String(Config.specialLabel || ""),
            font: String(Config.specialFont || ""),
            fontPx: Config.fontPxClamp(Config.specialFontPx),
            text: String(Config.specialText || ""),
            bold: Config.specialBold !== false,
            italic: !!Config.specialItalic,
            color: Config.colorNorm(Config.specialColor)
        }
    }

    function specialFace() {
        const spec = root.specialObject()
        let symbol = Config.symbolClamp(spec.label)
        if (!symbol.length && !Config.textClamp(spec.text).length)
            symbol = root.iconSpecial
        return {
            id: -1,
            label: symbol,
            font: spec.font,
            fontPx: spec.fontPx,
            text: spec.text,
            bold: spec.bold,
            italic: spec.italic,
            color: spec.color
        }
    }

    function copySpecial(raw) {
        const src = raw || {}
        return {
            name: String(src.name || ""),
            label: Config.symbolClamp(src.label),
            font: Config.fontClamp(src.font),
            fontPx: Config.fontPxClamp(src.fontPx),
            text: Config.textClamp(src.text),
            bold: src.bold === undefined ? true : !!src.bold,
            italic: !!src.italic,
            color: Config.colorNorm(src.color)
        }
    }

    function slotsSignature(slots) {
        return JSON.stringify(root.sanitizeSlots(slots))
    }

    function specialSignature(spec) {
        const src = root.copySpecial(spec)
        src.name = root.nameNorm(src.name)
        return JSON.stringify(src)
    }

    function setShowSpecial(enabled) {
        const next = !!enabled
        if (Config.showSpecial === next)
            return
        Config.showSpecial = next
        Config.touch()
    }

    function setShowOnlyActive(enabled) {
        const next = !!enabled
        if (Config.showOnlyActive === next)
            return
        Config.showOnlyActive = next
        Config.touch()
    }

    // ── Colors ──────────────────────────────────────────────────────────
    readonly property var colorKeys: ["wsActiveBg", "wsActiveFg", "wsIdleFg", "wsHoverFg"]

    // "theme" or "custom". Unset means custom when any face already has a
    // color (so an older setup keeps its look), else theme.
    function colorMode() {
        const saved = String(Config.wsColorMode || "")
        if (saved === "theme" || saved === "custom")
            return saved
        const slots = root.effectiveSlots()
        const any = slots.some((s) => String(s.color || "").length) || String(Config.specialColor || "").length
        return any ? "custom" : "theme"
    }

    function setColorMode(mode) {
        if (mode !== "theme" && mode !== "custom")
            return
        Config.saveFields(() => {
            Config.wsColorMode = mode
        })
    }

    // A custom color, or "" for the theme's (also "" in theme mode).
    function customColor(key) {
        if (root.colorKeys.indexOf(key) < 0 || root.colorMode() !== "custom")
            return ""
        return Config.colorNorm(Config[key])
    }

    function setCustomColor(key, value) {
        if (root.colorKeys.indexOf(key) < 0)
            return
        const next = value === "" ? "" : Config.colorNorm(String(value))
        Config.saveFields(() => {
            Config[key] = next
        })
    }

    // A face's own label color, used only in custom mode.
    function labelColor(face) {
        return root.colorMode() === "custom" ? String((face && face.color) || "") : ""
    }

    function setShowNumbers(enabled) {
        const next = !!enabled
        if (Config.showNumbers === next)
            return
        Config.showNumbers = next
        Config.touch()
    }

    function setStartupWorkspace(workspace) {
        const next = root.clampStartup(workspace)
        if (Config.startupWorkspace === next)
            return
        Config.startupWorkspace = next
        Config.touch()
    }

    function setStartupCloseSpecial(enabled) {
        const next = !!enabled
        if (Config.startupCloseSpecial === next)
            return
        Config.startupCloseSpecial = next
        Config.touch()
    }

    function setMinimumShown(count) {
        let n = root.clampCount(count)
        let slots = null
        if (Config.hasSlots) {
            slots = root.sanitizeSlots(Config.slotsJson)
            while (slots.length > n)
                slots.pop()
            while (slots.length < n) {
                const id = root.nextFreeId(slots)
                if (id < 0)
                    break
                slots.push(root.blankSlot(id, root.iconForId(id)))
            }
            n = slots.length || 1
        }
        Config.saveFields(() => {
            if (slots)
                Config.slotsJson = slots
            Config.minimumShown = n
        })
    }

    function commit(slots, special) {
        const clean = root.sanitizeSlots(slots)
        const next = clean.length ? clean : root.defaultSlots(1)
        const spec = root.copySpecial(special)
        spec.name = root.nameNorm(spec.name)
        Config.saveFields(() => {
            Config.slotsJson = next
            Config.hasSlots = true
            Config.minimumShown = next.length
            Config.specialNameCustom = spec.name
            Config.specialLabel = spec.label
            Config.specialFont = spec.font
            Config.specialFontPx = spec.fontPx
            Config.specialText = spec.text
            Config.specialBold = spec.bold
            Config.specialItalic = spec.italic
            Config.specialColor = spec.color
        })
    }
}
