import QtQuick
import Quickshell
import Quickshell.Io
import qs.freshrss
import qs.services
import "tests"

// ReaderModel: grouping, filters, the cursor, and article stepping.
ShellRoot {
    Check { id: t }

    ReaderModel { id: m }

    FileView {
        id: items
        path: Quickshell.shellDir + "/tests/fixtures/greader-items.json"
        onLoaded: {
            const list = JSON.parse(items.text()).map((x) => FreshRssService.itemNorm(x, {}))
            list.sort((a, b) => b.published - a.published)
            FreshRssService.items = list

            t.eq("feeds A-Z, closed", m.rows.map((r) => r.kind + ":" + r.title), ["feed:Alpha Feed", "feed:Zeta Feed"])
            t.eq("feed counts", m.rows.map((r) => r.count), [2, 1])

            m.cursor = 0
            m.activateCursor()
            t.eq("Enter opens the feed", m.rows.map((r) => r.kind), ["feed", "day", "item", "day", "item", "feed"])
            m.toggleAtCursor()
            t.eq("Space closes it", m.rows.length, 2)

            m.nextArticle(1)
            t.eq("j opens and selects the first article", m.selected && m.selected.title, "Video one")
            m.nextArticle(1)
            t.eq("j steps to the next", m.selected && m.selected.title, "Older alpha")
            m.nextArticle(1)
            t.eq("j stops at the end", m.selected && m.selected.title, "Older alpha")
            m.nextArticle(-1)
            t.eq("k steps back", m.selected && m.selected.title, "Video one")
            t.eq("cursor follows the article", m.cursorRow && m.cursorRow.kind, "item")

            m.typeFilter = "video"
            t.eq("video filter", m.filtered.map((x) => x.title), ["Video one"])
            m.typeFilter = "any"
            m.search = "SEARCHABLE"
            t.eq("search is case-insensitive", m.filtered.map((x) => x.title), ["Older alpha"])
            t.ok("search opens feeds", m.rows.some((r) => r.kind === "item"))
            m.search = ""

            m.collapseAll()
            t.eq("collapse all", m.rows.length, 2)
            m.expandAll()
            t.eq("expand all", m.rows.filter((r) => r.kind === "item").length, 3)
            t.done()
        }
    }
}
