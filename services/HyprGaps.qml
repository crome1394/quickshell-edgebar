pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// One hyprctl read of general:gaps_out while flush-windows is on.
// CSS order is top, right, bottom, left. Missing hyprctl keeps the fallback.
Singleton {
    id: root

    property int top: Theme.gapsFallback
    property int right: Theme.gapsFallback
    property int bottom: Theme.gapsFallback
    property int left: Theme.gapsFallback

    function apply(text) {
        let parsed = null
        try {
            parsed = JSON.parse(String(text || ""))
        } catch (e) {
            return
        }
        if (!parsed)
            return
        const raw = parsed.css !== undefined ? String(parsed.css) : ""
        const parts = raw.trim().length ? raw.trim().split(/\s+/) : []
        const nums = []
        for (let i = 0; i < parts.length; i++) {
            const n = parseInt(parts[i], 10)
            if (!isNaN(n) && n >= 0)
                nums.push(n)
        }
        if (nums.length >= 4) {
            root.top = nums[0]
            root.right = nums[1]
            root.bottom = nums[2]
            root.left = nums[3]
            return
        }
        if (nums.length === 3) {
            root.top = nums[0]
            root.right = nums[1]
            root.left = nums[1]
            root.bottom = nums[2]
            return
        }
        if (nums.length === 2) {
            root.top = nums[0]
            root.bottom = nums[0]
            root.right = nums[1]
            root.left = nums[1]
            return
        }
        if (nums.length === 1) {
            root.top = nums[0]
            root.right = nums[0]
            root.bottom = nums[0]
            root.left = nums[0]
            return
        }
        if (parsed.int === undefined)
            return
        const v = Number(parsed.int)
        if (!(v >= 0))
            return
        root.top = v
        root.right = v
        root.bottom = v
        root.left = v
    }

    function refresh() {
        if (!Config.flushWindowsToBar)
            return
        gapProc.running = false
        gapProc.running = true
    }

    Component.onCompleted: root.refresh()

    Connections {
        target: Config
        function onFlushWindowsToBarChanged() {
            root.refresh()
        }
    }

    Process {
        id: gapProc
        command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
        stdout: StdioCollector {
            id: gapOut
            waitForEnd: true
            onStreamFinished: root.apply(gapOut.text)
        }
    }
}
