import QtQuick
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    required property bool active
    required property bool special
    required property int workspaceId
    required property string symbol
    required property string label
    required property string fontName
    required property int symbolPx
    required property bool bold
    required property bool italic
    required property string labelColor
    // Custom workspace colors (Bar → Workspaces → Colors); "" uses the theme.
    property string activeBg: ""
    property string activeFg: ""
    property string idleFg: ""
    property string hoverFg: ""
    required property bool showNumber
    required property var theme
    property string edge: "top"
    property real dockNeighbor: 1

    signal clicked()

    property bool hovered: mouse.containsMouse

    readonly property real ui: WidgetService.uiScale

    radius: Theme.radiusSm
    height: Math.max(1, Math.round(Theme.wsButtonHeight * root.ui))
    implicitHeight: height
    implicitWidth: Math.max(
        Math.round(Theme.wsButtonWidth * root.ui),
        Math.min(Math.round(Theme.wsButtonWidth * 4 * root.ui), face.implicitWidth + Math.round(Theme.wsInnerPad * root.ui)))
    color: root.active ? (root.activeBg.length ? root.activeBg : root.theme.colWsActive) : (root.hovered ? root.theme.colHover : "transparent")
    border.width: (root.active || root.hovered) ? Theme.borderWidth : 0
    border.color: root.active ? root.theme.colAccent : root.theme.colBorder
    z: Math.round((dock.mag - 1) * 24)
    transform: [
        Scale {
            xScale: dock.mag
            yScale: dock.mag
            origin.x: root.width / 2
            origin.y: dock.growIn ? root.height : 0
        },
        Translate { y: dock.jumpY }
    ]

    DockFace {
        id: dock
        edge: root.edge
        neighbors: true
        hovered: root.hovered
        neighbor: root.dockNeighbor
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.colorAnimMs
            easing.type: Easing.OutQuad
        }
    }

    function stateColor() {
        if (root.active)
            return root.activeFg.length ? root.activeFg : root.theme.colWsActiveFg
        if (root.hovered)
            return root.hoverFg.length ? root.hoverFg : root.theme.colAccent
        return root.idleFg.length ? root.idleFg : root.theme.colWsIdleFg
    }

    Row {
        id: face
        anchors.centerIn: parent
        spacing: 3

        Text {
            visible: text.length > 0
            text: root.symbol
            font.pixelSize: Math.max(1, Math.round(root.symbolPx * root.ui))
            font.family: root.fontName.length ? root.fontName : root.theme.fontFamily
            font.bold: root.bold
            font.italic: root.italic
            color: root.stateColor()
        }

        Text {
            visible: text.length > 0
            width: Math.min(implicitWidth, Math.round(Theme.wsLabelMax * root.ui))
            elide: Text.ElideRight
            text: root.label
            font.pixelSize: Theme.barTextPx(root.ui, 1)
            font.family: root.fontName.length ? root.fontName : root.theme.fontFamily
            font.bold: root.bold
            font.italic: root.italic
            color: root.labelColor.length ? root.labelColor : root.stateColor()
        }

        Text {
            visible: root.showNumber
            // The hidden (special) workspace is numbered 0: it sits in front
            // of workspace 1 on the bar.
            text: root.special ? "0" : String(root.workspaceId)
            font.pixelSize: Theme.barTextPx(root.ui, 1)
            font.bold: true
            font.family: root.theme.fontFamily
            color: root.stateColor()
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            root.clicked()
        }
    }
}
