import QtQuick
import qs.config
import qs.search
import qs.services

// What the App Library shows: Library Home or one folder, or, while
// something is typed, every app that matches. Folder changes save at once
// (LibrarySettings.saveFolders).
Item {
    id: root

    property string query: ""
    // -1 is Library Home; otherwise an index into folders.
    property int folder: -1
    property int cursor: 0

    readonly property var folders: LibraryLogic.foldersFrom(Config.libraryFoldersJson)
    readonly property bool hideFoldered: LibrarySettings.hideFoldered()
    readonly property bool searching: root.query.trim().length > 0

    AppCatalog {
        id: catalog
    }

    readonly property var apps: catalog.apps

    readonly property var shown: {
        const q = root.query.trim()
        if (q.length) {
            const now = Date.now()
            const hist = SearchService.history
            const scored = []
            for (let i = 0; i < root.apps.length; i++) {
                const a = root.apps[i]
                const s = SearchLogic.appScore(q, a)
                if (s > 0)
                    scored.push({ a: a, s: s + SearchLogic.historyBonus(hist["app:" + a.id], now) })
            }
            scored.sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
            return scored.map((x) => x.a)
        }
        return LibraryLogic.viewApps(root.apps, root.folders, root.folder, root.hideFoldered)
    }

    readonly property var current: root.shown.length ? root.shown[Math.min(root.cursor, root.shown.length - 1)] : null
    readonly property string title: {
        if (root.searching)
            return root.shown.length + (root.shown.length === 1 ? " app" : " apps")
        if (root.folder >= 0 && root.folder < root.folders.length)
            return root.folders[root.folder].name
        return "Library Home"
    }

    onQueryChanged: root.cursor = 0
    onFolderChanged: root.cursor = 0
    onShownChanged: {
        if (root.cursor >= root.shown.length)
            root.cursor = Math.max(0, root.shown.length - 1)
    }
    // A folder deleted out from under the view: back to Home.
    onFoldersChanged: {
        if (root.folder >= root.folders.length)
            root.folder = -1
    }

    function iconSource(name) {
        return catalog.iconSource(name)
    }

    function move(step) {
        const n = root.shown.length
        if (!n)
            return
        root.cursor = Math.max(0, Math.min(n - 1, root.cursor + step))
    }

    function moveTo(index) {
        if (index >= 0 && index < root.shown.length)
            root.cursor = index
    }

    // Tab and Shift+Tab: Home, then each folder, round and round.
    function cycleFolder(step) {
        const n = root.folders.length + 1
        root.folder = ((root.folder + 1 + step) % n + n) % n - 1
    }

    function launch(app) {
        if (!app)
            return false
        SearchService.launchApp(app.entry)
        return true
    }

    function save(next) {
        if (next !== root.folders)
            LibrarySettings.saveFolders(next)
    }

    function addTo(index, app) {
        root.save(LibraryLogic.addApp(root.folders, index, app))
    }

    function removeFrom(index, app) {
        root.save(LibraryLogic.removeApp(root.folders, index, app))
    }

    // Returns the new folder's index, or -1.
    function createFolder(name) {
        const next = LibraryLogic.create(root.folders, name)
        if (next === root.folders)
            return -1
        root.save(next)
        return next.length - 1
    }

    function renameFolder(index, name) {
        const next = LibraryLogic.rename(root.folders, index, name)
        if (next === root.folders)
            return false
        root.save(next)
        return true
    }

    function deleteFolder(index) {
        if (root.folder === index)
            root.folder = -1
        else if (root.folder > index)
            root.folder -= 1
        root.save(LibraryLogic.remove(root.folders, index))
    }

    function moveFolder(from, to) {
        if (root.folder === from)
            root.folder = to
        root.save(LibraryLogic.move(root.folders, from, to))
    }

    function inFolder(app, index) {
        return index >= 0 && index < root.folders.length && LibraryLogic.inFolder(app, root.folders[index])
    }

    function nameTaken(name, except) {
        return LibraryLogic.nameTaken(root.folders, name, except)
    }
}
