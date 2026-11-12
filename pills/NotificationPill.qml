import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.panels
import qs.services
import qs.theme

// Bell. Left click opens history. Middle click marks all read. Right
// click toggles Do Not Disturb. The badge counts unread notifications.
// Loaded only while the Notifications widget is on the bar.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property string screenName: ""
    readonly property bool historyHere: NotificationService.historyOpen && ScreenService.owns(NotificationService.historyScreen, root.screenName)
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property bool dnd: NotificationService.dnd
    readonly property int count: NotificationService.unread
    readonly property string bellGlyph: {
        if (root.dnd)
            return root.count > 0 ? String.fromCodePoint(0xf00a0) : String.fromCodePoint(0xf0a93)
        return root.count > 0 ? String.fromCodePoint(0xf116b) : String.fromCodePoint(0xf009c)
    }
    readonly property string tipText: {
        const head = root.count > 0 ? root.count + " unread" : "Notifications"
        const dnd = root.dnd ? " · DND on" : ""
        const middle = root.count > 0 ? " · Middle: mark read" : ""
        return head + dnd + " · Left: history" + middle + " · Right: DND"
    }

    // Sit outside the bar. nudge is only for open: onAnchoring must pass false.
    function placeHistory(nudge) {
        WidgetService.placePopup(root, historyPopup.anchor, root.edge, nudge)
    }

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.dnd
           ? Qt.rgba(root.theme.colDanger.r, root.theme.colDanger.g, root.theme.colDanger.b, bellMouse.containsMouse ? 0.38 : 0.24)
           : (bellMouse.containsMouse || root.historyHere ? root.theme.colHover : root.theme.colSurface)
    border.width: Theme.borderWidth
    border.color: root.dnd
                  ? root.theme.colDanger
                  : (bellMouse.containsMouse || root.historyHere ? root.theme.colAccent : root.theme.colBorder)
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
        hovered: bellMouse.containsMouse
    }

    Text {
        id: bellIcon
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: root.bellGlyph
        color: root.dnd ? root.theme.colDanger : root.theme.colFg
        font.family: root.theme.fontFamily
        font.pixelSize: root.icon
    }

    Rectangle {
        visible: root.count > 0 && Config.notificationShowCount !== false
        z: 1
        width: Math.max(Theme.badgeHeight - 4, badgeText.implicitWidth + Theme.tabGap)
        height: Theme.badgeHeight - 6
        radius: (Theme.badgeHeight - 6) / 2
        color: root.dnd ? root.theme.colDanger : root.theme.colAccent
        anchors.top: bellIcon.top
        anchors.right: bellIcon.right
        anchors.topMargin: -4
        anchors.rightMargin: -6

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.count > 99 ? "99+" : root.count
            color: root.theme.colWsActiveFg
            font.family: root.theme.fontFamily
            font.pixelSize: Theme.smallPx
            font.bold: true
        }
    }

    MouseArea {
        id: bellMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton)
                NotificationService.toggleDnd()
            else if (mouse.button === Qt.MiddleButton)
                NotificationService.markAllRead()
            else
                NotificationService.toggleHistory(root.screenName)
        }

        BarTip {
            edge: root.edge
            message: root.tipText
            show: bellMouse.containsMouse && !root.historyHere
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: historyPopup
        visible: root.historyHere && Config.showNotificationPill
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.notificationPanelWidth
        implicitHeight: Theme.notificationPanelHeight
        onClosed: NotificationService.hideHistory()
        // A popup only shows once it has an anchor, so set it up front;
        // placeHistory() then fine-tunes the edge and position.
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property
        onVisibleChanged: {
            if (visible) {
                root.placeHistory(true)
                if (historyBody)
                    historyBody.focusKeys()
            }
        }
        Component.onCompleted: root.placeHistory()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            NotificationHistory {
                id: historyBody
                anchors.fill: parent
                theme: root.theme
                onCloseRequested: NotificationService.hideHistory()
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: historyPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeHistory(false)
        }
    }
}
