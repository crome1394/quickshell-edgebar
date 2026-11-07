pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Built-in screen brightness from /sys/class/backlight. Reading is a file
// read; setting goes through logind (SetBrightness on your session), so no
// root, setuid helper, or udev rule is needed. `available` is false on a
// desktop with external monitors only, so the Brightness pill hides itself.
// The level is read when asked (hover, wheel, IPC), not polled.
//
// IPC (qs ipc call brightness …), the same functions the pill uses:
//   status       "60%"
//   set <pct>    1–100
//   up / down    one step (Theme.brightnessStep)
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int level: 0
    property bool checked: false
    // A level waiting while logind handles the previous one.
    property int queued: -1

    readonly property bool available: root.device.length > 0 && root.max > 0
    readonly property int percent: root.available ? Math.round(root.level * 100 / root.max) : 0

    // One line per device: name|type|max_brightness. Prefer firmware, then
    // platform, then raw (the order desktops use), then the finest scale.
    function pickDevice(text) {
        const rank = { firmware: 0, platform: 1, raw: 2 }
        let best = null
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const f = lines[i].split("|")
            if (f.length !== 3 || !/^[A-Za-z0-9_.:-]{1,64}$/.test(f[0]))
                continue
            const max = Number(f[2])
            if (!(max > 0))
                continue
            const r = rank[f[1]] !== undefined ? rank[f[1]] : 3
            if (!best || r < best.r || (r === best.r && max > best.max))
                best = { name: f[0], r: r, max: max }
        }
        return best ? { name: best.name, max: best.max } : null
    }

    function refresh() {
        if (root.available)
            levelFile.reload()
    }

    // Percent to a raw level, never fully dark.
    function rawFor(pct) {
        const p = Math.max(Theme.brightnessMinPercent, Math.min(100, Math.round(Number(pct))))
        return Math.max(1, Math.round(p * root.max / 100))
    }

    function setPercent(pct) {
        if (!root.available || isNaN(Number(pct)))
            return false
        const raw = root.rawFor(pct)
        root.level = raw
        if (setter.running) {
            root.queued = raw
            return true
        }
        setter.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
            "org.freedesktop.login1.Session", "SetBrightness", "ssu", "backlight", root.device, String(raw)]
        setter.running = true
        return true
    }

    function step(dir) {
        root.refresh()
        root.setPercent(root.percent + (dir > 0 ? Theme.brightnessStep : -Theme.brightnessStep))
    }

    // Left click on the pill: 25, 50, 75, 100 %, then round again.
    function cycle() {
        root.refresh()
        const steps = Theme.brightnessSteps
        const next = steps.find((s) => s > root.percent + 1)
        root.setPercent(next !== undefined ? next : steps[0])
    }

    // Fixed script, no outside input; prints each device once.
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -r \"$d/max_brightness\" ] || continue; "
            + "printf '%s|%s|%s\\n' \"${d##*/}\" \"$(cat \"$d/type\" 2>/dev/null)\" \"$(cat \"$d/max_brightness\")\"; done"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: {
            const pick = root.pickDevice(listOut.text)
            if (pick) {
                root.max = pick.max
                root.device = pick.name
            }
            root.checked = true
        }
    }

    FileView {
        id: levelFile
        path: root.available ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        blockLoading: true
        printErrors: false
        onLoaded: {
            const n = Number(String(levelFile.text()).trim())
            if (n >= 0)
                root.level = n
        }
    }

    Process {
        id: setter
        onExited: {
            if (root.queued >= 0) {
                const next = root.queued
                root.queued = -1
                root.setPercent(next * 100 / root.max)
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function status(): string {
            root.refresh()
            return root.available ? root.percent + "%" : "no backlight"
        }

        function set(pct: string): string {
            if (!/^[0-9]{1,3}$/.test(pct) || Number(pct) > 100)
                return "give a percent, 1–100"
            return root.setPercent(Number(pct)) ? "ok" : "no backlight"
        }

        function up(): string {
            root.step(1)
            return root.percent + "%"
        }

        function down(): string {
            root.step(-1)
            return root.percent + "%"
        }
    }
}
