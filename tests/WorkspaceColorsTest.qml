import QtQuick
import Quickshell
import qs.config
import "tests"

// WorkspaceSettings colors: theme by default, custom only when chosen,
// and a face's own label color only in custom mode.
ShellRoot {
    Check { id: t }

    Timer {
        // Let Config load its (empty) store first.
        interval: 300
        running: Config.ready
        onTriggered: {
            const W = WorkspaceSettings
            const face = { color: "#ff0000" }
            t.eq("theme by default", W.colorMode(), "theme")
            t.eq("label color ignored in theme mode", W.labelColor(face), "")
            W.setCustomColor("wsActiveFg", "#00ff00")
            t.eq("custom colors ignored in theme mode", W.customColor("wsActiveFg"), "")
            W.setColorMode("custom")
            t.eq("custom mode", W.colorMode(), "custom")
            t.eq("label color in custom mode", W.labelColor(face), "#ff0000")
            t.eq("custom color in custom mode", W.customColor("wsActiveFg"), "#00ff00")
            t.eq("unset custom color uses the theme", W.customColor("wsIdleFg"), "")
            W.setCustomColor("wsActiveFg", "")
            t.eq("clearing goes back to the theme", W.customColor("wsActiveFg"), "")
            const before = JSON.stringify(W.colorKeys.map((k) => W.customColor(k)))
            W.setCustomColor("evil", "#000000")
            t.eq("unknown keys are ignored", JSON.stringify(W.colorKeys.map((k) => W.customColor(k))), before)
            W.setColorMode("rainbow")
            t.eq("unknown modes are ignored", W.colorMode(), "custom")
            t.done()
        }
    }
}
