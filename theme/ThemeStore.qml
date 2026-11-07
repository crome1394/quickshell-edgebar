pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The active look, saved in state/theme.json: the theme (themeJson) and
// the stat and audio threshold steps and colors (statsJson, audioJson).
// Empty fields keep the defaults (Liquid amber, DefaultTheme.qml). Older
// setups kept the thresholds in theme/theme.json; they are copied over once.
//
// Also the lookups the pills use: which color a stat or volume level gets.
// Theme holds the sizes and the live palette built from activeTheme.
Singleton {
    id: root

    // The saved theme, cleaned. Liquid amber until one is applied.
    readonly property var activeTheme: ThemeBuilder.normalize(root.parsedObject(root.themeJson) || ThemePresets.defaultTheme())

    function statUtilColor(util, metric, t1, t2, t3) {
        const kind = String(metric || "")
        const colors = root.statColors(kind)
        let u = Number(util)
        if (!(u >= 0))
            u = 0
        else if (u > 100)
            u = 100
        let lowAt = Number(t1)
        let midAt = Number(t2)
        let highAt = Number(t3)
        if (!(lowAt >= 0) || !(midAt >= 0) || !(highAt >= 0)) {
            const saved = root.statThresholds(kind)
            lowAt = saved[0]
            midAt = saved[1]
            highAt = saved[2]
        }
        if (u <= lowAt)
            return colors[0]
        if (u <= midAt)
            return colors[1]
        if (u <= highAt)
            return colors[2]
        return colors[3]
    }

    function statTempColor(temp) {
        const p = Theme.palette
        let t = Math.round(Number(temp))
        if (!(t >= 0))
            t = 0
        if (t > p.statTempHotAt)
            return p.colStatTempHot
        if (t > p.statTempWarmAt)
            return p.colStatTempWarm
        return p.colStatTempCool
    }

    property bool themeReady: false
    property bool themeApplying: false
    property bool themeWriting: false
    property bool themeLegacy: false
    property alias themeJson: themeStore.themeJson
    property alias statsJson: themeStore.statsJson
    property alias audioJson: themeStore.audioJson

    function colorHex(value) {
        const text = String(value === undefined || value === null ? "" : value)
        if (text.length < 4)
            return ""
        const color = Qt.color(text)
        const byte = (channel) => {
            const n = Math.round(Math.max(0, Math.min(1, Number(channel))) * 255)
            const hex = n.toString(16)
            return hex.length < 2 ? "0" + hex : hex
        }
        return "#" + byte(color.r) + byte(color.g) + byte(color.b)
    }

    function normSteps(raw, fallback) {
        const base = fallback && fallback.length >= 3 ? fallback : [25, 50, 75]
        let low = base[0]
        let mid = base[1]
        let high = base[2]
        if (raw && raw.length >= 3) {
            low = Math.round(Number(raw[0]) / 5) * 5
            mid = Math.round(Number(raw[1]) / 5) * 5
            high = Math.round(Number(raw[2]) / 5) * 5
        }
        if (!(low >= 0))
            low = 0
        if (low > 100)
            low = 100
        if (!(mid >= low))
            mid = low
        if (mid > 100)
            mid = 100
        if (!(high >= mid))
            high = mid
        if (high > 100)
            high = 100
        return [low, mid, high]
    }

    function normColors(raw, fallback) {
        const base = fallback && fallback.length >= 4 ? fallback : ["#10b981", "#f59e0b", "#f97316", "#ef4444"]
        const out = [base[0], base[1], base[2], base[3]]
        if (!raw || raw.length < 4)
            return out
        for (let i = 0; i < 4; i++) {
            const hex = root.colorHex(raw[i])
            if (hex.length)
                out[i] = hex
        }
        return out
    }

    function defaultStatColors(metric) {
        const p = DefaultTheme
        const kind = String(metric || "")
        if (kind === "cpu")
            return [root.colorHex(p.colStatCpu1), root.colorHex(p.colStatCpu2), root.colorHex(p.colStatCpu3), root.colorHex(p.colStatCpu4)]
        if (kind === "mem")
            return [root.colorHex(p.colStatMem1), root.colorHex(p.colStatMem2), root.colorHex(p.colStatMem3), root.colorHex(p.colStatMem4)]
        if (kind === "gpu")
            return [root.colorHex(p.colStatGpu1), root.colorHex(p.colStatGpu2), root.colorHex(p.colStatGpu3), root.colorHex(p.colStatGpu4)]
        if (kind === "vram")
            return [root.colorHex(p.colStatVram1), root.colorHex(p.colStatVram2), root.colorHex(p.colStatVram3), root.colorHex(p.colStatVram4)]
        return [root.colorHex(p.colStatUtil1), root.colorHex(p.colStatUtil2), root.colorHex(p.colStatUtil3), root.colorHex(p.colStatUtil4)]
    }

    function defaultStatSteps() {
        return [DefaultTheme.statUtilThreshold1, DefaultTheme.statUtilThreshold2, DefaultTheme.statUtilThreshold3]
    }

    function defaultStatVisual() {
        const steps = root.defaultStatSteps()
        return {
            cpu: { t: steps.slice(), c: root.defaultStatColors("cpu") },
            mem: { t: steps.slice(), c: root.defaultStatColors("mem") },
            gpu: { t: steps.slice(), c: root.defaultStatColors("gpu") },
            vram: { t: steps.slice(), c: root.defaultStatColors("vram") }
        }
    }

    function defaultAudioVisual() {
        return {
            t: [DefaultTheme.audioUtilThreshold1, DefaultTheme.audioUtilThreshold2, DefaultTheme.audioUtilThreshold3],
            c: [root.colorHex(DefaultTheme.colAudio1), root.colorHex(DefaultTheme.colAudio2), root.colorHex(DefaultTheme.colAudio3), root.colorHex(DefaultTheme.colAudio4)]
        }
    }

    function parsedObject(text) {
        const body = String(text || "").trim()
        if (!body.length)
            return null
        try {
            const parsed = JSON.parse(body)
            if (!parsed || typeof parsed !== "object" || parsed.length !== undefined)
                return null
            return parsed
        } catch (e) {
            return null
        }
    }

    function hasStatEntry(metric) {
        const all = root.parsedObject(root.statsJson)
        if (!all)
            return false
        const row = all[String(metric || "")]
        return !!(row && row.t && row.t.length >= 3 && row.c && row.c.length >= 4)
    }

    function statThresholds(metric) {
        const key = String(metric || "cpu")
        const fallback = root.defaultStatSteps()
        if (!root.hasStatEntry(key))
            return fallback.slice()
        return root.normSteps(root.parsedObject(root.statsJson)[key].t, fallback)
    }

    function statColors(metric) {
        const key = String(metric || "cpu")
        const fallback = root.defaultStatColors(key)
        if (!root.hasStatEntry(key))
            return fallback.slice()
        return root.normColors(root.parsedObject(root.statsJson)[key].c, fallback)
    }

    function hasAudioEntry() {
        const row = root.parsedObject(root.audioJson)
        return !!(row && row.t && row.t.length >= 3 && row.c && row.c.length >= 4)
    }

    function audioVisual() {
        const base = root.defaultAudioVisual()
        if (!root.hasAudioEntry())
            return { t: base.t.slice(), c: base.c.slice() }
        const row = root.parsedObject(root.audioJson)
        return {
            t: root.normSteps(row.t, base.t),
            c: root.normColors(row.c, base.c)
        }
    }

    function audioSpeakerColor(percent) {
        const visual = root.audioVisual()
        let u = Number(percent)
        if (!(u >= 0))
            u = 0
        if (u <= visual.t[0])
            return visual.c[0]
        if (u <= visual.t[1])
            return visual.c[1]
        if (u <= visual.t[2])
            return visual.c[2]
        return visual.c[3]
    }

    // A change during a write saves again when that write ends.
    property bool themeSavePending: false

    function queueThemeSave() {
        if (!root.themeReady || root.themeApplying)
            return
        if (root.themeWriting) {
            root.themeSavePending = true
            return
        }
        root.themeWriting = true
        themeFile.writeAdapter()
    }

    function themeSaveDone() {
        root.themeWriting = false
        if (root.themeSavePending) {
            root.themeSavePending = false
            root.queueThemeSave()
        }
    }

    function statsText(visual) {
        const source = visual || {}
        const defaults = root.defaultStatVisual()
        const keys = ["cpu", "mem", "gpu", "vram"]
        const out = {}
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            const row = source[key] || defaults[key]
            out[key] = {
                t: root.normSteps(row.t, defaults[key].t),
                c: root.normColors(row.c, defaults[key].c)
            }
        }
        return JSON.stringify(out)
    }

    function saveStats(visual) {
        root.themeApplying = true
        root.statsJson = root.statsText(visual)
        root.themeApplying = false
        root.queueThemeSave()
    }

    function audioText(visual) {
        const base = root.defaultAudioVisual()
        const row = visual || base
        const out = {
            t: root.normSteps(row.t, base.t),
            c: root.normColors(row.c, base.c)
        }
        return JSON.stringify(out)
    }

    function saveAudio(visual) {
        root.themeApplying = true
        root.audioJson = root.audioText(visual)
        root.themeApplying = false
        root.queueThemeSave()
    }

    // Apply a whole look in one write. `stats` and `audio` are optional:
    // null keeps the current thresholds (a preset carries colors only).
    function saveLook(theme, stats, audio) {
        root.themeApplying = true
        root.themeJson = JSON.stringify(ThemeBuilder.normalize(theme))
        if (stats)
            root.statsJson = root.statsText(stats)
        if (audio)
            root.audioJson = root.audioText(audio)
        root.themeApplying = false
        root.queueThemeSave()
    }

    // Every stat metric's steps and colors as saved now.
    function statVisual() {
        const keys = ["cpu", "mem", "gpu", "vram"]
        const out = {}
        for (let i = 0; i < keys.length; i++)
            out[keys[i]] = { t: root.statThresholds(keys[i]), c: root.statColors(keys[i]) }
        return out
    }

    FileView {
        id: themeFile
        path: Quickshell.shellDir + "/state/theme.json"
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: root.themeReady = true
        // No state/theme.json yet: copy from the old theme/theme.json.
        onLoadFailed: root.themeLegacy = true
        onAdapterUpdated: root.queueThemeSave()
        onSaved: root.themeSaveDone()
        onSaveFailed: root.themeSaveDone()
        onFileChanged: {
            if (!root.themeWriting && !root.themeSavePending)
                themeFile.reload()
        }

        // qmllint disable unresolved-type
        JsonAdapter {
        // qmllint enable unresolved-type
            id: themeStore
            property string themeJson: ""
            property string statsJson: ""
            property string audioJson: ""
        }
    }

    // One-time read of the old theme/theme.json. Ready either way.
    FileView {
        id: legacyFile
        path: root.themeLegacy ? Quickshell.shellDir + "/theme/theme.json" : ""
        printErrors: false
        onLoaded: {
            const old = root.parsedObject(legacyFile.text())
            root.themeReady = true
            if (old && (old.statsJson || old.audioJson)) {
                root.themeApplying = true
                root.statsJson = String(old.statsJson || "")
                root.audioJson = String(old.audioJson || "")
                root.themeApplying = false
                root.queueThemeSave()
            }
            root.themeLegacy = false
        }
        onLoadFailed: {
            root.themeReady = true
            root.themeLegacy = false
        }
    }
}
