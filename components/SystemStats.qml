import QtQuick
import Quickshell.Io
import qs.theme

// CPU, memory, and NVIDIA samples for the System Stats pill.
// CPU and memory come from /proc, CPU temp from hwmon, so no process runs
// for them. The GPU uses one long-running nvidia-smi in loop mode, started
// only while gpuWanted is true. A missing GPU reads as unknown, not 0.
Item {
    id: root

    required property bool gpuWanted

    property real cpuUtil: 0
    property int cpuTemp: 0
    property real memUtil: 0
    property real memUsedGib: 0
    property bool gpuKnown: false
    property real gpuUtil: 0
    property int gpuTemp: 0
    property bool vramKnown: false
    property real vramUtil: 0
    property real vramUsedGib: 0

    property var lastCpu: null
    property string tempPath: ""

    readonly property real kibPerGib: 1048576
    readonly property real mibPerGib: 1024

    function clampPct(value) {
        return Math.max(0, Math.min(100, value))
    }

    function readCpu(text) {
        const line = String(text || "").split("\n")[0]
        if (!line.startsWith("cpu "))
            return
        const f = line.trim().split(/\s+/).slice(1).map(Number)
        if (f.length < 8 || f.some(n => n !== n))
            return
        // user nice system idle iowait irq softirq steal
        const idle = f[3] + f[4]
        const total = f[0] + f[1] + f[2] + idle + f[5] + f[6] + f[7]
        const last = root.lastCpu
        root.lastCpu = { idle: idle, total: total }
        if (!last)
            return
        const dt = total - last.total
        if (dt > 0)
            root.cpuUtil = root.clampPct((dt - (idle - last.idle)) * 100 / dt)
    }

    function readMem(text) {
        const total = /^MemTotal:\s+(\d+)/m.exec(String(text || ""))
        const avail = /^MemAvailable:\s+(\d+)/m.exec(String(text || ""))
        if (!total || !avail || Number(total[1]) <= 0)
            return
        const used = Math.max(0, Number(total[1]) - Number(avail[1]))
        root.memUtil = root.clampPct(used * 100 / Number(total[1]))
        root.memUsedGib = used / root.kibPerGib
    }

    function readTemp(text) {
        const raw = Number(String(text || "").trim())
        if (raw === raw && raw >= 0 && raw <= 200000)
            root.cpuTemp = Math.round(raw / 1000)
    }

    // Prefer k10temp (AMD), then coretemp (Intel).
    function pickSensor(text) {
        let best = ""
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const at = lines[i].lastIndexOf(":")
            if (at < 0)
                continue
            const name = lines[i].slice(at + 1).trim()
            const dir = lines[i].slice(0, at).replace(/\/name$/, "")
            if (name === "k10temp")
                return dir
            if (name === "coretemp" && !best.length)
                best = dir
        }
        return best
    }

    function readGpu(line) {
        const f = String(line || "").split(",").map(s => Number(s.trim()))
        if (f.length < 4 || f.some(n => n !== n)) {
            root.gpuKnown = false
            root.vramKnown = false
            return
        }
        root.gpuKnown = true
        root.gpuUtil = root.clampPct(f[0])
        root.gpuTemp = Math.round(f[1])
        root.vramKnown = f[3] > 0
        if (root.vramKnown) {
            root.vramUtil = root.clampPct(f[2] * 100 / f[3])
            root.vramUsedGib = f[2] / root.mibPerGib
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root.readCpu(statFile.text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root.readMem(memFile.text())
    }

    FileView {
        id: tempFile
        path: root.tempPath.length ? root.tempPath + "/temp1_input" : ""
        onLoaded: root.readTemp(tempFile.text())
    }

    // One-shot lookup of the CPU sensor folder. No shell, fixed argv.
    Process {
        running: true
        command: ["find", "-L", "/sys/class/hwmon", "-mindepth", "2", "-maxdepth", "2",
            "-name", "name", "-exec", "grep", "-H", ".", "{}", "+"]
        stdout: StdioCollector {
            id: sensorList
            onStreamFinished: root.tempPath = root.pickSensor(sensorList.text)
        }
    }

    Process {
        id: gpuProc
        running: root.gpuWanted
        command: ["nvidia-smi",
            "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
            "--format=csv,noheader,nounits", "-lms", String(Theme.statPollMs)]
        stdout: SplitParser {
            onRead: (line) => root.readGpu(line)
        }
        onExited: {
            root.gpuKnown = false
            root.vramKnown = false
        }
    }

    Timer {
        interval: Theme.statPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            if (root.tempPath.length)
                tempFile.reload()
        }
    }
}
