pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.config
import qs.services
import qs.theme

// Settings → Notifications → Server.
//   Auto      use the notification daemon already running (SwayNC, dunst,
//             mako, …), or the built-in server when there is none
//   Built-in  the bar is the server: its own popups, history, and DND
//   SwayNC    SwayNC shows popups; the bar keeps history and DND
// Only one server can own the name, so Built-in needs others stopped.
// Saves at once.
Column {
    id: root

    readonly property string setting: NotificationDaemon.setting
    readonly property string owner: NotificationDaemon.owner
    readonly property bool otherRunning: root.owner.length > 0 && !NotificationDaemon.ownerIsBar
    // Built-in chosen but another daemon holds the name.
    readonly property bool blocked: root.setting === "builtin" && root.otherRunning

    function setServer(mode) {
        Config.saveFields(() => {
            Config.notificationServer = mode === "auto" ? "" : mode
        })
        NotificationDaemon.check()
    }

    Component.onCompleted: NotificationDaemon.watchers++
    Component.onDestruction: NotificationDaemon.watchers = Math.max(0, NotificationDaemon.watchers - 1)

    spacing: Theme.space

    // Stop the daemon that holds the name (its systemd user unit), then
    // let the built-in server claim it. Fixed argv; the unit name is the
    // process name, already limited to [A-Za-z0-9._-].
    Process {
        id: stopper
        onExited: {
            NotificationDaemon.check()
            BuiltinNotifications.reclaim()
        }
    }

    Row {
        spacing: Theme.tabGap

        ChipButton {
            label: "Auto"
            active: root.setting === "auto"
            tip: "Use the notification daemon that is already running, or the built-in server when there is none"
            onClicked: root.setServer("auto")
        }

        ChipButton {
            label: "Built-in"
            active: root.setting === "builtin"
            tip: "The bar is the notification server: its own popups, history, and Do Not Disturb"
            onClicked: root.setServer("builtin")
        }

        ChipButton {
            label: "SwayNC"
            active: root.setting === "swaync"
            tip: "SwayNC shows the popups; the bar keeps the history and Do Not Disturb"
            onClicked: root.setServer("swaync")
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: {
            if (!NotificationDaemon.checked)
                return "Checking which notification daemon is running…"
            if (root.blocked)
                return root.owner + " is running and holds notifications, so the built-in server cannot start."
            if (root.setting === "swaync" && root.owner !== "swaync")
                return "SwayNC is not running, so no popups show. Start it, or choose Auto or Built-in."
            const using = "Using " + NotificationDaemon.modeLabel + "."
            if (NotificationDaemon.mode === "external")
                return using + " It shows the popups; the bar keeps history" + (root.owner === "dunst" || root.owner === "mako" ? " and Do Not Disturb." : ". Use " + root.owner + "'s own Do Not Disturb.")
            if (root.setting === "auto" && NotificationDaemon.mode === "builtin")
                return using + " No other daemon is running."
            return using
        }
        color: root.blocked || (root.setting === "swaync" && root.owner !== "swaync") ? Theme.danger : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    ChipButton {
        visible: root.blocked
        label: "Stop " + root.owner
        tip: "systemctl --user stop " + root.owner + ".service, then start the built-in server"
        onClicked: {
            stopper.command = ["systemctl", "--user", "stop", "--", root.owner + ".service"]
            stopper.running = true
        }
    }

    Text {
        visible: root.setting === "builtin"
        width: parent.width
        wrapMode: Text.WordWrap
        text: "To keep it after a restart, make sure no other daemon starts at login (remove it from your Hyprland autostart, or uninstall it)."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }
}
