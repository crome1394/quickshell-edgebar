import QtQuick
import Quickshell

// The installed apps the launcher and the App Library show: every desktop
// entry not marked NoDisplay, as plain objects ready to search. Built
// when created and again when the list changes.
// [{ entry, id, name, genericName, comment, keywords, categories, program, icon }]
QtObject {
    id: root

    property var apps: []
    readonly property var values: DesktopEntries.applications.values

    onValuesChanged: root.load()
    Component.onCompleted: root.load()

    function load() {
        const list = []
        const values = root.values || []
        for (let i = 0; i < values.length; i++) {
            const e = values[i]
            if (!e || e.noDisplay)
                continue
            const cmd = e.command && e.command.length ? String(e.command[0]) : ""
            list.push({
                entry: e,
                id: String(e.id),
                name: String(e.name || ""),
                genericName: String(e.genericName || ""),
                comment: String(e.comment || ""),
                keywords: e.keywords || [],
                categories: e.categories || [],
                program: cmd.substring(cmd.lastIndexOf("/") + 1),
                icon: String(e.icon || "")
            })
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        root.apps = list
    }

    // An icon name or path as an Image source, or "" when the theme has none.
    function iconSource(name) {
        const n = String(name || "")
        if (!n.length)
            return ""
        if (n.charAt(0) === "/")
            return "file://" + n
        return Quickshell.iconPath(n, true)
    }
}
