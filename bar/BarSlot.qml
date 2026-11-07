pragma ComponentBehavior: Bound
import QtQuick
import qs.pills
import qs.services
import qs.theme

// One layout entry on an edge. Loads only the pill that entry draws.
Item {
    id: cell

    required property var modelData
    required property int index
    required property string edge
    required property bool horizontal
    required property var theme

    signal openSettings()

    readonly property string widgetId: String(cell.modelData.id || "")
    readonly property bool divider: WidgetService.isDivider(cell.widgetId)
    readonly property real factor: WidgetService.scaleOf(cell.widgetId)
    readonly property real ui: WidgetService.uiScale
    readonly property int thick: Math.max(1, Math.round(Theme.barHeight * cell.ui))
    readonly property bool toolWidget: cell.widgetId === "tray" || cell.widgetId === "power"
        || cell.widgetId === "opacity" || cell.widgetId === "networkPanel" || cell.widgetId === "bluetooth"
        || cell.widgetId === "launcher" || cell.widgetId === "stats"
        || cell.widgetId === "notifications" || cell.widgetId === "volume"
        || cell.widgetId === "tailscale" || cell.widgetId === "hyprInsp"
        || WidgetService.isLauncherId(cell.widgetId)
    // An empty launcher, or stats with every section off, stays unloaded.
    readonly property bool shown: {
        if (WidgetService.isLauncherId(cell.widgetId))
            return WidgetService.launcherPinCount(cell.widgetId) > 0
        if (cell.widgetId === "stats")
            return WidgetService.statsDrawn()
        return true
    }

    function launcherIndex() {
        if (cell.widgetId === "quickLaunch2")
            return 2
        if (cell.widgetId === "quickLaunch3")
            return 3
        if (cell.widgetId === "quickLaunch4")
            return 4
        return 1
    }
    readonly property int along: {
        if (cell.divider) {
            // Length follows the size slider. Thickness stays a hairline.
            return cell.horizontal
                ? Math.max(1, Math.round(Theme.dividerThickness * cell.ui))
                : Math.max(1, Math.round(Theme.dividerLength * cell.factor * cell.ui))
        }
        const drawn = cell.toolWidget ? tool : face
        return drawn.width > 0 ? drawn.width : cell.thick
    }
    readonly property int across: {
        if (cell.divider) {
            return cell.horizontal
                ? Math.max(1, Math.round(Theme.dividerLength * cell.factor * cell.ui))
                : Math.max(1, Math.round(Theme.dividerThickness * cell.ui))
        }
        const drawn = cell.toolWidget ? tool : face
        return drawn.height > 0 ? drawn.height : cell.thick
    }

    function loadTool() {
        if (!tool.active) {
            tool.source = ""
            return
        }
        let file = "PowerPill.qml"
        const props = {
            theme: cell.theme,
            edge: cell.edge
        }
        if (cell.widgetId === "tray")
            file = "TrayPill.qml"
        else if (cell.widgetId === "opacity")
            file = "OpacityPill.qml"
        else if (cell.widgetId === "networkPanel")
            file = "NetworkPill.qml"
        else if (cell.widgetId === "bluetooth")
            file = "BluetoothPill.qml"
        else if (cell.widgetId === "launcher")
            file = "MenuPill.qml"
        else if (cell.widgetId === "stats")
            file = "StatsPill.qml"
        else if (cell.widgetId === "notifications")
            file = "NotificationPill.qml"
        else if (cell.widgetId === "volume")
            file = "AudioPill.qml"
        else if (cell.widgetId === "tailscale")
            file = "TailscalePill.qml"
        else if (cell.widgetId === "hyprInsp")
            file = "InspectorPill.qml"
        else if (WidgetService.isLauncherId(cell.widgetId)) {
            file = "LaunchPill.qml"
            props.launcher = cell.launcherIndex()
        }
        tool.setSource(Qt.resolvedUrl("../pills/" + file), props)
    }

    function dockRaised(item) {
        return !!(item && item.dockHot === true)
    }

    // True while this pill has its menu, calendar, or history open, so an
    // auto-hide bar stays out until it closes.
    readonly property var pill: cell.toolWidget ? tool.item : face.item
    readonly property bool holding: {
        if (cell.widgetId === "notifications" && NotificationService.historyOpen)
            return true
        const item = cell.pill
        return !!(item && (item.menuOpen === true || item.calendarOpen === true))
    }

    visible: cell.shown
    z: cell.dockRaised(cell.toolWidget ? tool.item : face.item) ? 4 : 0
    implicitWidth: cell.shown ? (cell.horizontal ? cell.along : cell.thick) : 0
    implicitHeight: cell.shown ? (cell.horizontal ? cell.thick : cell.along) : 0

    Component {
        id: settingsFace
        SettingsPill {
            theme: cell.theme
            edge: cell.edge
        }
    }

    Component {
        id: workspacesFace
        WorkspacesPill {
            theme: cell.theme
            edge: cell.edge
        }
    }

    Component {
        id: clockFace
        ClockPill {
            theme: cell.theme
            edge: cell.edge
        }
    }

    Rectangle {
        visible: cell.divider
        anchors.centerIn: parent
        width: cell.along
        height: cell.across
        radius: Theme.borderWidth
        color: cell.theme.colBorder
    }

    Item {
        id: spin
        visible: !cell.divider
        anchors.centerIn: parent
        width: cell.along
        height: cell.across
        rotation: cell.horizontal ? 0 : 90

        // No anchors on the loader, so it keeps the pill's own size.
        Loader {
            id: face
            active: !cell.divider && !cell.toolWidget
            sourceComponent: {
                if (cell.widgetId === "workspaces")
                    return workspacesFace
                if (cell.widgetId === "clock")
                    return clockFace
                return settingsFace
            }
        }

        // Loaded by URL so tray, power, transparency, network, bluetooth, stats, notifications, audio, the Inspector, and the app launchers stay unloaded until that widget is on the bar.
        Loader {
            id: tool
            active: !cell.divider && cell.toolWidget && cell.shown
            onActiveChanged: cell.loadTool()
            Component.onCompleted: cell.loadTool()
        }
    }

    Binding {
        target: face.item
        property: "widthFactor"
        value: cell.factor
        when: face.item !== null
    }

    Binding {
        target: tool.item
        property: "widthFactor"
        value: cell.factor
        when: tool.item !== null
    }

    Connections {
        target: cell.widgetId === "controlBar" ? face.item : null
        function onClicked() {
            cell.openSettings()
        }
    }
}
