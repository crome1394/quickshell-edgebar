import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme
import "tests"

// Wallpaper picker options and the per-monitor helpers.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const W = WallpaperSettings
        const d = W.pickerNorm({})
        t.eq("picker defaults", [d.live, d.delay, d.height, d.close], [true, Theme.wallpaperPickDelay, Theme.wallpaperPickHeight, true])
        const bad = W.pickerNorm({ live: false, delay: 99999, height: 3, close: false })
        t.eq("bad numbers fall back, switches kept", [bad.live, bad.delay, bad.height, bad.close], [false, Theme.wallpaperPickDelay, Theme.wallpaperPickHeight, false])
        t.eq("delay snaps to 50 ms", W.pickerNorm({ delay: 330 }).delay, 350)
        t.eq("bad saved text gives defaults", W.pickerFrom("{nope").live, true)

        const S = WallpaperService
        S.monitors = { "DP-1": { path: "/w/a.png", fit: "contain" }, "HDMI-A-1": { path: "/w/b.png", fit: "zoom" } }
        t.eq("each monitor keeps its own", [S.pathFor("DP-1"), S.pathFor("HDMI-A-1")], ["/w/a.png", "/w/b.png"])
        t.eq("its fit", S.fitFor("DP-1"), "contain")
        t.eq("an unknown fit is cover", S.fitFor("HDMI-A-1"), "cover")
        t.eq("a monitor with none is cover", S.fitFor("DP-9"), "cover")
        t.eq("monitor names are checked", [S.monitorOk("DP-1"), S.monitorOk("DP-1;rm"), S.monitorOk("")], [true, false, false])
        S.monitors = ({})
        t.done()
    }
}
