import QtQuick
import qs.components
import qs.config
import qs.services
import qs.theme

// Night light: warms the screen against blue light. Left click turns it
// on or off; the wheel makes it warmer or cooler (100 K a step). The tip
// shows the temperature and the schedule.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool on: NightLightService.on
    readonly property bool lit: mouse.containsMouse || root.on

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: root.on ? root.theme.colAccentDim : (mouse.containsMouse ? root.theme.colHover : root.theme.colSurface)
    border.width: Theme.borderWidth
    border.color: root.lit ? root.theme.colAccent : root.theme.colBorder
    opacity: NightLightService.checked && !NightLightService.available ? Theme.widgetOffOpacity : 1
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
        text: Theme.nightGlyph
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
            NightLightService.toggle()
        }
        onWheel: (wheel) => {
            const step = wheel.angleDelta.y > 0 ? -Theme.nightTempStep : Theme.nightTempStep
            NightLightService.setTemp(Math.max(Theme.nightTempMin, Math.min(Theme.nightTempMax, NightLightService.temp + step)))
        }

        BarTip {
            edge: root.edge
            message: !NightLightService.available
                ? "Night light needs hyprsunset (sudo pacman -S hyprsunset)."
                : "Night light " + (NightLightService.on ? "on" : "off") + " · " + NightLightService.temp + " K"
                    + (Config.nightSchedule ? " · schedule " + Config.nightStart + "–" + Config.nightEnd : "")
                    + ". Wheel: warmer or cooler."
            show: mouse.containsMouse
        }
    }
}
