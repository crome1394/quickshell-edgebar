pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Transparency override levels for Quickshell and Satty windows.
// 0 means no override; the defaults live in theme/DefaultTheme.qml.
Singleton {
    id: root

    function clamp(value) {
        let n = Math.round(Number(value))
        if (!(n >= Theme.opacityMin))
            return Theme.opacityMax
        if (n > Theme.opacityMax)
            return Theme.opacityMax
        return n
    }

    function quickshellValue() {
        const stored = Math.round(Number(Config.opacityQuickshell))
        if (stored >= Theme.opacityMin && stored <= Theme.opacityMax)
            return stored
        return root.clamp(DefaultTheme.opacityQuickshell)
    }

    function sattyValue() {
        const stored = Math.round(Number(Config.opacitySatty))
        if (stored >= Theme.opacityMin && stored <= Theme.opacityMax)
            return stored
        return root.clamp(DefaultTheme.opacitySatty)
    }

    function setLevels(quickshell, satty) {
        const nextQuickshell = root.clamp(quickshell)
        const nextSatty = root.clamp(satty)
        if (Config.opacityQuickshell === nextQuickshell && Config.opacitySatty === nextSatty)
            return
        Config.saveFields(() => {
            Config.opacityQuickshell = nextQuickshell
            Config.opacitySatty = nextSatty
        })
    }

    function clearOverride() {
        if (Config.opacityQuickshell === 0 && Config.opacitySatty === 0)
            return
        Config.saveFields(() => {
            Config.opacityQuickshell = 0
            Config.opacitySatty = 0
        })
    }
}
