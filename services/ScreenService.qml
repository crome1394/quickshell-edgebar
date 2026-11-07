pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.theme

// Which monitors get bars, and which one is the main monitor.
//
// Bars on (Widgets → Bars → Monitors): "main" (the default), "all", or
// "pick" (the monitors named in Config.barScreenNames). The main monitor
// is Config.mainScreen, or the first one Quickshell lists. Single-screen
// things (the Active Window popup, menus opened over IPC) go to the main
// monitor, or to the first monitor with bars when main has none.
Singleton {
    id: root

    readonly property var screens: Quickshell.screens
    readonly property var names: root.screens.map((s) => String(s.name))

    readonly property string mode: {
        const m = String(Config.barScreenMode || "")
        return m === "all" || m === "pick" ? m : "main"
    }

    readonly property var picked: {
        try {
            const list = JSON.parse(String(Config.barScreenNames || "[]"))
            return Array.isArray(list) ? list.map(String) : []
        } catch (e) {
            return []
        }
    }

    readonly property var mainScreen: {
        const want = String(Config.mainScreen || "")
        for (let i = 0; i < root.screens.length; i++) {
            if (String(root.screens[i].name) === want)
                return root.screens[i]
        }
        return root.screens.length ? root.screens[0] : null
    }

    readonly property string mainName: root.mainScreen ? String(root.mainScreen.name) : ""

    // The screen with focus, where a new window opens.
    function focusedScreen() {
        const mon = Hyprland.focusedMonitor
        const name = mon ? String(mon.name) : ""
        for (let i = 0; i < root.screens.length; i++) {
            if (String(root.screens[i].name) === name)
                return root.screens[i]
        }
        return root.mainScreen
    }

    // A window size no larger than the focused screen less a margin, so
    // Settings and the readers fit a laptop panel. Read when a window
    // opens, not bound, so an open window never resizes on its own.
    function fitSize(w, h) {
        const s = root.focusedScreen()
        if (!s || s.width <= 0 || s.height <= 0)
            return Qt.size(w, h)
        const m = Theme.windowScreenMargin * 2
        return Qt.size(Math.max(1, Math.min(w, s.width - m)), Math.max(1, Math.min(h, s.height - m)))
    }

    // Opens `win` at its preferred size, shrunk to fit the screen; the
    // minimum shrinks with it.
    function fitWindow(win, w, h, minW, minH) {
        const size = root.fitSize(w, h)
        win.implicitWidth = size.width
        win.implicitHeight = size.height
        win.minimumSize = Qt.size(Math.min(minW, size.width), Math.min(minH, size.height))
    }

    // The screens that get a set of edge bars.
    readonly property var barScreens: {
        if (root.mode === "all")
            return root.screens
        if (root.mode === "pick") {
            const list = root.screens.filter((s) => root.picked.indexOf(String(s.name)) >= 0)
            if (list.length)
                return list
        }
        return root.mainScreen ? [root.mainScreen] : []
    }

    // Where a menu opened without a click (IPC) shows.
    readonly property string defaultName: {
        const bars = root.barScreens.map((s) => String(s.name))
        return bars.indexOf(root.mainName) >= 0 ? root.mainName : (bars.length ? bars[0] : root.mainName)
    }

    // True when a menu opened on `opened` ("" = no click) belongs to the
    // bar on screen `name`.
    function owns(opened, name) {
        return (opened.length ? opened : root.defaultName) === name
    }

    function setMode(next) {
        if (next !== "main" && next !== "all" && next !== "pick")
            return
        Config.saveFields(() => {
            Config.barScreenMode = next
        })
    }

    function togglePicked(name) {
        const list = root.picked.slice()
        const at = list.indexOf(name)
        if (at >= 0)
            list.splice(at, 1)
        else if (root.names.indexOf(name) >= 0)
            list.push(name)
        Config.saveFields(() => {
            Config.barScreenNames = JSON.stringify(list)
        })
    }

    function setMain(name) {
        if (name !== "" && root.names.indexOf(name) < 0)
            return
        Config.saveFields(() => {
            Config.mainScreen = name
        })
    }
}
