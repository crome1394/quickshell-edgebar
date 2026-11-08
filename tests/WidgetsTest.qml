import QtQuick
import Quickshell
import qs.config
import qs.services
import "tests"

// Caffeine steps and IPC limits, the night light schedule window, the
// recorder's argv (fixed values only, never a shell), the System Stats
// widget layout, and the shared stats sampler.
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
