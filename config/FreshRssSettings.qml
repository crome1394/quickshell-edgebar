pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// FreshRSS reader options: how often the unread badge checks, how many
// articles to load, and whether the reader opens with Filters showing.
// Settings → Applications → FreshRSS edits them through `editor`; the
// reader window changes scope, days, and limits at once with set*Live().
//
// The server address, user, and API password are not saved here. They
// live in ~/.config/freshrss-quickshell/freshrss.env (FreshRssService).
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property var scopes: ["unread", "all", "read", "starred"]

    function pick(list, value, fallback) {
        const n = Math.round(Number(value))
        return list.indexOf(n) >= 0 ? n : fallback
    }

    function pollMin() {
        const n = Math.round(Number(Config.freshRssPollMin))
        return n >= 1 && n <= Theme.freshRssPollMax ? n : Theme.freshRssPollDefault
    }

    function perFeed() {
        return root.pick(Theme.freshRssPerFeedChoices, Config.freshRssPerFeed, Theme.freshRssPerFeedDefault)
    }

    function itemLimit() {
        return root.pick(Theme.freshRssItemLimitChoices, Config.freshRssItemLimit, Theme.freshRssItemLimitDefault)
    }

    function maxDays() {
        return root.pick(Theme.freshRssMaxDaysChoices, Config.freshRssMaxDays, Theme.freshRssMaxDaysDefault)
    }

    function scope() {
        const s = String(Config.freshRssScope || "")
        return root.scopes.indexOf(s) >= 0 ? s : "all"
    }

    function listWidth() {
        const n = Math.round(Number(Config.freshRssListWidth))
        return n >= Theme.freshRssListMin ? n : Theme.freshRssListDefault
    }

    // The next value in a choice list, for the − and + buttons.
    function step(list, value, delta) {
        const at = list.indexOf(value)
        const next = Math.max(0, Math.min(list.length - 1, (at < 0 ? 0 : at) + delta))
        return list[next]
    }

    // ── Draft for the settings page ─────────────────────────────────────
    function normalize(src) {
        const s = src || {}
        const poll = Math.round(Number(s.pollMin))
        return {
            pollMin: poll >= 1 && poll <= Theme.freshRssPollMax ? poll : Theme.freshRssPollDefault,
            perFeed: root.pick(Theme.freshRssPerFeedChoices, s.perFeed, Theme.freshRssPerFeedDefault),
            itemLimit: root.pick(Theme.freshRssItemLimitChoices, s.itemLimit, Theme.freshRssItemLimitDefault),
            maxDays: root.pick(Theme.freshRssMaxDaysChoices, s.maxDays, Theme.freshRssMaxDaysDefault),
            filtersOpen: s.filtersOpen !== false
        }
    }

    function snapshot() {
        return root.normalize({
            pollMin: root.pollMin(),
            perFeed: root.perFeed(),
            itemLimit: root.itemLimit(),
            maxDays: root.maxDays(),
            filtersOpen: Config.freshRssFiltersOpen
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.freshRssPollMin = clean.pollMin
            Config.freshRssPerFeed = clean.perFeed
            Config.freshRssItemLimit = clean.itemLimit
            Config.freshRssMaxDays = clean.maxDays
            Config.freshRssFiltersOpen = clean.filtersOpen
        })
    }

    // ── Live changes from the reader window (saved at once) ─────────────
    function setScopeLive(scope) {
        if (root.scopes.indexOf(scope) < 0 || scope === root.scope())
            return
        Config.saveFields(() => {
            Config.freshRssScope = scope
        })
    }

    function setMaxDaysLive(days) {
        const n = root.pick(Theme.freshRssMaxDaysChoices, days, -2)
        if (n === -2 || n === root.maxDays())
            return
        Config.saveFields(() => {
            Config.freshRssMaxDays = n
        })
    }

    function setPerFeedLive(count) {
        const n = root.pick(Theme.freshRssPerFeedChoices, count, 0)
        if (!n || n === root.perFeed())
            return
        Config.saveFields(() => {
            Config.freshRssPerFeed = n
        })
    }

    function setItemLimitLive(count) {
        const n = root.pick(Theme.freshRssItemLimitChoices, count, 0)
        if (!n || n === root.itemLimit())
            return
        Config.saveFields(() => {
            Config.freshRssItemLimit = n
        })
    }

    function setFiltersOpenLive(open) {
        if (Config.freshRssFiltersOpen === !!open)
            return
        Config.saveFields(() => {
            Config.freshRssFiltersOpen = !!open
        })
    }

    function setListWidthLive(width) {
        const n = Math.max(Theme.freshRssListMin, Math.round(Number(width)))
        if (n === root.listWidth())
            return
        Config.saveFields(() => {
            Config.freshRssListWidth = n
        })
    }

    // Feeds whose articles open as the full web page (feed/<number> ids).
    function fullFeeds() {
        const list = Array.isArray(Config.freshRssFullFeeds) ? Config.freshRssFullFeeds : []
        return list.filter((id) => /^feed\/\d+$/.test(String(id)))
    }

    function isFullFeed(feedId) {
        return root.fullFeeds().indexOf(String(feedId || "")) >= 0
    }

    function setFullFeedLive(feedId, on) {
        const id = String(feedId || "")
        if (!/^feed\/\d+$/.test(id) || root.isFullFeed(id) === !!on)
            return
        const next = root.fullFeeds().filter((x) => x !== id)
        if (on)
            next.push(id)
        Config.saveFields(() => {
            Config.freshRssFullFeeds = next
        })
    }
}
