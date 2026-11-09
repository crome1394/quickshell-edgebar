pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Wallpaper folder, current wallpaper, the page's tile size, and the
// Ctrl+Super+Space picker's options. A change saves at once, like the rest
// of the Wallpaper page.
Singleton {
    id: root

    function dirValue() {
        const saved = String(Config.wallpaperDir || "").trim()
        if (saved.length)
            return saved
        const home = String(Quickshell.env("HOME") || "")
        return home.length ? home + "/Pictures/wallpapers" : ""
    }

    function setDir(path) {
        const next = String(path || "").trim()
        if (!next.length || next.indexOf("\n") >= 0 || next.indexOf("\r") >= 0)
            return
        if (Config.wallpaperDir === next)
            return
        Config.wallpaperDir = next
        Config.touch()
    }

    function setCurrent(path) {
        const next = String(path || "").trim()
        if (next.indexOf("\n") >= 0 || next.indexOf("\r") >= 0)
            return
        if (Config.wallpaperCurrent === next)
            return
        Config.wallpaperCurrent = next
        Config.touch()
    }

    readonly property var fits: ["cover", "contain", "tile", "fill"]

    // The picker's saved options, cleaned.
    readonly property var picker: root.pickerFrom(Config.wallpaperPickerJson)

    function stepped(value, low, high, step, fallback) {
        const n = Math.round(Number(value) / step) * step
        return n >= low && n <= high ? n : fallback
    }

    // live: preview each image on the screen while you move to it.
    // delay: how long to rest on one before it previews (ms).
    // height: thumbnail height (px). close: close after applying.
    function pickerNorm(src) {
        const s = src && typeof src === "object" ? src : {}
        return {
            live: s.live !== false,
            delay: root.stepped(s.delay, 0, 1500, 50, Theme.wallpaperPickDelay),
            height: root.stepped(s.height, 120, 400, 20, Theme.wallpaperPickHeight),
            close: s.close !== false
        }
    }

    function pickerFrom(text) {
        const raw = String(text || "").trim()
        try {
            return root.pickerNorm(raw.length ? JSON.parse(raw) : {})
        } catch (e) {
            return root.pickerNorm({})
        }
    }

    function setPicker(key, value) {
        const next = Object.assign({}, root.picker)
        next[key] = value
        const text = JSON.stringify(root.pickerNorm(next))
        if (Config.wallpaperPickerJson === text)
            return
        Config.wallpaperPickerJson = text
        Config.touch()
    }

    function tileValue() {
        const stored = Math.round(Number(Config.wallpaperTileSize))
        if (stored >= Theme.wallpaperTileMin && stored <= Theme.wallpaperTileMax)
            return stored
        return Theme.wallpaperTile
    }

    function setTileSize(value) {
        let next = Math.round(Number(value))
        if (next < Theme.wallpaperTileMin)
            next = Theme.wallpaperTileMin
        if (next > Theme.wallpaperTileMax)
            next = Theme.wallpaperTileMax
        if (Config.wallpaperTileSize === next)
            return
        Config.wallpaperTileSize = next
        Config.touch()
    }
}
