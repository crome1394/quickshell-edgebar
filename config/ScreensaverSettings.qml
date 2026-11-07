pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Tools → Screensaver: value helpers and the page draft. The saved values
// are not in bar-layout.json: they live in ~/.config/hypr/screensaver.conf,
// owned by scripts/screensaver-config.sh. ScreensaverService reads
// them into `saved` and writes them when commit() asks for a save.
//
// The program runs as `<program> start` after idle and `<program> stop`
// on activity. A blank program means the built-in screensaver.sh.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property string home: String(Quickshell.env("HOME") || "")
    // In the bar's scripts/ (install-deps.sh links them into ~/.local/bin).
    readonly property string helperPath: Quickshell.shellDir + "/scripts/screensaver-config.sh"
    readonly property string builtInProgram: Quickshell.shellDir + "/scripts/screensaver.sh"
    readonly property string defaultVideo: root.home + "/Videos/screensaver/screensaver.mp4"

    // The Look choices: Video, or one of the built-in text styles.
    readonly property var styles: [
        { id: "video", label: "Video", tip: "Loop a video file with mpv" },
        { id: "night", label: "Night watch", tip: "Text saver: quiet night sky" },
        { id: "rain", label: "Rain", tip: "Text saver: falling characters" },
        { id: "orbital", label: "Orbital", tip: "Text saver: orbiting points" },
        { id: "warp", label: "Warp", tip: "Text saver: star field" },
        { id: "pyro", label: "Pyro", tip: "Text saver: fireworks" },
        { id: "scanner", label: "Scanner", tip: "Text saver: sweeping scanner" }
    ]

    // Last values read from the helper, already normalized. Set by the service.
    property var saved: root.defaults()
    property bool loaded: false

    signal saveRequested(var values)

    function styleOk(id) {
        return root.styles.some((s) => s.id === id)
    }

    function intIn(value, lo, hi, fallback) {
        const n = Math.round(Number(value))
        if (!isFinite(n))
            return fallback
        return Math.max(lo, Math.min(hi, n))
    }

    // One line, no control characters, ~ kept (the helper expands it).
    // Not trimmed, so a field can be typed into; pathArg() trims for saving.
    function pathClean(text) {
        return String(text || "").replace(/[\x00-\x1f\x7f]/g, "").substring(0, Theme.toolPathMax)
    }

    function pathArg(text) {
        return root.pathClean(text).trim()
    }

    // Blank (built-in), or an absolute or ~/ path. Bare names are refused:
    // the helper runs the program by path and checks it is executable.
    function programOk(text) {
        const p = root.pathArg(text)
        return p.length === 0 || p.charAt(0) === "/" || p.indexOf("~/") === 0
    }

    function isBuiltIn(text) {
        const p = root.pathArg(text)
        return p.length === 0 || p === root.builtInProgram || p === "~/.local/bin/screensaver.sh" || p === root.home + "/.local/bin/screensaver.sh"
    }

    function timeoutLabel(minutes) {
        const m = Math.round(Number(minutes) || 0)
        if (m < 60)
            return m + " min"
        const h = Math.floor(m / 60)
        const rest = m % 60
        return rest ? h + " h " + rest + " min" : h + " h"
    }

    // ── Draft ───────────────────────────────────────────────────────────
    function normalize(src) {
        const s = src || {}
        const style = root.styleOk(s.style) && s.style !== "video" ? String(s.style) : "night"
        return {
            enabled: s.enabled !== false,
            timeoutMin: root.intIn(s.timeoutMin, Theme.screensaverMinutesMin, Theme.screensaverMinutesMax, Theme.screensaverMinutesDefault),
            ignoreInhibit: s.ignoreInhibit === true,
            program: root.pathClean(s.program),
            mode: s.mode === "video" ? "video" : "text",
            style: style,
            video: root.pathClean(s.video),
            clock: s.clock !== false,
            warpSpeed: root.intIn(s.warpSpeed, 1, 10, 4),
            warpDensity: root.intIn(s.warpDensity, 1, 10, 5),
            warpStreak: root.intIn(s.warpStreak, 1, 10, 6),
            dimEnable: s.dimEnable === true,
            dimLevel: root.intIn(s.dimLevel, 0, 100, 10),
            restoreEnable: s.restoreEnable === true,
            restoreLevel: root.intIn(s.restoreLevel, 0, 100, 80)
        }
    }

    function snapshot() {
        return root.normalize(root.saved)
    }

    function defaults() {
        return root.normalize({
            enabled: true,
            timeoutMin: Theme.screensaverMinutesDefault,
            ignoreInhibit: false,
            program: root.builtInProgram,
            mode: "text",
            style: "night",
            video: root.defaultVideo,
            clock: true
        })
    }

    function commit(obj) {
        root.saveRequested(root.normalize(obj))
    }

    // The helper's `get` JSON → draft fields.
    function fromHelper(j) {
        const sec = Number(j.timeout_sec)
        return root.normalize({
            enabled: !!j.enabled,
            timeoutMin: sec > 0 ? Math.round(sec / 60) : Theme.screensaverMinutesDefault,
            ignoreInhibit: !!j.ignore_inhibit,
            program: j.script,
            mode: j.mode,
            style: j.style,
            video: j.video,
            clock: !!j.clock,
            warpSpeed: j.warp_speed,
            warpDensity: j.warp_density,
            warpStreak: j.warp_streak,
            dimEnable: !!j.dim_enable,
            dimLevel: j.dim_level,
            restoreEnable: !!j.restore_enable,
            restoreLevel: j.restore_level
        })
    }

    // The Look box shows one id for mode + style.
    function lookId(n) {
        return n.mode === "video" ? "video" : n.style
    }

    // Draft fields → `set` arguments. Every value is already clamped; each
    // is its own argv entry, so nothing is parsed by a shell.
    function setArgs(obj) {
        const n = root.normalize(obj)
        return [
            "--enabled", n.enabled ? "1" : "0",
            "--timeout-sec", String(n.timeoutMin * 60),
            "--ignore-inhibit", n.ignoreInhibit ? "1" : "0",
            "--script", root.pathArg(n.program),
            "--mode", n.mode,
            "--style", n.style,
            "--video", root.pathArg(n.video),
            "--clock", n.clock ? "1" : "0",
            "--warp-speed", String(n.warpSpeed),
            "--warp-density", String(n.warpDensity),
            "--warp-streak", String(n.warpStreak),
            "--dim-enable", n.dimEnable ? "1" : "0",
            "--dim-level", String(n.dimLevel),
            "--restore-enable", n.restoreEnable ? "1" : "0",
            "--restore-level", String(n.restoreLevel)
        ]
    }
}
