pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.theme

// The on-screen display's front door. Anything can ask for a popup with
// show(); OsdHost draws it. An item is { kind, glyph, title, detail,
// value (0–1, or -1 for no bar), percent ("" for none), art (a cover URL
// or ""), look (settings to draw with; null uses the saved ones) }.
Singleton {
    id: root

    property double lastSound: 0

    signal requested(var item)

    function show(item) {
        if (item && typeof item === "object")
            root.requested(item)
    }

    // The volume sound, at most once per Theme.osdSoundGapMs, so key
    // repeat and slider drags do not pile up players.
    function playSound(look) {
        const now = Date.now()
        if (now - root.lastSound < Theme.osdSoundGapMs)
            return
        const argv = OsdSettings.soundArgv(look)
        if (!argv.length)
            return
        root.lastSound = now
        Quickshell.execDetached(argv)
    }

    // A sample popup (the settings page's Preview, and qs ipc call osd
    // preview). kind is "volume", "mic", "track", or "brightness".
    function preview(kind, look) {
        const l = look || OsdSettings.live
        const k = String(kind || "volume")
        if (k === "track") {
            root.show({ kind: "track", glyph: OsdSettings.glyph("track", l), title: "Track title", detail: "Artist", value: -1, percent: "", art: "", look: l })
            return
        }
        if (k === "mic") {
            root.show({ kind: "mic", glyph: OsdSettings.glyph("micMuted", l), title: "Microphone", detail: "Muted", value: -1, percent: "", art: "", look: l })
            return
        }
        if (k === "brightness") {
            root.show({ kind: "brightness", glyph: OsdSettings.glyph("brightness", l), title: "Brightness", detail: "", value: 0.6, percent: "60%", art: "", look: l })
            return
        }
        root.show({ kind: "volume", glyph: OsdSettings.glyph("volMid", l), title: "Volume", detail: "", value: 0.45, percent: "45%", art: "", look: l })
        root.playSound(l)
    }
}
