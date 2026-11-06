pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme

// One screen edge. The window stays on the edge so the exclusive zone is
// stable. Hug paints the background behind the widgets. Span fills the edge.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    required property string edge
    required property var theme

    signal openSettings()

    readonly property bool horizontal: root.edge === "top" || root.edge === "bottom"
    readonly property bool enabledBar: {
        if (root.edge === "bottom")
            return Config.showBottomBar
        if (root.edge === "left")
            return Config.showLeftBar
        if (root.edge === "right")
            return Config.showRightBar
        return Config.showTopBar
    }
    readonly property bool span: {
        if (root.edge === "bottom")
            return Config.panelSpanFull
        if (root.edge === "left")
            return Config.leftBarSpanFull
        if (root.edge === "right")
            return Config.rightBarSpanFull
        return Config.barSpanFull
    }
    readonly property string align: {
        let value = String(Config.topBarAlign || "")
        if (root.edge === "bottom")
            value = String(Config.bottomBarAlign || "")
        else if (root.edge === "left")
            value = String(Config.leftBarAlign || "")
        else if (root.edge === "right")
            value = String(Config.rightBarAlign || "")
        if (value === "left" || value === "right")
            return value
        return "center"
    }
    readonly property bool topShown: Config.showTopBar
    readonly property bool bottomShown: Config.showBottomBar
    readonly property bool shown: root.enabledBar
    readonly property real ui: WidgetService.uiScale
    readonly property int thickness: Math.max(1, Math.round(Theme.barHeight * root.ui))
    readonly property int dockRoom: DockSettings.room(root.thickness)
    readonly property int pad: Math.max(0, Math.round(Theme.barPad * root.ui))
    readonly property int sideGap: Math.max(0, Math.round(Theme.barSideGap * root.ui))
    readonly property int edgeInset: root.sideGap + root.pad
    readonly property int minAlong: Math.max(root.thickness, Math.round(Theme.barMinLength * root.ui))
    readonly property bool flush: Config.flushWindowsToBar
    readonly property int edgeGap: {
        if (!root.flush)
            return 0
        if (root.edge === "right")
            return WidgetService.gapsRight
        if (root.edge === "bottom")
            return WidgetService.gapsBottom
        if (root.edge === "left")
            return WidgetService.gapsLeft
        return WidgetService.gapsTop
    }

    visible: root.shown
    color: "transparent"
    exclusiveZone: {
        if (!root.shown)
            return 0
        if (!root.flush)
            return root.thickness
        return Math.max(0, root.thickness - root.pad - root.edgeGap)
    }

    anchors.top: root.edge === "top" || root.edge === "left" || root.edge === "right"
    anchors.bottom: root.edge === "bottom" || root.edge === "left" || root.edge === "right"
    anchors.left: root.edge === "left" || root.edge === "top" || root.edge === "bottom"
    anchors.right: root.edge === "right" || root.edge === "top" || root.edge === "bottom"

    implicitHeight: root.horizontal ? root.thickness + root.dockRoom : root.thickness
    implicitWidth: root.horizontal ? root.thickness : root.thickness + root.dockRoom

    // The glass stays the click target. The extra band is room for the dock.
    // qmllint disable missing-property
    mask: Region {
        item: root.horizontal ? hGlass : vGlass
    }
    // qmllint enable missing-property

    // Margins is opaque to qmllint. Side bars sit between the horizontal bars.
    // qmllint disable missing-property
    margins.top: !root.horizontal && root.topShown ? root.thickness : 0
    margins.bottom: !root.horizontal && root.bottomShown ? root.thickness : 0
    // qmllint enable missing-property

    Rectangle {
        id: hGlass
        visible: root.horizontal
        color: root.theme.colBar
        radius: root.span ? 0 : Theme.radius
        border.width: Theme.borderWidth
        border.color: root.theme.colBarBorder
        y: root.edge === "bottom" ? parent.height - height : 0
        height: root.thickness
        anchors.left: root.span ? parent.left : hCluster.left
        anchors.right: root.span ? parent.right : hCluster.right
        anchors.leftMargin: root.span ? root.sideGap : -root.pad
        anchors.rightMargin: root.span ? root.sideGap : -root.pad

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.borderWidth
            color: root.theme.colGlassHighlight
        }
    }

    Item {
        id: hCluster
        visible: root.horizontal
        y: root.edge === "bottom" ? parent.height - height : 0
        height: root.thickness
        width: {
            const content = hRow.implicitWidth
            if (root.span)
                return content
            const inner = Math.max(0, root.minAlong - root.pad * 2)
            return Math.max(content, inner)
        }
        x: {
            const end = Math.max(root.edgeInset, parent.width - width - root.edgeInset)
            if (root.align === "right")
                return end
            if (root.align === "center")
                return Math.max(root.edgeInset, (parent.width - width) / 2)
            return root.edgeInset
        }

        Row {
            id: hRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(0, Math.round(Theme.wsGap * root.ui))
            x: {
                if (root.align === "right")
                    return Math.max(0, parent.width - implicitWidth)
                if (root.align === "center")
                    return Math.max(0, (parent.width - implicitWidth) / 2)
                return 0
            }

            Repeater {
                model: root.horizontal ? WidgetService.barEntries(root.edge) : []
                delegate: BarSlot {
                    edge: root.edge
                    horizontal: root.horizontal
                    theme: root.theme
                    onOpenSettings: root.openSettings()
                }
            }
        }
    }

    Rectangle {
        id: vGlass
        visible: !root.horizontal
        color: root.theme.colBar
        radius: root.span ? 0 : Theme.radius
        border.width: Theme.borderWidth
        border.color: root.theme.colBarBorder
        x: root.edge === "right" ? parent.width - width : 0
        width: root.thickness
        anchors.top: root.span ? parent.top : vCluster.top
        anchors.bottom: root.span ? parent.bottom : vCluster.bottom
        anchors.topMargin: root.span ? root.sideGap : -root.pad
        anchors.bottomMargin: root.span ? root.sideGap : -root.pad

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: root.edge === "right" ? parent.width - width : 0
            width: Theme.borderWidth
            color: root.theme.colGlassHighlight
        }
    }

    Item {
        id: vCluster
        visible: !root.horizontal
        x: root.edge === "right" ? parent.width - width : 0
        width: root.thickness
        height: {
            const content = vCol.implicitHeight
            if (root.span)
                return content
            const inner = Math.max(0, root.minAlong - root.pad * 2)
            return Math.max(content, inner)
        }
        y: {
            const end = Math.max(root.edgeInset, parent.height - height - root.edgeInset)
            if (root.align === "right")
                return end
            if (root.align === "center")
                return Math.max(root.edgeInset, (parent.height - height) / 2)
            return root.edgeInset
        }

        Column {
            id: vCol
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.max(0, Math.round(Theme.wsGap * root.ui))
            y: {
                if (root.align === "right")
                    return Math.max(0, parent.height - implicitHeight)
                if (root.align === "center")
                    return Math.max(0, (parent.height - implicitHeight) / 2)
                return 0
            }

            Repeater {
                model: root.horizontal ? [] : WidgetService.barEntries(root.edge)
                delegate: BarSlot {
                    edge: root.edge
                    horizontal: root.horizontal
                    theme: root.theme
                    onOpenSettings: root.openSettings()
                }
            }
        }
    }
}
