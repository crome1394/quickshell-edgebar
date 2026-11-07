pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The installed font families, for every font picker in Settings. The
// list is read once with fc-list (scalable fonts only) the first time a
// page asks, then kept; without fc-list it falls back to Qt's list.
//   FontService.load()      start reading (safe to call often)
//   FontService.ready       true once `families` is filled
Singleton {
    id: root

    property var families: []
    property bool ready: false

    function load() {
        if (!root.ready && !lister.running)
            lister.running = true
    }

    function parse(text) {
        const lines = String(text || "").split("\n")
        const seen = {}
        const out = []
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const bar = line.lastIndexOf("|")
            if (bar <= 0 || line.substring(bar + 1).trim() !== "True")
                continue
            const names = line.substring(0, bar).split(",")
            for (let j = 0; j < names.length; j++) {
                const name = names[j].trim()
                if (name.length && !seen[name]) {
                    seen[name] = true
                    out.push(name)
                }
            }
        }
        out.sort((a, b) => a.localeCompare(b))
        return out
    }

    function fallback() {
        return Qt.fontFamilies().filter((n) => String(n || "").length && !/\.(pcf|bdf|psf|otb|fon)$/i.test(n))
    }

    Process {
        id: lister
        command: ["fc-list", "-f", "%{family}|%{scalable}\n"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: (code) => {
            const found = code === 0 ? root.parse(listOut.text) : []
            root.families = found.length ? found : root.fallback()
            root.ready = true
        }
    }
}
