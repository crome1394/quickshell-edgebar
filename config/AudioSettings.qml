pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Audio page: scroll step, the percent readout, the audio menu's level
// meters, and the level thresholds.
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

    // Highest volume a slider, + button, or the wheel may set: 100 with the
    // limit on, else Theme.volumeMax.
    function volumeCap() {
        return Config.audioLimit100 ? 100 : Theme.volumeMax
    }

    // Where a change from `current` to `next` percent may land. Above the
    // cap it never goes up, but a volume already over it is not pulled down.
    function limitRaise(current, next) {
        const cap = root.volumeCap()
        if (next <= cap)
            return next
        return Math.max(cap, Math.min(Number(current) || 0, next))
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
            limit100: src.limit100 === true,
            meterStreams: src.meterStreams !== false,
            meterDevices: src.meterDevices !== false,
            tiers: root.visualNorm(src.tiers)
        }
    }

    function snapshot() {
        return root.normalize({
            step: Config.audioScrollStep,
            percent: Config.audioShowPercent,
            limit100: Config.audioLimit100,
            meterStreams: Config.audioMeterStreams,
            meterDevices: Config.audioMeterDevices,
            tiers: Theme.audioVisual()
        })
    }

    function defaults() {
        return { step: Theme.volumeStep, percent: true, limit100: false, meterStreams: true, meterDevices: true, tiers: Theme.defaultAudioVisual() }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.audioScrollStep = clean.step
            Config.audioShowPercent = clean.percent
            Config.audioLimit100 = clean.limit100
            Config.audioMeterStreams = clean.meterStreams
            Config.audioMeterDevices = clean.meterDevices
        })
        Theme.saveAudio(clean.tiers)
    }

    // Playback and Recording in the audio menu remember whether they are open.
    // Saved at once: a click in the menu, not a settings page.
    function setSectionOpen(sink, open) {
        Config.saveFields(() => {
            if (sink)
                Config.audioPlaybackOpen = !!open
            else
                Config.audioRecordingOpen = !!open
        })
    }
}
