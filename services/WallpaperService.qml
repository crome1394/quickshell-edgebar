pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper folder and hyprpaper apply. Processes start from the Wallpaper tab.
Singleton {
    id: root

    property var images: []
    property bool loading: false
    property bool busy: false
    property string status: ""
    property string error: ""
    property string pendingAction: ""

    function script() {
        return Quickshell.shellDir + "/scripts/wallpaper.py"
    }

    function refresh() {
        if (listProc.running)
            return
        root.loading = true
        root.error = ""
        listProc.command = ["python3", root.script(), "list", WallpaperSettings.dirValue()]
        listProc.running = true
    }

    function takeList(text) {
        root.loading = false
        let parsed = null
        try {
            parsed = JSON.parse(String(text || ""))
        } catch (e) {
            parsed = null
        }
        if (!parsed || parsed.ok !== true) {
            root.images = []
            root.error = parsed && parsed.error ? String(parsed.error) : "Could not read the wallpaper folder"
            return
        }
        root.images = parsed.images || []
        root.status = String(parsed.count || 0) + " images"
        root.error = ""
    }

    function run(args) {
        if (actionProc.running)
            return
        root.busy = true
        root.error = ""
        root.pendingAction = String(args[0] || "")
        const command = ["python3", root.script()].concat(args)
        actionProc.command = command
        actionProc.running = true
    }

    function apply(path) {
        root.status = "Applying…"
        root.run(["apply", String(path || "")])
    }

    function add(paths) {
        const files = []
        const list = paths || []
        for (let i = 0; i < list.length && files.length < 40; i++) {
            const path = root.urlToPath(list[i])
            if (path.length)
                files.push(path)
        }
        if (!files.length) {
            root.error = "No images to add"
            return
        }
        root.status = "Adding…"
        root.run(["add", WallpaperSettings.dirValue()].concat(files))
    }

    function rename(name, next) {
        root.status = "Renaming…"
        root.run(["rename", WallpaperSettings.dirValue(), String(name || ""), String(next || "")])
    }

    function remove(name) {
        root.status = "Deleting…"
        root.run(["delete", WallpaperSettings.dirValue(), String(name || "")])
    }

    function finish(text, code) {
        root.busy = false
        let parsed = null
        try {
            parsed = JSON.parse(String(text || ""))
        } catch (e) {
            parsed = null
        }
        if (code !== 0 || !parsed || parsed.ok !== true) {
            root.error = parsed && parsed.error ? String(parsed.error) : "Wallpaper command failed"
            root.status = ""
            return
        }
        root.error = ""
        if (root.pendingAction === "apply" && parsed.path)
            WallpaperSettings.setCurrent(String(parsed.path))
        if (parsed.monitor)
            root.status = "Applied on " + parsed.monitor
        else if (parsed.deleted)
            root.status = "Deleted"
        else if (parsed.name)
            root.status = parsed.name
        else if (parsed.count !== undefined)
            root.status = "Added " + parsed.count
        root.refresh()
    }

    function urlToPath(url) {
        let text = String(url || "")
        if (text.startsWith("file://"))
            text = text.slice(7)
        if (text.startsWith("localhost/"))
            text = "/" + text.slice("localhost/".length)
        try {
            text = decodeURIComponent(text)
        } catch (e) {
        }
        return text
    }

    Process {
        id: listProc
        command: ["python3", "--version"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: (code) => {
            if (code === 0)
                root.takeList(listOut.text)
            else {
                root.loading = false
                root.images = []
                root.error = "Could not read the wallpaper folder"
            }
        }
    }

    Process {
        id: actionProc
        command: ["python3", "--version"]
        stdout: StdioCollector {
            id: actionOut
            waitForEnd: true
        }
        onExited: (code) => root.finish(actionOut.text, code)
    }
}
