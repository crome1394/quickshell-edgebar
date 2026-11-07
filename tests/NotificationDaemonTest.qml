import QtQuick
import Quickshell
import qs.config
import qs.services
import "tests"

// NotificationDaemon: which server Auto picks for each owner of the
// notification name, and that Built-in and SwayNC override it.
ShellRoot {
    Check { id: t }

    Timer {
        // Wait for Config and the first D-Bus check, then set owners by hand.
        interval: 200
        running: Config.ready && NotificationDaemon.checked
        onTriggered: {
            const D = NotificationDaemon
            t.eq("auto is the default", D.setting, "auto")
            t.ok("the first check finished", D.checked)
            D.owner = ""
            t.eq("auto with no daemon: built-in", D.mode, "builtin")
            D.owner = "swaync"
            t.eq("auto finds SwayNC", D.mode, "swaync")
            D.owner = "dunst"
            t.eq("auto finds another daemon", [D.mode, D.modeLabel], ["external", "dunst"])
            D.owner = "quickshell"
            t.eq("auto when the bar owns it: built-in", D.mode, "builtin")
            Config.notificationServer = "builtin"
            D.owner = "dunst"
            t.eq("built-in chosen wins over a running daemon", D.mode, "builtin")
            Config.notificationServer = "swaync"
            D.owner = ""
            t.eq("SwayNC chosen", D.mode, "swaync")
            Config.notificationServer = "nonsense"
            t.eq("unknown values mean auto", D.setting, "auto")
            t.done()
        }
    }
}
