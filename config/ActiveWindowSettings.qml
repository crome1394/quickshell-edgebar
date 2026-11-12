pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Widgets → Active Window: the corner pill, its width cap, PID, layout, and excludes.
Singleton {
    id: root

    readonly property int excludeMax: 40
    // Left to right, unless Layout says otherwise.
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
    // part is added at the end, in the default order.
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

    function layoutJson(raw) {
        return JSON.stringify(root.layoutNorm(raw))
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

    function savedExcludes() {
        return root.normalizeExcludes(root.parseList(Config.activeWindowExcludesJson))
    }

    // The draft's excludes as a list, for the settings page.
    function draftExcludes() {
        return root.normalizeExcludes(root.parseList(root.editor.value.excludes))
    }

    function normalize(src) {
        return {
            show: !!src.show,
            corner: root.cornerNorm(src.corner),
            width: root.widthNorm(src.width),
            showPid: !!src.showPid,
            layout: root.layoutJson(src.layout),
            excludes: root.excludeJson(src.excludes)
        }
    }

    function snapshot() {
        return root.normalize({
            show: Config.showActiveWindowPill,
            corner: Config.activeWindowPillCorner,
            width: Config.activeWindowPillWidth,
            showPid: Config.activeWindowShowPid,
            layout: Config.activeWindowLayoutJson,
            excludes: Config.activeWindowExcludesJson
        })
    }

    function showPidValue() {
        return !!Config.activeWindowShowPid
    }

    function layoutValue() {
        return root.layoutNorm(Config.activeWindowLayoutJson)
    }

    function draftLayout() {
        return root.layoutNorm(root.editor.value.layout)
    }

    function defaults() {
        return {
            show: true,
            corner: "topLeft",
            width: Theme.activeWindowWidthDefault,
            showPid: false,
            layout: root.layoutJson(root.layoutOrder),
            excludes: "[\"hypr-screensaver\"]"
        }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.showActiveWindowPill = clean.show
            Config.activeWindowPillCorner = clean.corner
            Config.activeWindowPillWidth = clean.width
            Config.activeWindowShowPid = clean.showPid
            Config.activeWindowLayoutJson = clean.layout
            Config.activeWindowExcludesJson = clean.excludes
        })
    }
}
