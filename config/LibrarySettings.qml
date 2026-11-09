pragma Singleton
import QtQuick
import Quickshell
import qs.library
import qs.theme

// Applications → App Library: Pop's application library (LibraryService).
// Built in, or the Application Menu command run instead; the grid's size;
// and whether Library Home leaves out apps that are in a folder. Folders
// are made and filled in the library itself and save at once.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function columnsNorm(value) {
        const n = Math.round(Number(value))
        return Theme.libraryColumnChoices.indexOf(n) >= 0 ? n : Theme.libraryColumnsDefault
    }

    function iconNorm(value) {
        const n = Math.round(Number(value))
        return Theme.libraryIconChoices.indexOf(n) >= 0 ? n : Theme.libraryIconDefault
    }

    // Saved values, for the library.
    function builtIn() {
        return Config.libraryBuiltIn !== false
    }

    function columns() {
        return root.columnsNorm(Config.libraryColumns)
    }

    function iconPx() {
        return root.iconNorm(Config.libraryIconPx)
    }

    function hideFoldered() {
        return Config.libraryHideFoldered !== false
    }

    function showNames() {
        return Config.libraryShowNames !== false
    }

    function folders() {
        return LibraryLogic.foldersFrom(Config.libraryFoldersJson)
    }

    // Pop's defaults save as "", so the store stays empty until you change them.
    function saveFolders(list) {
        const clean = LibraryLogic.foldersFrom(JSON.stringify(list || []))
        const text = LibraryLogic.sameAsDefaults(clean) ? "" : JSON.stringify(clean)
        if (text === Config.libraryFoldersJson)
            return
        Config.saveFields(() => {
            Config.libraryFoldersJson = text
        })
    }

    function resetFolders() {
        Config.saveFields(() => {
            Config.libraryFoldersJson = ""
        })
    }

    function normalize(src) {
        const s = src || {}
        return {
            builtIn: s.builtIn !== false,
            columns: root.columnsNorm(s.columns),
            iconPx: root.iconNorm(s.iconPx),
            hideFoldered: s.hideFoldered !== false,
            showNames: s.showNames !== false
        }
    }

    function snapshot() {
        return root.normalize({
            builtIn: Config.libraryBuiltIn,
            columns: Config.libraryColumns,
            iconPx: Config.libraryIconPx,
            hideFoldered: Config.libraryHideFoldered,
            showNames: Config.libraryShowNames
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.libraryBuiltIn = clean.builtIn
            Config.libraryColumns = clean.columns
            Config.libraryIconPx = clean.iconPx
            Config.libraryHideFoldered = clean.hideFoldered
            Config.libraryShowNames = clean.showNames
        })
    }
}
