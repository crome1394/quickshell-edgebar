pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Clipboard history: whether the bar keeps it (with cliphist), how many
// entries, and whether pictures are kept too. Settings → Tools →
// Clipboard edits these through `editor`.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function maxItemsNorm(value) {
        const n = Math.round(Number(value))
        return Theme.clipboardMaxItemsChoices.indexOf(n) >= 0 ? n : Theme.clipboardMaxItemsDefault
    }

    function enabled() {
        return Config.clipboardHistory !== false
    }

    function maxItems() {
        return root.maxItemsNorm(Config.clipboardMaxItems)
    }

    function images() {
        return Config.clipboardImages !== false
    }

    function normalize(src) {
        const s = src || {}
        return {
            enabled: s.enabled !== false,
            maxItems: root.maxItemsNorm(s.maxItems),
            images: s.images !== false
        }
    }

    function snapshot() {
        return root.normalize({ enabled: Config.clipboardHistory, maxItems: Config.clipboardMaxItems, images: Config.clipboardImages })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.clipboardHistory = clean.enabled
            Config.clipboardMaxItems = clean.maxItems
            Config.clipboardImages = clean.images
        })
    }
}
