pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Which notification server is in use (Settings → Notifications → Server).
//
//   setting  "auto" (also unset, or an older "swaync") or "builtin"
//   mode     what runs: "builtin", "swaync" (SwayNC found), or "external"
//            (another daemon such as dunst or mako; the bar keeps history)
//
// Auto asks D-Bus who owns org.freedesktop.Notifications. Another daemon
// → use it; nobody → the built-in server. When nobody owns it at start,
// Auto waits Theme.notificationClaimDelayMs and asks again before taking
// over, so a daemon starting at login alongside the bar wins. After that
// it checks only while the Notifications page is open (watchers > 0).
Singleton {
    id: root

    readonly property string setting: {
        return String(Config.notificationServer || "") === "builtin" ? "builtin" : "auto"
    }

    // The owner of the notification name, by process name; "" for none,
    // "quickshell" when it is this bar.
    property string owner: ""
    property bool checked: false
    // The first look found nobody; the second one, after the delay, decides.
    property bool firstLook: true
    property int watchers: 0

    readonly property bool ownerIsBar: root.owner === "quickshell" || root.owner === "qs"

    readonly property string mode: {
        if (root.setting === "builtin")
            return "builtin"
        if (!root.checked)
            return "pending"
        if (!root.owner.length || root.ownerIsBar)
            return "builtin"
        return root.owner === "swaync" ? "swaync" : "external"
    }

    // A short name for the daemon in use, for Settings.
    readonly property string modeLabel: {
        if (root.mode === "builtin")
            return "the built-in server"
        if (root.mode === "swaync")
            return "SwayNC"
        if (root.mode === "external")
            return root.owner
        return "…"
    }

    function check() {
        if (!pidProc.running)
            pidProc.running = true
    }

    Component.onCompleted: root.check()

    // Fixed argv; the reply is "(uint32 1234,)" or an error with no owner.
    Process {
        id: pidProc
        command: ["gdbus", "call", "--session", "--dest", "org.freedesktop.DBus",
            "--object-path", "/org/freedesktop/DBus",
            "--method", "org.freedesktop.DBus.GetConnectionUnixProcessID",
            "org.freedesktop.Notifications"]
        stdout: StdioCollector {
            id: pidOut
            waitForEnd: true
        }
        onExited: (code) => {
            const m = /uint32 (\d+)/.exec(String(pidOut.text || ""))
            if (code === 0 && m) {
                const path = "/proc/" + m[1] + "/comm"
                // Setting a new path loads it; the same path needs a reload.
                if (commFile.path === path)
                    commFile.reload()
                else
                    commFile.path = path
            } else if (root.firstLook && root.setting === "auto") {
                // Nobody yet: give a daemon starting at login a moment.
                root.firstLook = false
                secondLook.start()
            } else {
                root.firstLook = false
                root.owner = ""
                root.checked = true
            }
        }
    }

    FileView {
        id: commFile
        printErrors: false
        onLoaded: {
            root.firstLook = false
            root.owner = String(commFile.text() || "").trim().replace(/[^A-Za-z0-9._-]/g, "").substring(0, 32)
            root.checked = true
        }
        onLoadFailed: {
            root.owner = ""
            root.checked = true
        }
    }

    Timer {
        id: secondLook
        interval: Theme.notificationClaimDelayMs
        onTriggered: root.check()
    }

    // Re-check while the Notifications page is open, to show what is running.
    Timer {
        interval: 3000
        repeat: true
        running: root.watchers > 0
        onTriggered: root.check()
    }
}
