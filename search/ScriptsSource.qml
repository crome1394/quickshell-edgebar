pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Pop Launcher scripts: each file in ~/.local/share/pop-launcher/scripts,
// named and described by its "# name:", "# description:", "# icon:", and
// "# keywords:" header lines. Read only while the launcher is open.
Item {
    id: root

    property bool active: false
    property string home: ""
    // { path: header } as each file is read.
    property var headers: ({})
    // [{ path, name, description, icon, keywords }]
    readonly property var scripts: {
        const out = []
        const keys = Object.keys(root.headers)
        for (let i = 0; i < keys.length; i++) {
            const h = root.headers[keys[i]]
            const file = keys[i].substring(keys[i].lastIndexOf("/") + 1)
            out.push({ path: keys[i], name: h.name || file, description: h.description, icon: h.icon, keywords: h.keywords })
        }
        return out
    }

    FolderListModel {
        id: listing
        folder: root.active && root.home.length ? "file://" + root.home + "/.local/share/pop-launcher/scripts" : ""
        showDirs: false
        showHidden: false
    }

    Instantiator {
        model: listing
        delegate: FileView {
            id: script
            required property string filePath
            path: script.filePath
            printErrors: false
            onLoaded: {
                const next = Object.assign({}, root.headers)
                next[script.filePath] = SearchLogic.scriptHeader(script.text())
                root.headers = next
            }
        }
    }
}
