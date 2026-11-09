pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.search
import qs.theme

// The launcher (Pop Launcher style): whether it is open, launching what it
// finds, and launch history so frequent picks rank higher. shell.qml
// creates SearchPanel only while open. With the built-in launcher off
// (Settings → Applications → Launcher), toggling runs your command.
// The App Library launches apps through here too, so both share history.
Singleton {
    id: root

    property bool open: false
    // Text the box opens with (qs ipc call launcher search <text>).
    property string startQuery: ""
    readonly property string home: String(Quickshell.env("HOME") || "")

    // { key: { n, t } } where key is "app:<desktop id>".
    property var history: ({})
    property bool historyLoaded: false
    readonly property string historyPath: Quickshell.shellDir + "/state/search-history.json"

    function toggle() {
        if (root.open)
            root.hide()
        else
            root.show("")
    }

    function show(query) {
        if (!SearchSettings.builtIn()) {
            root.runCustom()
            return
        }
        LibraryService.hide()
        root.loadHistory()
        root.startQuery = String(query || "").substring(0, Theme.searchQueryMax)
        root.open = true
    }

    function hide() {
        root.open = false
    }

    function runCustom() {
        const argv = SearchSettings.commandArgv()
        if (argv.length)
            Quickshell.execDetached(argv)
    }

    // An app from DesktopEntries. Apps marked Terminal=true open in the
    // launcher's terminal.
    function launchApp(entry) {
        if (!entry)
            return
        root.record("app:" + String(entry.id))
        const command = entry.command
        if (entry.runInTerminal && command && command.length)
            Quickshell.execDetached(SearchSettings.terminalArgv().concat(command))
        else
            entry.execute()
    }

    // One of an app's desktop actions (New Window, and so on).
    function launchAction(entry, action) {
        if (!entry || !action)
            return
        root.record("app:" + String(entry.id))
        action.execute()
    }

    function focusWindow(address) {
        const addr = String(address || "")
        if (!addr.length)
            return
        try {
            Hyprland.dispatch("hl.dsp.focus({ window = " + OverviewService.quote(OverviewService.addressOf(addr)) + " })")
        } catch (e) {
        }
    }

    // A file or folder, in its default app.
    function openPath(path) {
        const p = String(path || "")
        if (p.charAt(0) === "/")
            Quickshell.execDetached(["xdg-open", p])
    }

    function openUrl(url) {
        const u = String(url || "")
        if (/^https?:\/\//i.test(u))
            Qt.openUrlExternally(u)
    }

    // A command typed after t:, :, or run. This is text you typed to run,
    // so it goes to sh as one argument; nothing else is added to it.
    function runCommand(command, inTerminal) {
        const text = String(command || "").trim()
        if (!text.length || text.length > Theme.searchQueryMax)
            return
        if (!inTerminal) {
            Quickshell.execDetached(["sh", "-c", text])
            return
        }
        // Keep the terminal open after the command, so its output can be read.
        const hold = text + "\nprintf '\\n[exited %s] Press Enter to close' \"$?\"; read -r _"
        Quickshell.execDetached(SearchSettings.terminalArgv().concat(["sh", "-c", hold]))
    }

    // A Pop Launcher script. sh runs it, as Pop Launcher does.
    function runScript(path) {
        const p = String(path || "")
        if (p.charAt(0) === "/")
            Quickshell.execDetached(["sh", p])
    }

    function copyText(text) {
        Quickshell.clipboardText = String(text || "")
    }

    function loadHistory() {
        if (root.historyLoaded)
            return
        root.historyLoaded = true
        historyFile.path = root.historyPath
    }

    function record(key) {
        if (Config.searchHistory === false)
            return
        root.loadHistory()
        const next = SearchLogic.historyAdd(root.history, key, Date.now())
        root.history = SearchLogic.historyTrim(next, Theme.searchHistoryMax)
        saveTimer.restart()
    }

    function clearHistory() {
        root.loadHistory()
        root.history = ({})
        saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: Theme.searchSaveMs
        onTriggered: historyFile.setText(JSON.stringify(root.history))
    }

    FileView {
        id: historyFile
        atomicWrites: true
        printErrors: false
        onLoaded: {
            let parsed = null
            try {
                parsed = JSON.parse(historyFile.text())
            } catch (e) {
                parsed = null
            }
            // Launches made before the file finished loading are kept.
            const loaded = SearchLogic.historyNorm(parsed)
            const early = root.history
            const keys = Object.keys(early)
            for (let i = 0; i < keys.length; i++) {
                const k = keys[i]
                const old = loaded[k] || { n: 0, t: 0 }
                loaded[k] = { n: old.n + early[k].n, t: Math.max(old.t, early[k].t) }
            }
            root.history = loaded
        }
    }

    // qs ipc call launcher toggle | open | close   (same as the keybind)
    // qs ipc call launcher search <text>           (opens with text typed, e.g. "= 2+2")
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(): void { root.show("") }
        function close(): void { root.hide() }
        function search(text: string): void {
            const t = String(text || "")
            if (t.length <= Theme.searchQueryMax && !/[\r\n\0]/.test(t))
                root.show(t)
        }
    }
}
