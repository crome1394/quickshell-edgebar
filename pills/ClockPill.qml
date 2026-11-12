pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

Rectangle {
    id: root

    required property var theme

    property string edge: "top"
    property real widthFactor: 1
    property bool calendarOpen: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int barInner: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int facePx: Theme.barTextPx(root.ui, root.widthFactor, ClockSettings.percentValue())
    readonly property string format: ClockSettings.formatText()
    readonly property string clickSide: ClockSettings.clickValue()
    readonly property color faceColor: {
        const ink = ClockSettings.colorValue()
        return ink.length ? ink : root.theme.colFg
    }
    readonly property int hPad: Math.max(1, Math.round(Theme.wsInnerPad * root.ui))

    // Center the calendar on the bar, not on the clock.
    function placeCalendar(nudge) {
        WidgetService.placePopup(root, calendarPopup.anchor, root.edge, nudge)
    }

    implicitWidth: Math.max(1, clockLabel.implicitWidth + root.hPad * 2)
    implicitHeight: root.barInner
    radius: Theme.radiusSm
    color: clockMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: clockMouse.containsMouse ? root.theme.colAccent : root.theme.colBorder
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
        hovered: clockMouse.containsMouse
    }

    // Ticks on the second only when the format shows seconds, else on the minute.
    SystemClock {
        id: clock
        precision: ClockSettings.hasSeconds(root.format) ? SystemClock.Seconds : SystemClock.Minutes
    }

    Text {
        id: clockLabel
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, root.format)
        color: root.faceColor
        font.family: ClockSettings.fontFamily(root.theme.fontFamily)
        font.pixelSize: root.facePx
        font.bold: Config.clockBold
        font.italic: Config.clockItalic
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            const right = mouse.button === Qt.RightButton
            if (root.clickSide === "right" ? right : !right)
                root.calendarOpen = !root.calendarOpen
        }

        BarTip {
            edge: root.edge
            message: root.clickSide === "left" ? "Left-click for the calendar" : "Right-click for the calendar"
            show: clockMouse.containsMouse && !root.calendarOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: calendarPopup
        visible: root.calendarOpen
        color: "transparent"
        grabFocus: true
        // qmllint disable missing-property
        implicitWidth: calendarLoader.item ? calendarLoader.item.implicitWidth : Theme.chip * 8
        implicitHeight: calendarLoader.item ? calendarLoader.item.implicitHeight : Theme.chip * 8
        // qmllint enable missing-property
        onVisibleChanged: if (visible) root.placeCalendar(true)
        onClosed: root.calendarOpen = false
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        Loader {
            id: calendarLoader
            active: calendarPopup.visible
            sourceComponent: Component {
                ClockCalendar {
                    theme: root.theme
                    weekStart: ClockSettings.weekStartValue()
                    onDismissed: root.calendarOpen = false
                }
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: calendarPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeCalendar(false)
        }
    }
}
