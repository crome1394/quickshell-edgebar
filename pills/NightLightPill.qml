pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// Night light: warms the screen against blue light. Left click turns it
// on or off; the wheel makes it warmer or cooler (100 K a step). Right
// click opens the menu (warmth and schedule). The tip shows the
// temperature and the schedule.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool menuOpen: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool on: NightLightService.on
    readonly property bool hot: nlMouse.containsMouse || root.menuOpen
    readonly property bool lit: root.hot || root.on

    function tipText() {
        if (NightLightService.checked && !NightLightService.available)
            return "Night light needs hyprsunset (sudo pacman -S hyprsunset)."
        let text = "Night light " + (root.on ? "on" : "off") + " · " + NightLightService.temp + " K"
        if (Config.nightSchedule)
            text += " · schedule " + Config.nightStart + "–" + Config.nightEnd
        return text + ". Right-click for warmth and schedule. Wheel: warmer or cooler."
    }

    // Center the menu on the bar, not on this icon.
    function placeMenu(nudge) {
        WidgetService.placePopup(root, menuPopup.anchor, root.edge, nudge)
    }

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: root.on ? root.theme.colAccentDim : (root.hot ? root.theme.colHover : root.theme.colSurface)
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
        hovered: nlMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: Theme.nightGlyph
        color: root.lit ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: nlMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton) {
                NightLightService.recheck()
                root.menuOpen = !root.menuOpen
                return
            }
            NightLightService.toggle()
        }
        onWheel: (wheel) => {
            const step = wheel.angleDelta.y > 0 ? -Theme.nightTempStep : Theme.nightTempStep
            NightLightService.setTemp(Math.max(Theme.nightTempMin, Math.min(Theme.nightTempMax, NightLightService.temp + step)))
        }

        BarTip {
            edge: root.edge
            message: root.tipText()
            show: nlMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.nightPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.nightPopupMaxHeight, menu.implicitHeight)
        // qmllint enable missing-property
        onVisibleChanged: if (visible) root.placeMenu(true)
        onClosed: root.menuOpen = false
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            NightLightMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
                open: root.menuOpen
                onCloseRequested: root.menuOpen = false
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: menuPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeMenu(false)
        }
    }
}
