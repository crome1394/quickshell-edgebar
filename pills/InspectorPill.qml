import QtQuick
import qs.components
import qs.services
import qs.theme

// Opens and closes the Inspector window (Bindings, System Info). Loaded
// only while the Inspector widget is on the bar. The window itself is
// created only while open, so this pill costs a single icon.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool lit: mouse.containsMouse || InspectorService.open

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: root.lit ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.lit ? root.theme.colAccent : root.theme.colBorder
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
        hovered: mouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: Theme.inspectorGlyph
        color: root.lit ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            InspectorService.toggle()
        }

        BarTip {
            edge: root.edge
            message: InspectorService.open ? "Close the Inspector" : "Inspector: keybinds and system info"
            show: mouse.containsMouse
        }
    }
}
