pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.theme

// Colors for the index-divider tabs in Settings. The main strip along the
// bottom gives each tab its own color (Rainbow or From accent) and records
// the active one in `activeColor`; section strips along the top of a page
// use shades of it, so a page matches its divider.
Singleton {
    id: root

    readonly property bool light: ThemeStore.activeTheme.tone === "light"
    readonly property string mode: Config.settingsTabColors === "accent" ? "accent" : "rainbow"
    readonly property bool indexed: Config.settingsTabStyle !== "flat"

    // Set by the main strip when its active tab changes.
    property color activeColor: Theme.accent

    function soften(c) {
        return root.light ? ThemeBuilder.mix(c, Qt.rgba(1, 1, 1, 1), 0.18) : c
    }

    // Main tab i of count.
    function mainColor(i, count) {
        let c
        if (root.mode === "accent") {
            const a = Theme.accent
            c = Qt.hsla(((a.hslHue < 0 ? 0 : a.hslHue) + i / Math.max(1, count)) % 1, 0.62, root.light ? 0.6 : 0.55, 1)
        } else {
            c = ThemeBuilder.parse(Theme.indexTabColors[i % Theme.indexTabColors.length])
        }
        return root.soften(c)
    }

    // Section tab i: the active main color, a little lighter or darker per step.
    function sectionColor(i) {
        const base = root.activeColor
        const step = Theme.indexTabShadeStep * i
        return root.light || ThemeBuilder.luminance(base) > 0.55
            ? ThemeBuilder.mix(base, Qt.rgba(0, 0, 0, 1), step)
            : ThemeBuilder.mix(base, Qt.rgba(1, 1, 1, 1), step)
    }

    function inkFor(c) {
        return ThemeBuilder.luminance(c) > 0.55 ? Theme.indexTabDarkInk : Theme.indexTabLightInk
    }
}
