pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// Screen recording with gpu-screen-recorder (encoded on the GPU). Records
// the focused monitor, or a region picked with slurp. Stop sends Ctrl-C,
// so the recorder finishes the file properly. Nothing runs while idle.
//
//   qs ipc call recorder toggle | start | startRegion | stop | status
Singleton {
    id: root

    property bool available: false
    property bool checked: false
    property bool recording: false
    property bool picking: false
    property real startedAt: 0
    property real now: Date.now()
    property string file: ""
    property string lastFile: ""
    property string error: ""
    // Video codecs this GPU encodes in hardware, from gpu-screen-recorder --info.
    property var codecs: []

    readonly property int seconds: root.recording ? Math.max(0, Math.floor((root.now - root.startedAt) / 1000)) : 0
    readonly property string elapsed: {
        const s = root.seconds
        const m = Math.floor(s / 60)
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    function stamp() {
        const d = new Date()
        const two = (n) => (n < 10 ? "0" : "") + n
        return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate()) + "_" + two(d.getHours()) + "-" + two(d.getMinutes()) + "-" + two(d.getSeconds())
    }

    function start(target) {
        if (root.recording || root.picking || recorder.running)
            return "already recording"
        if (!root.available)
            return "gpu-screen-recorder is not installed"
        root.error = ""
        const opts = RecorderSettings.snapshot()
        if ((target || opts.target) === "region") {
            root.picking = true
            slurp.running = true
            return "pick a region"
        }
        const monitor = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name) : ""
        if (!DisplaySettings.outputOk(monitor)) {
            root.error = "No focused monitor to record."
            return root.error
        }
        root.launch(opts, monitor, "")
        return "recording " + monitor
    }

    function launch(opts, target, geometry) {
        opts = Object.assign({}, opts, { codec: RecorderSettings.resolveCodec(opts.codec, root.codecs) })
        root.file = opts.dir + "/Recording_" + root.stamp() + "." + opts.container
        recorder.command = RecorderSettings.argv(opts, target, geometry, root.file)
        mkdir.command = ["mkdir", "-p", "--", opts.dir]
        mkdir.running = true
    }

    function stop() {
        if (!recorder.running)
            return "not recording"
        // SIGINT: gpu-screen-recorder writes out the file and exits.
        recorder.signal(2)
        return "stopping"
    }

    function toggle() {
        return root.recording ? root.stop() : root.start("")
    }

    function describe() {
        if (!root.available)
            return "gpu-screen-recorder is not installed"
        if (root.recording)
            return "recording " + root.elapsed + " to " + root.file
        return root.lastFile.length ? "idle; last saved " + root.lastFile : "idle"
    }

    function openFolder() {
        Qt.openUrlExternally("file://" + RecorderSettings.snapshot().dir)
    }

    Component.onCompleted: probe.running = true

    Process {
        id: probe
        command: ["sh", "-c", "command -v gpu-screen-recorder"]
        onExited: (code) => {
            root.available = code === 0
            root.checked = true
            if (root.available)
                info.running = true
        }
    }

    // Which codecs the GPU can encode, read once.
    Process {
        id: info
        command: ["gpu-screen-recorder", "--info"]
        stdout: StdioCollector {
            id: infoOut
            waitForEnd: true
        }
        onExited: {
            const lines = String(infoOut.text || "").split("\n")
            const out = []
            let inCodecs = false
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (line.startsWith("section="))
                    inCodecs = line === "section=video_codecs"
                else if (inCodecs && /^(h264|hevc|av1|vp8|vp9)$/.test(line))
                    out.push(line)
            }
            root.codecs = out
        }
    }

    // Drag a region; slurp prints WxH+X+Y, or nothing when cancelled.
    // slurp reads preset boxes from stdin when stdin is not a terminal,
    // and Process always gives it an open pipe, so it waited forever and
    // never showed. An empty stdin (a fixed line, nothing added) fixes it.
    Process {
        id: slurp
        command: ["sh", "-c", "exec slurp -f '%wx%h+%x+%y' </dev/null"]
        stdout: StdioCollector {
            id: slurpOut
            waitForEnd: true
        }
        onExited: (code) => {
            root.picking = false
            const geometry = String(slurpOut.text || "").trim()
            if (code !== 0 || !/^\d{1,5}x\d{1,5}\+-?\d{1,5}\+-?\d{1,5}$/.test(geometry))
                return
            root.launch(RecorderSettings.snapshot(), "region", geometry)
        }
    }

    Process {
        id: mkdir
        onExited: (code) => {
            if (code !== 0) {
                root.error = "Could not create the folder for recordings."
                return
            }
            recorder.running = true
        }
    }

    Process {
        id: recorder
        stderr: StdioCollector {
            id: recErr
            waitForEnd: true
        }
        onStarted: {
            root.startedAt = Date.now()
            root.now = root.startedAt
            root.recording = true
        }
        onExited: (code) => {
            root.recording = false
            // 0, or the Ctrl-C exit codes, mean a finished file.
            if (code === 0 || code === 2 || code === 130) {
                root.lastFile = root.file
                if (Config.recNotify)
                    Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "Recording saved", root.file])
            } else {
                const said = String(recErr.text || "").trim().split("\n").slice(-2).join(" ")
                root.error = "Recording failed (exit " + code + ")" + (said.length ? ": " + said.substring(0, 240) : ".")
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.now = Date.now()
    }

    // qs ipc call recorder toggle        start (default target) or stop, like a left click
    // qs ipc call recorder start         the focused monitor or a region, per Settings
    // qs ipc call recorder startRegion   pick a region with the mouse
    // qs ipc call recorder stop
    // qs ipc call recorder status
    IpcHandler {
        target: "recorder"
        function toggle(): string { return root.toggle() }
        function start(): string { return root.start("") }
        function startRegion(): string { return root.start("region") }
        function stop(): string { return root.stop() }
        function status(): string { return root.describe() }
    }
}
