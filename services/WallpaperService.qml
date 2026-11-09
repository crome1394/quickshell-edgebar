pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.theme

// Wallpaper folder and apply, per monitor, through awww (awww-daemon must
// be running; Hyprland starts it). Processes start from the Wallpaper
// tab, the picker, or IPC; nothing runs otherwise.
//
// The picker (panels/WallpaperPicker.qml) previews an image with one
// awww call and saves only on Enter, through scripts/wallpaper.py, which
// keeps every monitor's entry in state/wallpapers.json.
//
// qs ipc call wallpaper toggle | open | close   the picker (Ctrl+Super+Space)
// qs ipc call wallpaper next | previous         the next image on the focused monitor
// qs ipc call wallpaper status                  "DP-1: /path (cover)" per monitor
Singleton {
    id: root

    // monitor → { path, fit }, from state/wallpapers.json.
    property var monitors: ({})
    property bool pickerOpen: false
    // The monitor the picker opened on.
    property string pickerMonitor: ""
    // -1 or +1 while next/previous waits for the folder list.
    property int pendingCycle: 0

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
        if (root.pendingCycle !== 0) {
            const dir = root.pendingCycle
            root.pendingCycle = 0
            root.cycle(dir)
        }
    }

    function monitorOk(name) {
        return DisplaySettings.outputOk(name)
    }

    function focusedName() {
        const mon = Hyprland.focusedMonitor
        return mon ? String(mon.name || "") : ""
    }

    function fitFor(name) {
        const row = root.monitors[String(name || "")]
        return row && WallpaperSettings.fits.indexOf(row.fit) >= 0 ? row.fit : "cover"
    }

    // A monitor's saved wallpaper, else the last one set.
    function pathFor(name) {
        const row = root.monitors[String(name || "")]
        return row && row.path ? String(row.path) : String(Config.wallpaperCurrent || "")
    }

    function loadStatus() {
        if (statusProc.running)
            return
        statusProc.command = ["python3", root.script(), "status"]
        statusProc.running = true
    }

    function takeStatus(text) {
        try {
            const parsed = JSON.parse(String(text || ""))
            if (parsed && parsed.ok === true && parsed.monitors && typeof parsed.monitors === "object")
                root.monitors = parsed.monitors
        } catch (e) {
        }
    }

    // Show an image on a monitor now, without saving it. One awww call,
    // fixed argv, with a quick fade.
    function preview(path, monitor) {
        const file = String(path || "")
        const name = String(monitor || "")
        if (file.charAt(0) !== "/" || /[\n\r]/.test(file) || !root.monitorOk(name))
            return
        Quickshell.execDetached(["awww", "img", "--outputs", name, "--resize", WallpaperSettings.resizeFor(root.fitFor(name)),
            "--transition-type", "fade", "--transition-duration", Theme.wallpaperPreviewFade, file])
    }

    // Set and save an image on one monitor (fit "" keeps its fit).
    function applyTo(path, monitor, fit) {
        const name = String(monitor || "")
        if (!root.monitorOk(name)) {
            root.apply(path)
            return
        }
        const args = ["apply", String(path || ""), name]
        if (WallpaperSettings.fits.indexOf(fit) >= 0)
            args.push(fit)
        root.status = "Applying…"
        root.run(args)
    }

    // A new fit for a monitor's current wallpaper.
    function setFit(monitor, fit) {
        const path = root.pathFor(monitor)
        if (path.length)
            root.applyTo(path, monitor, fit)
    }

    function openPicker() {
        root.pickerMonitor = root.focusedName()
        root.refresh()
        root.loadStatus()
        root.pickerOpen = true
    }

    function closePicker() {
        root.pickerOpen = false
    }

    function togglePicker() {
        if (root.pickerOpen)
            root.closePicker()
        else
            root.openPicker()
    }

    // The next (+1) or previous (-1) image in the folder on the focused
    // monitor, wrapping around.
    function cycle(dir) {
        const step = dir < 0 ? -1 : 1
        if (!root.images.length) {
            root.pendingCycle = step
            root.loadStatus()
            root.refresh()
            return
        }
        const name = root.focusedName()
        const now = root.pathFor(name)
        let at = -1
        for (let i = 0; i < root.images.length; i++) {
            if (String(root.images[i].path) === now)
                at = i
        }
        const next = at < 0 ? 0 : (at + step + root.images.length) % root.images.length
        root.applyTo(String(root.images[next].path), name, "")
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
        if (root.pendingAction === "apply" && parsed.path) {
            WallpaperSettings.setCurrent(String(parsed.path))
            root.loadStatus()
        }
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
        id: statusProc
        command: ["python3", "--version"]
        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
        }
        onExited: (code) => {
            if (code === 0)
                root.takeStatus(statusOut.text)
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.togglePicker() }
        function open(): void { root.openPicker() }
        function close(): void { root.closePicker() }
        function next(): void { root.cycle(1) }
        function previous(): void { root.cycle(-1) }
        // Reads the saved wallpapers again; a call right after start may
        // show the previous reading.
        function status(): string {
            root.loadStatus()
            const names = Object.keys(root.monitors)
            if (!names.length)
                return "no saved wallpaper yet (try again in a moment)"
            return names.map(n => n + ": " + root.monitors[n].path + " (" + root.monitors[n].fit + ")").join("\n")
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
