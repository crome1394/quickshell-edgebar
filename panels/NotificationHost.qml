import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// History window when the bell is not on a bar. IPC can still open it.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: host

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    implicitWidth: Theme.notificationPanelWidth
    implicitHeight: Theme.notificationPanelHeight

    anchors.right: true
    anchors.bottom: true
    // qmllint disable missing-property
    margins.right: Theme.space * 2
    margins.bottom: (Config.showBottomBar ? Theme.barHeight : 0) + Theme.space * 2
    // qmllint enable missing-property

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.barBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        NotificationHistory {
            id: history
            anchors.fill: parent
            theme: Theme.palette
            onCloseRequested: NotificationService.hideHistory()
            Component.onCompleted: history.focusKeys()
        }
    }
}
