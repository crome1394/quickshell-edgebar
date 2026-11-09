import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme

// What Code Aid shows: snippets grouped by language (Recent first), or,
// while something is typed, every match best first. Tracks the
// highlighted snippet and what is typed into its blanks.
// rows: [{ kind: "header", title } | { kind: "snip", snip, pick }], where
// pick numbers the snippets in list order for the cursor.
Item {
    id: root

    property string query: ""
    property int cursor: 0
    // What is typed into the current snippet's blanks: { name: text }.
    property var values: ({})

    readonly property var store: CodeAidService.store
    readonly property var snippets: root.store ? root.store.snippets : []
    readonly property bool searching: root.query.trim().length > 0

    readonly property var rows: {
        const out = []
        let pick = 0
        const add = (s) => out.push({ kind: "snip", snip: s, pick: pick++ })
        if (root.searching) {
            const scored = root.snippets.map((s) => ({ s: s, v: CodeAidLogic.score(root.query, s) })).filter((x) => x.v > 0)
            scored.sort((a, b) => b.v - a.v || a.s.label.localeCompare(b.s.label))
            scored.forEach((x) => add(x.s))
            return out
        }
        if (CodeAidSettings.recentFirst()) {
            const hist = SearchService.history
            const used = root.snippets.filter((s) => hist["snip:" + s.label])
                .sort((a, b) => Number(hist["snip:" + b.label].t) - Number(hist["snip:" + a.label].t))
                .slice(0, Theme.codeAidRecentMax)
            if (used.length) {
                out.push({ kind: "header", title: "Recent" })
                used.forEach(add)
            }
        }
        const groups = CodeAidLogic.group(root.snippets)
        for (let i = 0; i < groups.length; i++) {
            out.push({ kind: "header", title: groups[i].title })
            groups[i].snips.forEach(add)
        }
        return out
    }

    readonly property int count: {
        let n = 0
        for (let i = 0; i < root.rows.length; i++) {
            if (root.rows[i].kind === "snip")
                n++
        }
        return n
    }

    // The row index of the snippet the cursor is on.
    readonly property int currentRow: {
        for (let i = 0; i < root.rows.length; i++) {
            if (root.rows[i].kind === "snip" && root.rows[i].pick === root.cursor)
                return i
        }
        return -1
    }

    readonly property var current: root.currentRow >= 0 ? root.rows[root.currentRow].snip : null
    readonly property var fields: root.current ? CodeAidLogic.fields(root.current.body) : []
    // The blanks you type into ({{clipboard}} fills itself).
    readonly property var typedFields: root.fields.filter((f) => !f.clipboard)
    readonly property bool usesClipboard: root.fields.some((f) => f.clipboard)
    readonly property string clipboard: root.usesClipboard ? CodeAidService.clipboard : ""
    readonly property string filled: root.current ? CodeAidLogic.fill(root.current.body, root.values, root.clipboard) : ""

    onQueryChanged: root.cursor = 0
    onCurrentChanged: root.values = ({})
    onCountChanged: {
        if (root.cursor >= root.count)
            root.cursor = Math.max(0, root.count - 1)
    }

    function move(step) {
        if (!root.count)
            return
        root.cursor = (root.cursor + step + root.count) % root.count
    }

    function moveTo(pick) {
        if (pick >= 0 && pick < root.count)
            root.cursor = pick
    }

    // Highlight a snippet by label. False while it is not listed yet.
    function moveToLabel(label) {
        for (let i = 0; i < root.rows.length; i++) {
            const r = root.rows[i]
            if (r.kind === "snip" && r.snip.label === label) {
                root.cursor = r.pick
                return true
            }
        }
        return false
    }

    function setValue(name, text) {
        const next = Object.assign({}, root.values)
        next[String(name)] = String(text || "")
        root.values = next
    }

    function valueOf(name) {
        const v = root.values[String(name)]
        return v === undefined ? "" : v
    }

    // The languages in use, for the editor's suggestions.
    readonly property var languages: CodeAidLogic.group(root.snippets).map((g) => g.language)
}
