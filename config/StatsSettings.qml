pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Widgets → System Stats: which sections the pill draws, its font, the
// terminal and click that open btop or nvtop, and the color thresholds.
// Thresholds and colors are saved in theme/theme.json by Theme.
Singleton {
    id: root

    readonly property var metrics: ["cpu", "mem", "gpu", "vram"]

    readonly property Draft editor: Draft {
        owner: root
    }

    function terminalOk(name) {
        return /^[A-Za-z0-9._+-]{1,64}$/.test(String(name || ""))
    }

    function terminalNorm(name) {
        const text = String(name || "").trim()
        return root.terminalOk(text) ? text : "kitty"
    }

    function clickNorm(side) {
        return String(side || "") === "right" ? "right" : "left"
    }

    // Saved values, for the pill and the widget list.
    function terminalValue() {
        return root.terminalNorm(Config.statTerminal)
    }

    function clickValue() {
        return root.clickNorm(Config.statClick)
    }

    function fontPercentValue() {
        return Config.fontPercentNorm(Config.statFontPercent)
    }

    function anyShown() {
        return !!Config.showStatCpu || !!Config.showStatMem || !!Config.showStatGpu || !!Config.showStatVram
    }

    // btop and nvtop only. The terminal name is a saved token, never a shell line.
    function launchArgv(app) {
        const program = app === "nvtop" ? "nvtop" : (app === "btop" ? "btop" : "")
        if (!program.length)
            return []
        const term = root.terminalValue()
        if (term === "kitty")
            return [term, "--class", program, "--name", program, "--title", program, "-e", program]
        if (term === "foot" || term === "footclient")
            return [term, "--app-id", program, "--title", program, program]
        if (term === "alacritty")
            return [term, "--class", program, "-t", program, "-e", program]
        if (term === "ghostty")
            return [term, "--class=" + program, "--title=" + program, "-e", program]
        if (term === "wezterm")
            return [term, "start", "--class", program, "--", program]
        if (term === "gnome-terminal")
            return [term, "--title", program, "--", program]
        if (term === "xfce4-terminal" || term === "mate-terminal" || term === "terminator")
            return [term, "--title", program, "-x", program]
        if (term === "st")
            return [term, "-n", program, "-T", program, "-e", program]
        if (term === "xterm")
            return [term, "-name", program, "-T", program, "-e", program]
        if (term === "urxvt")
            return [term, "-name", program, "-title", program, "-e", program]
        return [term, "-e", program]
    }

    function themeBands() {
        const palette = Theme.palette
        return [palette.statUtilThreshold1, palette.statUtilThreshold2, palette.statUtilThreshold3]
    }

    function normTriple(raw) {
        const theme = root.themeBands()
        let low = theme[0]
        let mid = theme[1]
        let high = theme[2]
        if (raw && raw.length >= 3) {
            low = Config.bandStep(raw[0])
            mid = Config.bandStep(raw[1])
            high = Config.bandStep(raw[2])
        }
        mid = Math.max(mid, low)
        high = Math.max(high, mid)
        return [low, mid, high]
    }

    function entry(raw, metric) {
        const defaults = Theme.defaultStatVisual()[String(metric || "cpu")]
        let steps = null
        let colors = null
        if (raw && raw.length >= 3) {
            steps = raw
        } else if (raw && raw.t) {
            steps = raw.t
            colors = raw.c
        }
        return { t: root.normTriple(steps), c: Theme.normColors(colors, defaults.c) }
    }

    function bandsFrom(src) {
        const base = src || {}
        return {
            cpu: root.entry(base.cpu, "cpu"),
            mem: root.entry(base.mem, "mem"),
            gpu: root.entry(base.gpu, "gpu"),
            vram: root.entry(base.vram, "vram")
        }
    }

    // Thresholds from an older layout file, used until theme.json has them.
    function legacyBands() {
        const text = String(Config.statThresholdsJson || "").trim()
        if (!text.length)
            return null
        try {
            const parsed = JSON.parse(text)
            if (!parsed || typeof parsed !== "object" || parsed.length !== undefined)
                return null
            return root.bandsFrom(parsed)
        } catch (e) {
            return null
        }
    }

    // Saved steps for one metric, for the pill.
    function bandsFor(metric) {
        const key = String(metric || "")
        if (Theme.hasStatEntry(key))
            return Theme.statThresholds(key)
        const legacy = root.legacyBands()
        if (legacy && legacy[key])
            return legacy[key].t
        return root.themeBands()
    }

    function savedVisual() {
        const legacy = root.legacyBands()
        const out = {}
        for (let i = 0; i < root.metrics.length; i++) {
            const key = root.metrics[i]
            let steps = Theme.statThresholds(key)
            if (!Theme.hasStatEntry(key) && legacy && legacy[key])
                steps = legacy[key].t
            out[key] = { t: steps, c: Theme.statColors(key) }
        }
        return out
    }

    // Draft thresholds, for the settings page.
    function bandAt(metric, index) {
        const e = root.editor.value.bands[String(metric || "cpu")] || root.entry(null, "cpu")
        const slot = Math.round(Number(index))
        return slot >= 0 && slot <= 2 ? e.t[slot] : e.t[0]
    }

    function colorAt(metric, index) {
        const e = root.editor.value.bands[String(metric || "cpu")] || root.entry(null, "cpu")
        const slot = Math.round(Number(index))
        return slot >= 0 && slot <= 3 ? e.c[slot] : e.c[0]
    }

    function setBand(metric, index, value) {
        const key = String(metric || "")
        const slot = Math.round(Number(index))
        if (root.metrics.indexOf(key) < 0 || slot < 0 || slot > 2)
            return
        const all = root.bandsFrom(root.editor.value.bands)
        all[key] = Config.withBand(all[key], slot, value)
        root.editor.set("bands", all)
    }

    function setColor(metric, index, color) {
        const key = String(metric || "")
        const slot = Math.round(Number(index))
        if (root.metrics.indexOf(key) < 0 || slot < 0 || slot > 3)
            return
        const all = root.bandsFrom(root.editor.value.bands)
        const next = Config.withColor(all[key], slot, color)
        if (!next)
            return
        all[key] = next
        root.editor.set("bands", all)
    }

    // An unknown terminal name is ignored, not saved.
    function setTerminal(name) {
        const text = String(name || "").trim()
        if (root.terminalOk(text))
            root.editor.set("terminal", text)
    }

    function normalize(src) {
        return {
            cpu: !!src.cpu,
            mem: !!src.mem,
            gpu: !!src.gpu,
            vram: !!src.vram,
            gauges: !!src.gauges,
            terminal: root.terminalNorm(src.terminal),
            click: root.clickNorm(src.click),
            font: Config.fontClamp(src.font),
            fontPercent: Config.fontPercentNorm(src.fontPercent === undefined ? 100 : src.fontPercent),
            bold: src.bold !== false,
            italic: !!src.italic,
            bands: root.bandsFrom(src.bands)
        }
    }

    function snapshot() {
        return root.normalize({
            cpu: Config.showStatCpu,
            mem: Config.showStatMem,
            gpu: Config.showStatGpu,
            vram: Config.showStatVram,
            gauges: Config.showStatGauges,
            terminal: Config.statTerminal,
            click: Config.statClick,
            font: Config.statFont,
            fontPercent: root.fontPercentValue(),
            bold: Config.statBold,
            italic: Config.statItalic,
            bands: root.savedVisual()
        })
    }

    function defaults() {
        return {
            cpu: true,
            mem: true,
            gpu: true,
            vram: true,
            gauges: true,
            terminal: "kitty",
            click: "left",
            font: "",
            fontPercent: Theme.clockFontDefault,
            bold: true,
            italic: false,
            bands: Theme.defaultStatVisual()
        }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.showStatCpu = clean.cpu
            Config.showStatMem = clean.mem
            Config.showStatGpu = clean.gpu
            Config.showStatVram = clean.vram
            Config.showStatGauges = clean.gauges
            Config.statTerminal = clean.terminal
            Config.statClick = clean.click
            Config.statFont = clean.font
            Config.statFontPercent = clean.fontPercent
            Config.statBold = clean.bold
            Config.statItalic = clean.italic
            Config.statThresholdsJson = ""
        })
        Theme.saveStats(clean.bands)
    }
}
