pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Inspector → System Info: fastfetch's summary as label/value rows. Runs
// only when asked (the tab opening, or Refresh), never in the background.
Singleton {
    id: root

    property string title: ""       // user@host
    property var entries: []        // { label, value }
    property bool loading: false
    property bool loaded: false
    property bool missing: false
    property string error: ""

    function refresh() {
        if (proc.running)
            return
        root.loading = true
        root.error = ""
        proc.finished = false
        proc.running = true
    }

    function ensure() {
        if (!root.loaded && !root.loading)
            root.refresh()
    }

    // fastfetch runs as a child of the bar, so these describe the bar's own
    // process, not your session; they are left out.
    readonly property var skipped: ["Shell", "Terminal", "Terminal Font"]

    // "Label: value" lines. The user@host line, the dashes under it, and the
    // color swatch rows (escape codes) are not entries.
    function parse(text) {
        const out = []
        const lines = String(text || "").split("\n")
        let title = ""
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].replace(/\s+$/, "")
            if (!line.length || line.indexOf("\x1b") >= 0 || /^-+$/.test(line))
                continue
            const colon = line.indexOf(": ")
            if (colon > 0) {
                if (root.skipped.indexOf(line.substring(0, colon)) >= 0)
                    continue
                out.push({ label: line.substring(0, colon), value: line.substring(colon + 2) })
            } else if (!title.length && out.length === 0) {
                title = line
            }
        }
        root.title = title
        root.entries = out
    }

    function copyText() {
        const rows = root.entries.map((e) => e.label + ": " + e.value)
        return (root.title.length ? [root.title].concat(rows) : rows).join("\n")
    }

    // A Process that cannot start never sends exited.
    function checkStarted() {
        if (proc.running || proc.finished)
            return
        root.loading = false
        root.loaded = true
        root.missing = true
        root.entries = []
        root.error = "fastfetch is not installed (pacman -S fastfetch)."
    }

    Process {
        id: proc
        property bool finished: false
        command: ["fastfetch", "--logo", "none", "--pipe", "true"]
        stdout: StdioCollector {
            id: out
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted)
        onExited: (code) => {
            proc.finished = true
            root.loading = false
            root.loaded = true
            root.missing = false
            root.parse(out.text)
            if (code !== 0 && !root.entries.length)
                root.error = "fastfetch stopped with exit code " + code + "."
        }
    }
}
