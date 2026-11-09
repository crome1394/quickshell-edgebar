import QtQuick
import Quickshell.Io
import qs.theme

// "find <name>": file names under the home folder that contain the words.
// Runs fd shortly after typing stops, or find when fd is not installed,
// and stops at Theme.searchFindMax results.
Item {
    id: root

    property string term: ""
    property string home: ""
    // Absolute paths for `searched`.
    property var paths: []
    property string searched: ""
    property bool busy: proc.running
    // null until the first search finds out whether fd is there.
    property var hasFd: null

    onTermChanged: {
        proc.running = false
        if (root.term.trim().length)
            delay.restart()
        else
            delay.stop()
    }

    function start() {
        const t = root.term.trim()
        if (!t.length || !root.home.length)
            return
        proc.found = []
        proc.asked = t
        if (root.hasFd === false) {
            // Hidden folders are skipped, like fd does by default.
            proc.command = ["find", root.home, "-path", "*/.*", "-prune", "-o", "-iname", "*" + t + "*", "-print"]
        } else {
            proc.command = ["fd", "--absolute-path", "--max-results", String(Theme.searchFindMax), "--", t, root.home]
        }
        proc.running = true
    }

    Timer {
        id: delay
        interval: Theme.searchDelayMs * 2
        onTriggered: root.start()
    }

    Process {
        id: proc
        property var found: []
        property string asked: ""
        stdout: SplitParser {
            onRead: (line) => {
                if (proc.found.length >= Theme.searchFindMax) {
                    proc.running = false
                    return
                }
                const path = String(line || "").replace(/\/$/, "")
                if (path.charAt(0) === "/")
                    proc.found = proc.found.concat([path])
            }
        }
        onExited: (code) => {
            // fd missing: try again with find.
            if (root.hasFd === null && proc.command[0] === "fd" && (code === 127 || code < 0) && !proc.found.length) {
                root.hasFd = false
                root.start()
                return
            }
            if (proc.command[0] === "fd")
                root.hasFd = true
            root.searched = proc.asked
            root.paths = proc.found
        }
    }
}
