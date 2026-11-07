pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.config
import qs.services
import qs.theme

// Settings → Notifications → Server. SwayNC: SwayNC shows popups and the
// bar records history. Built-in: the bar is the notification server (its
// own popups, history, and Do Not Disturb, no extra processes). Only one
// server can run, so Built-in needs SwayNC stopped. Saves at once.
Column {
    id: root

    property bool swayncRunning: false
    readonly property bool builtin: Config.notificationServer === "builtin"

    function setServer(mode) {
        Config.saveFields(() => {
            Config.notificationServer = mode === "builtin" ? "builtin" : ""
        })
    }

    spacing: Theme.space

    // Is SwayNC running? Checked while this page is open.
    Process {
        id: check
        command: ["pgrep", "-x", "swaync"]
        onExited: (code) => root.swayncRunning = code === 0
    }

    Timer {
        interval: Theme.notificationSyncMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    Process {
        id: stopper
        command: ["systemctl", "--user", "stop", "swaync.service"]
        onExited: {
            check.running = true
            BuiltinNotifications.reclaim()
        }
    }

    Row {
        spacing: Theme.tabGap

        ChipButton {
            label: "SwayNC"
            active: !root.builtin
            tip: "SwayNC shows the popups; the bar keeps the history"
            onClicked: root.setServer("swaync")
        }

        ChipButton {
            label: "Built-in"
            active: root.builtin
            tip: "The bar is the notification server: its own popups, history, and Do Not Disturb"
            onClicked: root.setServer("builtin")
        }
    }

    Row {
        visible: root.builtin && root.swayncRunning
        width: parent.width
        spacing: Theme.space

        Text {
            width: parent.width - stopButton.width - Theme.space
            height: Theme.fieldHeight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: "SwayNC is running and holds notifications, so the built-in server cannot start."
            color: Theme.danger
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ChipButton {
            id: stopButton
            label: "Stop SwayNC"
            tip: "systemctl --user stop swaync.service, then start the built-in server"
            onClicked: stopper.running = true
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.builtin
            ? "To keep it after a restart, remove SwayNC from your Hyprland autostart (the systemctl --user start swaync.service line). Popups use the corner and timeout below; Apply saves them."
            : (root.swayncRunning ? "SwayNC is running." : "SwayNC is not running, so no popups will show. Start it, or choose Built-in.")
        color: root.builtin || root.swayncRunning ? Theme.subtext : Theme.danger
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }
}
