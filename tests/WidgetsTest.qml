import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme
import "tests"

// Caffeine steps and IPC limits, the night light schedule window, the
// recorder's argv (fixed values only, never a shell), the System Stats
// widget layout and text style, the shared stats sampler, and the split
// Audio widgets and their menu.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const C = CaffeineService
        C.step()
        t.eq("first right-click: 30 min", [C.on, C.minutesLeft], [true, 30])
        C.step()
        t.eq("then 1 h", C.minutesLeft, 60)
        C.step()
        C.step()
        t.eq("then until off", [C.on, C.until], [true, 0])
        C.step()
        t.eq("then off", C.on, false)
        C.toggle()
        t.eq("left click: until off", C.describe(), "on until turned off")
        t.eq("too long is refused", C.forMinutes(5000), false)
        C.setOn(false)

        const N = NightLightSettings
        const at = (h, m) => new Date(2026, 0, 1, h, m)
        t.eq("schedule crossing midnight: late evening", N.inWindow(at(22, 0), "20:00", "07:00"), true)
        t.eq("schedule crossing midnight: early morning", N.inWindow(at(6, 59), "20:00", "07:00"), true)
        t.eq("schedule crossing midnight: daytime", N.inWindow(at(12, 0), "20:00", "07:00"), false)
        t.eq("schedule within a day", N.inWindow(at(14, 30), "13:00", "15:00"), true)
        t.eq("bad times fall back", N.normalize({ start: "25:00", end: "x" }).start, "20:00")
        t.eq("temperature snaps and clamps", [N.tempNorm(3456), N.tempNorm(99999)], [3500, 4000])
        t.eq("menu schedule turns on", N.setScheduleLive(true), true)
        t.eq("menu schedule saved", Config.nightSchedule, true)
        t.eq("menu schedule already on", N.setScheduleLive(true), false)
        t.eq("menu start pads", N.setStartLive("9:05"), true)
        t.eq("menu start saved", Config.nightStart, "09:05")
        t.eq("menu start unchanged", N.setStartLive("09:05"), false)
        t.eq("menu bad start refused", N.setStartLive("25:00"), false)
        t.eq("menu start kept", Config.nightStart, "09:05")
        t.eq("menu end pads", N.setEndLive("6:30"), true)
        t.eq("menu end saved", Config.nightEnd, "06:30")
        t.eq("menu bad end refused", N.setEndLive("7:60"), false)
        t.eq("menu end kept", Config.nightEnd, "06:30")
        N.setScheduleLive(false)

        const R = RecorderSettings
        const o = R.normalize({})
        t.eq("recorder defaults", [o.codec, o.quality, o.container, o.fps, o.audio], ["auto", "very_high", "mp4", 60, "output"])
        t.eq("bad values fall back", R.normalize({ codec: "rm -rf", fps: 7, dir: "relative/path" }).codec, "auto")
        t.eq("auto picks AV1 when the GPU has it", R.resolveCodec("auto", ["h264", "hevc", "av1"]), "av1")
        t.eq("auto picks HEVC on older GPUs", R.resolveCodec("auto", ["h264", "hevc"]), "hevc")
        t.eq("auto picks H.264 last", R.resolveCodec("auto", ["h264"]), "h264")
        t.eq("auto before the GPU is read: HEVC", R.resolveCodec("auto", []), "hevc")
        t.eq("a chosen codec is kept", R.resolveCodec("h264", ["av1"]), "h264")
        t.eq("relative folders are refused", R.normalize({ dir: "relative/path" }).dir, R.defaultDir)
        t.eq("~ expands", R.normalize({ dir: "~/Clips/" }).dir, R.home + "/Clips")
        const av1 = R.normalize({ codec: "av1" })
        t.eq("argv for a monitor", R.argv(av1, "DP-1", "", "/tmp/a.mp4"),
            ["gpu-screen-recorder", "-w", "DP-1", "-c", "mp4", "-k", "av1", "-q", "very_high", "-f", "60", "-cursor", "yes", "-a", "default_output", "-ac", "aac", "-o", "/tmp/a.mp4"])
        const mkv = R.normalize({ codec: "av1", container: "mkv", audio: "none" })
        t.eq("argv for a region, no audio", R.argv(mkv, "region", "800x600+10+20", "/tmp/b.mkv"),
            ["gpu-screen-recorder", "-w", "region", "-region", "800x600+10+20", "-c", "mkv", "-k", "av1", "-q", "very_high", "-f", "60", "-cursor", "yes", "-o", "/tmp/b.mkv"])

        // System Stats: per-metric widgets start beside the combined pill.
        const W = WidgetService
        const laid = W.normalizeLayout([{ id: "clock", zone: "top" }, { id: "stats", zone: "top" }, { id: "tray", zone: "top" }], false)
        t.eq("metric widgets follow System Stats", laid.slice(0, 7).map(e => e.id),
            ["clock", "stats", "statCpu", "statMem", "statGpu", "statVram", "tray"])
        t.eq("and share its bar", laid[3].zone, "top")
        const kept = W.normalizeLayout([{ id: "statGpu", zone: "left" }, { id: "stats", zone: "top" }], false)
        t.eq("a placed metric keeps its bar", kept[0], { id: "statGpu", zone: "left" })
        t.eq("one mode parks the other", W.parked("stats") !== W.parked("statCpu"), true)
        t.eq("combined is the default", StatsSettings.normalize({}).combined, true)

        // Audio: Speaker and Microphone start beside the combined pill.
        const al = W.normalizeLayout([{ id: "volume", zone: "right" }, { id: "clock", zone: "right" }], false)
        t.eq("audio parts follow Audio", al.slice(0, 4).map(e => e.id), ["volume", "audioOut", "audioIn", "clock"])
        t.eq("and share its bar", al[2].zone, "right")
        t.eq("one audio mode parks the other", W.parked("volume") !== W.parked("audioOut"), true)
        t.eq("audio combined by default", AudioSettings.normalize({}).combined, true)

        // Only the pill that opened the audio menu shows it.
        const M = AudioMenuService
        M.toggle("A", "in")
        t.eq("mic click: mic pill shows it", [M.shownBy("A", "in"), M.shownBy("A", "out")], [true, false])
        M.toggle("A", "out")
        t.eq("speaker click moves it", [M.shownBy("A", "in"), M.shownBy("A", "out"), M.open], [false, true, true])
        M.toggle("A", "out")
        t.eq("same pill again closes it", M.open, false)
        M.show("A")
        t.eq("IPC: combined or speaker pill", [M.shownBy("A", "both"), M.shownBy("A", "out"), M.shownBy("A", "in")], [true, true, false])
        M.hide()

        // Text Style: All is complete; a metric holds only what it overrides.
        const Y = StatStyle
        const base = { font: "Inter", bold: false, italic: true, size: 120, color: "auto" }
        const st = Y.norm({ cpu: { value: { color: "#ff0000", junk: 1 } } }, base)
        t.eq("All takes the older font setting", st.all.label, base)
        t.eq("a metric keeps only its overrides", st.cpu.value, { color: "#ff0000" })
        t.eq("effective: All, then the override", Y.effective(st, "cpu", "value"), { font: "Inter", bold: false, italic: true, size: 120, color: "#ff0000" })
        t.eq("other metrics follow All", Y.effective(st, "gpu", "value").color, "auto")
        t.eq("percent color stays auto", Y.norm({ all: { percent: { color: "#00ff00" } } }, base).all.percent.color, "auto")
        t.eq("bad color is auto", Y.fieldNorm("color", "javascript:"), "auto")
        const sized = Y.edited(st, "mem", "label", "size", 999)
        t.eq("size is clamped", sized.mem.label.size, Theme.clockFontMax)
        t.eq("overrides listed", Y.overrides(sized, "mem", "label"), ["size"])
        t.eq("Use All drops them", Y.overrides(Y.edited(sized, "mem", "label"), "mem", "label"), [])

        // Transparency: an app can keep its level fullscreen.
        const O = OpacitySettings
        t.eq("fullscreen solid by default", O.overrideNorm({ cls: "foot", active: 85 }).fullSolid, true)
        const lua = O.luaText(100, [{ cls: "foot", active: 85, inactive: 80, fullSolid: false }, { cls: "brave-origin", active: 90 }])
        const generic = lua.indexOf("qs-opacity-fullscreen'")
        const keep = lua.indexOf("qs-opacity-app-1-fullscreen")
        t.ok("the kept level comes after the solid fullscreen rule", generic > 0 && keep > generic)
        t.ok("it keeps 85% fullscreen", lua.indexOf("fullscreen = true }, opacity = '0.85 override 0.80 override 0.85 override'") > 0)
        t.ok("other apps stay solid fullscreen", lua.indexOf("qs-opacity-app-2-fullscreen") < 0)

        // The shared sampler runs only while held; GPU only while asked for.
        const S = StatsService
        const before = [S.users, S.gpuUsers]
        S.retain(false)
        S.retain(true)
        t.eq("held twice, once for GPU", [S.users - before[0], S.gpuUsers - before[1], S.active, S.gpuWanted], [2, 1, true, true])
        S.release(true)
        t.eq("GPU let go", S.gpuUsers, before[1])
        S.release(false)
        t.eq("all let go", S.users, before[0])
        t.done()
    }
}
