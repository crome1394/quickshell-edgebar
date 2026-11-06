pragma Singleton
import QtQuick
import Quickshell

// Bar → Overview: layout, strip, previews, motion, workspaces, and input
// for the workspace overview. Draft keys match the saved field names.
Singleton {
    id: root

    readonly property var keys: [
        "ovLayout",
        "ovAnchor",
        "ovGap",
        "ovPadding",
        "ovPaddingTop",
        "ovPaddingBottom",
        "ovMaxScale",
        "ovDuration",
        "ovPreviewRound",
        "ovBlur",
        "ovBackdropBlur",
        "ovSwitchAnimation",
        "ovSwitchDuration",
        "ovMoveAnimation",
        "ovMoveDuration",
        "ovStripOffset",
        "ovStripHeight",
        "ovStripWidth",
        "ovStripCardMax",
        "ovStripMargin",
        "ovStripGap",
        "ovStripCardRound",
        "ovHoverBorder",
        "ovSelectBorder",
        "ovLivePreviews",
        "ovShowWindowLabels",
        "ovShowWsLabels",
        "ovStripPreviews",
        "ovNumberLabels",
        "ovDynamic",
        "ovAutodelete",
        "ovShowEmpty",
        "ovShowSpecial",
        "ovStripAllCard",
        "ovShowAll",
        "ovSwitchOnNew",
        "ovSwitchOnDrop",
        "ovDragToSwap",
        "ovFocusFollowsMouse",
        "ovScrollSwitches",
        "ovExitOnClick",
        "ovExitOnSwitch"
    ]

    // Saved options, clamped. The overlay reads this, not the draft. It is
    // rebuilt only when a saved option changes.
    readonly property var live: root.snapshot()

    readonly property Draft editor: Draft {
        owner: root
    }

    function layoutNorm(value) {
        const text = String(value || "")
        return text === "grid" || text === "natural" ? text : "rows"
    }

    function anchorNorm(value) {
        const text = String(value || "")
        return text === "bottom" || text === "left" || text === "right" ? text : "top"
    }

    function intIn(value, lo, hi, fallback) {
        let n = Math.round(Number(value))
        if (!(n >= lo) && !(n <= hi))
            n = fallback
        return Math.max(lo, Math.min(hi, n))
    }

    // Steps of 0.05.
    function stepIn(value, lo, hi, fallback) {
        let n = Math.round(Number(value) * 20) / 20
        if (!(n >= lo) && !(n <= hi))
            n = fallback
        n = Math.max(lo, Math.min(hi, n))
        return Math.round(n * 20) / 20
    }

    function flag(value, fallback) {
        if (value === undefined || value === null)
            return fallback
        return !!value
    }

    function normalize(src) {
        const snap = src || {}
        return {
            ovLayout: root.layoutNorm(snap.ovLayout),
            ovAnchor: root.anchorNorm(snap.ovAnchor),
            ovGap: root.intIn(snap.ovGap, 0, 120, 34),
            ovPadding: root.intIn(snap.ovPadding, 0, 200, 80),
            ovPaddingTop: root.intIn(snap.ovPaddingTop, 0, 160, 40),
            ovPaddingBottom: root.intIn(snap.ovPaddingBottom, 0, 160, 70),
            ovMaxScale: root.stepIn(snap.ovMaxScale, 0.2, 1.5, 1),
            ovDuration: root.intIn(snap.ovDuration, 0, 800, 360),
            ovPreviewRound: root.intIn(snap.ovPreviewRound, 0, 32, 12),
            ovBlur: root.stepIn(snap.ovBlur, 0, 1, 1),
            ovBackdropBlur: root.flag(snap.ovBackdropBlur, false),
            ovSwitchAnimation: root.flag(snap.ovSwitchAnimation, true),
            ovSwitchDuration: root.intIn(snap.ovSwitchDuration, 0, 800, 260),
            ovMoveAnimation: root.flag(snap.ovMoveAnimation, true),
            ovMoveDuration: root.intIn(snap.ovMoveDuration, 0, 800, 240),
            ovStripOffset: root.intIn(snap.ovStripOffset, 0, 120, 0),
            ovStripHeight: root.intIn(snap.ovStripHeight, 72, 640, 150),
            ovStripWidth: root.intIn(snap.ovStripWidth, 72, 640, 150),
            ovStripCardMax: root.intIn(snap.ovStripCardMax, 160, 960, 300),
            ovStripMargin: root.intIn(snap.ovStripMargin, 0, 64, 22),
            ovStripGap: root.intIn(snap.ovStripGap, 0, 64, 18),
            ovStripCardRound: root.intIn(snap.ovStripCardRound, 0, 28, 10),
            ovHoverBorder: root.intIn(snap.ovHoverBorder, 0, 8, 3),
            ovSelectBorder: root.intIn(snap.ovSelectBorder, 0, 8, 3),
            ovLivePreviews: root.flag(snap.ovLivePreviews, true),
            ovShowWindowLabels: root.flag(snap.ovShowWindowLabels, true),
            ovShowWsLabels: root.flag(snap.ovShowWsLabels, true),
            ovStripPreviews: root.flag(snap.ovStripPreviews, true),
            ovNumberLabels: root.flag(snap.ovNumberLabels, false),
            ovDynamic: root.flag(snap.ovDynamic, true),
            ovAutodelete: root.flag(snap.ovAutodelete, true),
            ovShowEmpty: root.flag(snap.ovShowEmpty, true),
            ovShowSpecial: root.flag(snap.ovShowSpecial, false),
            ovStripAllCard: root.flag(snap.ovStripAllCard, false),
            ovShowAll: root.flag(snap.ovShowAll, false),
            ovSwitchOnNew: root.flag(snap.ovSwitchOnNew, true),
            ovSwitchOnDrop: root.flag(snap.ovSwitchOnDrop, false),
            ovDragToSwap: root.flag(snap.ovDragToSwap, true),
            ovFocusFollowsMouse: root.flag(snap.ovFocusFollowsMouse, true),
            ovScrollSwitches: root.flag(snap.ovScrollSwitches, true),
            ovExitOnClick: root.flag(snap.ovExitOnClick, true),
            ovExitOnSwitch: root.flag(snap.ovExitOnSwitch, false)
        }
    }

    function snapshot() {
        const src = {}
        for (let i = 0; i < root.keys.length; i++)
            src[root.keys[i]] = Config[root.keys[i]]
        return root.normalize(src)
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            for (let i = 0; i < root.keys.length; i++)
                Config[root.keys[i]] = clean[root.keys[i]]
        })
    }

    // Sliders work in whole numbers; scale turns 0.05 steps into 1, 2, 3...
    function draftInt(key, scale) {
        const factor = Number(scale) || 1
        return Math.round(Number(root.editor.value[key]) * factor)
    }

    function setScaled(key, value, scale) {
        const factor = Number(scale) || 1
        const raw = Math.round(Number(value))
        root.editor.set(key, factor === 1 ? raw : raw / factor)
    }
}
