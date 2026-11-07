import QtQuick
import qs.components
import qs.services
import qs.theme

// Screen brightness for a built-in panel. The wheel steps it up or down;
// left click goes 25, 50, 75, 100 %. The tip shows the level, read when
// hovered. BarSlot loads it only when a backlight exists.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: mouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: mouse.containsMouse ? root.theme.colAccent : root.theme.colBorder
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
        text: Theme.brightnessGlyph
        color: mouse.containsMouse ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (mouse.containsMouse)
                BrightnessService.refresh()
        }
        onClicked: {
            dock.play()
            BrightnessService.cycle()
        }
        onWheel: (wheel) => BrightnessService.step(wheel.angleDelta.y > 0 ? 1 : -1)

        BarTip {
            edge: root.edge
            message: "Brightness " + BrightnessService.percent + "%. Wheel: brighter or dimmer; click: 25, 50, 75, 100 %."
            show: mouse.containsMouse
        }
    }
}
