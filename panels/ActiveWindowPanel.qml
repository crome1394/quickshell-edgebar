pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// Focused-window pill in a screen corner. It is not a bar-zone widget.
// Show, corner, pattern, and excludes are the Widgets → Active Window settings.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    required property var theme

    readonly property real ui: WidgetService.uiScale
    readonly property string corner: ActiveWindowSettings.cornerValue()
    readonly property var excludeList: ActiveWindowSettings.savedExcludes()
    readonly property bool atTop: root.corner === "topLeft" || root.corner === "topRight"
    readonly property bool atLeft: root.corner === "topLeft" || root.corner === "bottomLeft"
    readonly property int thickness: Math.max(1, Math.round(Theme.barHeight * root.ui))
    readonly property int pad: Math.max(0, Math.round(Theme.barPad * root.ui))
    readonly property int sideGap: Math.max(0, Math.round(Theme.barSideGap * root.ui))
    readonly property int pillHeight: Math.max(1, root.thickness - root.pad * 2)
    readonly property int fontPx: Math.max(1, Math.round(root.theme.fontPx * root.ui))
    readonly property int iconPx: Math.max(1, Math.round(root.theme.iconPx * root.ui))
    readonly property int hPad: Math.max(1, Math.round(Theme.wsInnerPad * root.ui))
    readonly property int textGap: Math.max(1, Math.round(Theme.space * root.ui))
    readonly property int pillMax: Math.max(1, Math.round(ActiveWindowSettings.widthValue() * root.ui))
    readonly property bool showTitle: root.winTitle.length > 0 && root.winTitle !== root.classLabel
    // Room left for the title after padding, marks, and every other part that shows.
    // This does not read the drawn segments. Those depend on whether the title fits.
    readonly property int titleLimit: root.titleRoom()
    readonly property int titleNatural: Math.ceil(titleMetrics.width)
    // A title shorter than one word of room stays hidden so the class is never squeezed.
    readonly property bool titleVisible: root.showTitle && root.titleNatural > 0
        && (root.titleNatural <= root.titleLimit || root.titleLimit >= root.fontPx * 2)
    readonly property bool clipTitle: root.titleVisible && root.titleNatural > root.titleLimit
    readonly property var shownSegments: root.segments()
    readonly property int contentWidth: {
        const parts = root.shownSegments
        let w = 0
        for (let i = 0; i < parts.length; i++)
            w += root.segmentWidth(parts[i])
        return Math.max(0, w)
    }

    function gapWidth(gap) {
        const text = String(gap || "")
        if (!text.length)
            return 0
        if (text === " ")
            return root.textGap
        return Math.ceil(plainMetrics.advanceWidth(text))
    }

    function litWidth(text) {
        const s = String(text || "")
        if (!s.length)
            return 0
        return Math.ceil(plainMetrics.advanceWidth(s))
    }

    function titleRoom() {
        if (!root.showTitle)
            return 0
        const model = ActiveWindowSettings.formatValue()
        let used = root.hPad * 2
        let shown = 0
        let titleOn = false
        for (let i = 0; i < model.length; i++) {
            const part = model[i]
            if (!part || !part.on)
                continue
            const id = String(part.id || "")
            let body = 0
            let draws = false
            if (id === "title") {
                draws = true
                titleOn = true
            } else if (id === "icon") {
                draws = root.iconSource.length > 0
                body = root.iconPx
            } else if (id === "class") {
                draws = root.classLabel.length > 0
                body = Math.ceil(classMetrics.width)
            } else if (id === "pid") {
                draws = root.winPid.length > 0
                body = Math.ceil(pidMetrics.width)
            }
            if (!draws)
                continue
            const gap = String(part.gap || "")
            const gapW = shown === 0 && gap.trim() === "" ? 0 : root.gapWidth(gap)
            used += gapW + root.litWidth(part.open) + body + root.litWidth(part.close) + root.litWidth(part.tail)
            shown++
        }
        if (!titleOn)
            return 0
        return Math.max(0, root.pillMax - used)
    }

    function segmentWidth(seg) {
        const kind = seg ? String(seg.kind || "") : ""
        if (kind === "gap")
            return root.textGap
        if (kind === "icon")
            return root.iconPx
        if (kind === "class")
            return Math.ceil(classMetrics.width)
        if (kind === "title")
            return root.clipTitle ? root.titleLimit : root.titleNatural
        if (kind === "pid")
            return Math.ceil(pidMetrics.width)
        return root.litWidth(seg ? seg.text : "")
    }

    function segmentColor(seg) {
        const kind = seg ? String(seg.kind || "") : ""
        const tone = seg ? String(seg.tone || "") : ""
        const which = kind === "lit" ? tone : kind
        if (which === "class")
            return root.theme.colAccent
        if (which === "pid" || which === "")
            return root.theme.colFgMuted
        return root.theme.colFg
    }

    // One drawn piece per gap, mark, or part. A single space is the usual gap.
    function segments() {
        const model = ActiveWindowSettings.formatValue()
        const out = []
        let shown = 0
        for (let i = 0; i < model.length; i++) {
            const part = model[i]
            if (!part || !part.on)
                continue
            const id = String(part.id || "")
            let kind = ""
            let text = ""
            if (id === "icon") {
                if (!root.iconSource.length)
                    continue
                kind = "icon"
            } else if (id === "class") {
                if (!root.classLabel.length)
                    continue
                kind = "class"
                text = root.classLabel
            } else if (id === "title") {
                if (!root.titleVisible)
                    continue
                kind = "title"
                text = root.winTitle
            } else if (id === "pid") {
                if (!root.winPid.length)
                    continue
                kind = "pid"
                text = root.winPid
            } else {
                continue
            }
            const gap = String(part.gap || "")
            if (!(shown === 0 && gap.trim() === "")) {
                if (gap === " ")
                    out.push({ kind: "gap", text: "" })
                else if (gap.length)
                    out.push({ kind: "lit", text: gap, tone: "" })
            }
            const open = String(part.open || "")
            const close = String(part.close || "")
            const tail = String(part.tail || "")
            if (open.length)
                out.push({ kind: "lit", text: open, tone: id })
            out.push({ kind: kind, text: text })
            if (close.length)
                out.push({ kind: "lit", text: close, tone: id })
            if (tail.length)
                out.push({ kind: "lit", text: tail, tone: "" })
            shown++
        }
        return out
    }
    readonly property bool edgeBarShown: root.atTop ? Config.showTopBar : Config.showBottomBar
    readonly property int edgeInset: {
        if (root.edgeBarShown && root.thickness > root.pillHeight)
            return Math.round((root.thickness - root.pillHeight) / 2)
        return root.pad
    }

    function patternMatches(pattern, value) {
        const text = String(value || "")
        const pat = String(pattern || "").trim()
        if (pat.length < 2 || text.length === 0)
            return false
        if (pat.indexOf("*") < 0)
            return text.toLowerCase() === pat.toLowerCase()
        if (pat.replace(/\*/g, "").trim().length < 2)
            return false
        const escaped = pat.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*")
        try {
            return new RegExp("^" + escaped + "$", "i").test(text)
        } catch (e) {
            return false
        }
    }

    function field(obj, key) {
        if (!obj)
            return ""
        const value = obj[key]
        if (value === undefined || value === null)
            return ""
        return String(value)
    }

    function desktopEntryFor(id) {
        let name = String(id || "")
        if (!name.length)
            return null
        if (name.slice(-8) === ".desktop")
            name = name.slice(0, -8)
        let entry = DesktopEntries.byId(name)
        if (!entry)
            entry = DesktopEntries.heuristicLookup(name)
        return entry
    }

    function refreshClasses() {
        if (!Config.showActiveWindowPill)
            return
        Hyprland.refreshToplevels()
    }

    // Hyprland.activeToplevel is often still null just after the bar starts.
    // focusTick re-reads the lists until a focused window shows up.
    property int focusTick: 0
    readonly property var hyprFocused: {
        void root.focusTick
        const active = Hyprland.activeToplevel
        if (active)
            return active
        // qmllint disable missing-property
        const values = Hyprland.toplevels ? Hyprland.toplevels.values : []
        // qmllint enable missing-property
        const list = values || []
        for (let i = 0; i < list.length; i++) {
            const top = list[i]
            if (top && top.activated)
                return top
        }
        return null
    }
    readonly property var waylandFocused: {
        void root.focusTick
        const active = ToplevelManager.activeToplevel
        if (active)
            return active
        // qmllint disable missing-property
        const values = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []
        // qmllint enable missing-property
        const list = values || []
        for (let i = 0; i < list.length; i++) {
            const top = list[i]
            if (top && top.activated)
                return top
        }
        return null
    }
    readonly property var toplevel: root.hyprFocused
    readonly property var waylandToplevel: {
        if (root.hyprFocused && root.hyprFocused.wayland)
            return root.hyprFocused.wayland
        return root.waylandFocused
    }
    readonly property string ipcClass: root.field(root.toplevel ? root.toplevel.lastIpcObject : null, "class")
    readonly property string ipcInitialClass: root.field(root.toplevel ? root.toplevel.lastIpcObject : null, "initialClass")
    readonly property string waylandAppId: root.waylandToplevel ? String(root.waylandToplevel.appId || "") : ""
    readonly property string winClass: {
        if (root.waylandAppId.length)
            return root.waylandAppId
        if (root.ipcClass.length)
            return root.ipcClass
        return root.ipcInitialClass
    }
    readonly property string winTitle: {
        const live = root.toplevel ? String(root.toplevel.title || "") : ""
        if (live.length)
            return live
        const waylandTitle = root.waylandToplevel ? String(root.waylandToplevel.title || "") : ""
        if (waylandTitle.length)
            return waylandTitle
        return root.field(root.toplevel ? root.toplevel.lastIpcObject : null, "initialTitle")
    }
    readonly property bool steamGame: root.winClass.indexOf("steam_app_") === 0
    readonly property string winPid: {
        const n = root.field(root.toplevel ? root.toplevel.lastIpcObject : null, "pid")
        if (!n.length || n === "0")
            return ""
        return n
    }
    readonly property string classLabel: {
        if (root.steamGame && root.winTitle.length)
            return root.winTitle
        if (root.winClass.length)
            return root.winClass
        return root.winTitle
    }
    readonly property string iconSource: {
        const fromClass = root.desktopEntryFor(root.winClass)
        const fromIpc = fromClass ? fromClass : root.desktopEntryFor(root.ipcClass)
        const entry = fromIpc ? fromIpc : root.desktopEntryFor(root.ipcInitialClass)
        const fromEntry = entry ? IconService.url(entry.icon) : ""
        if (fromEntry.length)
            return fromEntry
        if (root.steamGame)
            return IconService.url("steam")
        return IconService.url(root.winClass)
    }
    readonly property bool excluded: {
        const list = root.excludeList || []
        for (let i = 0; i < list.length; i++) {
            const item = list[i]
            const text = item && item.text !== undefined ? String(item.text) : String(item || "")
            const kind = item && item.kind === "title" ? "title" : "class"
            if (kind === "title") {
                if (root.patternMatches(text, root.winTitle))
                    return true
            } else if (root.patternMatches(text, root.waylandAppId)
                    || root.patternMatches(text, root.ipcClass)
                    || root.patternMatches(text, root.ipcInitialClass)) {
                return true
            }
        }
        return false
    }
    // The window's own screen property is not read here. visible depends on
    // this flag, and reading screen while that binding runs loops back into it.
    readonly property var hostScreen: ScreenService.mainScreen
    readonly property bool onThisMonitor: {
        const host = root.hostScreen
        if (!host)
            return false
        // One screen is always the main one. Hyprland's monitor name can
        // arrive late and disagree for a moment after startup.
        if (Quickshell.screens.length <= 1)
            return true
        const focused = Hyprland.focusedMonitor
        if (!focused)
            return false
        const mine = Hyprland.monitorFor(host)
        return mine !== null && mine.name === focused.name
    }

    function noteFocus() {
        if (!Config.showActiveWindowPill)
            return
        root.refreshClasses()
        classRefresh.restart()
    }

    screen: root.hostScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Create the layer while the feature is on. Starting hidden and turning
    // visible later does not map the surface after a cold start.
    readonly property bool pillShown: root.classLabel.length > 0 && root.onThisMonitor && !root.excluded
        && root.shownSegments.length > 0
    visible: Config.showActiveWindowPill

    anchors.top: root.atTop
    anchors.bottom: !root.atTop
    anchors.left: root.atLeft
    anchors.right: !root.atLeft
    // qmllint disable missing-property
    margins.top: root.atTop ? root.edgeInset : 0
    margins.bottom: root.atTop ? 0 : root.edgeInset
    margins.left: root.atLeft ? root.sideGap : 0
    margins.right: root.atLeft ? 0 : root.sideGap
    // qmllint enable missing-property

    implicitWidth: root.pillShown ? root.contentWidth + root.hPad * 2 : 0
    implicitHeight: root.pillShown ? root.pillHeight : 0

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.noteFocus()
        }
        function onRawEvent(event) {
            const name = event ? String(event.name || "") : ""
            if (name === "activewindow" || name === "activewindowv2"
                    || name === "openwindow" || name === "closewindow")
                root.noteFocus()
        }
    }

    Timer {
        id: classRefresh
        interval: Theme.activeWindowClassMs
        repeat: false
        onTriggered: root.refreshClasses()
    }

    // The focused window can arrive after the first read. Stop once it shows.
    Timer {
        id: focusWait
        interval: Theme.activeWindowClassMs
        repeat: true
        running: Config.showActiveWindowPill && root.hyprFocused === null && root.focusTick < 12
        onTriggered: {
            root.focusTick++
            root.refreshClasses()
        }
    }

    Component.onCompleted: root.noteFocus()

    TextMetrics {
        id: classMetrics
        font.family: root.theme.fontFamily
        font.pixelSize: root.fontPx
        font.bold: true
        text: root.classLabel
    }

    TextMetrics {
        id: titleMetrics
        font.family: root.theme.fontFamily
        font.pixelSize: root.fontPx
        text: root.winTitle
    }

    TextMetrics {
        id: pidMetrics
        font.family: root.theme.fontFamily
        font.pixelSize: root.fontPx
        text: root.winPid
    }

    FontMetrics {
        id: plainMetrics
        font.family: root.theme.fontFamily
        font.pixelSize: root.fontPx
    }

    Rectangle {
        id: pill
        visible: root.pillShown
        anchors.fill: parent
        radius: Theme.radius
        color: root.theme.colBg
        border.width: Theme.borderWidth
        border.color: root.theme.colBorder

        Row {
            id: content
            anchors.left: parent.left
            anchors.leftMargin: root.hPad
            anchors.verticalCenter: parent.verticalCenter
            width: root.contentWidth
            // Gaps are their own segments. A second spacing would double them.
            spacing: 0

            Repeater {
                model: root.shownSegments
                delegate: Item {
                    id: slot
                    required property var modelData
                    readonly property string kind: String(slot.modelData.kind || "")
                    width: root.segmentWidth(slot.modelData)
                    height: root.pillHeight

                    Image {
                        visible: slot.kind === "icon"
                        anchors.fill: parent
                        source: slot.kind === "icon" ? root.iconSource : ""
                        sourceSize.width: root.iconPx
                        sourceSize.height: root.iconPx
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        visible: slot.kind !== "icon" && slot.kind !== "gap"
                        width: slot.kind === "title" ? parent.width : implicitWidth
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        elide: slot.kind === "title" && root.clipTitle ? Text.ElideRight : Text.ElideNone
                        text: String(slot.modelData.text || "")
                        color: root.segmentColor(slot.modelData)
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.fontPx
                        font.bold: slot.kind === "class"
                    }
                }
            }
        }
    }
}
