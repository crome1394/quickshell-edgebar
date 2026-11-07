pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Caffeine: keeps the screen awake (no screensaver, no idle lock) while on.
// It holds a Wayland idle inhibitor through CaffeineInhibitor, a tiny
// invisible window that exists only while Caffeine is on (shell.qml).
// Hyprland and hypridle respect it, unless the screensaver's "Always start
// after idle" option is on, which ignores inhibitors on purpose.
//
//   qs ipc call caffeine toggle | on | off | forMinutes <n> | status
Singleton {
    id: root

    property bool on: false
    // When a timed Caffeine ends (ms since epoch), or 0 for "until off".
    property real until: 0
    // Ticks once a minute while a timer runs, for the remaining time.
    property real now: Date.now()

    readonly property int minutesLeft: root.on && root.until > 0 ? Math.max(0, Math.ceil((root.until - root.now) / 60000)) : 0

    function setOn(next) {
        root.on = !!next
        root.until = 0
        // On with no timer counts as the last step ("until off").
        root.stepIndex = root.on ? Theme.caffeineSteps.length - 1 : -1
    }

    function toggle() {
        root.setOn(!root.on)
    }

    // On for `minutes` (0 = until turned off).
    function forMinutes(minutes) {
        const n = Math.round(Number(minutes))
        if (!(n >= 0) || n > 24 * 60)
            return false
        root.now = Date.now()
        root.until = n > 0 ? root.now + n * 60000 : 0
        root.on = true
        root.stepIndex = Theme.caffeineSteps.indexOf(n)
        return true
    }

    // Right-click: off → 30 min → 1 h → 2 h → until off → off.
    property int stepIndex: -1

    function step() {
        const steps = Theme.caffeineSteps
        const next = root.on ? root.stepIndex + 1 : 0
        if (next >= steps.length) {
            root.setOn(false)
            return
        }
        root.forMinutes(steps[next])
        root.stepIndex = next
    }

    function describe() {
        if (!root.on)
            return "off"
        return root.until > 0 ? "on, " + root.minutesLeft + " min left" : "on until turned off"
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.on && root.until > 0
        onTriggered: {
            root.now = Date.now()
            if (root.now >= root.until)
                root.setOn(false)
        }
    }

    // qs ipc call caffeine toggle           same as a left click
    // qs ipc call caffeine on | off
    // qs ipc call caffeine forMinutes 45    on for 45 minutes (0 = until off)
    // qs ipc call caffeine status
    IpcHandler {
        target: "caffeine"
        function toggle(): void { root.toggle() }
        function on(): void { root.setOn(true) }
        function off(): void { root.setOn(false) }
        function forMinutes(minutes: int): string { return root.forMinutes(minutes) ? root.describe() : "minutes must be 0 to 1440" }
        function status(): string { return root.describe() }
    }
}
