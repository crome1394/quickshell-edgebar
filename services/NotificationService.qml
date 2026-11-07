pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Notification history and Do Not Disturb.
// The bell and the history window load on demand. This singleton stays up
// so `qs ipc call notificationBell` works.
//
// Two servers (Settings → Notifications → Server):
//   SwayNC   SwayNC shows popups; a watcher script records history and
//            swaync-client reports DND, only while the bell is on a bar or
//            the history is open.
//   Built-in BuiltinNotifications is the server; no extra processes. History
//            and DND are kept by the bar.
Singleton {
    id: root

    readonly property bool resident: true
    property bool historyOpen: false
    // The monitor whose bell opened the history; "" means the main monitor.
    property string historyScreen: ""
    readonly property bool builtin: BuiltinNotifications.enabled
    // DND as SwayNC reports it; in built-in mode DND is a saved setting.
    property bool swayncDnd: false
    readonly property bool dnd: root.builtin ? Config.notificationDnd : root.swayncDnd
    property var items: []
    property int cursor: 0
    property bool allExpanded: false

    readonly property int count: root.items ? root.items.length : 0
    readonly property bool watching: !root.builtin && (Config.showNotificationPill || root.historyOpen)

    function historyScript() {
        return Quickshell.shellDir + "/scripts/notification-history.py"
    }

    function keepExpanded() {
        return !!Config.notificationAutoExpand
    }

    function cloneItem(it, expanded) {
        const row = it || {}
        return {
            id: String(row.id || ""),
            ts: Number(row.ts) || 0,
            app: String(row.app || "Notification"),
            summary: String(row.summary || ""),
            body: String(row.body || ""),
            icon: String(row.icon || ""),
            image: String(row.image || ""),
            urgency: Number(row.urgency) || 1,
            expanded: expanded === undefined ? !!row.expanded : !!expanded
        }
    }

    function syncExpandedFlag() {
        const list = root.items || []
        if (!list.length) {
            root.allExpanded = false
            return
        }
        for (let i = 0; i < list.length; i++) {
            if (!list[i].expanded) {
                root.allExpanded = false
                return
            }
        }
        root.allExpanded = true
    }

    function clampCursor() {
        const n = root.count
        if (n <= 0) {
            root.cursor = 0
            return
        }
        if (root.cursor < 0)
            root.cursor = 0
        if (root.cursor >= n)
            root.cursor = n - 1
    }

    function applyList(arr) {
        const out = []
        const list = arr || []
        const expand = root.keepExpanded()
        for (let i = 0; i < list.length; i++) {
            if (!list[i])
                continue
            out.push(root.cloneItem(list[i], expand ? true : !!list[i].expanded))
        }
        out.sort((a, b) => (b.ts || 0) - (a.ts || 0))
        while (out.length > 80)
            out.pop()
        root.items = out
        root.syncExpandedFlag()
        root.clampCursor()
    }

    function addItem(it) {
        const row = root.cloneItem(it, root.keepExpanded())
        if (!row.id.length)
            row.id = "n" + Date.now()
        const list = (root.items || []).slice()
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].id || "") === row.id)
                return
        }
        list.unshift(row)
        if (root.cursor >= 0)
            root.cursor = root.cursor + 1
        while (list.length > 80)
            list.pop()
        root.items = list
        root.syncExpandedFlag()
        root.clampCursor()
    }

    function removeLocal(id) {
        const want = String(id || "")
        if (!want.length)
            return
        const src = root.items || []
        const list = []
        for (let i = 0; i < src.length; i++) {
            if (String(src[i].id || "") !== want)
                list.push(src[i])
        }
        root.items = list
        root.syncExpandedFlag()
        root.clampCursor()
    }

    function takeHistoryLine(line) {
        const text = String(line || "").trim()
        if (!text.startsWith("{"))
            return
        let event
        try {
            event = JSON.parse(text)
        } catch (e) {
            return
        }
        if (!event)
            return
        if (event.type === "snapshot")
            root.applyList(event.items)
        else if (event.type === "add" && event.item)
            root.addItem(event.item)
        else if ((event.type === "remove" || event.type === "dismiss") && event.id)
            root.removeLocal(event.id)
    }

    function applySync(text) {
        const line = String(text || "").trim()
        if (!line.startsWith("{"))
            return
        let state
        try {
            state = JSON.parse(line)
        } catch (e) {
            return
        }
        if (!state || state.dnd === undefined || state.dnd === null)
            return
        if (typeof state.dnd === "boolean")
            root.swayncDnd = state.dnd
        else
            root.swayncDnd = String(state.dnd).toLowerCase() === "true"
    }

    function syncWatchers() {
        if (root.watching) {
            if (!historyProc.running)
                historyProc.running = true
            return
        }
        historyProc.running = false
    }

    function applyToast() {
        if (!Config.ready || toastProc.running || root.builtin)
            return
        toastProc.command = [
            "python3",
            Quickshell.shellDir + "/scripts/swaync-corner.py",
            NotificationSettings.cornerValue(),
            String(NotificationSettings.timeoutValue())
        ]
        toastProc.running = true
    }

    function showHistory(name) {
        root.historyScreen = String(name || "")
        if (root.keepExpanded())
            root.expandAll(true)
        root.cursor = 0
        root.historyOpen = true
    }

    function hideHistory() {
        root.historyOpen = false
    }

    function toggleHistory(name) {
        const where = String(name || "")
        if (root.historyOpen && root.historyScreen === where)
            root.hideHistory()
        else
            root.showHistory(where)
    }

    function toggleDnd() {
        if (root.builtin) {
            BuiltinNotifications.setDnd(!Config.notificationDnd)
            return
        }
        // The subscriber reports the new state.
        Quickshell.execDetached(["swaync-client", "-d", "-sw"])
    }

    function setExpanded(index, on) {
        const list = (root.items || []).slice()
        if (index < 0 || index >= list.length)
            return
        list[index] = root.cloneItem(list[index], !!on)
        root.items = list
        root.syncExpandedFlag()
    }

    function expandAll(on) {
        const list = (root.items || []).slice()
        for (let i = 0; i < list.length; i++)
            list[i] = root.cloneItem(list[i], !!on)
        root.items = list
        root.allExpanded = !!on && list.length > 0
    }

    function dismiss(id) {
        const want = String(id || "")
        if (!/^[A-Za-z0-9._-]{1,80}$/.test(want))
            return
        if (root.builtin) {
            root.removeLocal(want)
            BuiltinNotifications.save(root.items)
            return
        }
        Quickshell.execDetached(["python3", root.historyScript(), "dismiss", want])
        root.removeLocal(want)
    }

    function clearHistory() {
        if (root.builtin) {
            const live = BuiltinNotifications.live.slice()
            for (let i = 0; i < live.length; i++)
                live[i].dismiss()
            BuiltinNotifications.save([])
        } else {
            Quickshell.execDetached(["python3", root.historyScript(), "clear"])
            Quickshell.execDetached(["swaync-client", "-C", "-sw"])
        }
        root.items = []
        root.cursor = 0
        root.allExpanded = false
    }

    function itemAt(index) {
        const list = root.items || []
        if (index < 0 || index >= list.length)
            return null
        return list[index]
    }

    function moveCursor(delta) {
        if (root.count <= 0)
            return
        let next = root.cursor + delta
        if (next < 0)
            next = 0
        if (next >= root.count)
            next = root.count - 1
        root.cursor = next
    }

    function localImagePath(raw) {
        let path = String(raw || "").trim()
        if (path.indexOf("file://") === 0)
            path = path.substring(7)
        if (path.charAt(0) !== "/" || path.indexOf("\u0000") >= 0)
            return ""
        if (!/\.(png|jpe?g|webp|gif|bmp)$/i.test(path))
            return ""
        return path
    }

    function imagePathFor(item) {
        if (!item)
            return ""
        const direct = root.localImagePath(item.image)
        if (direct.length)
            return direct
        const icon = root.localImagePath(item.icon)
        if (icon.length)
            return icon
        const body = String(item.body || "")
        const match = body.match(/(\/[^\s'"<>]+?\.(?:png|jpe?g|webp|gif|bmp))/i)
        if (match && match[1])
            return root.localImagePath(match[1])
        return ""
    }

    function copyItem(item) {
        if (!item)
            return
        const image = root.imagePathFor(item)
        if (image.length) {
            Quickshell.execDetached([
                "python3",
                Quickshell.shellDir + "/scripts/notification-copy.py",
                image
            ])
            return
        }
        const parts = []
        if (item.app)
            parts.push(String(item.app))
        if (item.summary)
            parts.push(String(item.summary))
        if (item.body)
            parts.push(String(item.body))
        const text = parts.join("\n")
        if (!text.length)
            return
        Quickshell.clipboardText = text
    }

    function formatTime(ts) {
        const n = Number(ts) || 0
        if (!(n > 0))
            return ""
        const when = new Date(n * 1000)
        const hh = String(when.getHours()).padStart(2, "0")
        const mm = String(when.getMinutes()).padStart(2, "0")
        return hh + ":" + mm
    }

    function bodyHtml(raw) {
        const text = String(raw || "")
        if (text.indexOf("<") < 0)
            return text
        return text.split("\n").join("<br>")
    }

    onWatchingChanged: root.syncWatchers()

    Component.onCompleted: {
        Qt.callLater(() => {
            if (Config.ready)
                root.applyToast()
            root.syncWatchers()
        })
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.applyToast()
        }
    }

    Connections {
        target: BuiltinNotifications
        function onHistoryLoaded(items) {
            root.applyList(items)
        }
        function onReceived(item) {
            root.addItem(item)
            BuiltinNotifications.save(root.items)
        }
    }

    Connections {
        target: NotificationSettings
        function onApplySerialChanged() {
            if (NotificationSettings.applySerial > 0)
                root.applyToast()
        }
    }

    Process {
        id: historyProc
        command: ["python3", Quickshell.shellDir + "/scripts/notification-history.py", "watch"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => root.takeHistoryLine(line)
        }
        onExited: {
            if (root.watching)
                historyRestart.restart()
        }
    }

    Timer {
        id: historyRestart
        interval: Theme.notificationSyncMs
        onTriggered: {
            if (root.watching && !historyProc.running)
                historyProc.running = true
        }
    }

    // swaync pushes one JSON line per change (count, dnd, ...), so nothing
    // polls. If swaync restarts, the subscriber exits and is started again.
    Process {
        id: stateProc
        running: root.watching
        command: ["swaync-client", "--subscribe"]
        stdout: SplitParser {
            onRead: (line) => root.applySync(line)
        }
        onExited: {
            if (root.watching)
                stateRestart.restart()
        }
    }

    Timer {
        id: stateRestart
        interval: Theme.notificationSyncMs
        onTriggered: {
            // Re-binding (not assigning true) restarts it and keeps it tied to watching.
            if (root.watching && !stateProc.running)
                stateProc.running = Qt.binding(() => root.watching)
        }
    }

    Process {
        id: toastProc
        command: ["python3", Quickshell.shellDir + "/scripts/swaync-corner.py", "bottomRight", "8"]
    }

    IpcHandler {
        target: "notificationBell"
        function toggleHistory(): void { root.toggleHistory() }
        function showHistory(): void { root.showHistory() }
        function hideHistory(): void { root.hideHistory() }
        function toggleDoNotDisturb(): void { root.toggleDnd() }
    }
}
