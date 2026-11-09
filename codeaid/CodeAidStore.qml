pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// The snippet files in one folder, read and kept up to date while this
// exists. CodeAidService creates it only while Code Aid is open or a copy
// by name is waiting.
// snippets: [{ path, file, label, language, name, body }]
Item {
    id: root

    required property string dir

    // path → snippet, as each file is read.
    property var byPath: ({})
    readonly property int fileCount: listing.status === FolderListModel.Ready ? listing.count : 0
    readonly property bool ready: listing.status === FolderListModel.Ready && Object.keys(root.byPath).length >= root.counted
    property int counted: 0
    readonly property var snippets: {
        const out = []
        const keys = Object.keys(root.byPath)
        for (let i = 0; i < keys.length; i++) {
            const s = root.byPath[keys[i]]
            if (s)
                out.push(s)
        }
        return out
    }
    // Every file name in the folder, snippet or not, so a new file never
    // takes a name already used.
    readonly property var fileNames: {
        const out = []
        for (let i = 0; i < root.fileCount; i++)
            out.push(String(listing.get(i, "fileName") || ""))
        return out
    }

    function forget(path) {
        if (!(path in root.byPath))
            return
        const next = Object.assign({}, root.byPath)
        delete next[path]
        root.byPath = next
    }

    FolderListModel {
        id: listing
        folder: root.dir.length ? "file://" + root.dir.split("/").map(encodeURIComponent).join("/") : ""
        showDirs: false
        showHidden: false
        onCountChanged: root.counted = listing.count
        onStatusChanged: root.counted = listing.count
    }

    Instantiator {
        model: listing
        delegate: FileView {
            id: file
            required property string filePath
            required property string fileName
            path: file.filePath
            watchChanges: true
            printErrors: false
            onFileChanged: file.reload()
            onLoaded: {
                const s = CodeAidLogic.parse(file.text())
                const next = Object.assign({}, root.byPath)
                // A file that is not a snippet still counts as read.
                next[file.filePath] = s ? Object.assign(s, { path: file.filePath, file: file.fileName }) : null
                root.byPath = next
            }
            onLoadFailed: {
                const next = Object.assign({}, root.byPath)
                next[file.filePath] = null
                root.byPath = next
            }
            Component.onDestruction: root.forget(file.filePath)
        }
    }
}
