pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings → Tools → Screensaver. Talks to scripts/screensaver-config.sh,
// which owns ~/.config/hypr/screensaver.conf and the hypridle listener:
//   get          current settings as JSON
//   set ...      save, patch hypridle.conf, restart hypridle, print JSON
//   start        run the screensaver now
//   pick-script  zenity file picker (prints a path, or nothing)
//   pick-video   same, for the video
// Nothing runs unless the page is open (retain/release). Every command is
// a fixed argv, never a shell.
Singleton {
    id: root

    property int watchers: 0
    property bool loading: false
    property bool saving: false
    property bool helperMissing: false
    property string error: ""
    property string notice: ""

    // Checks from the last `get` or `set`.
    property bool programOk: false
    property bool videoOk: false
    property bool ddcutilOk: false

    readonly property bool busy: root.loading || root.saving

    // A picked path, for the page to put in its draft. Bumped on each pick.
    property string pickedPath: ""
    property string pickedKind: ""
    property int pickSerial: 0

    function retain() {
        root.watchers += 1
        if (root.watchers === 1)
            root.refresh()
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function refresh() {
        if (getProc.running || setProc.running)
            return
        root.loading = true
        root.error = ""
        getProc.finished = false
        getProc.command = [ScreensaverSettings.helperPath, "get"]
        getProc.running = true
    }

    function save(values) {
        if (setProc.running)
            return
        root.saving = true
        root.error = ""
        root.notice = "Saving…"
        setProc.finished = false
        setProc.command = [ScreensaverSettings.helperPath, "set"].concat(ScreensaverSettings.setArgs(values))
        setProc.running = true
    }

    // Detached: the saver outlives this call, and mpv must not hold our pipes.
    // Uses the last `get`, so problems show before anything starts.
    function startNow() {
        const saved = ScreensaverSettings.saved
        root.error = ""
        if (root.helperMissing) {
            root.error = "Could not run " + ScreensaverSettings.helperPath + "."
            return
        }
        if (!root.programOk) {
            root.error = "The saved program is not an executable file. Fix it and Apply first."
            return
        }
        if (ScreensaverSettings.isBuiltIn(saved.program) && saved.mode === "video" && !root.videoOk) {
            root.error = "The saved video file is missing."
            return
        }
        root.notice = "Started. Move the mouse or press a key to dismiss."
        Quickshell.execDetached([ScreensaverSettings.helperPath, "start"])
    }

    function pick(kind) {
        if (pickProc.running || (kind !== "script" && kind !== "video"))
            return
        root.error = ""
        pickProc.kind = kind
        pickProc.finished = false
        pickProc.command = [ScreensaverSettings.helperPath, kind === "script" ? "pick-script" : "pick-video"]
        pickProc.running = true
    }

    // Returns false when the text is not the helper's JSON.
    function ingest(text) {
        let j = null
        try {
            j = JSON.parse(String(text || "").trim())
        } catch (e) {
            return false
        }
        if (!j || j.ok !== true)
            return false
        root.programOk = !!j.script_ok
        root.videoOk = !!j.video_ok
        root.ddcutilOk = !!j.ddcutil_ok
        ScreensaverSettings.saved = ScreensaverSettings.fromHelper(j)
        ScreensaverSettings.loaded = true
        return true
    }

    function firstLine(text) {
        return String(text || "").trim().split("\n")[0].substring(0, 200)
    }

    // A Process that cannot start never sends exited. Each one sets
    // finished in onExited; if running drops without it, the helper is gone.
    function checkStarted(proc) {
        if (proc.running || proc.finished)
            return
        root.helperMissing = true
        root.loading = false
        root.saving = false
        root.notice = ""
        root.error = "Could not run " + ScreensaverSettings.helperPath + ". Is it there and executable?"
    }

    Connections {
        target: ScreensaverSettings
        function onSaveRequested(values) {
            root.save(values)
        }
    }

    Process {
        id: getProc
        property bool finished: false
        stdout: StdioCollector {
            id: getOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: getErr
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted, getProc)
        onExited: (code) => {
            getProc.finished = true
            root.loading = false
            root.helperMissing = false
            if (code !== 0 || !root.ingest(getOut.text))
                root.error = "Could not read the screensaver settings: " + (root.firstLine(getErr.text) || "exit " + code)
        }
    }

    Process {
        id: setProc
        property bool finished: false
        stdout: StdioCollector {
            id: setOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: setErr
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted, setProc)
        onExited: (code) => {
            setProc.finished = true
            root.saving = false
            root.helperMissing = false
            if (code === 0 && root.ingest(setOut.text)) {
                root.notice = ScreensaverSettings.saved.enabled
                    ? "Saved. The idle timer restarted with the new settings."
                    : "Saved. The idle timer is off."
            } else {
                root.notice = ""
                root.error = "Could not save: " + (root.firstLine(setErr.text) || "exit " + code)
                root.refresh()
            }
        }
    }

    Process {
        id: pickProc
        property bool finished: false
        property string kind: ""
        stdout: StdioCollector {
            id: pickOut
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted, pickProc)
        onExited: (code) => {
            pickProc.finished = true
            const path = ScreensaverSettings.pathArg(root.firstLine(pickOut.text))
            if (path.length) {
                root.pickedKind = pickProc.kind
                root.pickedPath = path
                root.pickSerial += 1
            } else if (code !== 0 && pickProc.kind.length) {
                root.error = "The file picker needs zenity."
            }
        }
    }
}
