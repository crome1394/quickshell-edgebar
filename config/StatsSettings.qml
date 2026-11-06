pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Widgets → System Stats: which sections the pill draws, its font, the
// terminal and the left/right click commands, and the color thresholds.
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

    // Saved values, for the pill and the widget list.
    function terminalValue() {
        return root.terminalNorm(Config.statTerminal)
    }

    function fontPercentValue() {
        return Config.fontPercentNorm(Config.statFontPercent)
    }

    function anyShown() {
        return !!Config.showStatCpu || !!Config.showStatMem || !!Config.showStatGpu || !!Config.showStatVram
    }

    // What a click on a stats group runs: a command line per group and
    // button, optionally inside the chosen terminal. Never a shell.
    readonly property var actionSlots: [
        { id: "cpuLeft", group: "cpu", button: "left", label: "CPU · Memory, left click" },
        { id: "cpuRight", group: "cpu", button: "right", label: "CPU · Memory, right click" },
        { id: "gpuLeft", group: "gpu", button: "left", label: "GPU · VRAM, left click" },
        { id: "gpuRight", group: "gpu", button: "right", label: "GPU · VRAM, right click" }
    ]

    // btop and nvtop on the button the older click setting chose.
    function defaultActions() {
        const side = String(Config.statClick || "") === "right" ? "Right" : "Left"
        const other = side === "Left" ? "Right" : "Left"
        const out = {}
        out["cpu" + side] = { cmd: "btop", term: true }
        out["gpu" + side] = { cmd: "nvtop", term: true }
        out["cpu" + other] = { cmd: "", term: false }
        out["gpu" + other] = { cmd: "", term: false }
        return out
    }

    function actionsNorm(raw) {
        const src = raw && typeof raw === "object" ? raw : {}
        const out = {}
        for (let i = 0; i < root.actionSlots.length; i++) {
            const id = root.actionSlots[i].id
            const a = src[id] || {}
            let cmd = String(a.cmd || "").replace(/[\r\n]/g, " ")
            if (cmd.length > Theme.menuCommandMax)
                cmd = cmd.substring(0, Theme.menuCommandMax)
            out[id] = { cmd: cmd, term: !!a.term }
        }
        return out
    }

    function savedActions() {
        const text = String(Config.statActionsJson || "").trim()
        if (!text.length)
            return root.actionsNorm(root.defaultActions())
        try {
            return root.actionsNorm(JSON.parse(text))
        } catch (e) {
            return root.actionsNorm(root.defaultActions())
        }
    }

    // The first action whose command line is not allowed, or "".
    function badAction(actions) {
        const a = root.actionsNorm(actions)
        for (let i = 0; i < root.actionSlots.length; i++) {
            const slot = root.actionSlots[i]
            if (Config.commandArgv(a[slot.id].cmd, Theme.menuCommandMax) === null)
                return slot.label
        }
        return ""
    }

    // Wrap argv so the terminal runs it. No class or app-id flags, so the
    // window keeps the terminal's own class and its window rules apply.
    function terminalArgv(argv) {
        const term = root.terminalValue()
        if (term === "kitty" || term === "foot" || term === "footclient")
            return [term].concat(argv)
        if (term === "wezterm")
            return [term, "start", "--"].concat(argv)
        if (term === "gnome-terminal" || term === "kgx" || term === "ptyxis")
            return [term, "--"].concat(argv)
        if (term === "xfce4-terminal" || term === "mate-terminal" || term === "terminator")
            return [term, "-x"].concat(argv)
        return [term, "-e"].concat(argv)
    }

    // argv for a click on a group ("cpu" or "gpu"), or [] for nothing.
    function actionArgv(group, button) {
        const id = String(group) + (button === "right" ? "Right" : "Left")
        const a = root.savedActions()[id]
        if (!a)
            return []
        const argv = Config.commandArgv(a.cmd, Theme.menuCommandMax)
        if (!argv || !argv.length)
            return []
        return a.term ? root.terminalArgv(argv) : argv
    }

    // Hover text for a group, e.g. "Left: btop · Right: nothing".
    function actionHint(group) {
        const all = root.savedActions()
        const left = all[group + "Left"].cmd.trim()
        const right = all[group + "Right"].cmd.trim()
        return "Left: " + (left.length ? left : "nothing") + " · Right: " + (right.length ? right : "nothing")
    }

    function setAction(id, field, next) {
        const all = root.actionsNorm(root.editor.value.actions)
        if (!all[id])
            return
        all[id][field] = next
        root.editor.set("actions", all)
    }

    // False, with nothing saved, when a command line is not allowed.
    function apply() {
        if (!root.editor.dirty)
            return true
        if (root.badAction(root.editor.draft.actions).length)
            return false
        root.editor.apply()
        return true
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
            actions: root.actionsNorm(src.actions),
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
            actions: root.savedActions(),
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
            actions: root.actionsNorm({ cpuLeft: { cmd: "btop", term: true }, gpuLeft: { cmd: "nvtop", term: true } }),
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
            Config.statActionsJson = JSON.stringify(clean.actions)
            Config.statFont = clean.font
            Config.statFontPercent = clean.fontPercent
            Config.statBold = clean.bold
            Config.statItalic = clean.italic
            Config.statThresholdsJson = ""
        })
        Theme.saveStats(clean.bands)
    }
}
