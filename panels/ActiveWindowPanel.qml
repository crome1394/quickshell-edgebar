pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// Focused-window pill in a screen corner. It is not a bar-zone widget.
// Show, corner, PID, layout, and excludes are the Widgets → Active Window settings.
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
    // Room left for the title after padding and every other part that shows.
    readonly property int titleLimit: {
        if (!root.showTitle)
            return 0
        let others = 0
        let used = root.hPad * 2
        if (root.iconSource.length > 0) {
            used += root.iconPx
            others += 1
        }
        const classW = Math.ceil(classMetrics.width)
        if (classW > 0) {
            used += classW
            others += 1
        }
        if (root.pidShown) {
            used += Math.ceil(pidMetrics.width)
            others += 1
        }
        if (others > 0)
            used += root.textGap * others
        return Math.max(0, root.pillMax - used)
    }
    readonly property int titleNatural: Math.ceil(titleMetrics.width)
    // A title shorter than one word of room stays hidden so the class is never squeezed.
    readonly property bool titleVisible: root.showTitle && root.titleNatural > 0
        && (root.titleNatural <= root.titleLimit || root.titleLimit >= root.fontPx * 2)
    readonly property bool clipTitle: root.titleVisible && root.titleNatural > root.titleLimit
    // Parts that have something to draw, in the saved left-to-right order.
    readonly property var shownParts: {
        const order = ActiveWindowSettings.layoutValue()
        const out = []
        for (let i = 0; i < order.length; i++) {
            const id = String(order[i] || "")
            if (id === "icon" && root.iconSource.length > 0)
                out.push(id)
            else if (id === "class" && root.classLabel.length > 0)
                out.push(id)
            else if (id === "title" && root.titleVisible)
                out.push(id)
            else if (id === "pid" && root.pidShown)
                out.push(id)
        }
        return out
    }

    function partWidth(id) {
        if (id === "icon")
            return root.iconPx
        if (id === "class")
            return Math.ceil(classMetrics.width)
        if (id === "title")
            return root.clipTitle ? root.titleLimit : root.titleNatural
        if (id === "pid")
            return Math.ceil(pidMetrics.width)
        return 0
    }

    readonly property int contentWidth: {
        const parts = root.shownParts
        let w = 0
        for (let i = 0; i < parts.length; i++)
            w += root.partWidth(parts[i])
        if (parts.length > 1)
            w += root.textGap * (parts.length - 1)
        return Math.max(0, w)
    }
    readonly property bool edgeBarShown: root.atTop ? Config.showTopBar : Config.showBottomBar
    readonly property int edgeInset: {
        if (root.edgeBarShown && root.thickness > root.pillHeight)
            return Math.round((root.thickness - root.pillHeight) / 2)
        return root.pad
    }

    property bool hasFocusedWindow: Hyprland.activeToplevel !== null

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

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property var waylandToplevel: root.toplevel ? root.toplevel.wayland : null
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
    readonly property bool pidShown: ActiveWindowSettings.showPidValue() && root.winPid.length > 0
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
        const focused = Hyprland.focusedMonitor
        const host = root.hostScreen
        if (!host || !focused)
            return false
        const mine = Hyprland.monitorFor(host)
        return mine !== null && mine.name === focused.name
    }

    function noteFocus(hasWindow) {
        root.hasFocusedWindow = hasWindow
        if (!Config.showActiveWindowPill)
            return
        root.refreshClasses()
        classRefresh.restart()
    }

    screen: root.hostScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Config.showActiveWindowPill
        && root.hasFocusedWindow
        && root.toplevel !== null
        && root.classLabel.length > 0
        && root.onThisMonitor
        && !root.excluded

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

    implicitWidth: root.contentWidth + root.hPad * 2
    implicitHeight: root.pillHeight

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.noteFocus(Hyprland.activeToplevel !== null)
        }
        function onRawEvent(event) {
            if (event.name === "activewindowv2")
                root.noteFocus(String(event.data || "").trim().length > 0)
            else if (event.name === "activewindow") {
                const data = String(event.data || "")
                const comma = data.indexOf(",")
                root.noteFocus(comma > 0 && data.slice(0, comma).trim().length > 0)
            }
        }
    }

    Timer {
        id: classRefresh
        interval: Theme.activeWindowClassMs
        repeat: false
        onTriggered: root.refreshClasses()
    }

    Component.onCompleted: root.noteFocus(Hyprland.activeToplevel !== null)

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

    Rectangle {
        id: pill
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
            spacing: root.textGap

            Repeater {
                model: root.shownParts
                delegate: Item {
                    id: slot
                    required property string modelData
                    width: root.partWidth(slot.modelData)
                    height: root.pillHeight

                    Image {
                        visible: slot.modelData === "icon"
                        anchors.fill: parent
                        source: slot.modelData === "icon" ? root.iconSource : ""
                        sourceSize.width: root.iconPx
                        sourceSize.height: root.iconPx
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        visible: slot.modelData !== "icon"
                        width: slot.modelData === "title" ? parent.width : implicitWidth
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        elide: slot.modelData === "title" && root.clipTitle ? Text.ElideRight : Text.ElideNone
                        text: slot.modelData === "class" ? root.classLabel : (slot.modelData === "pid" ? root.winPid : root.winTitle)
                        color: slot.modelData === "class" ? root.theme.colAccent : (slot.modelData === "pid" ? root.theme.colFgMuted : root.theme.colFg)
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.fontPx
                        font.bold: slot.modelData === "class"
                    }
                }
            }
        }
    }
}
