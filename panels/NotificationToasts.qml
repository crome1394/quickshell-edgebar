pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The built-in server's popups, stacked in the corner chosen in Settings →
// Notifications, on the main monitor. Newest nearest the corner, at most
// Theme.notificationToastMax. The window is only as big as the popups and
// exists only while the built-in server is on (shell.qml).
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    readonly property string corner: NotificationSettings.cornerValue()
    readonly property bool top: root.corner.startsWith("top")
    readonly property bool left: root.corner.endsWith("Left")
    readonly property var shown: {
        const live = BuiltinNotifications.live
        const list = live.slice(Math.max(0, live.length - Theme.notificationToastMax))
        return root.top ? list.reverse() : list
    }

    screen: ScreenService.mainScreen
    visible: root.shown.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    anchors.top: root.top
    anchors.bottom: !root.top
    anchors.left: root.left
    anchors.right: !root.left
    // qmllint disable missing-property
    margins.top: Theme.notificationToastMargin
    margins.bottom: Theme.notificationToastMargin
    margins.left: Theme.notificationToastMargin
    margins.right: Theme.notificationToastMargin
    // qmllint enable missing-property
    implicitWidth: Theme.notificationToastWidth
    implicitHeight: Math.max(1, stack.implicitHeight)

    Column {
        id: stack
        width: parent.width
        spacing: Theme.space

        Repeater {
            model: root.shown
            delegate: NotificationToast {
                required property var modelData
                notification: modelData
            }
        }
    }
}
