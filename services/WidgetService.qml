pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.theme

// Widget catalog, zone order, width scales, and active-window excludes.
// The bar draws only the widgets that exist. The rest keep a place in settings.
Singleton {
    id: root

    // Launchers 2–4 appear only while launcherCount includes them. Their pins stay stored.
    readonly property var catalog: root.buildCatalog()

    readonly property var layoutEntries: root.normalizeLayout(
        root.parseList(Config.widgetLayoutJson),
        Config.barLayoutMode !== "dual")

    readonly property int screenWidth: {
        const main = ScreenService.mainScreen
        if (!main)
            return Theme.uiDesignWidth
        const width = Number(main.width)
        return width > 0 ? width : Theme.uiDesignWidth
    }

    readonly property real uiScale: {
        const manual = Number(Config.uiScaleManual)
        const width = root.screenWidth
        let scale = manual > 0 ? manual : width / Theme.uiDesignWidth
        if (scale < Theme.uiScaleMin)
            scale = Theme.uiScaleMin
        if (scale > Theme.uiScaleMax)
            scale = Theme.uiScaleMax
        return scale
    }

    // Bars page edits stay here until Apply. The bar itself keeps reading Config.
    property var editorLayout: []
    property string editorScalesJson: ""
    property var editorShown: ({})
    property bool editorShowTop: true
    property bool editorShowBottom: false
    property bool editorShowLeft: false
    property bool editorShowRight: false
    property string editorAlignTop: "left"
    property string editorAlignBottom: "left"
    property string editorAlignLeft: "left"
    property string editorAlignRight: "left"
    property bool editorSpanTop: false
    property bool editorSpanBottom: false
    property bool editorSpanLeft: false
    property bool editorSpanRight: false
    property real editorUiScale: 0
    property bool editorFlush: false
    property var editorAutoHide: ({ top: false, bottom: false, left: false, right: false })
    property var editorMonitors: ({ top: "", bottom: "", left: "", right: "" })
    property int editorHideDelay: 600
    property int editorRevealDelay: 150
    property bool editorReady: false
    property bool editorDirty: false
    property bool undoReady: false
    property var undoState: null

    readonly property bool uiScaleAuto: root.editorReady
        ? !(Number(root.editorUiScale) > 0)
        : !(Number(Config.uiScaleManual) > 0)
    readonly property int uiScalePercent: {
        if (root.editorReady && Number(root.editorUiScale) > 0)
            return Math.round(Number(root.editorUiScale) * 100)
        return Math.round(root.uiScale * 100)
    }
    readonly property bool flushWindows: root.editorReady ? root.editorFlush : Config.flushWindowsToBar
    readonly property int gapsTop: HyprGaps.top
    readonly property int gapsRight: HyprGaps.right
    readonly property int gapsBottom: HyprGaps.bottom
    readonly property int gapsLeft: HyprGaps.left

    function launcherId(n) {
        const index = Math.round(Number(n))
        if (index <= 1)
            return "quickLaunch"
        return "quickLaunch" + index
    }

    // How far a bar popup moves in from the outer edge of its bar window,
    // toward the bar. The window is the bar plus a band for the dock's
    // zoom; popups sit Theme.popupGapCut of the way across that band.
    // content is the bar window's content item.
    function popupInset(content, edge) {
        if (!content)
            return 0
        const thick = Math.max(1, Math.round(Theme.barHeight * root.uiScale))
        const across = edge === "left" || edge === "right" ? content.width : content.height
        return Math.round(Math.max(0, across - thick) * Theme.popupGapCut)
    }

    // Put a bar menu on the screen side of its bar, centered on the bar
    // rather than on the icon. A side bar centers it vertically, so a tall
    // menu stays on the monitor when the widget sits low. A top or bottom
    // bar centers it horizontally, so a wide menu stays on the monitor when
    // the widget sits at one end. The anchor rect is in the widget's own
    // coordinates (a side bar turns the pill). nudge shifts it once so a
    // just-opened menu repositions.
    function placePopup(item, anchor, edge, nudge) {
        const content = item && item.Window ? item.Window.contentItem : null
        if (!content || !anchor)
            return
        const inset = root.popupInset(content, edge)
        let x = Math.round(content.width / 2)
        let y = Math.round(content.height) - inset
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (edge === "bottom") {
            y = inset
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (edge === "left") {
            x = Math.round(content.width) - inset
            y = Math.round(content.height / 2)
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (edge === "right") {
            x = inset
            y = Math.round(content.height / 2)
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const local = item.mapFromItem(content, x, y, 1, 1)
        const lx = Math.round(local.x)
        const ly = Math.round(local.y)
        // qmllint disable missing-property
        if (anchor.edges !== edgeFlags)
            anchor.edges = edgeFlags
        if (anchor.gravity !== grow)
            anchor.gravity = grow
        if (nudge)
            anchor.rect = Qt.rect(lx + 3, ly + 3, 1, 1)
        const r = anchor.rect
        if (nudge || !r || r.x !== lx || r.y !== ly || r.width !== 1 || r.height !== 1)
            anchor.rect = Qt.rect(lx, ly, 1, 1)
        // qmllint enable missing-property
    }

    // BarSlot turns a side-bar pill 90° clockwise so it lies along the bar.
    // A pill's icon turns back by this much so it stays upright:
    // rotation: WidgetService.iconTurn(root.edge). Text that runs along
    // the bar keeps the pill's turn.
    function iconTurn(edge) {
        return edge === "left" || edge === "right" ? -90 : 0
    }

    function launcherLabel(n) {
        const count = LauncherSettings.slots()
        const index = Math.round(Number(n))
        if (count <= 1)
            return "Quick Launch"
        return "Quick Launch " + index
    }

    function isLauncherId(id) {
        const key = String(id || "")
        return key === "quickLaunch" || key === "quickLaunch2"
            || key === "quickLaunch3" || key === "quickLaunch4"
    }

    function launcherPinCount(id) {
        const key = String(id || "")
        let index = 1
        if (key === "quickLaunch2")
            index = 2
        else if (key === "quickLaunch3")
            index = 3
        else if (key === "quickLaunch4")
            index = 4
        else if (key !== "quickLaunch")
            return 0
        const boards = LauncherSettings.savedBoards()
        const row = boards[index - 1]
        if (!row || row.length === undefined)
            return 0
        return row.length
    }

    function statsDrawn() {
        return StatsSettings.anyShown()
    }

    // The per-metric System Stats widgets, in bar order.
    readonly property var statMetricIds: ["statCpu", "statMem", "statGpu", "statVram"]

    function isStatMetric(id) {
        return root.statMetricIds.indexOf(String(id || "")) >= 0
    }

    // The separate Speaker and Microphone widgets.
    readonly property var audioPartIds: ["audioOut", "audioIn"]

    function isAudioPart(id) {
        return root.audioPartIds.indexOf(String(id || "")) >= 0
    }

    // Entries the current System Stats or Audio mode does not draw. They
    // keep their place in the layout, so switching modes back restores it.
    function parked(id) {
        const key = String(id || "")
        if (root.isStatMetric(key))
            return Config.statsCombined
        if (key === "stats")
            return !Config.statsCombined
        if (root.isAudioPart(key))
            return Config.audioCombined
        if (key === "volume")
            return !Config.audioCombined
        return false
    }

    function buildCatalog() {
        const count = LauncherSettings.slots()
        const rows = [
            { id: "launcher", label: "Application Menu" }
        ]
        for (let n = 1; n <= count; n++)
            rows.push({ id: root.launcherId(n), label: root.launcherLabel(n) })
        rows.push(
            { id: "freshRss", label: "FreshRSS" },
            { id: "clipboard", label: "Clipboard" },
            { id: "caffeine", label: "Caffeine" },
            { id: "nightLight", label: "Night Light" },
            { id: "recorder", label: "Screen Recorder" },
            { id: "firewall", label: "Firewall" },
            { id: "battery", label: "Battery (laptops)" },
            { id: "brightness", label: "Brightness (laptops)" },
            { id: "workspaces", label: "Workspaces" },
            { id: "stats", label: "System Stats" },
            { id: "statCpu", label: "System Stats · CPU" },
            { id: "statMem", label: "System Stats · Memory" },
            { id: "statGpu", label: "System Stats · GPU" },
            { id: "statVram", label: "System Stats · VRAM" },
            { id: "tray", label: "System Tray" },
            { id: "networkPanel", label: "Network" },
            { id: "bluetooth", label: "Bluetooth" },
            { id: "clock", label: "Clock" },
            { id: "notifications", label: "Notifications" },
            { id: "volume", label: "Audio" },
            { id: "audioOut", label: "Audio · Speaker" },
            { id: "audioIn", label: "Audio · Microphone" },
            { id: "hyprInsp", label: "Inspector" },
            { id: "controlBar", label: "Config Menu Icon" },
            { id: "tailscale", label: "Tailscale" },
            { id: "opacity", label: "Transparency" },
            { id: "power", label: "Power" }
        )
        return rows
    }

    function defaultLayout() {
        const rows = [
            { id: "controlBar", zone: "top" },
            { id: "workspaces", zone: "top" },
            { id: "clock", zone: "bottom" },
            { id: "tray", zone: "bottom" },
            { id: "notifications", zone: "bottom" },
            { id: "volume", zone: "bottom" },
            { id: "audioOut", zone: "bottom" },
            { id: "audioIn", zone: "bottom" },
            { id: "power", zone: "bottom" },
            { id: "hyprInsp", zone: "bottom" },
            { id: "stats", zone: "bottom" },
            { id: "statCpu", zone: "bottom" },
            { id: "statMem", zone: "bottom" },
            { id: "statGpu", zone: "bottom" },
            { id: "statVram", zone: "bottom" },
            { id: "launcher", zone: "bottom" }
        ]
        const count = LauncherSettings.slots()
        for (let n = 1; n <= count; n++)
            rows.push({ id: root.launcherId(n), zone: "bottom" })
        rows.push(
            { id: "freshRss", zone: "bottom" },
            { id: "clipboard", zone: "bottom" },
            { id: "caffeine", zone: "bottom" },
            { id: "nightLight", zone: "bottom" },
            { id: "recorder", zone: "bottom" },
            { id: "firewall", zone: "bottom" },
            { id: "brightness", zone: "bottom" },
            { id: "battery", zone: "bottom" },
            { id: "opacity", zone: "bottom" },
            { id: "networkPanel", zone: "bottom" },
            { id: "bluetooth", zone: "bottom" },
            { id: "tailscale", zone: "bottom" }
        )
        return rows
    }

    function parseList(raw) {
        if (raw === undefined || raw === null)
            return []
        if (typeof raw !== "string") {
            if (raw.length !== undefined)
                return raw
            return []
        }
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

    function parseObject(raw) {
        if (raw && typeof raw === "object" && raw.length === undefined)
            return raw
        const text = String(raw || "").trim()
        if (!text.length)
            return null
        try {
            const parsed = JSON.parse(text)
            if (parsed && typeof parsed === "object" && parsed.length === undefined)
                return parsed
        } catch (e) {
        }
        return null
    }

    function isDivider(id) {
        return /^divider[1-8]$/.test(String(id || ""))
    }

    function isImplemented(id) {
        const key = String(id || "")
        return key === "controlBar" || key === "workspaces" || key === "clock"
            || key === "tray" || key === "power" || key === "opacity"
            || key === "networkPanel" || key === "bluetooth" || key === "launcher"
            || key === "stats" || key === "notifications" || key === "volume"
            || key === "tailscale" || key === "hyprInsp" || key === "freshRss" || key === "clipboard"
            || key === "caffeine" || key === "nightLight" || key === "recorder" || key === "firewall"
            || key === "battery" || key === "brightness"
            || root.isStatMetric(key) || root.isAudioPart(key) || root.isLauncherId(key)
    }

    function labelFor(id) {
        const key = String(id || "")
        const cat = root.catalog
        for (let i = 0; i < cat.length; i++) {
            if (cat[i].id === key)
                return String(cat[i].label || key)
        }
        return key
    }

    function coerceZone(zone, classic) {
        const z = String(zone || "")
        if (classic) {
            if (z === "right" || z === "bottom")
                return "bottom"
            return "top"
        }
        if (z === "top" || z === "bottom" || z === "left" || z === "right")
            return z
        if (z === "center")
            return "top"
        return "top"
    }

    function knownId(id) {
        const key = String(id || "")
        if (root.isDivider(key))
            return true
        const cat = root.catalog
        for (let i = 0; i < cat.length; i++) {
            if (cat[i].id === key)
                return true
        }
        return false
    }

    function normalizeLayout(arr, classic) {
        const out = []
        const seen = {}
        const list = arr || []
        for (let i = 0; i < list.length; i++) {
            const entry = list[i]
            if (!entry || !entry.id)
                continue
            let id = String(entry.id)
            if (id === "audio")
                id = "connectivity"
            if (!root.knownId(id) || seen[id])
                continue
            seen[id] = true
            out.push({ id: id, zone: root.coerceZone(entry.zone, classic) })
        }
        const defaults = root.defaultLayout()
        for (let i = 0; i < defaults.length; i++) {
            const id = defaults[i].id
            if (seen[id])
                continue
            seen[id] = true
            // A missing split widget starts next to its combined one.
            let after = -1
            if (root.isStatMetric(id))
                after = root.lastGroupIndex(out, ["stats"].concat(root.statMetricIds))
            else if (root.isAudioPart(id))
                after = root.lastGroupIndex(out, ["volume"].concat(root.audioPartIds))
            if (after >= 0)
                out.splice(after + 1, 0, { id: id, zone: out[after].zone })
            else
                out.push({ id: id, zone: defaults[i].zone })
        }
        return out
    }

    // Index of the last entry whose id is in ids, or -1.
    function lastGroupIndex(list, ids) {
        let at = -1
        for (let i = 0; i < list.length; i++) {
            if (ids.indexOf(list[i].id) >= 0)
                at = i
        }
        return at
    }

    function copyLayout(src) {
        const list = src || []
        const out = []
        for (let i = 0; i < list.length; i++)
            out.push({ id: list[i].id, zone: list[i].zone })
        return out
    }

    function editingLayout() {
        if (root.editorReady)
            return root.editorLayout
        return root.layoutEntries
    }

    function layoutCopy() {
        return root.copyLayout(root.editingLayout())
    }

    function writeLayout(layout, turnLeft, turnRight, turnTop, turnBottom) {
        root.ensureEditor()
        root.editorLayout = layout
        if (turnLeft)
            root.editorShowLeft = true
        if (turnRight)
            root.editorShowRight = true
        if (turnTop)
            root.editorShowTop = true
        if (turnBottom)
            root.editorShowBottom = true
        root.editorDirty = true
    }

    function visible(id) {
        if (BarSettings.isWidget(id))
            return BarSettings.shown(id)
        return root.isDivider(id)
    }

    function zoneEntries(zone) {
        const all = root.editingLayout()
        const rows = []
        for (let i = 0; i < all.length; i++) {
            if (all[i].zone === zone && !root.parked(all[i].id))
                rows.push(all[i])
        }
        const out = []
        for (let i = 0; i < rows.length; i++) {
            const id = String(rows[i].id)
            const divider = root.isDivider(id)
            const number = divider ? id.substring(7) : ""
            out.push({
                id: id,
                zone: zone,
                label: divider ? ("|  Divider " + number) : root.labelFor(id),
                divider: divider
            })
        }
        return out
    }

    function barEntries(zone) {
        const all = root.layoutEntries
        const out = []
        for (let i = 0; i < all.length; i++) {
            if (all[i].zone !== zone || root.parked(all[i].id))
                continue
            const id = String(all[i].id)
            if (root.isDivider(id)) {
                out.push({ id: id })
                continue
            }
            if (root.isImplemented(id) && root.visible(id))
                out.push({ id: id })
        }
        return out
    }

    function toggle(id) {
        const key = String(id || "")
        if (root.isDivider(key)) {
            root.removeDivider(key)
            return
        }
        if (key === "activeWindow") {
            BarSettings.setShown(key, !root.visible(key))
            return
        }
        root.ensureEditor()
        const src = root.editorShown || {}
        const next = {}
        const names = Object.keys(src)
        for (let i = 0; i < names.length; i++)
            next[names[i]] = src[names[i]]
        next[key] = !root.editorVisible(key)
        root.editorShown = next
        root.editorDirty = true
    }

    function place(id, zone, index) {
        const key = String(id || "")
        const target = root.coerceZone(zone, false)
        let at = Math.round(Number(index))
        if (!key.length || isNaN(at))
            return
        const layout = root.layoutCopy()
        let from = -1
        for (let i = 0; i < layout.length; i++) {
            if (layout[i].id === key) {
                from = i
                break
            }
        }
        if (from < 0)
            return
        const fromZone = layout[from].zone
        const zoneIds = []
        for (let i = 0; i < layout.length; i++) {
            if (layout[i].zone === target && !root.parked(layout[i].id))
                zoneIds.push(layout[i].id)
        }
        if (at < 0)
            at = 0
        if (at > zoneIds.length)
            at = zoneIds.length
        let local = at
        if (fromZone === target) {
            let localFrom = -1
            for (let i = 0; i < zoneIds.length; i++) {
                if (zoneIds[i] === key) {
                    localFrom = i
                    break
                }
            }
            if (local === localFrom || local === localFrom + 1)
                return
            if (localFrom >= 0 && localFrom < local)
                local -= 1
        }
        const moving = { id: key, zone: target }
        const next = []
        for (let i = 0; i < layout.length; i++) {
            if (i !== from)
                next.push(layout[i])
        }
        let seen = 0
        let insertAt = next.length
        for (let i = 0; i < next.length; i++) {
            if (next[i].zone === target && !root.parked(next[i].id)) {
                if (seen === local) {
                    insertAt = i
                    break
                }
                seen++
            }
        }
        next.splice(insertAt, 0, moving)
        const moved = fromZone !== target
        root.writeLayout(
            next,
            moved && target === "left",
            moved && target === "right",
            moved && target === "top",
            moved && target === "bottom")
    }

    function move(id, delta) {
        const key = String(id || "")
        const layout = root.layoutCopy()
        let idx = -1
        for (let i = 0; i < layout.length; i++) {
            if (layout[i].id === key) {
                idx = i
                break
            }
        }
        if (idx < 0)
            return
        const zone = layout[idx].zone
        const zoneIdxs = []
        for (let i = 0; i < layout.length; i++) {
            if (layout[i].zone === zone && !root.parked(layout[i].id))
                zoneIdxs.push(i)
        }
        let pos = -1
        for (let i = 0; i < zoneIdxs.length; i++) {
            if (zoneIdxs[i] === idx) {
                pos = i
                break
            }
        }
        const next = pos + (delta < 0 ? -1 : 1)
        if (pos < 0 || next < 0 || next >= zoneIdxs.length)
            return
        const swap = zoneIdxs[next]
        const tmp = layout[idx]
        layout[idx] = layout[swap]
        layout[swap] = tmp
        root.writeLayout(layout, false, false, false, false)
    }

    function addDivider() {
        const layout = root.layoutCopy()
        const used = {}
        for (let i = 0; i < layout.length; i++)
            used[layout[i].id] = true
        let id = ""
        for (let n = 1; n <= 8; n++) {
            const cand = "divider" + n
            if (!used[cand]) {
                id = cand
                break
            }
        }
        if (!id.length)
            return
        layout.push({ id: id, zone: "bottom" })
        root.writeLayout(layout, false, false, false, false)
    }

    function canAddDivider() {
        const layout = root.editingLayout()
        let count = 0
        for (let i = 0; i < layout.length; i++) {
            if (root.isDivider(layout[i].id))
                count++
        }
        return count < 8
    }

    function removeDivider(id) {
        if (!root.isDivider(id))
            return
        const layout = root.layoutCopy()
        const next = []
        for (let i = 0; i < layout.length; i++) {
            if (layout[i].id !== id)
                next.push(layout[i])
        }
        root.writeLayout(next, false, false, false, false)
    }

    function resetLayout() {
        root.ensureEditor()
        root.editorLayout = root.defaultLayout()
        root.editorShowTop = true
        root.editorDirty = true
    }

    function barEnabled(edge) {
        if (!root.editorReady) {
            switch (String(edge || "")) {
            case "bottom": return Config.showBottomBar
            case "left": return Config.showLeftBar
            case "right": return Config.showRightBar
            case "top": return Config.showTopBar
            default: return false
            }
        }
        switch (String(edge || "")) {
        case "bottom": return root.editorShowBottom
        case "left": return root.editorShowLeft
        case "right": return root.editorShowRight
        case "top": return root.editorShowTop
        default: return false
        }
    }

    function setBarEnabled(edge, on) {
        root.ensureEditor()
        const next = !!on
        switch (String(edge || "")) {
        case "top":
            if (root.editorShowTop === next)
                return
            root.editorShowTop = next
            break
        case "bottom":
            if (root.editorShowBottom === next)
                return
            root.editorShowBottom = next
            break
        case "left":
            if (root.editorShowLeft === next)
                return
            root.editorShowLeft = next
            break
        case "right":
            if (root.editorShowRight === next)
                return
            root.editorShowRight = next
            break
        default:
            return
        }
        root.editorDirty = true
    }

    function barAlign(edge) {
        let value = "left"
        switch (String(edge || "")) {
        case "bottom":
            value = root.editorReady ? root.editorAlignBottom : String(Config.bottomBarAlign || "")
            break
        case "left":
            value = root.editorReady ? root.editorAlignLeft : String(Config.leftBarAlign || "")
            break
        case "right":
            value = root.editorReady ? root.editorAlignRight : String(Config.rightBarAlign || "")
            break
        case "top":
            value = root.editorReady ? root.editorAlignTop : String(Config.topBarAlign || "")
            break
        }
        if (value === "left" || value === "right" || value === "center")
            return value
        return "left"
    }

    function setBarAlign(edge, align) {
        root.ensureEditor()
        const next = root.normalizeAlign(align)
        switch (String(edge || "")) {
        case "top":
            if (root.editorAlignTop === next)
                return
            root.editorAlignTop = next
            break
        case "bottom":
            if (root.editorAlignBottom === next)
                return
            root.editorAlignBottom = next
            break
        case "left":
            if (root.editorAlignLeft === next)
                return
            root.editorAlignLeft = next
            break
        case "right":
            if (root.editorAlignRight === next)
                return
            root.editorAlignRight = next
            break
        default:
            return
        }
        root.editorDirty = true
    }

    // The monitor one bar is on: a name, or "" for every bar monitor.
    function barMonitor(edge) {
        const key = String(edge || "")
        const map = root.editorReady ? root.editorMonitors : BarSettings.monitorsSnapshot()
        return String(map[key] || "")
    }

    function setBarMonitor(edge, name) {
        const key = String(edge || "")
        if (BarSettings.edges.indexOf(key) < 0)
            return
        root.ensureEditor()
        const next = Object.assign({}, root.editorMonitors)
        next[key] = String(name || "")
        const clean = BarSettings.monitorsNorm(next)
        if (clean[key] === root.editorMonitors[key])
            return
        root.editorMonitors = clean
        root.editorDirty = true
    }

    // Auto-hide per edge, and the shared delays (draft while editing).
    function barAutoHides(edge) {
        const key = String(edge || "")
        return root.editorReady ? !!root.editorAutoHide[key] : BarSettings.autoHides(key)
    }

    function setBarAutoHides(edge, on) {
        const key = String(edge || "")
        if (BarSettings.edges.indexOf(key) < 0)
            return
        root.ensureEditor()
        if (!!root.editorAutoHide[key] === !!on)
            return
        const next = Object.assign({}, root.editorAutoHide)
        next[key] = !!on
        root.editorAutoHide = next
        root.editorDirty = true
    }

    function hideDelay() {
        return root.editorReady ? root.editorHideDelay : BarSettings.hideDelayValue()
    }

    function revealDelay() {
        return root.editorReady ? root.editorRevealDelay : BarSettings.revealDelayValue()
    }

    function setHideDelay(ms) {
        root.ensureEditor()
        const next = BarSettings.hideDelayNorm(ms)
        if (next === root.editorHideDelay)
            return
        root.editorHideDelay = next
        root.editorDirty = true
    }

    function setRevealDelay(ms) {
        root.ensureEditor()
        const next = BarSettings.revealDelayNorm(ms)
        if (next === root.editorRevealDelay)
            return
        root.editorRevealDelay = next
        root.editorDirty = true
    }

    function barSpans(edge) {
        if (!root.editorReady) {
            switch (String(edge || "")) {
            case "bottom": return Config.panelSpanFull
            case "left": return Config.leftBarSpanFull
            case "right": return Config.rightBarSpanFull
            case "top": return Config.barSpanFull
            default: return false
            }
        }
        switch (String(edge || "")) {
        case "bottom": return root.editorSpanBottom
        case "left": return root.editorSpanLeft
        case "right": return root.editorSpanRight
        case "top": return root.editorSpanTop
        default: return false
        }
    }

    function setBarSpans(edge, on) {
        root.ensureEditor()
        const next = !!on
        switch (String(edge || "")) {
        case "top":
            if (root.editorSpanTop === next)
                return
            root.editorSpanTop = next
            break
        case "bottom":
            if (root.editorSpanBottom === next)
                return
            root.editorSpanBottom = next
            break
        case "left":
            if (root.editorSpanLeft === next)
                return
            root.editorSpanLeft = next
            break
        case "right":
            if (root.editorSpanRight === next)
                return
            root.editorSpanRight = next
            break
        default:
            return
        }
        root.editorDirty = true
    }

    function setUiScaleAuto(on) {
        root.ensureEditor()
        if (on) {
            if (!(Number(root.editorUiScale) > 0))
                return
            root.editorUiScale = 0
            root.editorDirty = true
            return
        }
        if (Number(root.editorUiScale) > 0)
            return
        let percent = Math.round(root.uiScale * 100 / 5) * 5
        const min = Math.round(Theme.uiScaleMin * 100)
        const max = Math.round(Theme.uiScaleMax * 100)
        if (percent < min)
            percent = min
        if (percent > max)
            percent = max
        root.editorUiScale = percent / 100
        root.editorDirty = true
    }

    function setUiScalePercent(percent) {
        root.ensureEditor()
        let next = Math.round(Number(percent) / 5) * 5
        const min = Math.round(Theme.uiScaleMin * 100)
        const max = Math.round(Theme.uiScaleMax * 100)
        if (!(next >= min))
            next = min
        if (next > max)
            next = max
        const value = next / 100
        if (Math.abs(Number(root.editorUiScale) - value) < 0.001)
            return
        root.editorUiScale = value
        root.editorDirty = true
    }

    function setFlushWindows(on) {
        root.ensureEditor()
        const next = !!on
        if (root.editorFlush === next)
            return
        root.editorFlush = next
        root.editorDirty = true
    }

    function parseScale(raw) {
        const parsed = root.parseObject(raw)
        const out = {}
        if (!parsed)
            return out
        const keys = Object.keys(parsed)
        for (let i = 0; i < keys.length; i++) {
            const n = Number(parsed[keys[i]])
            if (n >= 0.8 && n <= 1.8)
                out[keys[i]] = Math.round(n * 100) / 100
        }
        return out
    }

    function scaleMap() {
        return root.parseScale(Config.widgetScalesJson)
    }

    function scaleOf(id) {
        const map = root.scaleMap()
        const n = map[String(id || "")]
        if (n === undefined || n === null)
            return 1
        return n
    }

    function scalePercent(id) {
        const map = root.editorReady ? root.parseScale(root.editorScalesJson) : root.scaleMap()
        const n = map[String(id || "")]
        if (n === undefined || n === null)
            return 100
        return Math.round(Number(n) * 100)
    }

    function setScale(id, percent) {
        const key = String(id || "")
        if (!key.length || !root.knownId(key))
            return
        let p = Math.round(Number(percent) / 5) * 5
        if (!(p >= 80))
            p = 80
        if (p > 180)
            p = 180
        const factor = Math.round(p) / 100
        root.ensureEditor()
        const map = root.parseScale(root.editorScalesJson)
        const prev = map[key] !== undefined ? Number(map[key]) : 1
        if (Math.abs(prev - factor) < 0.001)
            return
        const next = {}
        const keys = Object.keys(map)
        for (let i = 0; i < keys.length; i++) {
            if (keys[i] !== key)
                next[keys[i]] = map[keys[i]]
        }
        if (Math.abs(factor - 1) >= 0.001)
            next[key] = factor
        const names = Object.keys(next)
        root.editorScalesJson = names.length ? JSON.stringify(next) : ""
        root.editorDirty = true
    }

    function resetScales() {
        root.ensureEditor()
        if (!String(root.editorScalesJson || "").length)
            return
        root.editorScalesJson = ""
        root.editorDirty = true
    }

    function normalizeAlign(value) {
        const text = String(value || "")
        if (text === "left" || text === "right")
            return text
        return "center"
    }

    function shownSnapshot() {
        return BarSettings.shownSnapshot()
    }

    function editorVisible(id) {
        const key = String(id || "")
        if (key === "activeWindow")
            return Config.showActiveWindowPill
        if (root.isDivider(key))
            return true
        if (!root.editorReady)
            return root.visible(key)
        const shown = root.editorShown
        if (!shown || shown[key] === undefined)
            return root.visible(key)
        return !!shown[key]
    }

    function appliedState() {
        return {
            layout: JSON.stringify(root.copyLayout(root.layoutEntries)),
            scales: String(Config.widgetScalesJson || ""),
            shown: root.shownSnapshot(),
            showTopBar: !!Config.showTopBar,
            showBottomBar: !!Config.showBottomBar,
            showLeftBar: !!Config.showLeftBar,
            showRightBar: !!Config.showRightBar,
            topBarAlign: root.normalizeAlign(Config.topBarAlign),
            bottomBarAlign: root.normalizeAlign(Config.bottomBarAlign),
            leftBarAlign: root.normalizeAlign(Config.leftBarAlign),
            rightBarAlign: root.normalizeAlign(Config.rightBarAlign),
            barSpanFull: !!Config.barSpanFull,
            panelSpanFull: !!Config.panelSpanFull,
            leftBarSpanFull: !!Config.leftBarSpanFull,
            rightBarSpanFull: !!Config.rightBarSpanFull,
            uiScaleManual: Number(Config.uiScaleManual) > 0 ? Number(Config.uiScaleManual) : 0,
            flushWindowsToBar: !!Config.flushWindowsToBar,
            autoHide: BarSettings.autoHideSnapshot(),
            barMonitors: BarSettings.monitorsSnapshot(),
            hideDelayMs: BarSettings.hideDelayValue(),
            revealDelayMs: BarSettings.revealDelayValue()
        }
    }

    function editorState() {
        return {
            layout: JSON.stringify(root.copyLayout(root.editorLayout)),
            scales: String(root.editorScalesJson || ""),
            shown: root.editorShown,
            showTopBar: !!root.editorShowTop,
            showBottomBar: !!root.editorShowBottom,
            showLeftBar: !!root.editorShowLeft,
            showRightBar: !!root.editorShowRight,
            topBarAlign: root.normalizeAlign(root.editorAlignTop),
            bottomBarAlign: root.normalizeAlign(root.editorAlignBottom),
            leftBarAlign: root.normalizeAlign(root.editorAlignLeft),
            rightBarAlign: root.normalizeAlign(root.editorAlignRight),
            barSpanFull: !!root.editorSpanTop,
            panelSpanFull: !!root.editorSpanBottom,
            leftBarSpanFull: !!root.editorSpanLeft,
            rightBarSpanFull: !!root.editorSpanRight,
            uiScaleManual: Number(root.editorUiScale) > 0 ? Number(root.editorUiScale) : 0,
            flushWindowsToBar: !!root.editorFlush,
            autoHide: Object.assign({}, root.editorAutoHide),
            barMonitors: Object.assign({}, root.editorMonitors),
            hideDelayMs: root.editorHideDelay,
            revealDelayMs: root.editorRevealDelay
        }
    }

    function seedEditor() {
        root.editorLayout = root.copyLayout(root.layoutEntries)
        root.editorScalesJson = String(Config.widgetScalesJson || "")
        root.editorShown = root.shownSnapshot()
        root.editorShowTop = !!Config.showTopBar
        root.editorShowBottom = !!Config.showBottomBar
        root.editorShowLeft = !!Config.showLeftBar
        root.editorShowRight = !!Config.showRightBar
        root.editorAlignTop = root.normalizeAlign(Config.topBarAlign)
        root.editorAlignBottom = root.normalizeAlign(Config.bottomBarAlign)
        root.editorAlignLeft = root.normalizeAlign(Config.leftBarAlign)
        root.editorAlignRight = root.normalizeAlign(Config.rightBarAlign)
        root.editorSpanTop = !!Config.barSpanFull
        root.editorSpanBottom = !!Config.panelSpanFull
        root.editorSpanLeft = !!Config.leftBarSpanFull
        root.editorSpanRight = !!Config.rightBarSpanFull
        root.editorUiScale = Number(Config.uiScaleManual) > 0 ? Number(Config.uiScaleManual) : 0
        root.editorFlush = !!Config.flushWindowsToBar
        root.editorAutoHide = BarSettings.autoHideSnapshot()
        root.editorMonitors = BarSettings.monitorsSnapshot()
        root.editorHideDelay = BarSettings.hideDelayValue()
        root.editorRevealDelay = BarSettings.revealDelayValue()
        root.editorReady = true
        root.editorDirty = false
    }

    function ensureEditor() {
        if (!root.editorReady)
            root.seedEditor()
    }

    // A clean editor reseeds from layoutEntries when the count changes.
    // A dirty editor keeps its other rows and only gains or loses launcher ids.
    function syncLaunchers() {
        if (!root.editorReady || !root.editorDirty)
            return
        const count = LauncherSettings.slots()
        const keep = {}
        for (let n = 1; n <= count; n++)
            keep[root.launcherId(n)] = true
        const next = []
        const seen = {}
        let changed = false
        const cur = root.editorLayout || []
        for (let i = 0; i < cur.length; i++) {
            const id = String(cur[i].id || "")
            if (root.isLauncherId(id) && !keep[id]) {
                changed = true
                continue
            }
            if (seen[id])
                continue
            seen[id] = true
            next.push({ id: id, zone: cur[i].zone })
        }
        for (let n = 1; n <= count; n++) {
            const id = root.launcherId(n)
            if (seen[id])
                continue
            next.push({ id: id, zone: "bottom" })
            seen[id] = true
            changed = true
        }
        if (!changed)
            return
        root.editorLayout = next
        root.editorDirty = true
    }

    function canUndo() {
        return root.editorDirty || root.undoReady
    }

    function applyEditor() {
        if (!root.editorDirty)
            return
        root.undoState = root.appliedState()
        root.undoReady = true
        const next = root.editorState()
        root.editorDirty = false
        BarSettings.apply(next)
        root.seedEditor()
    }

    function undoEditor() {
        if (root.editorDirty) {
            root.seedEditor()
            return
        }
        if (!root.undoReady || !root.undoState)
            return
        const previous = root.undoState
        root.undoReady = false
        root.undoState = null
        root.editorDirty = false
        BarSettings.apply(previous)
        root.seedEditor()
    }

    Component.onCompleted: root.seedEditor()

    Connections {
        target: Config
        function onRevisionChanged() {
            if (!root.editorDirty)
                root.seedEditor()
        }
    }
}
