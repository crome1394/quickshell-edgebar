import QtQuick
import Quickshell.Io
import qs.theme

// "recent <name>": recently opened files, from the list apps share in
// ~/.local/share/recently-used.xbel. Read once, the first time recent is
// typed, and again if it changes while open.
Item {
    id: root

    property bool active: false
    property string home: ""
    // [{ path, name, modified }], newest first.
    property var files: []

    FileView {
        id: file
        path: root.active && root.home.length ? root.home + "/.local/share/recently-used.xbel" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: file.reload()
        onLoaded: root.files = SearchLogic.recentFiles(file.text(), Theme.searchFilesMax * 4)
    }
}
