pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.config

// Writes the transparency override and applies it in Hyprland.
// Started from the shell so a hidden pill still keeps the override.
Singleton {
    id: root

    property bool appliedOnce: false
    property bool queued: false
    property int pendingQuickshell: 100
    property int pendingSatty: 100
    property string error: ""

    function ensureApplied() {
        if (!Config.ready || root.appliedOnce)
            return
        root.appliedOnce = true
        root.apply(Config.opacityQuickshellValue(), Config.opacitySattyValue(), true)
    }

    function apply(quickshell, satty, immediate) {
        root.pendingQuickshell = quickshell
        root.pendingSatty = satty
        if (immediate) {
            delay.stop()
            root.kick()
            return
        }
        delay.restart()
    }

    function kick() {
        if (proc.running) {
            root.queued = true
            return
        }
        root.error = ""
        proc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/opacity.py",
            "set",
            String(root.pendingQuickshell),
            String(root.pendingSatty)
        ]
        proc.running = true
    }

    Timer {
        id: delay
        interval: Theme.opacityApplyDelayMs
        repeat: false
        onTriggered: root.kick()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            root.ensureApplied()
        }
    }

    Component.onCompleted: root.ensureApplied()

    Process {
        id: proc
        command: ["python3", "--version"]
        stderr: StdioCollector {
            id: err
            waitForEnd: true
        }
        onExited: {
            const message = String(err.text || "").trim()
            if (message.length)
                root.error = message.slice(0, 180)
            if (root.queued) {
                root.queued = false
                Qt.callLater(root.kick)
            }
        }
    }
}
