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

    // The popup anchors to the outer edge of the bar window, beside the clock.
    function placeCalendar() {
        const content = root.Window.contentItem
        if (!content)
            return
        const bounds = root.mapToItem(content, 0, 0, root.width, root.height)
        const cx = Math.round(bounds.x + bounds.width / 2)
        const cy = Math.round(bounds.y + bounds.height / 2)
        let x = cx
        let y = Math.round(content.height)
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (root.edge === "bottom") {
            y = 0
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width)
            y = cy
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (root.edge === "right") {
            x = 0
            y = cy
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const anchor = calendarPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = grow
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
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
            root.placeCalendar()
        }
    }
}
