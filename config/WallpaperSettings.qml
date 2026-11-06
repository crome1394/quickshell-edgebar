pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Wallpaper folder, current wallpaper, and the picker's tile size. A change
// saves through the store's own change handler.
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
