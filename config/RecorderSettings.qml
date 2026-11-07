pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Screen recorder options (gpu-screen-recorder). Settings → Tools →
// Recording edits them through `editor`. Defaults: AV1 at very high
// quality in MP4, 60 fps, system audio, the cursor, the focused monitor,
// saved to ~/Videos/Recordings. AV1 is encoded on the GPU (NVENC, VCN, or
// Quick Sync), so recording costs the CPU almost nothing.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string defaultDir: root.home + "/Videos/Recordings"

    readonly property var codecs: [
        { id: "av1", label: "AV1", tip: "Smallest files for the quality, encoded on the GPU. Plays in browsers, VLC, and mpv; some editors want HEVC." },
        { id: "hevc", label: "HEVC", tip: "Small files, encoded on the GPU, and the widest editor support of the efficient codecs" },
        { id: "h264", label: "H.264", tip: "Plays everywhere; larger files" }
    ]
    readonly property var containers: ["mp4", "mkv"]
    readonly property var qualities: [
        { id: "high", label: "High" },
        { id: "very_high", label: "Very high" },
        { id: "ultra", label: "Ultra" }
    ]
    readonly property var audios: [
        { id: "output", label: "System", tip: "What you hear" },
        { id: "mic", label: "Microphone", tip: "The default microphone" },
        { id: "both", label: "Both", tip: "System sound and the microphone" },
        { id: "none", label: "None", tip: "No audio" }
    ]

    function pick(list, value, fallback) {
        return list.indexOf(value) >= 0 ? value : fallback
    }

    // An absolute folder (or ~/…), one line, no odd characters.
    function dirNorm(value) {
        let d = String(value || "").trim()
        if (d.startsWith("~/"))
            d = root.home + d.substring(1)
        d = d.replace(/\/+$/, "")
        return /^\/[^\u0000-\u001f]{0,500}$/.test(d) ? d : root.defaultDir
    }

    function normalize(src) {
        const s = src || {}
        const fps = Math.round(Number(s.fps))
        return {
            dir: root.dirNorm(s.dir),
            codec: root.pick(root.codecs.map((c) => c.id), s.codec, "av1"),
            container: root.pick(root.containers, s.container, "mp4"),
            quality: root.pick(root.qualities.map((q) => q.id), s.quality, "very_high"),
            fps: Theme.recFpsChoices.indexOf(fps) >= 0 ? fps : 60,
            audio: root.pick(root.audios.map((a) => a.id), s.audio, "output"),
            cursor: s.cursor !== false,
            target: s.target === "region" ? "region" : "screen",
            notify: s.notify !== false
        }
    }

    function snapshot() {
        return root.normalize({
            dir: Config.recDir, codec: Config.recCodec, container: Config.recContainer,
            quality: Config.recQuality, fps: Config.recFps, audio: Config.recAudio,
            cursor: Config.recCursor, target: Config.recTarget, notify: Config.recNotify
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const c = root.normalize(snap)
        Config.saveFields(() => {
            Config.recDir = c.dir === root.defaultDir ? "" : c.dir
            Config.recCodec = c.codec
            Config.recContainer = c.container
            Config.recQuality = c.quality
            Config.recFps = c.fps
            Config.recAudio = c.audio
            Config.recCursor = c.cursor
            Config.recTarget = c.target
            Config.recNotify = c.notify
        })
    }

    // The gpu-screen-recorder argv for a capture target ("DP-1" or
    // "region" with a geometry) and an output file. Every value is from a
    // fixed list or checked, and the argv never goes through a shell.
    function argv(o, target, geometry, file) {
        const args = ["gpu-screen-recorder", "-w", target]
        if (target === "region")
            args.push("-region", geometry)
        args.push("-c", o.container, "-k", o.codec, "-q", o.quality, "-f", String(o.fps),
            "-cursor", o.cursor ? "yes" : "no")
        const sources = { output: "default_output", mic: "default_input", both: "default_output|default_input" }
        if (sources[o.audio]) {
            args.push("-a", sources[o.audio])
            args.push("-ac", o.container === "mp4" ? "aac" : "opus")
        }
        args.push("-o", file)
        return args
    }
}
