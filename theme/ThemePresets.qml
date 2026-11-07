pragma Singleton
import QtQuick
import Quickshell

// Built-in themes for Settings → Theme. Each is the short form ThemeBuilder
// expands: tone, accent, alert, tint, glass, menu, and a few `colors` where
// a preset differs from the derived palette. The first 23 come from the old
// bar's presets; "New" ones were added with this bar. Presets carry colors
// only, so choosing one keeps your stat and audio thresholds.
Singleton {
    id: root

    readonly property var groups: ["Liquid", "Classic", "Light", "New"]

    function liquid(name, accent, alert, tint, colors) {
        return { group: "Liquid", name: name, tone: "dark", accent: accent, alert: alert, tint: tint, glass: 56, menu: 90, colors: colors || {} }
    }

    function classic(name, accent, alert, tint, glass, menu, colors) {
        return { group: "Classic", name: name, tone: "dark", accent: accent, alert: alert, tint: tint, glass: glass, menu: menu, colors: colors || {} }
    }

    function paper(name, accent, alert, tint) {
        return { group: "Light", name: name, tone: "light", accent: accent, alert: alert, tint: tint, glass: 100, menu: 100, colors: {} }
    }

    function fresh(name, accent, alert, tint, colors) {
        return { group: "New", name: name, tone: "dark", accent: accent, alert: alert, tint: tint, glass: 62, menu: 92, colors: colors || {} }
    }

    // Text colors for a classic preset: body, muted, active workspace,
    // idle workspace, weekday, and the "ok" green.
    function ink(fg, muted, wsActive, wsIdle, weekday, ok) {
        return {
            colFg: fg, colFgMuted: muted, colWsActiveFg: wsActive, colWsIdleFg: wsIdle,
            colWeekday: weekday, colOk: ok, colStatTempCool: fg
        }
    }

    // Liquid amber is the bar's own default (DefaultTheme.qml).
    readonly property string defaultName: "Liquid amber"

    readonly property var list: [
        root.liquid("Liquid amber", "#fbbf24", "#fb7185", "#17120a"),
        root.liquid("Liquid glass", "#00f0e0", "#ff3d8a", "#0a0f1a", { colWeekday: "#ff5c9a", colBarBorder: "#8cb8d129" }),
        root.liquid("Liquid mint", "#5eead4", "#f472b6", "#0a1414"),
        root.liquid("Liquid violet", "#c4b5fd", "#f9a8d4", "#120d1f"),
        root.liquid("Liquid rose", "#f9a8d4", "#fb7185", "#1a0d14"),
        root.liquid("Liquid ice", "#7dd3fc", "#a5b4fc", "#0a121f"),
        root.liquid("Liquid aurora", "#34d399", "#818cf8", "#081417"),
        root.liquid("Ink", "#e4c58a", "#d4a0a0", "#0d0b0a"),
        root.liquid("Cocoa", "#e0a36a", "#e8a090", "#1c120d"),
        root.liquid("Graphite", "#d6d3d1", "#a8a29e", "#131315"),

        root.classic("Solid dark", "#00c4f5", "#e85d6f", "#000000", 100, 100, Object.assign(
            root.ink("#ececee", "#b0b0b2", "#ececee", "#ffffff", "#e85d6f", "#10b981"),
            { colBarBorder: "#1e2024", colGlassHighlight: "#00000000", colSurface: "#0a0c0e", colSection: "#121416", colField: "#0a0c0e" })),
        root.classic("Soft grey", "#7ec8e3", "#e88a9a", "#1a1b1e", 72, 92, Object.assign(
            root.ink("#e8e8ec", "#a0a4b0", "#e8f7fc", "#ffffff", "#e88a9a", "#10b981"),
            { colGlassHighlight: "#ffffff1f" })),
        root.classic("Nordic frost", "#88c0d0", "#bf616a", "#1a1e26", 62, 92,
            root.ink("#e8eef7", "#9aa8bc", "#e8f4f8", "#d8dee9", "#b48ead", "#a3be8c")),
        root.classic("Warm ember", "#e0a36a", "#d4756a", "#16120f", 64, 93,
            root.ink("#f3ebe3", "#b5a497", "#fff4e8", "#e8ddd2", "#c98b7a", "#7cb88a")),
        root.classic("Deep ocean", "#3db8c9", "#e06c75", "#0b1219", 60, 93,
            root.ink("#e6f0fa", "#8fa3b8", "#e8fbff", "#c8d8e8", "#7aa2f7", "#2ee59a")),
        root.classic("Lavender dusk", "#b39ddb", "#e5738a", "#14121a", 62, 93,
            root.ink("#f0eaf8", "#a89bb8", "#f8f0ff", "#e0d6f0", "#ce93d8", "#81c784")),
        root.classic("Forest moss", "#7cb87c", "#d08070", "#101612", 62, 93,
            root.ink("#e8f0e9", "#9aafa0", "#f0fff0", "#d4e4d6", "#a8c878", "#6bcf8e")),

        root.paper("Paper", "#8a5a2a", "#a15c4a", "#f6f1e7"),
        root.paper("Daylight", "#0369a1", "#b4536a", "#f8f9fc"),
        root.paper("Mist", "#0f766e", "#9a6b4f", "#e7eef1"),
        root.paper("Blossom", "#9d3d5a", "#c26b4a", "#fbf5f4"),
        root.paper("Sage", "#2f6b45", "#a1624a", "#ecf2eb"),
        root.paper("Porcelain", "#3730a3", "#9d4b6a", "#f7f6fa"),

        root.fresh("Midnight", "#7aa2f7", "#f7768e", "#1a1b26",
            root.ink("#c0caf5", "#9aa5ce", "#e6ecff", "#c0caf5", "#bb9af7", "#9ece6a")),
        root.fresh("Velvet", "#cba6f7", "#f38ba8", "#1e1e2e",
            root.ink("#cdd6f4", "#a6adc8", "#f5ecff", "#cdd6f4", "#f5c2e7", "#a6e3a1")),
        root.fresh("Dune", "#d8a657", "#ea6962", "#1d2021",
            root.ink("#ebdbb2", "#a89984", "#fbf1c7", "#ebdbb2", "#e78a4e", "#a9b665")),
        root.fresh("Evergreen", "#a7c080", "#e67e80", "#232a2e",
            root.ink("#d3c6aa", "#9da9a0", "#f2efdf", "#d3c6aa", "#dbbc7f", "#83c092")),
        root.fresh("Copper", "#e8935a", "#f06a6a", "#14100e",
            root.ink("#f2e8e1", "#b3a59c", "#fff1e6", "#eadcd2", "#d9a38a", "#8fc79a"))
    ]

    function find(name) {
        for (let i = 0; i < root.list.length; i++) {
            if (root.list[i].name === name)
                return root.list[i]
        }
        return null
    }

    function defaultTheme() {
        return root.find(root.defaultName)
    }
}
