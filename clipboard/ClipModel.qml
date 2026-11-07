import QtQuick
import qs.services

// The viewer's state: the search, the entries that match it, and the
// cursor (the one highlighted row, moved by keys and by the mouse).
// No drawing here. Search matches every word, in any order, against the
// preview text and the entry's kind ("image", "link", "code", …).
QtObject {
    id: root

    property string search: ""
    property int cursor: 0

    readonly property var filtered: {
        const words = root.search.toLowerCase().split(/\s+/).filter((w) => w.length)
        const list = ClipboardService.entries
        if (!words.length)
            return list
        return list.filter((e) => {
            const hay = (e.preview + " " + e.kind).toLowerCase()
            for (let i = 0; i < words.length; i++) {
                if (hay.indexOf(words[i]) < 0)
                    return false
            }
            return true
        })
    }

    readonly property var current: root.filtered.length
        ? root.filtered[Math.max(0, Math.min(root.cursor, root.filtered.length - 1))] : null

    function moveTo(index) {
        if (root.filtered.length)
            root.cursor = Math.max(0, Math.min(root.filtered.length - 1, index))
    }

    function move(step) {
        root.moveTo(root.cursor + step)
    }

    // The nth match (1-based), for Alt+1…9.
    function nth(n) {
        return n >= 1 && n <= root.filtered.length ? root.filtered[n - 1] : null
    }

    onSearchChanged: root.cursor = 0
    onFilteredChanged: {
        if (root.cursor >= root.filtered.length)
            root.cursor = Math.max(0, root.filtered.length - 1)
    }
}
