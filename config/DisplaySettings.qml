pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// System → Display: value helpers for monitor modes. Parsing what Hyprland
// reports, labels, the hl.monitor() Lua call, the monitors.lua text, and
// the saved list of mode + color depth pairs Hyprland would not keep.
// Every value that reaches Lua is checked against a strict pattern first.
Singleton {
    id: root

    readonly property var depths: [8, 10]
    readonly property string fileMarker: "Managed by Quickshell"

    function outputOk(name) {
        return /^[A-Za-z0-9._-]{1,32}$/.test(String(name || ""))
    }

    // "5120x1440@239.76Hz" or "5120x1440@239.76" → { w, h, hz, mode }.
    function parseMode(text) {
        const m = /^(\d{2,5})x(\d{2,5})@(\d{1,3}(?:\.\d{1,3})?)(?:Hz)?$/.exec(String(text || "").trim())
        if (!m)
            return null
        const w = Number(m[1])
        const h = Number(m[2])
        const hz = Number(m[3])
        if (!(w > 0 && h > 0 && hz > 0))
            return null
        return { w: w, h: h, hz: hz, mode: w + "x" + h + "@" + hz.toFixed(2) }
    }

    function modeOk(text) {
        return root.parseMode(text) !== null
    }

    // Modes grouped by resolution, largest first, each with its refresh
    // rates fastest first: [{ w, h, key, rates: [{ hz, mode, label }] }].
    function groupModes(list) {
        const byKey = {}
        const out = []
        const src = list || []
        for (let i = 0; i < src.length; i++) {
            const p = root.parseMode(src[i])
            if (!p)
                continue
            const key = p.w + "x" + p.h
            let group = byKey[key]
            if (!group) {
                group = { w: p.w, h: p.h, key: key, rates: [] }
                byKey[key] = group
                out.push(group)
            }
            if (!group.rates.some((r) => r.mode === p.mode))
                group.rates.push({ hz: p.hz, mode: p.mode, label: "" })
        }
        for (let g = 0; g < out.length; g++) {
            const rates = out[g].rates
            rates.sort((a, b) => b.hz - a.hz)
            // Whole numbers unless two rates round to the same one (60 and 59.94).
            for (let r = 0; r < rates.length; r++) {
                const whole = Math.round(rates[r].hz)
                const clash = rates.some((o, k) => k !== r && Math.round(o.hz) === whole)
                rates[r].label = clash ? rates[r].hz.toFixed(2) : String(whole)
            }
        }
        out.sort((a, b) => (b.w * b.h) - (a.w * a.h) || b.w - a.w)
        return out
    }

    function ratioLabel(w, h) {
        if (!(w > 0 && h > 0))
            return ""
        const known = [
            { r: 32 / 9, label: "32:9" },
            { r: 64 / 27, label: "21:9" },
            { r: 43 / 18, label: "21:9" },
            { r: 16 / 9, label: "16:9" },
            { r: 16 / 10, label: "16:10" },
            { r: 4 / 3, label: "4:3" },
            { r: 5 / 4, label: "5:4" }
        ]
        const ratio = w / h
        for (let i = 0; i < known.length; i++) {
            if (Math.abs(ratio - known[i].r) < 0.02)
                return known[i].label
        }
        let a = w
        let b = h
        while (b) {
            const t = b
            b = a % b
            a = t
        }
        return (w / a) + ":" + (h / a)
    }

    // Hyprland's pixel format: 2101010 formats are 10-bit, the rest 8-bit.
    function depthFromFormat(format) {
        return /2101010/.test(String(format || "")) ? 10 : 8
    }

    function depthOk(depth) {
        return root.depths.indexOf(Number(depth)) >= 0
    }

    // The hl.monitor({...}) call for one monitor, or "" when a value is off.
    // cm stays "srgb": "auto" turns 10-bit into wide gamut and fringes Qt text.
    function luaMonitor(spec) {
        if (!spec || !root.outputOk(spec.output))
            return ""
        const mode = root.parseMode(spec.mode)
        if (!mode || !root.depthOk(spec.depth))
            return ""
        const x = Math.round(Number(spec.x))
        const y = Math.round(Number(spec.y))
        const scale = Number(spec.scale)
        const transform = Math.round(Number(spec.transform) || 0)
        if (!isFinite(x) || !isFinite(y) || !(scale >= 0.25 && scale <= 4) || transform < 0 || transform > 7)
            return ""
        const parts = [
            "output = \"" + spec.output + "\"",
            "mode = \"" + mode.mode + "\"",
            "position = \"" + x + "x" + y + "\"",
            "scale = " + scale.toFixed(2),
            "bitdepth = " + Number(spec.depth),
            "cm = \"srgb\""
        ]
        if (transform)
            parts.push("transform = " + transform)
        return "hl.monitor({ " + parts.join(", ") + " })"
    }

    // Whole monitors.lua text for these monitors, or "" when one is off.
    function monitorsFile(specs, stamp) {
        const blocks = []
        for (let i = 0; i < specs.length; i++) {
            const line = root.luaMonitor(specs[i])
            if (!line.length)
                return ""
            blocks.push(line)
        }
        return [
            "-- ━━━━ Monitors ╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸",
            "--",
            "-- " + root.fileMarker + " (Settings → System → Display).",
            "-- Last applied: " + String(stamp || ""),
            "-- Manual edits are fine; the next Keep from the bar rewrites this file.",
            "--",
            "-- See https://wiki.hypr.land/Configuring/Basics/Monitors/",
            "",
            blocks.join("\n"),
            ""
        ].join("\n")
    }

    // Saved pairs Hyprland would not keep, as "output|mode|depth".
    function rejectedList() {
        try {
            const list = JSON.parse(String(Config.displayRejectedJson || "[]"))
            return Array.isArray(list) ? list.filter((s) => typeof s === "string") : []
        } catch (e) {
            return []
        }
    }

    function rejectKey(output, mode, depth) {
        return String(output) + "|" + String(mode) + "|" + Number(depth)
    }

    function isRejected(output, mode, depth) {
        return root.rejectedList().indexOf(root.rejectKey(output, mode, depth)) >= 0
    }

    function markRejected(output, mode, depth) {
        const key = root.rejectKey(output, mode, depth)
        const list = root.rejectedList()
        if (list.indexOf(key) >= 0)
            return
        list.push(key)
        while (list.length > Theme.displayRejectedMax)
            list.shift()
        Config.saveFields(() => {
            Config.displayRejectedJson = JSON.stringify(list)
        })
    }

    function clearRejected() {
        Config.saveFields(() => {
            Config.displayRejectedJson = "[]"
        })
    }
}
