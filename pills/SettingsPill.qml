import QtQuick
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    required property var theme
    property string edge: "top"

    signal clicked()

    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: mouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
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

    SpannerIcon {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        theme: root.theme
        pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui))
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
