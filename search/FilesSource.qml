import QtQuick
import Qt.labs.folderlistmodel
import qs.theme

// "~/" or "/": the folder typed so far, filtered by the part after the
// last slash. Qt lists the folder itself; nothing runs. Hidden entries
// show once the part typed starts with a dot.
Item {
    id: root

    // The folder (ends in /) and the name typed in it, from SearchLogic.pathParts.
    property string dir: ""
    property string base: ""
    // [{ name, path, isDir }] matching `base`.
    readonly property var entries: root.collect(listing.count, listing.status, root.base)

    function collect(count, status, base) {
        if (!root.dir.length || status !== FolderListModel.Ready)
            return []
        const want = String(base || "").toLowerCase()
        const starts = []
        const contains = []
        for (let i = 0; i < count; i++) {
            const name = String(listing.get(i, "fileName") || "")
            const lower = name.toLowerCase()
            const item = { name: name, path: String(listing.get(i, "filePath") || ""), isDir: !!listing.get(i, "fileIsDir") }
            if (!want.length || lower.indexOf(want) === 0)
                starts.push(item)
            else if (lower.indexOf(want) > 0)
                contains.push(item)
            if (starts.length >= Theme.searchFilesMax)
                break
        }
        return starts.concat(contains).slice(0, Theme.searchFilesMax)
    }

    FolderListModel {
        id: listing
        folder: root.dir.length ? "file://" + root.dir.split("/").map(encodeURIComponent).join("/") : ""
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: root.base.charAt(0) === "."
        caseSensitive: false
        sortCaseSensitive: false
    }
}
