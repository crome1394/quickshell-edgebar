pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// System → Display: value helpers for monitor modes. Parsing what Hyprland
// reports, labels, the hl.monitor() Lua call, the monitors.lua text, and
// the saved list of mode + color depth pairs Hyprland would not keep, and
// each monitor's edge inset for TV overscan. Every value that reaches Lua
// is checked against a strict pattern first.
Singleton {
    id: root

    readonly property var depths: [8, 10]
    readonly property string fileMarker: "Managed by Quickshell"
    readonly property var insetEdges: ["top", "bottom", "left", "right"]

    // Monitor → { top, bottom, left, right }, saved. The bars on that
    // monitor move inward by these and windows stay clear of them, for a
    // TV that crops the picture's edges. Nothing here touches the driver.
    readonly property var insets: root.insetsFrom(Config.displayInsetsJson)
    // The monitor whose guide frame shows while you adjust; not saved.
    property string guideMonitor: ""

    function insetNorm(value) {
        const step = Theme.displayInsetStep
        const n = Math.round(Number(value) / step) * step
        return n >= 0 && n <= Theme.displayInsetMax ? n : 0
    }

    function insetsFrom(text) {
        let raw = {}
        try {
            const t = String(text || "").trim()
            raw = t.length ? JSON.parse(t) : {}
        } catch (e) {
            raw = {}
        }
        const out = {}
        for (const name in raw) {
            if (!root.outputOk(name) || !raw[name] || typeof raw[name] !== "object")
                continue
            const row = {}
            let any = false
            for (let i = 0; i < root.insetEdges.length; i++) {
                const e = root.insetEdges[i]
                row[e] = root.insetNorm(raw[name][e])
                any = any || row[e] > 0
            }
            if (any)
                out[name] = row
        }
        return out
    }

    // A monitor's insets; zeros when it has none.
    function insetsFor(name) {
        return root.insets[String(name || "")] || { top: 0, bottom: 0, left: 0, right: 0 }
    }

    function hasInsets(name) {
        return root.insets[String(name || "")] !== undefined
    }

    // edge is one of insetEdges, or "all". Saves at once.
    function setInset(name, edge, px) {
        const key = String(name || "")
        if (!root.outputOk(key))
            return
        const next = JSON.parse(JSON.stringify(root.insets))
        const row = Object.assign({ top: 0, bottom: 0, left: 0, right: 0 }, next[key] || {})
        const value = root.insetNorm(px)
        if (edge === "all") {
            for (let i = 0; i < root.insetEdges.length; i++)
                row[root.insetEdges[i]] = value
        } else if (root.insetEdges.indexOf(edge) >= 0) {
            row[edge] = value
        } else {
            return
        }
        next[key] = row
        const text = JSON.stringify(root.insetsFrom(JSON.stringify(next)))
        if (Config.displayInsetsJson === text)
            return
        Config.saveFields(() => {
            Config.displayInsetsJson = text
        })
    }

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
        // disabled = false: a monitor once turned off stays off without it.
        const parts = [
            "output = \"" + spec.output + "\"",
            "disabled = false",
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

    // A monitor turned off: Hyprland drops it from the layout and moves its
    // windows to the others.
    function luaMonitorOff(output) {
        return root.outputOk(output) ? "hl.monitor({ output = \"" + output + "\", disabled = true })" : ""
    }

    // Turned on with no saved mode: Hyprland's preferred mode, placed
    // automatically.
    function luaMonitorAuto(output) {
        return root.outputOk(output) ? "hl.monitor({ output = \"" + output + "\", disabled = false, mode = \"preferred\", position = \"auto\", scale = 1 })" : ""
    }

    // Move a numbered workspace to a monitor.
    function luaMoveWorkspace(id, output) {
        const n = Math.round(Number(id))
        if (!(n >= 1 && n <= 999) || !root.outputOk(output))
            return ""
        return "hl.dispatch(hl.dsp.workspace.move({ workspace = \"" + n + "\", monitor = \"" + output + "\" }))"
    }

    // Monitors turned off here, saved: name → { spec, workspaces, active
    // (the one it was showing) }.
    readonly property var offMonitors: root.offFrom(Config.displayOffJson)

    function offFrom(text) {
        let raw = {}
        try {
            const t = String(text || "").trim()
            raw = t.length ? JSON.parse(t) : {}
        } catch (e) {
            raw = {}
        }
        const out = {}
        for (const name in raw) {
            if (!root.outputOk(name) || !raw[name] || typeof raw[name] !== "object")
                continue
            const spec = raw[name].spec && root.luaMonitor(raw[name].spec).length ? raw[name].spec : null
            const ws = Array.isArray(raw[name].workspaces) ? raw[name].workspaces.map(Number).filter((n) => n >= 1 && n <= 999) : []
            const active = Math.round(Number(raw[name].active))
            out[name] = { spec: spec, workspaces: ws, active: active >= 1 && active <= 999 ? active : 0 }
        }
        return out
    }

    function isOff(name) {
        return root.offMonitors[String(name || "")] !== undefined
    }

    function setOff(name, record) {
        const next = Object.assign({}, root.offMonitors)
        if (record)
            next[name] = record
        else
            delete next[name]
        Config.saveFields(() => {
            Config.displayOffJson = JSON.stringify(root.offFrom(JSON.stringify(next)))
        })
    }

    // Whole monitors.lua text for these monitors, or "" when one is off.
    // ── Arrangement ─────────────────────────────────────────────────────
    // A monitor's size in layout space: logical pixels, turned by its
    // transform (1, 3, 5, 7 swap width and height).
    function logicalSize(m) {
        const scale = Number(m.scale) > 0 ? Number(m.scale) : 1
        const w = Math.round(Number(m.width) / scale)
        const h = Math.round(Number(m.height) / scale)
        return Number(m.transform) % 2 === 1 ? { w: h, h: w } : { w: w, h: h }
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
    }

    // Where a monitor dropped at (x, y) lands: touching the nearest free
    // side of another monitor (left, right, above, below), edges aligned
    // when within `near`, never overlapping. rect: { x, y, w, h };
    // others: the same for the rest. With no others it goes to 0, 0.
    function snap(rect, others, near) {
        if (!others.length)
            return { x: 0, y: 0 }
        const pull = (value, targets) => {
            for (let i = 0; i < targets.length; i++) {
                if (Math.abs(value - targets[i]) <= near)
                    return targets[i]
            }
            return value
        }
        let best = null
        let bestGap = Infinity
        for (let i = 0; i < others.length; i++) {
            const o = others[i]
            // Along a side, keep at least one pixel of shared edge.
            const y = Math.min(o.y + o.h - 1, Math.max(o.y - rect.h + 1, pull(rect.y, [o.y, o.y + o.h - rect.h, o.y + (o.h - rect.h) / 2])))
            const x = Math.min(o.x + o.w - 1, Math.max(o.x - rect.w + 1, pull(rect.x, [o.x, o.x + o.w - rect.w, o.x + (o.w - rect.w) / 2])))
            const spots = [
                { x: o.x + o.w, y: y },
                { x: o.x - rect.w, y: y },
                { x: x, y: o.y + o.h },
                { x: x, y: o.y - rect.h }
            ]
            for (let k = 0; k < spots.length; k++) {
                const spot = { x: Math.round(spots[k].x), y: Math.round(spots[k].y), w: rect.w, h: rect.h }
                if (others.some((other) => root.overlaps(spot, other)))
                    continue
                const gap = Math.hypot(spot.x - rect.x, spot.y - rect.y)
                if (gap < bestGap) {
                    bestGap = gap
                    best = { x: spot.x, y: spot.y }
                }
            }
        }
        return best || { x: Math.round(rect.x), y: Math.round(rect.y) }
    }

    // Shift a layout { name: { x, y } } so its top-left corner is 0, 0.
    function normalized(layout) {
        const names = Object.keys(layout)
        if (!names.length)
            return layout
        const minX = Math.min.apply(null, names.map((n) => layout[n].x))
        const minY = Math.min.apply(null, names.map((n) => layout[n].y))
        const out = {}
        for (let i = 0; i < names.length; i++)
            out[names[i]] = { x: layout[names[i]].x - minX, y: layout[names[i]].y - minY }
        return out
    }

    // "DP-2 is to the right of DP-1": how b sits next to a, or "".
    function relation(a, b) {
        if (b.x >= a.x + a.w)
            return "right of"
        if (b.x + b.w <= a.x)
            return "left of"
        if (b.y >= a.y + a.h)
            return "below"
        if (b.y + b.h <= a.y)
            return "above"
        return ""
    }

    // offNames: monitors written as disabled, so they stay off after a
    // restart.
    function monitorsFile(specs, stamp, offNames) {
        const blocks = []
        for (let i = 0; i < specs.length; i++) {
            const line = root.luaMonitor(specs[i])
            if (!line.length)
                return ""
            blocks.push(line)
        }
        const off = Array.isArray(offNames) ? offNames : []
        for (let i = 0; i < off.length; i++) {
            const line = root.luaMonitorOff(off[i])
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
