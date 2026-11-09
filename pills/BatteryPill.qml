import QtQuick
import qs.components
import qs.services
import qs.theme

// Battery: a level glyph with the percent under it, red when low, a bolt
// while charging. Left click steps the power profile (power saver,
// balanced, performance). The tip shows time left and the profile.
// BarSlot loads it only on a machine with a battery.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property color ink: BatteryService.low ? root.theme.colDanger
        : (BatteryService.charging || mouse.containsMouse ? root.theme.colAccent : root.theme.colFg)

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: mouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: BatteryService.low ? root.theme.colDanger : (mouse.containsMouse ? root.theme.colAccent : root.theme.colBorder)
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

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            rotation: WidgetService.iconTurn(root.edge)
            anchors.horizontalCenter: parent.horizontalCenter
            text: BatteryService.glyph()
            color: root.ink
            font.family: root.theme.iconFont
            font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * 0.8 * root.ui * root.widthFactor))
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: BatteryService.percent
            color: root.ink
            font.family: Theme.uiFont
            font.bold: true
            font.pixelSize: Math.max(1, Math.round(Theme.batteryTextPx * root.ui * root.widthFactor))
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            BatteryService.cycleProfile()
        }

        BarTip {
            edge: root.edge
            message: "Battery " + BatteryService.summary() + ". Power profile: "
                + BatteryService.profileLabel(BatteryService.profile) + " (click to change)."
            show: mouse.containsMouse
        }
    }
}
