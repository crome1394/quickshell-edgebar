pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Workspace faces and widget layout. The cycle script reads
// wsSpecialNameCustom and wsSlotsJson from state/bar-layout.json.
// Widget keys keep the old bar's names so a copied layout can load.
Singleton {
    id: root

    readonly property string defaultSpecialName: "magic"
    readonly property string storePath: Quickshell.shellDir + "/state/bar-layout.json"

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

    property bool ready: false
    property bool applying: false
    property bool writing: false
    property int revision: 0

    // Clock page draft. These are not saved. Apply writes the adapter fields.
    property bool launcherEditorReady: false
    property bool launcherEditorDirty: false
    property bool launcherUndoReady: false
    property var launcherUndo: null
    property int editorLauncherCount: 1
    property string editorLaunchJson: "[]"

    // Page drafts. Apply writes the adapter. The bar keeps reading the saved fields.
    property bool ovEditorReady: false
    property bool ovEditorDirty: false
    property bool ovUndoReady: false
    property var ovUndo: null
    property var editorOv: null

    property alias showSpecial: data.wsShowSpecialPill
    property alias showOnlyActive: data.wsShowOnlyActive
    property alias showNumbers: data.wsShowNumbers
    property alias minimumShown: data.wsMinimumShown
    property alias startupWorkspace: data.wsStartupWorkspace
    property alias startupCloseSpecial: data.wsStartupCloseMagic
    property alias hasSlots: data.hasWsSlots
    property alias specialNameCustom: data.wsSpecialNameCustom
    property alias specialLabel: data.wsIconSpecialCustom
    property alias specialFont: data.wsSpecialFont
    property alias specialFontPx: data.wsSpecialFontPx
    property alias specialText: data.wsSpecialText
    property alias specialBold: data.wsSpecialBold
    property alias specialItalic: data.wsSpecialItalic
    property alias specialColor: data.wsSpecialColor
    property alias slotsJson: data.wsSlotsJson

    property alias barLayoutMode: data.barLayoutMode
    property alias showLeftBar: data.showLeftBar
    property alias showRightBar: data.showRightBar
    property alias showTopBar: data.showTopBar
    property alias showBottomBar: data.showBottomBar
    property alias topBarAlign: data.topBarAlign
    property alias bottomBarAlign: data.bottomBarAlign
    property alias leftBarAlign: data.leftBarAlign
    property alias rightBarAlign: data.rightBarAlign
    property alias barSpanFull: data.barSpanFull
    property alias panelSpanFull: data.panelSpanFull
    property alias leftBarSpanFull: data.leftBarSpanFull
    property alias rightBarSpanFull: data.rightBarSpanFull
    property alias uiScaleManual: data.uiScaleManual
    property alias flushWindowsToBar: data.flushWindowsToBar
    property alias widgetLayoutJson: data.widgetLayoutJson
    property alias widgetLayoutClassicJson: data.widgetLayoutClassicJson
    property alias widgetLayoutDualJson: data.widgetLayoutDualJson
    property alias widgetScalesJson: data.widgetScalesJson
    property alias showLauncherPill: data.showLauncherPill
    property alias showQuickLaunchPill: data.showQuickLaunchPill
    property alias showQuickLaunch2Pill: data.showQuickLaunch2Pill
    property alias showQuickLaunch3Pill: data.showQuickLaunch3Pill
    property alias showQuickLaunch4Pill: data.showQuickLaunch4Pill
    property alias launcherCount: data.launcherCount
    property alias quickLaunchJson: data.quickLaunchJson
    property alias menuSymbol: data.menuSymbol
    property alias menuFont: data.menuFont
    property alias menuFontPx: data.menuFontPx
    property alias menuBold: data.menuBold
    property alias menuItalic: data.menuItalic
    property alias menuColor: data.menuColor
    property alias menuCommand: data.menuCommand
    property alias showFreshRssPill: data.showFreshRssPill
    property alias showWorkspacesPill: data.showWorkspacesPill
    property alias showStatsWidget: data.showStatsWidget
    property alias showStatCpu: data.showStatCpu
    property alias showStatMem: data.showStatMem
    property alias showStatGpu: data.showStatGpu
    property alias showStatVram: data.showStatVram
    property alias showStatGauges: data.showStatGauges
    property alias statTerminal: data.statTerminal
    property alias statClick: data.statClick
    property alias statFont: data.statFont
    property alias statFontPercent: data.statFontPercent
    property alias statBold: data.statBold
    property alias statItalic: data.statItalic
    property alias statThresholdsJson: data.statThresholdsJson
    property alias showTrayPill: data.showTrayPill
    property alias showNetworkPanel: data.showNetworkPanel
    property alias showBluetoothPill: data.showBluetoothPill
    property alias showAudioPill: data.showAudioPill
    property alias showVolumePill: data.showVolumePill
    property alias audioScrollStep: data.audioScrollStep
    property alias audioShowPercent: data.audioShowPercent
    property alias showClockPill: data.showClockPill
    property alias showNotificationPill: data.showNotificationPill
    property alias notificationAutoExpand: data.notificationAutoExpand
    property alias notificationStaggerRows: data.notificationStaggerRows
    property alias notificationClearOnBoot: data.notificationClearOnBoot
    property alias notificationShowCount: data.notificationShowCount
    property alias notificationCorner: data.notificationCorner
    property alias notificationTimeout: data.notificationTimeout
    property alias showPowerPill: data.showPowerPill
    property alias showOpacityPill: data.showOpacityPill
    property alias showTailscalePill: data.showTailscalePill
    property alias showHyprInspPill: data.showHyprInspPill
    property alias showControlBarPill: data.showControlBarPill
    property alias showActiveWindowPill: data.showActiveWindowPill
    property alias activeWindowPillCorner: data.activeWindowPillCorner
    property alias activeWindowPillWidth: data.activeWindowPillWidth
    property alias activeWindowExcludesJson: data.activeWindowExcludesJson
    property alias clockFormat: data.clockFormat
    property alias clockFont: data.clockFont
    property alias clockFontPercent: data.clockFontPercent
    property alias clockBold: data.clockBold
    property alias clockItalic: data.clockItalic
    property alias clockColor: data.clockColor
    property alias clockWeekStart: data.clockWeekStart
    property alias clockClick: data.clockClick
    property alias opacityQuickshell: data.opacityQuickshell
    property alias opacitySatty: data.opacitySatty
    property alias wallpaperDir: data.wallpaperDir
    property alias wallpaperCurrent: data.wallpaperCurrent
    property alias wallpaperTileSize: data.wallpaperTileSize
    property alias showNetworkFullIp: data.showNetworkFullIp
    property alias showNetworkLastOctet: data.showNetworkLastOctet
    property alias showNetworkDeviceName: data.showNetworkDeviceName
    property alias bluetoothScanSeconds: data.bluetoothScanSeconds
    property alias dockEffect: data.dockEffect
    property alias dockScope: data.dockScope
    property alias dockPercent: data.dockPercent
    property alias dockRadius: data.dockRadius
    property alias dockJump: data.dockJump
    property alias dockDot: data.dockDot
    property alias ovLayout: data.ovLayout
    property alias ovAnchor: data.ovAnchor
    property alias ovGap: data.ovGap
    property alias ovPadding: data.ovPadding
    property alias ovPaddingTop: data.ovPaddingTop
    property alias ovPaddingBottom: data.ovPaddingBottom
    property alias ovMaxScale: data.ovMaxScale
    property alias ovDuration: data.ovDuration
    property alias ovPreviewRound: data.ovPreviewRound
    property alias ovBlur: data.ovBlur
    property alias ovBackdropBlur: data.ovBackdropBlur
    property alias ovSwitchAnimation: data.ovSwitchAnimation
    property alias ovSwitchDuration: data.ovSwitchDuration
    property alias ovMoveAnimation: data.ovMoveAnimation
    property alias ovMoveDuration: data.ovMoveDuration
    property alias ovStripOffset: data.ovStripOffset
    property alias ovStripHeight: data.ovStripHeight
    property alias ovStripWidth: data.ovStripWidth
    property alias ovStripCardMax: data.ovStripCardMax
    property alias ovStripMargin: data.ovStripMargin
    property alias ovStripGap: data.ovStripGap
    property alias ovStripCardRound: data.ovStripCardRound
    property alias ovHoverBorder: data.ovHoverBorder
    property alias ovSelectBorder: data.ovSelectBorder
    property alias ovLivePreviews: data.ovLivePreviews
    property alias ovShowWindowLabels: data.ovShowWindowLabels
    property alias ovShowWsLabels: data.ovShowWsLabels
    property alias ovStripPreviews: data.ovStripPreviews
    property alias ovNumberLabels: data.ovNumberLabels
    property alias ovDynamic: data.ovDynamic
    property alias ovAutodelete: data.ovAutodelete
    property alias ovShowEmpty: data.ovShowEmpty
    property alias ovShowSpecial: data.ovShowSpecial
    property alias ovStripAllCard: data.ovStripAllCard
    property alias ovShowAll: data.ovShowAll
    property alias ovSwitchOnNew: data.ovSwitchOnNew
    property alias ovSwitchOnDrop: data.ovSwitchOnDrop
    property alias ovDragToSwap: data.ovDragToSwap
    property alias ovFocusFollowsMouse: data.ovFocusFollowsMouse
    property alias ovScrollSwitches: data.ovScrollSwitches
    property alias ovExitOnClick: data.ovExitOnClick
    property alias ovExitOnSwitch: data.ovExitOnSwitch

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

    function symbolClamp(value) {
        let text = String(value || "").trim()
        const chars = Array.from(text)
        if (chars.length > 3)
            text = chars.slice(0, 3).join("")
        return text
    }

    function textClamp(value) {
        let text = String(value || "").trim()
        const chars = Array.from(text)
        if (chars.length > 24)
            text = chars.slice(0, 24).join("")
        return text
    }

    function fontClamp(value) {
        let name = String(value || "").trim()
        if (name.length > 120)
            name = name.substring(0, 120)
        return name
    }

    function fontPxClamp(value) {
        const n = Math.round(Number(value))
        if (n >= 8 && n <= 32)
            return n
        return 0
    }

    function colorNorm(value) {
        let c = String(value || "").trim()
        if (!c.length)
            return ""
        if (c.charAt(0) !== "#")
            c = "#" + c
        if (/^#[0-9a-fA-F]{3}$/.test(c)) {
            c = "#" + c.charAt(1) + c.charAt(1)
                + c.charAt(2) + c.charAt(2)
                + c.charAt(3) + c.charAt(3)
        }
        if (/^#[0-9a-fA-F]{8}$/.test(c))
            c = c.substring(0, 7)
        if (/^#[0-9a-fA-F]{6}$/.test(c))
            return c.toLowerCase()
        return ""
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
        const custom = String(root.specialNameCustom || "")
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
            label: root.symbolClamp(label),
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
            label: root.symbolClamp(src.label),
            font: root.fontClamp(src.font),
            fontPx: root.fontPxClamp(src.fontPx),
            text: root.textClamp(src.text),
            bold: src.bold === undefined ? true : !!src.bold,
            italic: !!src.italic,
            color: root.colorNorm(src.color)
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
        void root.revision
        if (!root.hasSlots)
            return root.defaultSlots(root.minimumShown)
        const clean = root.sortSlots(root.slotsJson)
        if (!clean.length)
            return root.defaultSlots(root.minimumShown)
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
        void root.revision
        return {
            name: String(root.specialNameCustom || ""),
            label: String(root.specialLabel || ""),
            font: String(root.specialFont || ""),
            fontPx: root.fontPxClamp(root.specialFontPx),
            text: String(root.specialText || ""),
            bold: root.specialBold !== false,
            italic: !!root.specialItalic,
            color: root.colorNorm(root.specialColor)
        }
    }

    function specialFace() {
        const spec = root.specialObject()
        let symbol = root.symbolClamp(spec.label)
        if (!symbol.length && !root.textClamp(spec.text).length)
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
            label: root.symbolClamp(src.label),
            font: root.fontClamp(src.font),
            fontPx: root.fontPxClamp(src.fontPx),
            text: root.textClamp(src.text),
            bold: src.bold === undefined ? true : !!src.bold,
            italic: !!src.italic,
            color: root.colorNorm(src.color)
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

    function touch() {
        root.revision++
    }

    function queueSave() {
        if (!root.ready || root.applying || root.writing)
            return
        saveTimer.restart()
    }

    // A text size percent, on the clock's step and range.
    function fontPercentNorm(pct) {
        const step = Math.max(1, Theme.clockFontStep)
        let n = Math.round(Number(pct) / step) * step
        if (!(n >= Theme.clockFontMin))
            n = Theme.clockFontMin
        if (n > Theme.clockFontMax)
            n = Theme.clockFontMax
        return n
    }

    // Threshold steps are 0–100 in steps of 5.
    function bandStep(value) {
        let n = Math.round(Number(value) / 5) * 5
        if (!(n >= 0))
            n = 0
        if (n > 100)
            n = 100
        return n
    }

    // A copy of a { t: [low, mid, high], c: [4 colors] } threshold set with
    // one step moved. The other steps move with it so low ≤ mid ≤ high.
    function withBand(visual, slot, value) {
        const triple = visual.t.slice()
        triple[slot] = root.bandStep(value)
        if (slot === 0) {
            triple[1] = Math.max(triple[1], triple[0])
            triple[2] = Math.max(triple[2], triple[1])
        } else if (slot === 1) {
            triple[0] = Math.min(triple[0], triple[1])
            triple[2] = Math.max(triple[2], triple[1])
        } else {
            triple[1] = Math.min(triple[1], triple[2])
            triple[0] = Math.min(triple[0], triple[1])
        }
        return { t: triple, c: visual.c.slice() }
    }

    // A copy with one color changed, or null when the color is not valid.
    function withColor(visual, slot, color) {
        const hex = Theme.colorHex(color)
        if (!hex.length)
            return null
        const colors = visual.c.slice()
        colors[slot] = hex
        return { t: visual.t.slice(), c: colors }
    }

    // Write several saved fields as one change: one revision bump, one save.
    function saveFields(write) {
        root.applying = true
        try {
            write()
        } finally {
            root.applying = false
        }
        root.touch()
        root.queueSave()
    }

    function setShowSpecial(enabled) {
        const next = !!enabled
        if (root.showSpecial === next)
            return
        root.showSpecial = next
        root.touch()
    }

    function setShowOnlyActive(enabled) {
        const next = !!enabled
        if (root.showOnlyActive === next)
            return
        root.showOnlyActive = next
        root.touch()
    }

    function setShowNumbers(enabled) {
        const next = !!enabled
        if (root.showNumbers === next)
            return
        root.showNumbers = next
        root.touch()
    }

    function setStartupWorkspace(workspace) {
        const next = root.clampStartup(workspace)
        if (root.startupWorkspace === next)
            return
        root.startupWorkspace = next
        root.touch()
    }

    function setStartupCloseSpecial(enabled) {
        const next = !!enabled
        if (root.startupCloseSpecial === next)
            return
        root.startupCloseSpecial = next
        root.touch()
    }

    function setMinimumShown(count) {
        let n = root.clampCount(count)
        root.applying = true
        if (root.hasSlots) {
            const cur = root.sanitizeSlots(root.slotsJson)
            while (cur.length > n)
                cur.pop()
            while (cur.length < n) {
                const id = root.nextFreeId(cur)
                if (id < 0)
                    break
                cur.push(root.blankSlot(id, root.iconForId(id)))
            }
            root.slotsJson = cur
            n = cur.length || 1
        }
        root.minimumShown = n
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function replaceWidgetLayout(json, turnLeftOn, turnRightOn, turnTopOn, turnBottomOn) {
        const text = String(json || "[]")
        const left = !!turnLeftOn
        const right = !!turnRightOn
        const top = !!turnTopOn
        const bottom = !!turnBottomOn
        const same = root.widgetLayoutJson === text
            && root.widgetLayoutDualJson === text
            && root.barLayoutMode === "dual"
            && (!left || root.showLeftBar)
            && (!right || root.showRightBar)
            && (!top || root.showTopBar)
            && (!bottom || root.showBottomBar)
        if (same)
            return
        root.applying = true
        root.widgetLayoutJson = text
        root.widgetLayoutDualJson = text
        root.barLayoutMode = "dual"
        if (left)
            root.showLeftBar = true
        if (right)
            root.showRightBar = true
        if (top)
            root.showTopBar = true
        if (bottom)
            root.showBottomBar = true
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function coerceAlign(align) {
        const value = String(align || "")
        if (value === "left" || value === "right")
            return value
        return "center"
    }

    function setShowTopBar(enabled) {
        const next = !!enabled
        if (root.showTopBar === next)
            return
        root.showTopBar = next
        root.touch()
    }

    function setShowBottomBar(enabled) {
        const next = !!enabled
        if (root.showBottomBar === next)
            return
        root.showBottomBar = next
        root.touch()
    }

    function setShowLeftBar(enabled) {
        const next = !!enabled
        if (root.showLeftBar === next)
            return
        root.showLeftBar = next
        root.touch()
    }

    function setShowRightBar(enabled) {
        const next = !!enabled
        if (root.showRightBar === next)
            return
        root.showRightBar = next
        root.touch()
    }

    function setBarAlign(edge, align) {
        const next = root.coerceAlign(align)
        switch (String(edge || "")) {
        case "top":
            if (root.topBarAlign === next)
                return
            root.topBarAlign = next
            break
        case "bottom":
            if (root.bottomBarAlign === next)
                return
            root.bottomBarAlign = next
            break
        case "left":
            if (root.leftBarAlign === next)
                return
            root.leftBarAlign = next
            break
        case "right":
            if (root.rightBarAlign === next)
                return
            root.rightBarAlign = next
            break
        default:
            return
        }
        root.touch()
    }

    function setBarSpan(edge, enabled) {
        const next = !!enabled
        switch (String(edge || "")) {
        case "top":
            if (root.barSpanFull === next)
                return
            root.barSpanFull = next
            break
        case "bottom":
            if (root.panelSpanFull === next)
                return
            root.panelSpanFull = next
            break
        case "left":
            if (root.leftBarSpanFull === next)
                return
            root.leftBarSpanFull = next
            break
        case "right":
            if (root.rightBarSpanFull === next)
                return
            root.rightBarSpanFull = next
            break
        default:
            return
        }
        root.touch()
    }

    function setUiScaleManual(scale) {
        let n = Number(scale)
        if (!(n > 0)) {
            n = 0
        } else {
            if (n < Theme.uiScaleMin)
                n = Theme.uiScaleMin
            if (n > Theme.uiScaleMax)
                n = Theme.uiScaleMax
            n = Math.round(n * 20) / 20
        }
        if (Math.abs(Number(root.uiScaleManual) - n) < 0.001)
            return
        root.uiScaleManual = n
        root.touch()
    }

    function setFlushWindowsToBar(enabled) {
        const next = !!enabled
        if (root.flushWindowsToBar === next)
            return
        root.flushWindowsToBar = next
        root.touch()
    }

    function setShowStatCpu(enabled) {
        const next = !!enabled
        if (root.showStatCpu === next)
            return
        root.showStatCpu = next
        root.touch()
    }

    function setShowStatMem(enabled) {
        const next = !!enabled
        if (root.showStatMem === next)
            return
        root.showStatMem = next
        root.touch()
    }

    function setShowStatGpu(enabled) {
        const next = !!enabled
        if (root.showStatGpu === next)
            return
        root.showStatGpu = next
        root.touch()
    }

    function setShowStatVram(enabled) {
        const next = !!enabled
        if (root.showStatVram === next)
            return
        root.showStatVram = next
        root.touch()
    }

    function setShowStatGauges(enabled) {
        const next = !!enabled
        if (root.showStatGauges === next)
            return
        root.showStatGauges = next
        root.touch()
    }

    function setStatTerminal(name) {
        const next = String(name || "").trim()
        if (!root.statTerminalOk(next) || root.statTerminal === next)
            return
        root.statTerminal = next
        root.touch()
    }

    function setStatClick(side) {
        const next = String(side || "") === "right" ? "right" : "left"
        if (root.statClick === next)
            return
        root.statClick = next
        root.touch()
    }

    function applyBarsState(state) {
        const src = state || {}
        const shown = src.shown || {}
        let manual = Number(src.uiScaleManual)
        if (!(manual > 0))
            manual = 0
        else {
            if (manual < Theme.uiScaleMin)
                manual = Theme.uiScaleMin
            if (manual > Theme.uiScaleMax)
                manual = Theme.uiScaleMax
        }
        root.applying = true
        root.widgetLayoutJson = String(src.layout || "[]")
        root.widgetLayoutDualJson = root.widgetLayoutJson
        root.barLayoutMode = "dual"
        root.widgetScalesJson = String(src.scales || "")
        root.showLauncherPill = !!shown.launcher
        root.showQuickLaunchPill = !!shown.quickLaunch
        root.showQuickLaunch2Pill = !!shown.quickLaunch2
        root.showQuickLaunch3Pill = !!shown.quickLaunch3
        root.showQuickLaunch4Pill = !!shown.quickLaunch4
        root.showFreshRssPill = !!shown.freshRss
        root.showWorkspacesPill = !!shown.workspaces
        root.showStatsWidget = !!shown.stats
        root.showTrayPill = !!shown.tray
        root.showNetworkPanel = !!shown.networkPanel
        // Bluetooth is its own widget. The BT · Audio row is gone. This key
        // still round-trips so Apply does not clear a saved audio flag.
        root.showBluetoothPill = !!shown.bluetooth
        root.showAudioPill = !!shown.connectivity
        root.showClockPill = !!shown.clock
        root.showNotificationPill = !!shown.notifications
        root.showHyprInspPill = !!shown.hyprInsp
        root.showControlBarPill = !!shown.controlBar
        root.showTailscalePill = !!shown.tailscale
        root.showOpacityPill = !!shown.opacity
        root.showPowerPill = !!shown.power
        root.showVolumePill = !!shown.volume
        root.showTopBar = !!src.showTopBar
        root.showBottomBar = !!src.showBottomBar
        root.showLeftBar = !!src.showLeftBar
        root.showRightBar = !!src.showRightBar
        root.topBarAlign = root.coerceAlign(src.topBarAlign)
        root.bottomBarAlign = root.coerceAlign(src.bottomBarAlign)
        root.leftBarAlign = root.coerceAlign(src.leftBarAlign)
        root.rightBarAlign = root.coerceAlign(src.rightBarAlign)
        root.barSpanFull = !!src.barSpanFull
        root.panelSpanFull = !!src.panelSpanFull
        root.leftBarSpanFull = !!src.leftBarSpanFull
        root.rightBarSpanFull = !!src.rightBarSpanFull
        root.uiScaleManual = manual
        root.flushWindowsToBar = !!src.flushWindowsToBar
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function replaceWidgetScales(json) {
        const text = String(json || "")
        if (root.widgetScalesJson === text)
            return
        root.widgetScalesJson = text
        root.touch()
    }

    function setClockFormat(fmt) {
        let text = String(fmt || "").replace(/[\r\n]/g, " ").trim()
        if (text.length > Theme.clockFormatMax)
            text = text.substring(0, Theme.clockFormatMax).trim()
        if (!text.length || root.clockFormat === text)
            return
        root.clockFormat = text
        root.touch()
    }

    function setClockFont(name) {
        const text = root.fontClamp(name)
        if (root.clockFont === text)
            return
        root.clockFont = text
        root.touch()
    }

    function setClockFontPercent(pct) {
        const n = root.fontPercentNorm(pct)
        if (root.clockFontPercent === n)
            return
        root.clockFontPercent = n
        root.touch()
    }

    function setConnectivityShown(enabled) {
        const on = !!enabled
        if (root.showAudioPill === on)
            return
        root.showAudioPill = on
        root.touch()
    }

    function setWidgetShown(id, enabled) {
        const on = !!enabled
        switch (String(id || "")) {
        case "launcher":
            if (root.showLauncherPill === on)
                return
            root.showLauncherPill = on
            break
        case "quickLaunch":
            if (root.showQuickLaunchPill === on)
                return
            root.showQuickLaunchPill = on
            break
        case "quickLaunch2":
            if (root.showQuickLaunch2Pill === on)
                return
            root.showQuickLaunch2Pill = on
            break
        case "quickLaunch3":
            if (root.showQuickLaunch3Pill === on)
                return
            root.showQuickLaunch3Pill = on
            break
        case "quickLaunch4":
            if (root.showQuickLaunch4Pill === on)
                return
            root.showQuickLaunch4Pill = on
            break
        case "freshRss":
            if (root.showFreshRssPill === on)
                return
            root.showFreshRssPill = on
            break
        case "workspaces":
            if (root.showWorkspacesPill === on)
                return
            root.showWorkspacesPill = on
            break
        case "stats":
            if (root.showStatsWidget === on)
                return
            root.showStatsWidget = on
            break
        case "tray":
            if (root.showTrayPill === on)
                return
            root.showTrayPill = on
            break
        case "networkPanel":
            if (root.showNetworkPanel === on)
                return
            root.showNetworkPanel = on
            break
        case "bluetooth":
            if (root.showBluetoothPill === on)
                return
            root.showBluetoothPill = on
            break
        case "clock":
            if (root.showClockPill === on)
                return
            root.showClockPill = on
            break
        case "notifications":
            if (root.showNotificationPill === on)
                return
            root.showNotificationPill = on
            break
        case "hyprInsp":
            if (root.showHyprInspPill === on)
                return
            root.showHyprInspPill = on
            break
        case "controlBar":
            if (root.showControlBarPill === on)
                return
            root.showControlBarPill = on
            break
        case "tailscale":
            if (root.showTailscalePill === on)
                return
            root.showTailscalePill = on
            break
        case "opacity":
            if (root.showOpacityPill === on)
                return
            root.showOpacityPill = on
            break
        case "power":
            if (root.showPowerPill === on)
                return
            root.showPowerPill = on
            break
        case "activeWindow":
            if (root.showActiveWindowPill === on)
                return
            root.showActiveWindowPill = on
            break
        case "connectivity":
            root.setConnectivityShown(on)
            return
        default:
            return
        }
        root.touch()
    }

    function commit(slots, special) {
        const clean = root.sanitizeSlots(slots)
        const next = clean.length ? clean : root.defaultSlots(1)
        const spec = root.copySpecial(special)
        spec.name = root.nameNorm(spec.name)
        root.applying = true
        root.slotsJson = next
        root.hasSlots = true
        root.minimumShown = next.length
        root.specialNameCustom = spec.name
        root.specialLabel = spec.label
        root.specialFont = spec.font
        root.specialFontPx = spec.fontPx
        root.specialText = spec.text
        root.specialBold = spec.bold
        root.specialItalic = spec.italic
        root.specialColor = spec.color
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function opacityClamp(value) {
        let n = Math.round(Number(value))
        if (!(n >= Theme.opacityMin))
            return Theme.opacityMax
        if (n > Theme.opacityMax)
            return Theme.opacityMax
        return n
    }

    function opacityQuickshellValue() {
        const stored = Math.round(Number(root.opacityQuickshell))
        if (stored >= Theme.opacityMin && stored <= Theme.opacityMax)
            return stored
        return root.opacityClamp(DefaultTheme.opacityQuickshell)
    }

    function opacitySattyValue() {
        const stored = Math.round(Number(root.opacitySatty))
        if (stored >= Theme.opacityMin && stored <= Theme.opacityMax)
            return stored
        return root.opacityClamp(DefaultTheme.opacitySatty)
    }

    function setOpacityLevels(quickshell, satty) {
        const nextQuickshell = root.opacityClamp(quickshell)
        const nextSatty = root.opacityClamp(satty)
        if (root.opacityQuickshell === nextQuickshell && root.opacitySatty === nextSatty)
            return
        root.applying = true
        root.opacityQuickshell = nextQuickshell
        root.opacitySatty = nextSatty
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function clearOpacityOverride() {
        if (root.opacityQuickshell === 0 && root.opacitySatty === 0)
            return
        root.applying = true
        root.opacityQuickshell = 0
        root.opacitySatty = 0
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function wallpaperDirValue() {
        const saved = String(root.wallpaperDir || "").trim()
        if (saved.length)
            return saved
        const home = String(Quickshell.env("HOME") || "")
        return home.length ? home + "/Pictures/wallpapers" : ""
    }

    function setWallpaperDir(path) {
        const next = String(path || "").trim()
        if (!next.length || next.indexOf("\n") >= 0 || next.indexOf("\r") >= 0)
            return
        if (root.wallpaperDir === next)
            return
        root.wallpaperDir = next
        root.touch()
    }

    function setWallpaperCurrent(path) {
        const next = String(path || "").trim()
        if (next.indexOf("\n") >= 0 || next.indexOf("\r") >= 0)
            return
        if (root.wallpaperCurrent === next)
            return
        root.wallpaperCurrent = next
        root.touch()
    }

    function wallpaperTileValue() {
        const stored = Math.round(Number(root.wallpaperTileSize))
        if (stored >= Theme.wallpaperTileMin && stored <= Theme.wallpaperTileMax)
            return stored
        return Theme.wallpaperTile
    }

    function setWallpaperTileSize(value) {
        let next = Math.round(Number(value))
        if (next < Theme.wallpaperTileMin)
            next = Theme.wallpaperTileMin
        if (next > Theme.wallpaperTileMax)
            next = Theme.wallpaperTileMax
        if (root.wallpaperTileSize === next)
            return
        root.wallpaperTileSize = next
        root.touch()
    }

    function programOk(text) {
        const program = String(text || "").trim()
        if (program.length < 1 || program.length > 240)
            return false
        if (program.charAt(0) === "-")
            return false
        return !/[\r\n;&|`$<>\\]/.test(program)
    }

    function argOk(text) {
        return /^[A-Za-z0-9_./:@+=,~%-]+$/.test(String(text || ""))
    }

    function launcherSlots() {
        let count = Math.round(Number(root.launcherCount))
        if (!(count >= Theme.launcherMin))
            count = Theme.launcherMin
        if (count > Theme.launcherMax)
            count = Theme.launcherMax
        return count
    }

    function setLauncherCount(value) {
        let count = Math.round(Number(value))
        if (!(count >= Theme.launcherMin))
            count = Theme.launcherMin
        if (count > Theme.launcherMax)
            count = Theme.launcherMax
        if (root.launcherCount === count)
            return
        root.launcherCount = count
        root.touch()
    }

    function iconOk(text) {
        const icon = String(text || "")
        if (!icon.length)
            return true
        if (icon.length > 240)
            return false
        return !/[\r\n;&|`$<>\\]/.test(icon)
    }

    function desktopIdOk(text) {
        return /^[A-Za-z0-9._+-]{1,200}$/.test(String(text || ""))
    }

    function pinKey(row) {
        if (!row)
            return ""
        const id = String(row.id || "")
        if (id.length)
            return "desk:" + id
        const command = row.command || []
        const parts = []
        for (let i = 0; i < command.length; i++)
            parts.push(String(command[i] || ""))
        return "cmd:" + parts.join("\n")
    }

    function cleanPin(row) {
        if (!row)
            return null
        const name = String(row.name || "").replace(/[\r\n]/g, " ").trim().slice(0, 80)
        if (!name.length)
            return null
        const icon = String(row.icon || "")
        if (!root.iconOk(icon))
            return null
        const id = String(row.id || "")
        if (id.length) {
            if (!root.desktopIdOk(id))
                return null
            return { id: id, name: name, icon: icon, command: [] }
        }
        const raw = row.command || []
        if (!raw.length)
            return null
        const program = String(raw[0] || "").trim()
        if (!root.programOk(program))
            return null
        const command = [program]
        for (let i = 1; i < raw.length && command.length < 13; i++) {
            const token = String(raw[i] || "")
            if (!root.argOk(token))
                return null
            command.push(token)
        }
        return { id: "", name: name, icon: icon, command: command }
    }

    function parseBoards(raw) {
        let parsed = []
        try {
            parsed = JSON.parse(String(raw || "[]"))
        } catch (e) {
            parsed = []
        }
        const boards = [[], [], [], []]
        if (!parsed || parsed.length === undefined)
            return boards
        const first = parsed.length ? parsed[0] : null
        const nested = !!(first && first.length !== undefined && first.id === undefined && first.name === undefined)
        if (!nested) {
            for (let i = 0; i < parsed.length && boards[0].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(parsed[i])
                if (pin)
                    boards[0].push(pin)
            }
            return boards
        }
        for (let b = 0; b < boards.length && b < parsed.length; b++) {
            const list = parsed[b] || []
            if (!list || list.length === undefined)
                continue
            const seen = {}
            for (let i = 0; i < list.length && boards[b].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(list[i])
                if (!pin)
                    continue
                const key = root.pinKey(pin)
                if (seen[key])
                    continue
                seen[key] = true
                boards[b].push(pin)
            }
        }
        return boards
    }

    function launchBoards() {
        return root.parseBoards(root.quickLaunchJson)
    }

    function canonicalBoards(boards) {
        const clean = [[], [], [], []]
        const src = boards || []
        for (let b = 0; b < clean.length; b++) {
            const list = src[b] || []
            if (!list || list.length === undefined)
                continue
            const seen = {}
            for (let i = 0; i < list.length && clean[b].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(list[i])
                if (!pin)
                    continue
                const key = root.pinKey(pin)
                if (seen[key])
                    continue
                seen[key] = true
                clean[b].push(pin)
            }
        }
        return JSON.stringify(clean)
    }

    function setLaunchBoards(boards) {
        const text = root.canonicalBoards(boards)
        if (root.quickLaunchJson === text)
            return
        root.quickLaunchJson = text
        root.touch()
    }

    function launcherSavedJson() {
        return root.canonicalBoards(root.launchBoards())
    }

    function launcherDraftDiffers() {
        return root.editorLaunchJson !== root.launcherSavedJson()
            || root.editorLauncherCount !== root.launcherSlots()
    }

    function seedLauncherEditor() {
        root.editorLaunchJson = root.launcherSavedJson()
        root.editorLauncherCount = root.launcherSlots()
        root.launcherEditorReady = true
        root.launcherEditorDirty = false
    }

    function ensureLauncherEditor() {
        if (!root.launcherEditorReady || !root.launcherEditorDirty)
            root.seedLauncherEditor()
    }

    // Read helpers run inside bindings, so they must not write. A clean
    // draft reads the saved value; reseeding here would undo the edit
    // that triggered the binding.
    function editorLaunchBoards() {
        const draft = root.launcherEditorReady && root.launcherEditorDirty
        return root.parseBoards(draft ? root.editorLaunchJson : root.quickLaunchJson)
    }

    function editorLauncherSlots() {
        const draft = root.launcherEditorReady && root.launcherEditorDirty
        let count = Math.round(Number(draft ? root.editorLauncherCount : root.launcherCount))
        if (!(count >= Theme.launcherMin))
            count = Theme.launcherMin
        if (count > Theme.launcherMax)
            count = Theme.launcherMax
        return count
    }

    function editLaunchBoards(boards) {
        root.ensureLauncherEditor()
        root.editorLaunchJson = root.canonicalBoards(boards)
        root.launcherEditorDirty = root.launcherDraftDiffers()
    }

    function editLauncherCount(value) {
        let count = Math.round(Number(value))
        if (!(count >= Theme.launcherMin))
            count = Theme.launcherMin
        if (count > Theme.launcherMax)
            count = Theme.launcherMax
        root.ensureLauncherEditor()
        root.editorLauncherCount = count
        root.launcherEditorDirty = root.launcherDraftDiffers()
    }

    function resetLauncherEditor() {
        root.ensureLauncherEditor()
        root.editorLauncherCount = Theme.launcherMin
        root.editorLaunchJson = root.canonicalBoards([[], [], [], []])
        root.launcherEditorDirty = root.launcherDraftDiffers()
    }

    function applyLauncherEditor() {
        if (!root.launcherEditorDirty)
            return false
        root.launcherUndo = {
            count: root.launcherSlots(),
            json: root.launcherSavedJson()
        }
        root.launcherUndoReady = true
        root.applying = true
        root.launcherCount = root.editorLauncherCount
        root.quickLaunchJson = root.editorLaunchJson
        root.applying = false
        root.touch()
        root.queueSave()
        root.seedLauncherEditor()
        return true
    }

    function undoLauncherEditor() {
        if (root.launcherEditorDirty) {
            root.seedLauncherEditor()
            return false
        }
        if (!root.launcherUndoReady || !root.launcherUndo)
            return false
        const previous = root.launcherUndo
        root.launcherUndo = null
        root.launcherUndoReady = false
        root.applying = true
        root.launcherCount = Math.round(Number(previous.count))
        root.quickLaunchJson = String(previous.json || "[]")
        root.applying = false
        root.touch()
        root.queueSave()
        root.seedLauncherEditor()
        return true
    }

    function canUndoLauncher() {
        return root.launcherEditorDirty || root.launcherUndoReady
    }

    function ovLayoutNorm(value) {
        const text = String(value || "")
        if (text === "grid" || text === "natural")
            return text
        return "rows"
    }

    function ovAnchorNorm(value) {
        const text = String(value || "")
        if (text === "bottom" || text === "left" || text === "right")
            return text
        return "top"
    }

    function ovInt(value, lo, hi, fallback) {
        let n = Math.round(Number(value))
        if (!(n >= lo) && !(n <= hi))
            n = fallback
        if (!(n >= lo))
            n = lo
        if (n > hi)
            n = hi
        return n
    }

    function ovStep(value, lo, hi, fallback) {
        let n = Math.round(Number(value) * 20) / 20
        if (!(n >= lo) && !(n <= hi))
            n = fallback
        if (!(n >= lo))
            n = lo
        if (n > hi)
            n = hi
        return Math.round(n * 20) / 20
    }

    function ovFlag(value, fallback) {
        if (value === undefined || value === null)
            return fallback
        return !!value
    }

    // Saved overview options, clamped. The overlay reads this, not the settings draft.
    function ovNorm(src) {
        const snap = src || {}
        return {
            ovLayout: root.ovLayoutNorm(snap.ovLayout),
            ovAnchor: root.ovAnchorNorm(snap.ovAnchor),
            ovGap: root.ovInt(snap.ovGap, 0, 120, 34),
            ovPadding: root.ovInt(snap.ovPadding, 0, 200, 80),
            ovPaddingTop: root.ovInt(snap.ovPaddingTop, 0, 160, 40),
            ovPaddingBottom: root.ovInt(snap.ovPaddingBottom, 0, 160, 70),
            ovMaxScale: root.ovStep(snap.ovMaxScale, 0.2, 1.5, 1),
            ovDuration: root.ovInt(snap.ovDuration, 0, 800, 360),
            ovPreviewRound: root.ovInt(snap.ovPreviewRound, 0, 32, 12),
            ovBlur: root.ovStep(snap.ovBlur, 0, 1, 1),
            ovBackdropBlur: root.ovFlag(snap.ovBackdropBlur, false),
            ovSwitchAnimation: root.ovFlag(snap.ovSwitchAnimation, true),
            ovSwitchDuration: root.ovInt(snap.ovSwitchDuration, 0, 800, 260),
            ovMoveAnimation: root.ovFlag(snap.ovMoveAnimation, true),
            ovMoveDuration: root.ovInt(snap.ovMoveDuration, 0, 800, 240),
            ovStripOffset: root.ovInt(snap.ovStripOffset, 0, 120, 0),
            ovStripHeight: root.ovInt(snap.ovStripHeight, 72, 640, 150),
            ovStripWidth: root.ovInt(snap.ovStripWidth, 72, 640, 150),
            ovStripCardMax: root.ovInt(snap.ovStripCardMax, 160, 960, 300),
            ovStripMargin: root.ovInt(snap.ovStripMargin, 0, 64, 22),
            ovStripGap: root.ovInt(snap.ovStripGap, 0, 64, 18),
            ovStripCardRound: root.ovInt(snap.ovStripCardRound, 0, 28, 10),
            ovHoverBorder: root.ovInt(snap.ovHoverBorder, 0, 8, 3),
            ovSelectBorder: root.ovInt(snap.ovSelectBorder, 0, 8, 3),
            ovLivePreviews: root.ovFlag(snap.ovLivePreviews, true),
            ovShowWindowLabels: root.ovFlag(snap.ovShowWindowLabels, true),
            ovShowWsLabels: root.ovFlag(snap.ovShowWsLabels, true),
            ovStripPreviews: root.ovFlag(snap.ovStripPreviews, true),
            ovNumberLabels: root.ovFlag(snap.ovNumberLabels, false),
            ovDynamic: root.ovFlag(snap.ovDynamic, true),
            ovAutodelete: root.ovFlag(snap.ovAutodelete, true),
            ovShowEmpty: root.ovFlag(snap.ovShowEmpty, true),
            ovShowSpecial: root.ovFlag(snap.ovShowSpecial, false),
            ovStripAllCard: root.ovFlag(snap.ovStripAllCard, false),
            ovShowAll: root.ovFlag(snap.ovShowAll, false),
            ovSwitchOnNew: root.ovFlag(snap.ovSwitchOnNew, true),
            ovSwitchOnDrop: root.ovFlag(snap.ovSwitchOnDrop, false),
            ovDragToSwap: root.ovFlag(snap.ovDragToSwap, true),
            ovFocusFollowsMouse: root.ovFlag(snap.ovFocusFollowsMouse, true),
            ovScrollSwitches: root.ovFlag(snap.ovScrollSwitches, true),
            ovExitOnClick: root.ovFlag(snap.ovExitOnClick, true),
            ovExitOnSwitch: root.ovFlag(snap.ovExitOnSwitch, false)
        }
    }

    function ovLive() {
        return root.ovNorm({
            ovLayout: root.ovLayout,
            ovAnchor: root.ovAnchor,
            ovGap: root.ovGap,
            ovPadding: root.ovPadding,
            ovPaddingTop: root.ovPaddingTop,
            ovPaddingBottom: root.ovPaddingBottom,
            ovMaxScale: root.ovMaxScale,
            ovDuration: root.ovDuration,
            ovPreviewRound: root.ovPreviewRound,
            ovBlur: root.ovBlur,
            ovBackdropBlur: root.ovBackdropBlur,
            ovSwitchAnimation: root.ovSwitchAnimation,
            ovSwitchDuration: root.ovSwitchDuration,
            ovMoveAnimation: root.ovMoveAnimation,
            ovMoveDuration: root.ovMoveDuration,
            ovStripOffset: root.ovStripOffset,
            ovStripHeight: root.ovStripHeight,
            ovStripWidth: root.ovStripWidth,
            ovStripCardMax: root.ovStripCardMax,
            ovStripMargin: root.ovStripMargin,
            ovStripGap: root.ovStripGap,
            ovStripCardRound: root.ovStripCardRound,
            ovHoverBorder: root.ovHoverBorder,
            ovSelectBorder: root.ovSelectBorder,
            ovLivePreviews: root.ovLivePreviews,
            ovShowWindowLabels: root.ovShowWindowLabels,
            ovShowWsLabels: root.ovShowWsLabels,
            ovStripPreviews: root.ovStripPreviews,
            ovNumberLabels: root.ovNumberLabels,
            ovDynamic: root.ovDynamic,
            ovAutodelete: root.ovAutodelete,
            ovShowEmpty: root.ovShowEmpty,
            ovShowSpecial: root.ovShowSpecial,
            ovStripAllCard: root.ovStripAllCard,
            ovShowAll: root.ovShowAll,
            ovSwitchOnNew: root.ovSwitchOnNew,
            ovSwitchOnDrop: root.ovSwitchOnDrop,
            ovDragToSwap: root.ovDragToSwap,
            ovFocusFollowsMouse: root.ovFocusFollowsMouse,
            ovScrollSwitches: root.ovScrollSwitches,
            ovExitOnClick: root.ovExitOnClick,
            ovExitOnSwitch: root.ovExitOnSwitch
        })
    }

    function ovDraft() {
        if (!root.ovEditorReady || !root.editorOv)
            return root.ovLive()
        return root.ovNorm(root.editorOv)
    }

    function ovEditorInt(key, scale) {
        const src = root.ovDraft()
        const factor = Number(scale) || 1
        return Math.round(Number(src[key]) * factor)
    }

    function seedOvEditor() {
        root.editorOv = root.ovLive()
        root.ovEditorReady = true
        root.ovEditorDirty = false
    }

    function ensureOvEditor() {
        if (!root.ovEditorReady || !root.ovEditorDirty)
            root.seedOvEditor()
    }

    function editOv(key, value) {
        root.ensureOvEditor()
        const next = root.ovNorm(root.editorOv)
        next[key] = value
        const cleaned = root.ovNorm(next)
        root.editorOv = cleaned
        root.ovEditorDirty = JSON.stringify(cleaned) !== JSON.stringify(root.ovLive())
    }

    function editOvScaled(key, value, scale) {
        const factor = Number(scale) || 1
        const raw = Number(value)
        const real = factor === 1 ? Math.round(raw) : Math.round(raw) / factor
        root.editOv(key, real)
    }

    function writeOvState(src) {
        const snap = root.ovNorm(src)
        root.applying = true
        root.ovLayout = snap.ovLayout
        root.ovAnchor = snap.ovAnchor
        root.ovGap = snap.ovGap
        root.ovPadding = snap.ovPadding
        root.ovPaddingTop = snap.ovPaddingTop
        root.ovPaddingBottom = snap.ovPaddingBottom
        root.ovMaxScale = snap.ovMaxScale
        root.ovDuration = snap.ovDuration
        root.ovPreviewRound = snap.ovPreviewRound
        root.ovBlur = snap.ovBlur
        root.ovBackdropBlur = snap.ovBackdropBlur
        root.ovSwitchAnimation = snap.ovSwitchAnimation
        root.ovSwitchDuration = snap.ovSwitchDuration
        root.ovMoveAnimation = snap.ovMoveAnimation
        root.ovMoveDuration = snap.ovMoveDuration
        root.ovStripOffset = snap.ovStripOffset
        root.ovStripHeight = snap.ovStripHeight
        root.ovStripWidth = snap.ovStripWidth
        root.ovStripCardMax = snap.ovStripCardMax
        root.ovStripMargin = snap.ovStripMargin
        root.ovStripGap = snap.ovStripGap
        root.ovStripCardRound = snap.ovStripCardRound
        root.ovHoverBorder = snap.ovHoverBorder
        root.ovSelectBorder = snap.ovSelectBorder
        root.ovLivePreviews = snap.ovLivePreviews
        root.ovShowWindowLabels = snap.ovShowWindowLabels
        root.ovShowWsLabels = snap.ovShowWsLabels
        root.ovStripPreviews = snap.ovStripPreviews
        root.ovNumberLabels = snap.ovNumberLabels
        root.ovDynamic = snap.ovDynamic
        root.ovAutodelete = snap.ovAutodelete
        root.ovShowEmpty = snap.ovShowEmpty
        root.ovShowSpecial = snap.ovShowSpecial
        root.ovStripAllCard = snap.ovStripAllCard
        root.ovShowAll = snap.ovShowAll
        root.ovSwitchOnNew = snap.ovSwitchOnNew
        root.ovSwitchOnDrop = snap.ovSwitchOnDrop
        root.ovDragToSwap = snap.ovDragToSwap
        root.ovFocusFollowsMouse = snap.ovFocusFollowsMouse
        root.ovScrollSwitches = snap.ovScrollSwitches
        root.ovExitOnClick = snap.ovExitOnClick
        root.ovExitOnSwitch = snap.ovExitOnSwitch
        root.applying = false
        root.touch()
        root.queueSave()
    }

    function applyOvEditor() {
        if (!root.ovEditorDirty)
            return
        root.ovUndo = root.ovLive()
        root.ovUndoReady = true
        root.writeOvState(root.ovDraft())
        root.seedOvEditor()
    }

    function undoOvEditor() {
        if (root.ovEditorDirty) {
            root.seedOvEditor()
            return
        }
        if (!root.ovUndoReady || !root.ovUndo)
            return
        const previous = root.ovUndo
        root.ovUndo = null
        root.ovUndoReady = false
        root.writeOvState(previous)
        root.seedOvEditor()
    }

    function resetOvEditor() {
        root.ensureOvEditor()
        const cleaned = root.ovNorm({})
        root.editorOv = cleaned
        root.ovEditorDirty = JSON.stringify(cleaned) !== JSON.stringify(root.ovLive())
    }

    function canUndoOv() {
        return root.ovEditorDirty || root.ovUndoReady
    }

    Process {
        id: ensureStateDir
        command: ["mkdir", "-p", Quickshell.shellDir + "/state"]
        running: true
        onExited: (exitCode) => {
            store.path = root.storePath
            if (exitCode !== 0)
                root.ready = true
        }
    }

    FileView {
        id: store
        atomicWrites: true
        watchChanges: true
        printErrors: true
        blockLoading: true

        onLoaded: {
            root.ready = true
            root.touch()
        }
        onLoadFailed: {
            root.ready = true
            root.touch()
        }
        onAdapterUpdated: root.queueSave()
        onSaved: root.writing = false
        onSaveFailed: root.writing = false
        onFileChanged: {
            if (!root.writing)
                store.reload()
        }
        JsonAdapter {
            id: data
            property bool wsShowSpecialPill: true
            property bool wsShowOnlyActive: false
            property bool wsShowNumbers: true
            property int wsMinimumShown: 3
            property int wsStartupWorkspace: 0
            property bool wsStartupCloseMagic: false
            property bool hasWsSlots: false
            property string wsSpecialNameCustom: ""
            property string wsIconSpecialCustom: ""
            property string wsSpecialFont: ""
            property int wsSpecialFontPx: 0
            property string wsSpecialText: ""
            property bool wsSpecialBold: true
            property bool wsSpecialItalic: false
            property string wsSpecialColor: ""
            property var wsSlotsJson: []

            property string barLayoutMode: "dual"
            property bool showLeftBar: false
            property bool showRightBar: false
            property bool showTopBar: true
            property bool showBottomBar: false
            property string topBarAlign: "left"
            property string bottomBarAlign: "left"
            property string leftBarAlign: "left"
            property string rightBarAlign: "left"
            property bool barSpanFull: false
            property bool panelSpanFull: false
            property bool leftBarSpanFull: false
            property bool rightBarSpanFull: false
            property real uiScaleManual: 0
            property bool flushWindowsToBar: false
            property string widgetLayoutJson: ""
            property string widgetLayoutClassicJson: ""
            property string widgetLayoutDualJson: ""
            property string widgetScalesJson: ""
            property bool showLauncherPill: false
            property bool showQuickLaunchPill: false
            property bool showQuickLaunch2Pill: false
            property bool showQuickLaunch3Pill: false
            property bool showQuickLaunch4Pill: false
            property int launcherCount: 1
            // Four arrays, index 0 is launcher 1. Missing JSON keeps this empty list.
            property string quickLaunchJson: "[]"
            property string menuSymbol: ""
            property string menuFont: ""
            property int menuFontPx: 0
            property bool menuBold: false
            property bool menuItalic: false
            property string menuColor: ""
            property string menuCommand: ""
            property bool showFreshRssPill: false
            property bool showWorkspacesPill: true
            property bool showStatsWidget: false
            property bool showStatCpu: true
            property bool showStatMem: true
            property bool showStatGpu: true
            property bool showStatVram: true
            property bool showStatGauges: true
            property string statTerminal: "kitty"
            property string statClick: "left"
            property string statFont: ""
            property int statFontPercent: 100
            property bool statBold: true
            property bool statItalic: false
            property string statThresholdsJson: ""
            property bool showTrayPill: false
            property bool showNetworkPanel: false
            property bool showBluetoothPill: false
            property bool showAudioPill: false
            property bool showVolumePill: false
            property int audioScrollStep: 5
            property bool audioShowPercent: true
            property bool showClockPill: false
            property bool showNotificationPill: false
            property bool notificationAutoExpand: false
            property bool notificationStaggerRows: true
            property bool notificationClearOnBoot: false
            property bool notificationShowCount: true
            property string notificationCorner: "bottomRight"
            property int notificationTimeout: 8
            property bool showPowerPill: false
            property bool showOpacityPill: false
            property bool showTailscalePill: false
            property bool showHyprInspPill: false
            property bool showControlBarPill: true
            property bool showActiveWindowPill: true
            property string activeWindowPillCorner: "topLeft"
            property int activeWindowPillWidth: 640
            property string activeWindowExcludesJson: "[\"hypr-screensaver\"]"
            property string clockFormat: "dddd, MM·dd·yyyy | HH:mm:ss"
            property string clockFont: ""
            property int clockFontPercent: 100
            property bool clockBold: true
            property bool clockItalic: false
            property string clockColor: ""
            property int clockWeekStart: 0
            property string clockClick: "right"
            // 0 means the theme file's opacity numbers.
            property int opacityQuickshell: 0
            property int opacitySatty: 0
            property string wallpaperDir: ""
            property string wallpaperCurrent: ""
            property int wallpaperTileSize: 148
            property bool showNetworkFullIp: false
            property bool showNetworkLastOctet: true
            property bool showNetworkDeviceName: false
            property int bluetoothScanSeconds: 45
            property string ovLayout: "rows"
            property string ovAnchor: "top"
            property int ovGap: 34
            property int ovPadding: 80
            property int ovPaddingTop: 40
            property int ovPaddingBottom: 70
            property real ovMaxScale: 1
            property int ovDuration: 360
            property int ovPreviewRound: 12
            property real ovBlur: 1
            property bool ovBackdropBlur: false
            property bool ovSwitchAnimation: true
            property int ovSwitchDuration: 260
            property bool ovMoveAnimation: true
            property int ovMoveDuration: 240
            property int ovStripOffset: 0
            property int ovStripHeight: 150
            property int ovStripWidth: 150
            property int ovStripCardMax: 300
            property int ovStripMargin: 22
            property int ovStripGap: 18
            property int ovStripCardRound: 10
            property int ovHoverBorder: 3
            property int ovSelectBorder: 3
            property bool ovLivePreviews: true
            property bool ovShowWindowLabels: true
            property bool ovShowWsLabels: true
            property bool ovStripPreviews: true
            property bool ovNumberLabels: false
            property bool ovDynamic: true
            property bool ovAutodelete: true
            property bool ovShowEmpty: true
            property bool ovShowSpecial: false
            property bool ovStripAllCard: false
            property bool ovShowAll: false
            property bool ovSwitchOnNew: true
            property bool ovSwitchOnDrop: false
            property bool ovDragToSwap: true
            property bool ovFocusFollowsMouse: true
            property bool ovScrollSwitches: true
            property bool ovExitOnClick: true
            property bool ovExitOnSwitch: false
            property string dockEffect: "both"
            property string dockScope: "icons"
            property int dockPercent: 128
            property int dockRadius: 72
            property int dockJump: 8
            property string dockDot: "#00f5ff"
        }
    }

    Timer {
        id: saveTimer
        interval: Theme.persistDelayMs
        repeat: false
        onTriggered: {
            if (!root.ready || root.writing)
                return
            root.writing = true
            store.writeAdapter()
        }
    }

    IpcHandler {
        target: "shell"
        function setShowMagicWorkspacePill(enabled: bool): void {
            root.setShowSpecial(enabled)
        }
        function toggleShowMagicWorkspacePill(): void {
            root.setShowSpecial(!root.showSpecial)
        }
        function setWsMinimumShown(count: string): void {
            root.setMinimumShown(count)
        }
        function setWsShowOnlyActive(enabled: bool): void {
            root.setShowOnlyActive(enabled)
        }
        function setWsShowNumbers(enabled: bool): void {
            root.setShowNumbers(enabled)
        }
        function setWsStartupWorkspace(workspace: string): void {
            root.setStartupWorkspace(workspace)
        }
        function setWsStartupCloseMagic(enabled: bool): void {
            root.setStartupCloseSpecial(enabled)
        }
    }
}
