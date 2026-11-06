pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.config

// Applies window transparency in Hyprland. Writes opacity.lua next to the
// Hyprland config (hyprland.lua loads it with require("opacity")), then
// swaps the live rules with one `hyprctl repl`: the old rules are turned
// off and the file is run again. Changes are coalesced, so dragging a
// slider runs one command at a time. Started from the shell, so the levels
// are applied at login even when the pill is not on a bar.
Singleton {
    id: root

    property bool appliedOnce: false
    property bool queued: false
    property string error: ""
    property var windows: []          // open windows for the override picker
    property bool listing: false
    property bool saveFailed: false

    readonly property string hyprDir: {
        const xdg = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        const home = String(Quickshell.env("HOME") || "")
        return (xdg.length ? xdg : home + "/.config") + "/hypr"
    }
    readonly property string luaPath: root.hyprDir + "/opacity.lua"
    // Saved levels; any change schedules an apply.
    readonly property string wanted: OpacitySettings.luaText(OpacitySettings.allValue(), OpacitySettings.savedOverrides())

    onWantedChanged: {
        if (root.appliedOnce)
            delay.restart()
    }

    function ensureApplied() {
        if (!Config.ready || root.appliedOnce)
            return
        root.appliedOnce = true
        root.kick()
    }

    // Lua long strings cannot hold "]]"; a path with it is refused.
    function pathOk(path) {
        return path.length > 1 && path.charAt(0) === "/" && path.indexOf("]]") < 0 && !/[\r\n\0]/.test(path)
    }

    function kick() {
        if (reload.running) {
            root.queued = true
            return
        }
        if (!root.pathOk(root.luaPath)) {
            root.error = "The Hyprland config folder path cannot be used: " + root.luaPath
            return
        }
        root.error = ""
        root.saveFailed = false
        writer.setText(root.wanted)
        if (root.saveFailed) {
            root.error = "Could not write " + root.luaPath
            root.finish()
            return
        }
        root.reloadLive()
    }

    function reloadLive() {
        reload.command = ["hyprctl", "repl", [
            "if _G.QS_OPACITY then",
            "  for i = 1, #_G.QS_OPACITY do",
            "    local rule = _G.QS_OPACITY[i]",
            "    if rule then rule:set_enabled(false) end",
            "  end",
            "end",
            "_G.QS_OPACITY = {}",
            "dofile([[" + root.luaPath + "]])",
            "return 'ok'"
        ].join("\n")]
        reload.running = true
    }

    function finish() {
        if (root.queued) {
            root.queued = false
            Qt.callLater(root.kick)
        }
    }

    // Open windows, one row per class, for the Add application picker.
    function listWindows() {
        if (clients.running)
            return
        root.listing = true
        clients.running = true
    }

    function readWindows(text) {
        let raw = []
        try {
            raw = JSON.parse(String(text || "[]"))
        } catch (e) {
            raw = []
        }
        const seen = {}
        const out = []
        for (let i = 0; i < raw.length; i++) {
            const cls = String(raw[i].class || raw[i].initialClass || "")
            if (!OpacitySettings.classOk(cls) || seen[cls])
                continue
            seen[cls] = true
            out.push({ cls: cls, title: String(raw[i].title || "").substring(0, 80) })
        }
        out.sort((a, b) => a.cls.localeCompare(b.cls))
        root.windows = out
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

    // Write-only: never reads the old file, and each write finishes before
    // setText() returns, so the live reload always sees the new rules.
    FileView {
        id: writer
        path: root.luaPath
        preload: false
        blockWrites: true
        atomicWrites: true
        printErrors: true
        onSaveFailed: root.saveFailed = true
    }

    Process {
        id: reload
        stdout: StdioCollector {
            id: reloadOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: reloadErr
            waitForEnd: true
        }
        onExited: (code) => {
            const said = (String(reloadOut.text) + String(reloadErr.text)).trim()
            if (code !== 0 || /^error/i.test(said))
                root.error = ("Hyprland did not take the rules: " + (said || "exit " + code)).slice(0, 220)
            root.finish()
        }
    }

    Process {
        id: clients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsOut
            waitForEnd: true
        }
        onExited: {
            root.listing = false
            root.readWindows(clientsOut.text)
        }
    }
}
