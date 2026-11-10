import QtQuick
import Quickshell.Io
import qs.defaultapps
import qs.services
import qs.theme

// A type's plain name, such as "Matroska video", from shared-mime-info's
// one small file per type (<data dir>/mime/<type>.xml). Read only while
// shown. Link types ("x-scheme-handler/https") read as "https links".
Text {
    id: root

    required property string type

    property int tryIndex: 0
    property string found: ""

    readonly property bool isScheme: root.type.indexOf("x-scheme-handler/") === 0
    readonly property bool lookable: !root.isScheme && DefaultAppsLogic.validType(root.type) && !DefaultAppsLogic.isWildcard(root.type)
    readonly property var dirs: DefaultAppsService.mimeDirs
    // Aliases ("video/x-matroska") have no file; read the main name's.
    readonly property string fileType: DefaultAppsLogic.canonical(root.type, DefaultAppsService.aliases)

    function decode(text) {
        return String(text).replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'").replace(/&amp;/g, "&")
    }

    onTypeChanged: {
        root.tryIndex = 0
        root.found = ""
    }

    text: root.isScheme ? root.type.slice("x-scheme-handler/".length) + " links" : root.found
    elide: Text.ElideRight
    color: Theme.subtext
    font.family: Theme.uiFont
    font.pixelSize: Theme.smallPx

    FileView {
        id: view
        path: root.lookable && root.tryIndex < root.dirs.length ? root.dirs[root.tryIndex] + "/" + root.fileType + ".xml" : ""
        printErrors: false
        onLoaded: {
            // The first comment with no xml:lang is the English one.
            const m = /<comment>([^<]{1,200})<\/comment>/.exec(view.text())
            root.found = m ? root.decode(m[1]) : ""
        }
        // Change the path after this callback returns: changing it inside
        // drops the next read. A Timer goes away with the label.
        onLoadFailed: nextDir.start()
    }

    Timer {
        id: nextDir
        interval: 0
        onTriggered: root.tryIndex += 1
    }
}
