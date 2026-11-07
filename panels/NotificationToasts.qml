pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The built-in server's popups, stacked in the corner chosen in Settings →
// Notifications, on the main monitor. With grouping on, one card per app
// (showing the newest and a count); newest nearest the corner, at most
// the number set under Popups. Cards are kept by key across updates so a
// new notification does not replay the others' entrance. The window is
// only as big as the popups and exists only with the built-in server.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    readonly property var look: PopupSettings.live
    readonly property string corner: NotificationSettings.cornerValue()
    readonly property bool top: root.corner.startsWith("top")
    readonly property bool left: root.corner.endsWith("Left")

    // key → notifications in that card, oldest first.
    readonly property var groups: {
        const live = BuiltinNotifications.live
        const map = {}
        const order = []
        for (let i = 0; i < live.length; i++) {
            const n = live[i]
            const app = String(n.appName || "")
            const key = root.look.group && app.length ? "app:" + app.toLowerCase() : "id:" + n.id
            if (!map[key]) {
                map[key] = []
                order.push(key)
            }
            map[key].push(n)
        }
        // Newest card last, by its newest notification.
        order.sort((a, b) => live.indexOf(map[a][map[a].length - 1]) - live.indexOf(map[b][map[b].length - 1]))
        const shown = order.slice(Math.max(0, order.length - root.look.max))
        return { map: map, keys: root.top ? shown.reverse() : shown }
    }

    // Keep cardModel in step with groups.keys without recreating cards.
    function sync() {
        const want = root.groups.keys
        for (let i = cardModel.count - 1; i >= 0; i--) {
            if (want.indexOf(cardModel.get(i).key) < 0)
                cardModel.remove(i)
        }
        for (let j = 0; j < want.length; j++) {
            let at = -1
            for (let k = 0; k < cardModel.count; k++) {
                if (cardModel.get(k).key === want[j]) {
                    at = k
                    break
                }
            }
            if (at < 0)
                cardModel.insert(j, { key: want[j] })
            else if (at !== j)
                cardModel.move(at, j, 1)
        }
    }

    onGroupsChanged: root.sync()
    Component.onCompleted: root.sync()

    ListModel {
        id: cardModel
    }

    screen: ScreenService.mainScreen
    visible: cardModel.count > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    anchors.top: root.top
    anchors.bottom: !root.top
    anchors.left: root.left
    anchors.right: !root.left
    // qmllint disable missing-property
    margins.top: root.look.margin
    margins.bottom: root.look.margin
    margins.left: root.look.margin
    margins.right: root.look.margin
    // qmllint enable missing-property
    implicitWidth: root.look.width
    implicitHeight: Math.max(1, stack.implicitHeight)

    Column {
        id: stack
        width: parent.width
        spacing: Theme.space

        Repeater {
            model: cardModel
            delegate: NotificationToast {
                required property string key
                width: stack.width
                notifications: root.groups.map[key] || []
                look: root.look
                fromLeft: root.left
            }
        }
    }
}
