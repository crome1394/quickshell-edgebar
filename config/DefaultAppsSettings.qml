pragma Singleton
import QtQuick
import Quickshell
import qs.defaultapps

// Applications → Default Apps: which app opens each kind of file and link.
// The saved store is ~/.config/mimeapps.list, not bar-layout.json:
// DefaultAppsService reads it into `saved` and writes it when the Draft
// commits (writeRequested). Problems you choose to keep save in Config.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    // What mimeapps.list holds now, normalized. Set by DefaultAppsService.
    property var saved: DefaultAppsLogic.emptyState()

    signal writeRequested(var state)

    function normalize(src) {
        return DefaultAppsLogic.normalize(src)
    }

    function snapshot() {
        return root.saved
    }

    // Your lines for the common tasks go, so the system decides them.
    // Scheme handlers and other types you set stay.
    function defaults() {
        return DefaultAppsLogic.resetGroups(root.saved)
    }

    // The service writes only the lines that differ from `saved`, then
    // reads the file back. `saved` moves first so the page does not
    // flash the old values while the file is written.
    function commit(snap) {
        const clean = root.normalize(snap)
        root.writeRequested(clean)
        root.saved = clean
    }

    // Problem keys you chose to keep. They save at once.
    function kept() {
        try {
            const list = JSON.parse(Config.defaultAppsKeptJson || "[]")
            return Array.isArray(list) ? list.filter((k) => typeof k === "string" && k.length <= 400) : []
        } catch (e) {
            return []
        }
    }

    // keys: one problem key or a list of them.
    function keep(keys) {
        const list = root.kept()
        const more = Array.isArray(keys) ? keys : [keys]
        let added = false
        for (const key of more) {
            const k = String(key || "")
            if (k.length && k.length <= 400 && list.indexOf(k) < 0) {
                list.push(k)
                added = true
            }
        }
        if (!added)
            return
        Config.saveFields(() => {
            Config.defaultAppsKeptJson = JSON.stringify(list)
        })
    }

    function clearKept() {
        if (!(Config.defaultAppsKeptJson || "").length)
            return
        Config.saveFields(() => {
            Config.defaultAppsKeptJson = ""
        })
    }
}
