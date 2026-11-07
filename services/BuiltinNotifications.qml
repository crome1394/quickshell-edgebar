pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// The bar's own notification server, used when Settings → Notifications →
// Server is Built-in (Config.notificationServer). It owns the
// org.freedesktop.Notifications name, so SwayNC (or any other server) must
// not be running. NotificationToasts draws the live notifications;
// NotificationService keeps the history list and the bell.
//
// History is saved to ~/.local/state/quickshell/notification-history.json,
// oldest first, the same file the SwayNC-mode watcher used, so switching
// keeps it. With "Clear at boot" on, it is emptied once per boot.
Singleton {
    id: root

    readonly property bool enabled: Config.notificationServer === "builtin"
    // False for a moment to drop and claim the bus name again (after SwayNC stops).
    property bool claiming: true

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string stateDir: {
        const xdg = String(Quickshell.env("XDG_STATE_HOME") || "")
        return (xdg.length ? xdg : root.home + "/.local/state") + "/quickshell"
    }

    readonly property NotificationServer server: loader.item as NotificationServer
    // Live notifications, newest last.
    // qmllint disable missing-property
    readonly property var live: root.server ? root.server.trackedNotifications.values : []
    // qmllint enable missing-property

    // Set when history has loaded from disk (already boot-cleared).
    signal historyLoaded(var items)
    signal received(var item)

    function reclaim() {
        root.claiming = false
        Qt.callLater(() => root.claiming = true)
    }

    function textClip(value, limit) {
        const s = String(value || "")
        return s.length > limit ? s.substring(0, limit) : s
    }

    function receive(n) {
        const critical = n.urgency === NotificationUrgency.Critical
        const item = {
            id: "q" + Date.now() + "-" + n.id,
            ts: Math.floor(Date.now() / 1000),
            app: root.textClip(n.appName || "Notification", 120),
            summary: root.textClip(n.summary, 500),
            body: root.textClip(n.body, 4000),
            icon: root.textClip(n.appIcon, 500),
            image: root.textClip(n.image, 500),
            urgency: critical ? 2 : (n.urgency === NotificationUrgency.Low ? 0 : 1),
            expanded: false
        }
        // In Do Not Disturb only critical ones show; the rest go to history.
        if (!Config.notificationDnd || critical)
            n.tracked = true
        if (!n.transient)
            root.received(item)
    }

    function setDnd(on) {
        Config.saveFields(() => {
            Config.notificationDnd = !!on
        })
    }

    // The newest-first list from NotificationService, saved oldest first.
    function save(items) {
        const list = (items || []).slice(0, 80).map((x) => ({
            id: x.id, ts: x.ts, app: x.app, summary: x.summary, body: x.body,
            icon: x.icon, image: x.image, urgency: x.urgency, expanded: false
        }))
        list.reverse()
        historyFile.setText(JSON.stringify(list))
    }

    // The state folder may not exist on a fresh system. Fixed argv.
    Process {
        running: root.enabled
        command: ["mkdir", "-p", "--", root.stateDir]
    }

    LazyLoader {
        id: loader
        active: root.enabled && root.claiming

        NotificationServer {
            keepOnReload: true
            persistenceSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: false
            bodyImagesSupported: false
            actionsSupported: true
            imageSupported: true
            onNotification: (n) => root.receive(n)
        }
    }

    // ── History file and clear-at-boot ──────────────────────────────────
    property string bootNow: ""
    property bool bootRead: false
    property bool historyRead: false
    property var historyRaw: []

    function finishLoad() {
        if (!root.bootRead || !root.historyRead)
            return
        const previous = String(bootFile.text() || "").trim()
        const fresh = root.bootNow.length && previous.length && previous !== root.bootNow
        if (root.bootNow.length && previous !== root.bootNow)
            bootFile.setText(root.bootNow + "\n")
        if (fresh && Config.notificationClearOnBoot) {
            root.historyLoaded([])
            root.save([])
            return
        }
        root.historyLoaded(root.historyRaw.slice().reverse())
    }

    FileView {
        id: kernelBoot
        path: root.enabled ? "/proc/sys/kernel/random/boot_id" : ""
        printErrors: false
        onLoaded: {
            root.bootNow = String(kernelBoot.text() || "").trim()
            bootFile.reload()
        }
        onLoadFailed: {
            root.bootRead = true
            root.finishLoad()
        }
    }

    FileView {
        id: bootFile
        path: root.enabled ? root.stateDir + "/notification-boot-id" : ""
        atomicWrites: true
        printErrors: false
        preload: false
        onLoaded: {
            root.bootRead = true
            root.finishLoad()
        }
        onLoadFailed: {
            root.bootRead = true
            root.finishLoad()
        }
    }

    FileView {
        id: historyFile
        path: root.enabled ? root.stateDir + "/notification-history.json" : ""
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(historyFile.text())
                root.historyRaw = Array.isArray(data) ? data.slice(-80) : []
            } catch (e) {
                root.historyRaw = []
            }
            root.historyRead = true
            root.finishLoad()
        }
        onLoadFailed: {
            root.historyRaw = []
            root.historyRead = true
            root.finishLoad()
        }
    }
}
