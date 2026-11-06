pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Audio page: scroll step, the percent readout, and the level thresholds.
// The thresholds and colors are saved in theme/theme.json by Theme.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function scrollNorm(value) {
        let n = Math.round(Number(value))
        if (!(n >= Theme.audioScrollMin))
            n = Theme.volumeStep
        if (n > Theme.audioScrollMax)
            n = Theme.audioScrollMax
        return n
    }

    // Saved scroll step, for the pill.
    function scrollStepValue() {
        return root.scrollNorm(Config.audioScrollStep)
    }

    function visualNorm(raw) {
        const base = Theme.defaultAudioVisual()
        if (!raw)
            return { t: base.t.slice(), c: base.c.slice() }
        const steps = raw.t ? raw.t : raw
        return {
            t: Theme.normSteps(steps, base.t),
            c: Theme.normColors(raw.c, base.c)
        }
    }

    // Draft thresholds, for the settings page.
    function bandAt(index) {
        const slot = Math.round(Number(index))
        const t = root.editor.value.tiers.t
        return slot >= 0 && slot <= 2 ? t[slot] : t[0]
    }

    function colorAt(index) {
        const slot = Math.round(Number(index))
        const c = root.editor.value.tiers.c
        return slot >= 0 && slot <= 3 ? c[slot] : c[0]
    }

    function setBand(index, value) {
        const slot = Math.round(Number(index))
        if (slot < 0 || slot > 2)
            return
        root.editor.set("tiers", Config.withBand(root.editor.value.tiers, slot, value))
    }

    function setColor(index, color) {
        const slot = Math.round(Number(index))
        if (slot < 0 || slot > 3)
            return
        const next = Config.withColor(root.editor.value.tiers, slot, color)
        if (next)
            root.editor.set("tiers", next)
    }

    function normalize(src) {
        return {
            step: root.scrollNorm(src.step),
            percent: src.percent !== false,
            tiers: root.visualNorm(src.tiers)
        }
    }

    function snapshot() {
        return root.normalize({
            step: Config.audioScrollStep,
            percent: Config.audioShowPercent,
            tiers: Theme.audioVisual()
        })
    }

    function defaults() {
        return { step: Theme.volumeStep, percent: true, tiers: Theme.defaultAudioVisual() }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.audioScrollStep = clean.step
            Config.audioShowPercent = clean.percent
        })
        Theme.saveAudio(clean.tiers)
    }
}
