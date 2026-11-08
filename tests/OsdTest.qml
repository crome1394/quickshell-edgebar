import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme
import "tests"

// On-screen display settings: defaults, value checks, symbols, and the
// sound argv (fixed programs, never a shell).
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const O = OsdSettings
        const d = O.defaults()
        t.eq("every event on by default", [d.volume, d.mic, d.device, d.track, d.playback, d.brightness], [true, true, true, true, true, true])
        t.eq("bottom center by default", [d.vplace, d.hplace], ["bottom", "center"])
        t.eq("theme colors and sound by default", [d.accent, d.text, d.sound, d.glass], ["auto", "auto", "theme", 0])

        const bad = O.normalize({ vplace: "sideways", margin: 9999, timeout: 10, glass: 20, accent: "nope", sound: "beep", soundFile: "relative.wav", soundVolume: 300 })
        t.eq("bad place falls back", bad.vplace, "bottom")
        t.eq("bad sizes fall back", [bad.margin, bad.timeout], [Theme.osdMargin, Theme.osdTimeoutMs])
        t.eq("too-thin glass follows the theme", bad.glass, 0)
        t.eq("bad color is auto", bad.accent, "auto")
        t.eq("bad sound is the theme sound", bad.sound, "theme")
        t.eq("relative sound file is refused", bad.soundFile, "")
        t.eq("bad sound volume falls back", bad.soundVolume, 60)
        t.eq("a color is kept", O.normalize({ text: "#AABBCC" }).text, "#aabbcc")
        t.eq("control characters leave paths", O.normalize({ soundFile: "/tmp/a\nb.wav" }).soundFile, "")

        t.eq("default symbol", O.glyph("volHigh", d), "")
        t.eq("own symbol", O.glyph("volHigh", O.normalize({ icons: { volHigh: "🔊" } })), "🔊")
        t.eq("symbols are short, no control characters", O.glyphNorm("ab\ncdefghijkl"), "abcdefgh")
        t.eq("unknown slots are dropped", O.normalize({ icons: { evil: "x" } }).icons.evil, undefined)

        t.eq("theme sound argv", O.soundArgv(d), ["canberra-gtk-play", "-i", "audio-volume-change", "--volume=0.60"])
        t.eq("file sound argv", O.soundArgv(O.normalize({ sound: "file", soundFile: "/s/click.oga", soundVolume: 40 })), ["pw-play", "--volume", "0.40", "/s/click.oga"])
        t.eq("file sound without a file plays nothing", O.soundArgv(O.normalize({ sound: "file" })), [])
        t.eq("off plays nothing", O.soundArgv(O.normalize({ sound: "off" })), [])

        // A request reaches whoever draws the popup.
        let got = null
        OsdService.requested.connect((item) => got = item)
        OsdService.show({ kind: "volume", title: "Volume" })
        t.eq("show() passes the item on", got ? got.title : "", "Volume")
        t.done()
    }
}
