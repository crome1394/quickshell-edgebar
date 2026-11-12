pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Widgets → Active Window: the corner pill, its width cap, pattern, and excludes.
// The pattern is the order, the on/off switch, and the marks around each part.
// An empty saved pattern still means the old layout list plus the PID switch.
Singleton {
    id: root

    readonly property int excludeMax: 40
    readonly property int formatMax: 160
    readonly property int formatMarkMax: 8
    readonly property int formatGapMax: 24
    readonly property string formatOpeners: "([{<"
    readonly property string formatClosers: ")]}>"
    // Left to right, unless the pattern says otherwise.
    readonly property var layoutOrder: ["icon", "class", "title", "pid"]

    readonly property Draft editor: Draft {
        owner: root
    }

    function parseList(raw) {
        if (raw === undefined || raw === null)
            return []
        if (typeof raw !== "string")
            return raw.length !== undefined ? raw : []
        const text = String(raw).trim()
        if (!text.length)
            return []
        try {
            const parsed = JSON.parse(text)
            if (parsed && parsed.length !== undefined)
                return parsed
        } catch (e) {
        }
        return []
    }

    // Class and title excludes. A pattern is 2–80 characters after trimming stars.
    function normalizeExcludes(list) {
        const src = list || []
        const out = []
        const seen = {}
        for (let i = 0; i < src.length && out.length < root.excludeMax; i++) {
            let text = ""
            let kind = "class"
            const item = src[i]
            if (item && typeof item === "object" && item.length === undefined) {
                text = String(item.text || item.pattern || "")
                kind = String(item.kind || "") === "title" ? "title" : "class"
            } else {
                text = String(item || "")
            }
            text = text.replace(/[\r\n]/g, " ").trim()
            if (text.length < 2 || text.length > 80)
                continue
            if (text.replace(/\*/g, "").trim().length < 2)
                continue
            const key = kind + "\n" + text.toLowerCase()
            if (seen[key])
                continue
            seen[key] = true
            out.push({ text: text, kind: kind })
        }
        return out
    }

    function excludeJson(raw) {
        return JSON.stringify(root.normalizeExcludes(root.parseList(raw)))
    }

    function layoutLabel(id) {
        if (id === "icon")
            return "Icon"
        if (id === "class")
            return "Class"
        if (id === "title")
            return "Title"
        if (id === "pid")
            return "PID"
        return ""
    }

    // Every part once, in the saved order. Unknown ids are dropped. A missing
    // part is added at the end, in the default order. This does not turn a
    // part on. Callers that still have the old layout list use it for order.
    function layoutNorm(raw) {
        const src = root.parseList(raw)
        const want = root.layoutOrder
        const out = []
        const seen = {}
        for (let i = 0; i < src.length; i++) {
            const id = String(src[i] || "")
            if (want.indexOf(id) < 0 || seen[id])
                continue
            seen[id] = true
            out.push(id)
        }
        for (let i = 0; i < want.length; i++) {
            if (!seen[want[i]])
                out.push(want[i])
        }
        return out
    }

    function wordChar(ch) {
        if (!ch || !ch.length)
            return false
        const c = ch.charCodeAt(0)
        return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c === 95
    }

    function clipDecor(text, max) {
        let s = String(text || "").replace(/[\r\n]/g, " ")
        if (s.length > max)
            s = s.slice(0, max)
        return s
    }

    function copyPart(item) {
        const id = String(item && item.id || "")
        if (root.layoutOrder.indexOf(id) < 0)
            return null
        return {
            id: id,
            on: !!(item && item.on),
            open: root.clipDecor(item.open, root.formatMarkMax),
            close: root.clipDecor(item.close, root.formatMarkMax),
            gap: root.clipDecor(item.gap, root.formatGapMax),
            tail: root.clipDecor(item.tail, root.formatGapMax)
        }
    }

    // A whole word icon, class, title, or pid. Marks glued to it stay with it.
    function tokenAt(src, i) {
        if (i > 0 && root.wordChar(src.charAt(i - 1)))
            return ""
        const names = root.layoutOrder
        const lower = src.slice(i).toLowerCase()
        for (let n = 0; n < names.length; n++) {
            const name = names[n]
            if (lower.slice(0, name.length) !== name)
                continue
            const after = i + name.length
            if (after < src.length && root.wordChar(src.charAt(after)))
                continue
            return name
        }
        return ""
    }

    // Parts named in the text, in that order. A repeated word is not a second part.
    function formatPieces(raw) {
        const src = String(raw || "").replace(/[\r\n]/g, " ").slice(0, root.formatMax)
        const found = []
        const seen = {}
        let i = 0
        while (i < src.length) {
            const name = root.tokenAt(src, i)
            if (!name.length) {
                i++
                continue
            }
            if (!seen[name]) {
                seen[name] = true
                found.push({ id: name, at: i, len: name.length })
            }
            i += name.length
        }
        const parts = []
        let cursor = 0
        for (let n = 0; n < found.length; n++) {
            const hit = found[n]
            let between = src.slice(cursor, hit.at)
            let open = ""
            while (between.length && open.length < root.formatMarkMax
                    && root.formatOpeners.indexOf(between.charAt(between.length - 1)) >= 0) {
                open = between.charAt(between.length - 1) + open
                between = between.slice(0, -1)
            }
            if (between.length > root.formatGapMax)
                between = between.slice(between.length - root.formatGapMax)
            let after = hit.at + hit.len
            let close = ""
            while (after < src.length && close.length < root.formatMarkMax
                    && root.formatClosers.indexOf(src.charAt(after)) >= 0) {
                close += src.charAt(after)
                after++
            }
            parts.push({
                id: hit.id,
                on: true,
                open: open,
                close: close,
                gap: between,
                tail: ""
            })
            cursor = after
        }
        if (parts.length) {
            let rest = src.slice(cursor)
            if (rest.length > root.formatGapMax)
                rest = rest.slice(0, root.formatGapMax)
            parts[parts.length - 1].tail = rest
        }
        return parts
    }

    function fillParts(list) {
        const out = []
        const seen = {}
        const src = list || []
        for (let i = 0; i < src.length; i++) {
            const part = root.copyPart(src[i])
            if (!part || seen[part.id])
                continue
            seen[part.id] = true
            out.push(part)
        }
        for (let i = 0; i < root.layoutOrder.length; i++) {
            const id = root.layoutOrder[i]
            if (seen[id])
                continue
            out.push({
                id: id,
                on: false,
                open: "",
                close: "",
                gap: out.length ? " " : "",
                tail: ""
            })
        }
        return out
    }

    // Old saves: the layout list, and the PID switch. Other parts are on.
    function legacyParts(layout, showPid) {
        const order = root.layoutNorm(layout)
        const out = []
        for (let i = 0; i < order.length; i++) {
            const id = order[i]
            out.push({
                id: id,
                on: id === "pid" ? !!showPid : true,
                open: "",
                close: "",
                gap: i === 0 ? "" : " ",
                tail: ""
            })
        }
        return out
    }

    // A saved pattern, a typed pattern, or the old layout list. Missing parts
    // are appended off, so a part the user turned off is not turned back on.
    function formatModel(raw, layout, showPid) {
        if (raw && typeof raw !== "string" && raw.length !== undefined) {
            if (!raw.length || typeof raw[0] !== "object")
                return root.legacyParts(raw, showPid)
            return root.fillParts(raw)
        }
        const text = String(raw === undefined || raw === null ? "" : raw).trim()
        if (!text.length)
            return root.legacyParts(layout, showPid)
        if (text.charAt(0) === "[") {
            try {
                const parsed = JSON.parse(text)
                if (parsed && parsed.length !== undefined) {
                    if (!parsed.length || typeof parsed[0] !== "object")
                        return root.legacyParts(parsed, showPid)
                    return root.fillParts(parsed)
                }
            } catch (e) {
            }
        }
        return root.fillParts(root.formatPieces(text))
    }

    function formatJson(parts) {
        return JSON.stringify(root.formatModel(parts))
    }

    // The field text: on parts only. A space before the first part is not shown.
    function formatText(parts) {
        const list = root.formatModel(parts)
        let out = ""
        let shown = 0
        for (let i = 0; i < list.length; i++) {
            const part = list[i]
            if (!part.on)
                continue
            let gap = String(part.gap || "")
            if (shown === 0 && gap.trim() === "")
                gap = ""
            out += gap + String(part.open || "") + part.id + String(part.close || "") + String(part.tail || "")
            shown++
        }
        return out
    }

    // Words in the text turn on and take their new marks. A word that is
    // missing stays off and keeps the marks it already had.
    function formatApply(typed, previous) {
        const prev = root.formatModel(previous)
        const pieces = root.formatPieces(typed)
        const mentioned = {}
        const out = []
        for (let i = 0; i < pieces.length; i++) {
            mentioned[pieces[i].id] = true
            out.push(pieces[i])
        }
        for (let i = 0; i < prev.length; i++) {
            if (mentioned[prev[i].id])
                continue
            const kept = root.copyPart(prev[i])
            if (!kept)
                continue
            kept.on = false
            out.push(kept)
        }
        return root.fillParts(out)
    }

    function formatToggle(parts, id) {
        const list = root.formatModel(parts)
        const want = String(id || "")
        const out = []
        for (let i = 0; i < list.length; i++) {
            const part = root.copyPart(list[i])
            if (!part)
                continue
            if (part.id === want)
                part.on = !part.on
            out.push(part)
        }
        return out
    }

    // Drag reorder. The part that was first keeps a normal space once it
    // is no longer first, unless it already had its own marks or gap.
    function formatMove(parts, from, to) {
        const cur = root.formatModel(parts)
        const n = cur.length
        const a = Number(from)
        const b = Number(to)
        if (!(a >= 0) || !(b >= 0) || a >= n || b >= n || a === b)
            return cur
        let firstId = ""
        for (let i = 0; i < cur.length; i++) {
            if (cur[i].on) {
                firstId = cur[i].id
                break
            }
        }
        const held = cur[a]
        cur.splice(a, 1)
        cur.splice(b, 0, held)
        let seen = false
        for (let i = 0; i < cur.length; i++) {
            const part = cur[i]
            if (!part.on)
                continue
            const gap = String(part.gap || "")
            const custom = gap !== "" && gap !== " "
            if (!seen) {
                seen = true
                continue
            }
            if (!custom && gap === "" && part.id === firstId)
                part.gap = " "
            seen = true
        }
        return cur
    }

    // Skip a part that is off or has an empty value, and the marks around it.
    function formatPlain(parts, values) {
        const list = root.formatModel(parts)
        const map = values || {}
        let out = ""
        let shown = 0
        for (let i = 0; i < list.length; i++) {
            const part = list[i]
            if (!part.on)
                continue
            const value = map[part.id] === undefined || map[part.id] === null ? "" : String(map[part.id])
            if (!value.length)
                continue
            let gap = String(part.gap || "")
            if (shown === 0 && gap.trim() === "")
                gap = ""
            out += gap + String(part.open || "") + value + String(part.close || "") + String(part.tail || "")
            shown++
        }
        return out.replace(/^\s+/, "").replace(/\s+$/, "")
    }

    function cornerNorm(corner) {
        const c = String(corner || "")
        if (c === "topRight" || c === "bottomLeft" || c === "bottomRight")
            return c
        return "topLeft"
    }

    function widthNorm(px) {
        const step = Math.max(1, Theme.activeWindowWidthStep)
        let n = Math.round(Number(px) / step) * step
        if (!(n >= Theme.activeWindowWidthMin))
            n = Theme.activeWindowWidthMin
        if (n > Theme.activeWindowWidthMax)
            n = Theme.activeWindowWidthMax
        return n
    }

    // Saved values, for the panel.
    function cornerValue() {
        return root.cornerNorm(Config.activeWindowPillCorner)
    }

    function widthValue() {
        return root.widthNorm(Config.activeWindowPillWidth)
    }

    function formatValue() {
        return root.formatModel(Config.activeWindowFormat, Config.activeWindowLayoutJson, Config.activeWindowShowPid)
    }

    function savedExcludes() {
        return root.normalizeExcludes(root.parseList(Config.activeWindowExcludesJson))
    }

    // The draft's excludes as a list, for the settings page.
    function draftExcludes() {
        return root.normalizeExcludes(root.parseList(root.editor.value.excludes))
    }

    function draftModel() {
        return root.formatModel(root.editor.value.format)
    }

    function normalize(src) {
        const model = root.formatModel(src.format, src.layout, src.showPid)
        return {
            show: !!src.show,
            corner: root.cornerNorm(src.corner),
            width: root.widthNorm(src.width),
            format: root.formatJson(model),
            excludes: root.excludeJson(src.excludes)
        }
    }

    function snapshot() {
        return root.normalize({
            show: Config.showActiveWindowPill,
            corner: Config.activeWindowPillCorner,
            width: Config.activeWindowPillWidth,
            format: Config.activeWindowFormat,
            layout: Config.activeWindowLayoutJson,
            showPid: Config.activeWindowShowPid,
            excludes: Config.activeWindowExcludesJson
        })
    }

    function defaults() {
        return {
            show: true,
            corner: "topLeft",
            width: Theme.activeWindowWidthDefault,
            format: root.formatJson(root.legacyParts(root.layoutOrder, false)),
            excludes: "[\"hypr-screensaver\"]"
        }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        const model = root.formatModel(clean.format)
        const order = []
        let showPid = false
        for (let i = 0; i < model.length; i++) {
            order.push(model[i].id)
            if (model[i].id === "pid" && model[i].on)
                showPid = true
        }
        Config.saveFields(() => {
            Config.showActiveWindowPill = clean.show
            Config.activeWindowPillCorner = clean.corner
            Config.activeWindowPillWidth = clean.width
            Config.activeWindowShowPid = showPid
            Config.activeWindowLayoutJson = JSON.stringify(order)
            Config.activeWindowFormat = clean.format
            Config.activeWindowExcludesJson = clean.excludes
        })
    }
}
