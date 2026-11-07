pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Monitor modes for Settings → System → Display. Works on any machine:
// monitors, modes, and 10-bit support come from Hyprland at runtime.
// Nothing runs unless the Display page is open (retain/release).
//
// Apply (a mode) or applyLayout (monitor positions) sets the change live,
// checks that Hyprland kept it, then waits for Keep in DisplayConfirmPanel,
// a small window centered on the monitor. Settings steps aside meanwhile
// (tryStarted / tryEnded) and comes back on the Display page. With no Keep
// before the countdown ends, the old setup comes back.
// Keep saves to a monitors file only when one already carries the
// "Managed by Quickshell" marker; otherwise the change lasts until
// Hyprland restarts. Every command is a fixed argv, never a shell.
Singleton {
    id: root

    property int watchers: 0
    property var monitors: []
    property bool loading: false
    property bool busy: false
    property string error: ""
    property string notice: ""

    // While a change waits for Keep: { kind: "mode" | "layout", specs, label }.
    property var pending: null
    // The specs to send back on Go back.
    property var previous: null
    property int countdown: 0

    signal tryStarted()
    signal tryEnded()

    // Counts finished applies, and which count each monitor read started
    // after, so the page can tell fresh monitor data from stale.
    property int applySerial: 0
    property int monitorSerial: 0
    readonly property bool settled: !root.busy && root.monitorSerial === root.applySerial

    // The monitors file Keep writes, or "" when there is none to manage.
    property string managedFile: ""
    readonly property string configHome: {
        const xdg = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        const home = String(Quickshell.env("HOME") || "")
        return xdg.length ? xdg : (home.length ? home + "/.config" : "")
    }
    readonly property var fileCandidates: root.configHome.length
        ? [root.configHome + "/hypr/config/monitors.lua", root.configHome + "/hypr/monitors.lua"]
        : []

    property int verifyTries: 0
    property bool useKeyword: false

    function retain() {
        root.watchers += 1
        if (root.watchers === 1) {
            root.refresh()
            root.findFile(0)
        }
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function refresh() {
        if (monitorProc.running)
            return
        root.loading = true
        monitorProc.startedAt = root.applySerial
        monitorProc.running = true
    }

    function monitorNamed(name) {
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === name)
                return root.monitors[i]
        }
        return null
    }

    function readMonitors(text) {
        let raw = []
        try {
            raw = JSON.parse(String(text || "[]"))
        } catch (e) {
            root.error = "Could not read the monitor list from Hyprland."
            return
        }
        const out = []
        for (let i = 0; i < raw.length; i++) {
            const m = raw[i] || {}
            if (!DisplaySettings.outputOk(m.name))
                continue
            const hw = m.hardwareDetails || {}
            const depth = DisplaySettings.depthFromFormat(m.currentFormat)
            const groups = DisplaySettings.groupModes(m.availableModes)
            const current = DisplaySettings.parseMode(m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2))
            out.push({
                name: String(m.name),
                label: String(m.description || m.model || m.name),
                disabled: !!m.disabled,
                width: Number(m.width) || 0,
                height: Number(m.height) || 0,
                hz: Number(m.refreshRate) || 0,
                mode: current ? current.mode : "",
                depth: depth,
                // 10-bit when the monitor is HDR-capable or already runs it.
                tenBit: depth === 10 || !!hw.hdr,
                x: Number(m.x) || 0,
                y: Number(m.y) || 0,
                scale: Number(m.scale) || 1,
                transform: Number(m.transform) || 0,
                groups: groups
            })
        }
        root.monitors = out
        if (!out.length)
            root.error = "Hyprland reported no monitors."
    }

    // The mode in a monitor's own list nearest to its live refresh rate.
    function liveMode(monitor) {
        if (!monitor)
            return ""
        let best = ""
        let gap = 1e9
        for (let g = 0; g < monitor.groups.length; g++) {
            const group = monitor.groups[g]
            if (group.w !== monitor.width || group.h !== monitor.height)
                continue
            for (let r = 0; r < group.rates.length; r++) {
                const d = Math.abs(group.rates[r].hz - monitor.hz)
                if (d < gap) {
                    gap = d
                    best = group.rates[r].mode
                }
            }
        }
        return gap <= 0.6 ? best : monitor.mode
    }

    function specFor(monitor, mode, depth) {
        return {
            output: monitor.name,
            mode: mode,
            depth: depth,
            x: monitor.x,
            y: monitor.y,
            scale: monitor.scale,
            transform: monitor.transform
        }
    }

    function modeListed(monitor, mode) {
        for (let g = 0; g < monitor.groups.length; g++) {
            if (monitor.groups[g].rates.some((r) => r.mode === mode))
                return true
        }
        return false
    }

    // Hyprland's older monitor= syntax, for configs without hyprctl eval.
    function keywordValue(spec) {
        const mode = DisplaySettings.parseMode(spec.mode)
        const parts = [spec.output, mode.w + "x" + mode.h + "@" + mode.hz.toFixed(2),
            Math.round(spec.x) + "x" + Math.round(spec.y), Number(spec.scale).toFixed(2),
            "bitdepth", String(spec.depth)]
        if (spec.transform)
            parts.push("transform", String(spec.transform))
        return parts.join(",")
    }

    // Send monitor specs in one Hyprland call.
    function send(specs) {
        const list = Array.isArray(specs) ? specs : [specs]
        const lines = list.map((sp) => DisplaySettings.luaMonitor(sp))
        if (!list.length || lines.some((l) => !l.length)) {
            root.error = "That change could not be checked, so it was not sent."
            return false
        }
        applyProc.specs = list
        applyProc.command = root.useKeyword
            ? ["hyprctl", "--batch", list.map((sp) => "keyword monitor " + root.keywordValue(sp)).join(" ; ")]
            : ["hyprctl", "eval", lines.join("\n")]
        root.busy = true
        applyProc.running = true
        return true
    }

    function begin(kind, label, previous, next) {
        root.error = ""
        root.notice = ""
        root.previous = previous
        root.pending = { kind: kind, specs: next, label: label }
        if (!root.send(next)) {
            root.pending = null
            root.previous = null
            return
        }
        root.tryStarted()
    }

    function end() {
        root.pending = null
        root.previous = null
        root.tryEnded()
    }

    // Try a mode. The current one is kept to go back to.
    function apply(name, mode, depth) {
        if (root.busy || root.pending)
            return
        const monitor = root.monitorNamed(name)
        if (!monitor || !root.modeListed(monitor, mode) || !DisplaySettings.depthOk(depth)) {
            root.error = "That mode is not in this monitor's list."
            return
        }
        if (Number(depth) === 10 && !monitor.tenBit) {
            root.error = "This monitor does not report 10-bit color."
            return
        }
        const p = DisplaySettings.parseMode(mode)
        root.begin("mode", p.w + " × " + p.h + " at " + Math.round(p.hz) + " Hz, " + depth + "-bit",
            [root.specFor(monitor, root.liveMode(monitor), monitor.depth)],
            [root.specFor(monitor, mode, Number(depth))])
    }

    // Try new monitor positions: { name: { x, y } }. Monitors left out stay put.
    function applyLayout(positions) {
        if (root.busy || root.pending)
            return
        const before = []
        const after = []
        for (let i = 0; i < root.monitors.length; i++) {
            const m = root.monitors[i]
            const want = positions[m.name]
            if (m.disabled || !want)
                continue
            const x = Math.round(Number(want.x))
            const y = Math.round(Number(want.y))
            if (!isFinite(x) || !isFinite(y) || (x === m.x && y === m.y))
                continue
            const spec = root.specFor(m, root.liveMode(m), m.depth)
            before.push(spec)
            after.push(Object.assign({}, spec, { x: x, y: y }))
        }
        if (!after.length) {
            root.notice = "The arrangement is already in place."
            return
        }
        root.begin("layout", "the new arrangement", before, after)
    }

    function revert(reason) {
        confirmTimer.stop()
        root.countdown = 0
        const back = root.previous
        root.end()
        if (reason)
            root.notice = reason
        if (back)
            root.send(back)
    }

    function keep() {
        if (!root.pending)
            return
        confirmTimer.stop()
        root.countdown = 0
        const kept = root.pending.specs
        root.end()
        root.save(kept)
    }

    // After an apply: does Hyprland show what we asked for?
    function verify() {
        const job = root.pending
        if (!job)
            return
        let failed = null
        let depthFailed = false
        for (let i = 0; i < job.specs.length; i++) {
            const spec = job.specs[i]
            const monitor = root.monitorNamed(spec.output)
            if (!monitor) {
                failed = spec
                break
            }
            const want = DisplaySettings.parseMode(spec.mode)
            const modeHeld = monitor.width === want.w && monitor.height === want.h && Math.abs(monitor.hz - want.hz) <= 0.6
            const depthHeld = monitor.depth === spec.depth
            const placeHeld = Math.abs(monitor.x - spec.x) <= 1 && Math.abs(monitor.y - spec.y) <= 1
            if (!modeHeld || !depthHeld || !placeHeld) {
                failed = spec
                depthFailed = modeHeld && !depthHeld
                break
            }
        }
        if (!failed) {
            root.countdown = Theme.displayConfirmSeconds
            confirmTimer.restart()
            return
        }
        if (root.verifyTries < 2) {
            root.verifyTries += 1
            settleTimer.restart()
            return
        }
        if (job.kind === "layout") {
            root.revert("Hyprland did not take the new arrangement, so the old one is back.")
            return
        }
        DisplaySettings.markRejected(failed.output, failed.mode, failed.depth)
        root.revert(depthFailed
            ? "This monitor would not keep " + failed.depth + "-bit at " + failed.mode + ". That pair is now marked as not supported."
            : "Hyprland did not switch to " + failed.mode + ". It is now marked as not supported.")
    }

    function save(kept) {
        if (!root.managedFile.length) {
            root.notice = "Applied. It lasts until Hyprland restarts: no monitors file with the \"" + DisplaySettings.fileMarker + "\" marker was found."
            return
        }
        const specs = []
        for (let i = 0; i < root.monitors.length; i++) {
            const m = root.monitors[i]
            if (m.disabled)
                continue
            const mine = kept.find((k) => k.output === m.name)
            specs.push(mine ? mine : root.specFor(m, root.liveMode(m), m.depth))
        }
        const stamp = new Date().toISOString()
        const text = DisplaySettings.monitorsFile(specs, stamp)
        if (!text.length) {
            root.error = "Applied, but the monitors file was not written: a value did not pass its check."
            return
        }
        managed.setText(text)
        root.notice = "Saved to " + root.managedFile
    }

    // Look for a monitors file that says the bar manages it.
    function findFile(index) {
        if (index >= root.fileCandidates.length) {
            root.managedFile = ""
            probe.path = ""
            return
        }
        probe.index = index
        probe.path = root.fileCandidates[index]
    }

    FileView {
        id: probe
        property int index: 0
        printErrors: false
        onLoaded: {
            if (String(probe.text()).indexOf(DisplaySettings.fileMarker) >= 0) {
                root.managedFile = probe.path
                managed.path = probe.path
                probe.path = ""
            } else {
                root.findFile(probe.index + 1)
            }
        }
        onLoadFailed: root.findFile(probe.index + 1)
    }

    FileView {
        id: managed
        atomicWrites: true
        printErrors: true
        onSaveFailed: root.error = "Could not write " + root.managedFile
    }

    Process {
        id: monitorProc
        property int startedAt: 0
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            id: monitorOut
            waitForEnd: true
        }
        onExited: (code) => {
            root.loading = false
            if (code !== 0) {
                root.error = "hyprctl is not available, so monitors cannot be read."
                return
            }
            root.monitorSerial = monitorProc.startedAt
            root.readMonitors(monitorOut.text)
            if (root.pending && !confirmTimer.running)
                root.verify()
        }
    }

    Process {
        id: applyProc
        property var specs: []
        stdout: StdioCollector {
            id: applyOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: applyErr
            waitForEnd: true
        }
        onExited: (code) => {
            root.busy = false
            root.applySerial += 1
            const said = [String(applyOut.text), String(applyErr.text)].join("").trim()
            const ok = code === 0 && !/^error/i.test(said)
            // hyprctl without Lua config: retry once with the older keyword form.
            if (!ok && !root.useKeyword && /unknown request|invalid command|not supported/i.test(said)) {
                root.useKeyword = true
                root.send(applyProc.specs)
                return
            }
            if (!ok) {
                root.error = "Hyprland refused the change: " + (said.length ? said : "exit " + code)
                if (root.pending && applyProc.specs === root.pending.specs)
                    root.end()
                root.refresh()
                return
            }
            root.verifyTries = 0
            if (root.pending && applyProc.specs === root.pending.specs)
                settleTimer.restart()
            else
                root.refresh()
        }
    }

    // Give the monitor time to retrain before reading its state back.
    Timer {
        id: settleTimer
        interval: Theme.displaySettleMs
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: confirmTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1
            if (root.countdown <= 0)
                root.revert("No answer, so the previous mode is back.")
        }
    }
}
