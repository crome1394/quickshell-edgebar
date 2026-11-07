import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import "tests"

// ThemeSettings: importing old-bar and new theme files, and rejecting bad ones.
ShellRoot {
    Check { id: t }

    FileView {
        id: oldFile
        path: Quickshell.shellDir + "/tests/fixtures/old-bar-theme.json"
        onLoaded: {
            const S = ThemeSettings
            const r = S.parseImport(oldFile.text())
            t.ok("old bar file imports", !!r.entry, r.error)
            const e = r.entry
            t.eq("old: name", e.name, "Old bar sample")
            t.eq("old: accent", e.accent, "#7dd3fc")
            t.eq("old: alert from muted", e.alert, "#d01f3e")
            t.eq("old: tint from glassBg", e.tint, "#0a121f")
            t.eq("old: glass from alpha", e.glass, 40)
            t.eq("old: clear pills kept", e.colors.colSurface, "#0a121f00")
            t.eq("old: weekday", e.colors.colWeekday, "#ff5c9a")
            t.eq("old: temp steps", e.temp, { warmAt: 65, hotAt: 80 })
            t.eq("old: cpu tiers", e.stats.cpu.c, ["#e8a0a4", "#ed1c24", "#c4161c", "#ff4500"])
            t.eq("old: cpu steps", e.stats.cpu.t, [30, 60, 90])
            t.eq("old: vram falls back to gpu", e.stats.vram.c, e.stats.gpu.c)
            t.eq("old: audio", e.audio, { t: [20, 40, 80], c: ["#10b981", "#31ff00", "#f97316", "#ef4444"] })

            // The old bar's active-theme file wraps the theme in a string.
            const wrapped = S.parseImport(JSON.stringify({ themeJson: oldFile.text() }))
            t.eq("old: wrapped state file", wrapped.entry && wrapped.entry.accent, "#7dd3fc")

            // Export → import gives back the same theme.
            const exported = JSON.stringify(Object.assign({ format: S.format, version: S.version }, e))
            t.eq("round trip", S.parseImport(exported).entry, e)

            t.ok("rejects empty", !!S.parseImport("").error)
            t.ok("rejects bad JSON", !!S.parseImport("{nope").error)
            t.ok("rejects arrays", !!S.parseImport("[1,2]").error)
            t.ok("rejects non-themes", !!S.parseImport("{\"hello\": 1}").error)
            t.ok("rejects huge files", !!S.parseImport(" ".repeat(Theme.themeImportMaxBytes + 1) + "{}").error)
            t.done()
        }
        onLoadFailed: {
            t.ok("fixture loads", false)
            t.done()
        }
    }
}
