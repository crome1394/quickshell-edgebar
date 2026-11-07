import QtQuick
import qs.components
import qs.services
import qs.theme

// Caffeine: a tea cup that keeps the screen awake while lit. Left click
// turns it on or off; right click steps through 30 min, 1 h, 2 h, and
// until off. The tip shows the time left.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool on: CaffeineService.on
    readonly property bool lit: mouse.containsMouse || root.on

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: root.on ? root.theme.colAccentDim : (mouse.containsMouse ? root.theme.colHover : root.theme.colSurface)
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
        text: root.on ? Theme.caffeineOnGlyph : Theme.caffeineOffGlyph
        color: root.lit ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (event) => {
            dock.play()
            if (event.button === Qt.RightButton)
                CaffeineService.step()
            else
                CaffeineService.toggle()
        }

        BarTip {
            edge: root.edge
            message: !CaffeineService.on
                ? "Caffeine off. Click to keep the screen awake; right-click for 30 min, 1 h, or 2 h."
                : (CaffeineService.until > 0
                    ? "Caffeine: awake for " + CaffeineService.minutesLeft + " more min. Right-click for longer."
                    : "Caffeine: awake until you turn it off.")
            show: mouse.containsMouse
        }
    }
}
