pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Bar → Dock: the hover effect on bar icons (magnify, jump, or both),
// which widgets it applies to, and the running-app dot color.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function clamp(value, low, high, fallback) {
        let n = Math.round(Number(value))
        if (!(n >= low))
            n = fallback
        if (n > high)
            n = high
        return n
    }

    function normalize(raw) {
        const src = raw || {}
        let effect = String(src.effect || "both")
        if (effect !== "off" && effect !== "magnify" && effect !== "jump" && effect !== "both")
            effect = "both"
        const scope = String(src.scope || "icons") === "quicklaunch" ? "quicklaunch" : "icons"
        const dot = Theme.colorHex(src.dot)
        return {
            effect: effect,
            scope: scope,
            percent: root.clamp(src.percent, Theme.dockScaleMin, Theme.dockScaleMax, Theme.dockScaleDefault),
            radius: root.clamp(src.radius, Theme.dockRadiusMin, Theme.dockRadiusMax, Theme.dockRadiusDefault),
            jump: root.clamp(src.jump, Theme.dockJumpMin, Theme.dockJumpMax, Theme.dockJumpDefault),
            dot: dot.length === 7 ? dot : Theme.colorHex(Theme.dockDotDefault)
        }
    }

    function snapshot() {
        return root.normalize({
            effect: Config.dockEffect,
            scope: Config.dockScope,
            percent: Config.dockPercent,
            radius: Config.dockRadius,
            jump: Config.dockJump,
            dot: Config.dockDot
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.dockEffect = clean.effect
            Config.dockScope = clean.scope
            Config.dockPercent = clean.percent
            Config.dockRadius = clean.radius
            Config.dockJump = clean.jump
            Config.dockDot = clean.dot
        })
    }

    // Saved values, for the bar.
    function effectValue() {
        return root.normalize({ effect: Config.dockEffect }).effect
    }

    function magnify() {
        const effect = root.effectValue()
        return effect === "magnify" || effect === "both"
    }

    function jumpOn() {
        const effect = root.effectValue()
        return effect === "jump" || effect === "both"
    }

    function allIcons() {
        return root.normalize({ scope: Config.dockScope }).scope !== "quicklaunch"
    }

    function percentValue() {
        return root.normalize({ percent: Config.dockPercent }).percent / 100
    }

    function radiusValue() {
        return root.normalize({ radius: Config.dockRadius }).radius
    }

    function jumpValue() {
        return root.normalize({ jump: Config.dockJump }).jump
    }

    function dotColor() {
        return Qt.color(root.normalize({ dot: Config.dockDot }).dot)
    }

    // Scale for an icon centered at centerX while the pointer is at hoverX.
    function neighbor(hoverX, centerX) {
        if (!root.magnify() || !(hoverX >= 0))
            return 1
        const dist = Math.abs(Number(hoverX) - Number(centerX))
        const radius = root.radiusValue()
        if (dist >= radius)
            return 1
        const t = Math.cos((dist / radius) * Math.PI / 2)
        return 1 + (root.percentValue() - 1) * t
    }

    // Extra room a bar of this thickness needs so icons can grow and jump.
    function room(thickness) {
        const thick = Math.max(1, Math.round(Number(thickness) || 0))
        let extra = 0
        if (root.magnify())
            extra += Math.ceil((root.percentValue() - 1) * thick)
        if (root.jumpOn())
            extra += root.jumpValue()
        return Math.max(0, extra)
    }
}
