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
    ReaderKeys { id: keys }

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

            // One highlight: the article shown follows the cursor.
            const zetaItem = m.rows.findIndex((r) => r.kind === "item" && r.item.feed === "Zeta Feed")
            m.cursor = zetaItem
            t.eq("cursor on an article shows it", m.selected && m.selected.feed, "Zeta Feed")
            m.cursor = 0
            t.eq("cursor on a header keeps the article", m.selected && m.selected.feed, "Zeta Feed")
            t.eq("no cursor article on a header", m.cursorItem, null)

            // Space: article alone, or the whole feed or day.
            m.cursor = zetaItem
            let target = m.spaceTarget()
            t.eq("space on an article", [target.kind, target.items.length], ["item", 1])
            t.eq("space on a read article marks unread", target.read, !m.cursorItem.read)
            m.cursor = 0
            target = m.spaceTarget()
            t.eq("space on a feed takes its articles", [target.kind, target.items.length], ["feed", 2])
            m.cursor = 1
            target = m.spaceTarget()
            t.eq("space on a day takes that day", [target.kind, target.items.length], ["day", 1])

            // Keys: Shift and Ctrl are matched exactly.
            const press = (key, mods) => ({ key: key, modifiers: mods || 0 })
            t.eq("r reads", keys.actionFor(press(Qt.Key_R), false), "read")
            t.eq("Shift+R reads the feed", keys.actionFor(press(Qt.Key_R, Qt.ShiftModifier), false), "feedRead")
            t.eq("Ctrl+R reloads", keys.actionFor(press(Qt.Key_R, Qt.ControlModifier), false), "reload")
            t.eq("u unreads", keys.actionFor(press(Qt.Key_U), false), "unread")
            t.eq("Shift+U unreads the feed", keys.actionFor(press(Qt.Key_U, Qt.ShiftModifier), false), "feedUnread")
            t.eq("s stars", keys.actionFor(press(Qt.Key_S), false), "star")
            t.eq("Shift+S is not star", keys.actionFor(press(Qt.Key_S, Qt.ShiftModifier), false), "")
            t.eq("? opens help", keys.actionFor(press(Qt.Key_Question, Qt.ShiftModifier), false), "help")
            t.eq("Ctrl+F finds", keys.actionFor(press(Qt.Key_F, Qt.ControlModifier), false), "find")
            t.eq("letters wait while typing", keys.actionFor(press(Qt.Key_R), true), "")
            t.eq("Ctrl+F works while typing", keys.actionFor(press(Qt.Key_F, Qt.ControlModifier), true), "find")
            t.eq("Alt is ignored", keys.actionFor(press(Qt.Key_R, Qt.AltModifier), false), "")
            t.done()
        }
    }
}
