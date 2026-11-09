pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Tools → Capture. Reads and writes ~/.config/hypr/capture.conf (atomic),
// lists installed OCR languages, reads the capture keybinds, and starts
// the capture scripts for the Try buttons. Nothing runs or is read unless
// the page is open (retain/release). Every command is a fixed argv.
Singleton {
    id: root

    property int watchers: 0
    readonly property bool active: root.watchers > 0

    property string error: ""
    property string notice: ""
    property bool confExists: false

    property var langs: []          // installed tesseract languages, osd left out
    property bool langsLoaded: false
    property bool tesseractMissing: false

    property var binds: []
    property string bindsFile: ""
    property int bindsTry: 0
    readonly property var bindFiles: [
        CaptureSettings.configHome + "/hypr/config/keybindings.lua",
        CaptureSettings.configHome + "/hypr/hyprland.lua"
    ]

    property bool screenshotScriptOk: false
    property bool ocrScriptOk: false

    // A picked path for the page's draft. Bumped on each pick.
    property string pickedPath: ""
    property string pickedKey: ""
    property int pickSerial: 0

    function retain() {
        root.watchers += 1
        if (root.watchers === 1) {
            root.error = ""
            root.notice = ""
            root.bindsTry = 0
            if (!langProc.running) {
                langProc.finished = false
                langProc.running = true
            }
            if (!editorProc.running)
                editorProc.running = true
        }
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function save(values) {
        const text = CaptureSettings.confText(values)
        if (!text.length) {
            root.error = "A value on this page cannot be saved. Check the red fields."
            return
        }
        root.error = ""
        conf.saveOk = true
        conf.setText(text)
        if (!conf.saveOk) {
            root.error = "Could not write " + CaptureSettings.confPath
            return
        }
        root.confExists = true
        CaptureSettings.saved = CaptureSettings.normalize(values)
        root.notice = "Saved. The next capture uses these settings."
    }

    // Runs a capture now, with the saved settings.
    function tryScreenshot(mode) {
        if (["smart", "region", "windows", "fullscreen"].indexOf(mode) < 0)
            return
        if (!root.screenshotScriptOk) {
            root.error = CaptureSettings.screenshotScript + " is missing."
            return
        }
        root.error = ""
        Quickshell.execDetached([CaptureSettings.screenshotScript, mode, "both"])
    }

    function editLatest() {
        if (root.screenshotScriptOk)
            Quickshell.execDetached([CaptureSettings.screenshotScript, "edit-latest"])
    }

    function tryOcr() {
        if (!root.ocrScriptOk) {
            root.error = CaptureSettings.ocrScript + " is missing."
            return
        }
        root.error = ""
        Quickshell.execDetached([CaptureSettings.ocrScript])
    }

    function openFolder(path) {
        const dir = CaptureSettings.expand(path)
        Quickshell.execDetached(["xdg-open", dir.length ? dir : CaptureSettings.defaultFolder])
    }

    // kind: "folder" or "program". key: the draft field the path goes to.
    function pick(kind, key, start) {
        if (pickProc.running)
            return
        const from = CaptureSettings.expand(start)
        const args = ["zenity", "--file-selection", "--title=" + (kind === "folder" ? "Screenshot folder" : "Choose a program")]
        if (kind === "folder")
            args.push("--directory")
        if (from.length && from.charAt(0) === "/")
            args.push("--filename=" + from + (kind === "folder" ? "/" : ""))
        root.error = ""
        pickProc.key = key
        pickProc.finished = false
        pickProc.command = args
        pickProc.running = true
    }

    // A Process that cannot start never sends exited.
    function checkStarted(proc) {
        if (proc.running || proc.finished)
            return
        if (proc === langProc) {
            root.tesseractMissing = true
            root.langsLoaded = true
            root.langs = []
        } else if (proc === pickProc) {
            root.error = "The file picker needs zenity."
        }
    }

    Connections {
        target: CaptureSettings
        function onSaveRequested(values) {
            root.save(values)
        }
    }

    FileView {
        id: conf
        property bool saveOk: true
        path: root.active ? CaptureSettings.confPath : ""
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.confExists = true
            CaptureSettings.saved = CaptureSettings.parse(conf.text())
            CaptureSettings.loaded = true
        }
        onLoadFailed: {
            // No file yet: the scripts use their defaults, and so does the page.
            root.confExists = false
            CaptureSettings.saved = CaptureSettings.defaults()
            CaptureSettings.loaded = true
        }
        onSaveFailed: conf.saveOk = false
    }

    FileView {
        id: bindsView
        path: root.active && root.bindsTry < root.bindFiles.length ? root.bindFiles[root.bindsTry] : ""
        printErrors: false
        onLoaded: {
            const found = CaptureSettings.parseBinds(bindsView.text())
            if (!found.length && root.bindsTry + 1 < root.bindFiles.length) {
                root.bindsTry += 1
                return
            }
            root.binds = found
            root.bindsFile = found.length ? bindsView.path : ""
        }
        onLoadFailed: {
            if (root.bindsTry + 1 < root.bindFiles.length)
                root.bindsTry += 1
            else
                root.binds = []
        }
    }

    // Only to learn whether the scripts are there; the text is not used.
    FileView {
        id: shotScript
        path: root.active ? CaptureSettings.screenshotScript : ""
        printErrors: false
        onLoaded: root.screenshotScriptOk = true
        onLoadFailed: root.screenshotScriptOk = false
    }

    FileView {
        id: ocrScriptView
        path: root.active ? CaptureSettings.ocrScript : ""
        printErrors: false
        onLoaded: root.ocrScriptOk = true
        onLoadFailed: root.ocrScriptOk = false
    }

    Process {
        id: langProc
        property bool finished: false
        command: ["tesseract", "--list-langs"]
        stdout: StdioCollector {
            id: langOut
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted, langProc)
        onExited: {
            langProc.finished = true
            const out = []
            const lines = String(langOut.text || "").split("\n")
            for (let i = 1; i < lines.length; i++) {
                const code = lines[i].trim()
                if (code !== "osd" && CaptureSettings.langOk(code))
                    out.push(code)
            }
            root.tesseractMissing = false
            root.langs = out
            root.langsLoaded = true
        }
    }

    // `which` prints the path of each editor it finds, in argument order.
    Process {
        id: editorProc
        // Tack also counts where cargo installs it, off some PATHs.
        command: ["which"].concat(CaptureSettings.editorChoices).concat([String(Quickshell.env("HOME") || "") + "/.local/bin/tack"])
        stdout: StdioCollector {
            id: editorOut
            waitForEnd: true
        }
        onExited: {
            const found = []
            const lines = String(editorOut.text || "").split("\n")
            for (let i = 0; i < lines.length; i++) {
                const name = lines[i].trim().replace(/^.*\//, "")
                if (CaptureSettings.editorChoices.indexOf(name) >= 0 && found.indexOf(name) < 0)
                    found.push(name)
            }
            CaptureSettings.editors = found
        }
    }

    // XDG_PICTURES_DIR="$HOME/Pictures" from user-dirs.dirs, shown with ~.
    FileView {
        id: picturesView
        path: root.active ? CaptureSettings.configHome + "/user-dirs.dirs" : ""
        printErrors: false
        onLoaded: {
            const m = /^XDG_PICTURES_DIR="([^"\n]+)"/m.exec(picturesView.text())
            const dir = m ? m[1].replace(/^\$HOME/, "~") : ""
            CaptureSettings.picturesDir = CaptureSettings.folderOk(dir) && dir.length ? dir : "~/Pictures"
        }
        onLoadFailed: CaptureSettings.picturesDir = "~/Pictures"
    }

    Process {
        id: pickProc
        property bool finished: false
        property string key: ""
        stdout: StdioCollector {
            id: pickOut
            waitForEnd: true
        }
        onRunningChanged: Qt.callLater(root.checkStarted, pickProc)
        onExited: {
            pickProc.finished = true
            const path = CaptureSettings.clean(String(pickOut.text || "").split("\n")[0]).trim()
            if (!path.length)
                return
            root.pickedKey = pickProc.key
            root.pickedPath = path
            root.pickSerial += 1
        }
    }
}
