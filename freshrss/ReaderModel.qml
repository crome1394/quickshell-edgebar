import QtQuick
import qs.config
import qs.services

// The reader's state: filters, which feeds and days are open, the list
// rows built from FreshRssService.items, the keyboard cursor, and the
// selected article. No drawing here; the panel and its views read it.
//
// Rows: a feed header, then (when the feed is open) a header per day,
// then (when the day is open) its articles. Feeds start closed, A–Z.
QtObject {
    id: root

    // Server-side choices (reload on change).
    property string scope: FreshRssSettings.scope()
    property int maxDays: FreshRssSettings.maxDays()
    property int perFeed: FreshRssSettings.perFeed()
    property int itemLimit: FreshRssSettings.itemLimit()

    // Filters on the loaded list.
    property string dateFilter: "all"
    property string typeFilter: "any"
    property string search: ""

    property var openFeeds: ({})
    property var closedDays: ({})
    property int cursor: 0
    property string selectedId: ""

    function reload() {
        FreshRssService.load(root.scope, root.maxDays, root.perFeed, root.itemLimit)
    }

    function setScope(next) {
        if (next === root.scope)
            return
        root.scope = next
        FreshRssSettings.setScopeLive(next)
        root.reload()
    }

    function setMaxDays(next) {
        root.maxDays = next
        FreshRssSettings.setMaxDaysLive(next)
        root.reload()
    }

    function setPerFeed(next) {
        root.perFeed = next
        FreshRssSettings.setPerFeedLive(next)
        if (root.scope === "all" || root.scope === "read")
            root.reload()
    }

    function setItemLimit(next) {
        root.itemLimit = next
        FreshRssSettings.setItemLimitLive(next)
        if (root.scope === "unread" || root.scope === "starred")
            root.reload()
    }

    function dayKey(epoch) {
        const d = new Date(epoch * 1000)
        return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate()
    }

    function dayLabel(epoch) {
        const d = new Date(epoch * 1000)
        const today = new Date()
        const key = root.dayKey(epoch)
        if (key === root.dayKey(today.getTime() / 1000))
            return "Today"
        const y = new Date(today.getTime() - 86400000)
        if (key === root.dayKey(y.getTime() / 1000))
            return "Yesterday"
        return d.toLocaleDateString(Qt.locale(), "ddd d MMM yyyy")
    }

    readonly property var filtered: {
        const now = Date.now() / 1000
        const startToday = new Date().setHours(0, 0, 0, 0) / 1000
        const words = root.search.toLowerCase().split(/\s+/).filter((w) => w.length)
        return FreshRssService.items.filter((it) => {
            if (root.dateFilter === "today" && it.published < startToday)
                return false
            if (root.dateFilter === "week" && it.published < now - 7 * 86400)
                return false
            if (root.typeFilter === "video" && !it.videoUrl.length)
                return false
            for (let i = 0; i < words.length; i++) {
                if (it.search.indexOf(words[i]) < 0)
                    return false
            }
            return true
        })
    }

    // While searching, every feed and day opens so matches show.
    readonly property bool searching: root.search.trim().length > 0

    readonly property var rows: {
        const byFeed = {}
        const order = []
        const list = root.filtered
        for (let i = 0; i < list.length; i++) {
            const it = list[i]
            const key = it.feedId || it.feed
            if (!byFeed[key]) {
                byFeed[key] = { key: key, feedId: it.feedId, title: it.feed, items: [] }
                order.push(byFeed[key])
            }
            byFeed[key].items.push(it)
        }
        order.sort((a, b) => a.title.localeCompare(b.title))
        const counts = FreshRssService.feedUnread
        const out = []
        for (let f = 0; f < order.length; f++) {
            const feed = order[f]
            const open = root.searching || root.openFeeds[feed.key] === true
            out.push({
                kind: "feed", key: feed.key, feedId: feed.feedId, title: feed.title, open: open,
                count: feed.items.length,
                unread: counts[feed.feedId] !== undefined ? counts[feed.feedId] : feed.items.filter((x) => !x.read).length
            })
            if (!open)
                continue
            let day = -1
            let dayOpen = true
            for (let k = 0; k < feed.items.length; k++) {
                const it = feed.items[k]
                const dk = root.dayKey(it.published)
                if (dk !== day) {
                    day = dk
                    const dayId = feed.key + "|" + dk
                    dayOpen = root.searching || root.closedDays[dayId] !== true
                    out.push({
                        kind: "day", key: dayId, feedId: feed.feedId, title: root.dayLabel(it.published), open: dayOpen,
                        count: feed.items.filter((x) => root.dayKey(x.published) === dk).length
                    })
                }
                if (dayOpen)
                    out.push({ kind: "item", key: it.id, feedId: feed.feedId, item: it })
            }
        }
        return out
    }

    readonly property var cursorRow: root.rows.length ? root.rows[Math.max(0, Math.min(root.cursor, root.rows.length - 1))] : null

    readonly property var selected: {
        const list = FreshRssService.items
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === root.selectedId)
                return list[i]
        }
        return null
    }

    // The feed the feed actions act on: the cursor's, else the article's.
    readonly property string actionFeedId: root.cursorRow ? root.cursorRow.feedId : (root.selected ? root.selected.feedId : "")
    readonly property string actionFeedTitle: {
        const id = root.actionFeedId
        const subs = FreshRssService.subscriptions
        for (let i = 0; i < subs.length; i++) {
            if (subs[i].id === id)
                return subs[i].title
        }
        return root.selected ? root.selected.feed : ""
    }

    function rowIndex(key) {
        for (let i = 0; i < root.rows.length; i++) {
            if (root.rows[i].key === key)
                return i
        }
        return -1
    }

    function moveCursor(step) {
        if (!root.rows.length)
            return
        root.cursor = Math.max(0, Math.min(root.rows.length - 1, root.cursor + step))
    }

    function setOpen(row, open) {
        if (!row)
            return
        if (row.kind === "feed") {
            const next = Object.assign({}, root.openFeeds)
            next[row.key] = open
            root.openFeeds = next
        } else if (row.kind === "day") {
            const next = Object.assign({}, root.closedDays)
            next[row.key] = !open
            root.closedDays = next
        }
    }

    function toggleRow(row) {
        if (row && row.kind !== "item")
            root.setOpen(row, !row.open)
    }

    // Space and ←: open or close the feed or day under the cursor. On an
    // article, close its day and put the cursor on the day.
    function toggleAtCursor() {
        const row = root.cursorRow
        if (!row)
            return
        if (row.kind !== "item") {
            root.toggleRow(row)
            return
        }
        for (let i = root.cursor; i >= 0; i--) {
            if (root.rows[i].kind === "day") {
                root.cursor = i
                root.setOpen(root.rows[i], false)
                return
            }
        }
    }

    function select(item) {
        if (!item)
            return
        root.selectedId = item.id
        const at = root.rowIndex(item.id)
        if (at >= 0)
            root.cursor = at
    }

    // Enter and →: open the article under the cursor, or open a header.
    function activateCursor() {
        const row = root.cursorRow
        if (!row)
            return
        if (row.kind === "item")
            root.select(row.item)
        else if (!row.open)
            root.setOpen(row, true)
        else
            root.moveCursor(1)
    }

    // j and k: the next or previous article, opening its feed if needed.
    function nextArticle(step) {
        const list = root.rows.filter((r) => r.kind === "item")
        if (!list.length) {
            const feeds = root.rows.filter((r) => r.kind === "feed")
            if (feeds.length && !feeds[0].open) {
                root.setOpen(feeds[0], true)
                root.nextArticle(step)
            }
            return
        }
        let at = -1
        for (let i = 0; i < list.length; i++) {
            if (list[i].key === root.selectedId)
                at = i
        }
        const next = at < 0 ? (step > 0 ? 0 : list.length - 1) : Math.max(0, Math.min(list.length - 1, at + step))
        root.select(list[next].item)
    }

    function expandAll() {
        const next = {}
        for (let i = 0; i < FreshRssService.items.length; i++) {
            const it = FreshRssService.items[i]
            next[it.feedId || it.feed] = true
        }
        root.openFeeds = next
        root.closedDays = ({})
    }

    function collapseAll() {
        root.openFeeds = ({})
        root.cursor = 0
    }

    onRowsChanged: {
        if (root.cursor >= root.rows.length)
            root.cursor = Math.max(0, root.rows.length - 1)
    }
}
