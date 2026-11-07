import QtQuick
import Quickshell.Io
import qs.services
import qs.theme

// CPU, memory, and GPU samples for the System Stats pill.
// CPU and memory come from /proc, CPU temp from hwmon, so no process runs
// for them. The GPU is the card GpuService picks, read only while
// gpuWanted is true: NVIDIA through one long-running nvidia-smi in loop
// mode; AMD from sysfs (busy percent, VRAM, hwmon temperature); Intel from
// its current and top clock, an estimate of load, with no VRAM of its own.
// A missing GPU reads as unknown, not 0.
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
    property bool gpuTempKnown: false
    property bool vramKnown: false
    property real vramUtil: 0
    property real vramUsedGib: 0

    property var lastCpu: null
    property string tempPath: ""

    readonly property real kibPerGib: 1048576
    readonly property real mibPerGib: 1024
    readonly property real bytesPerGib: 1073741824

    readonly property var gpu: root.gpuWanted ? GpuService.chosen : null
    readonly property string gpuSource: root.gpu ? root.gpu.source : ""
    readonly property string cardDir: root.gpu ? "/sys/class/drm/" + root.gpu.card : ""

    function num(text) {
        const t = String(text || "").trim()
        const n = t.length ? Number(t) : NaN
        return n === n ? n : -1
    }

    // AMD and Intel: one sample from the files read this tick.
    function readSysGpu() {
        if (root.gpuSource === "amd") {
            const busy = root.num(busyFile.text())
            root.gpuKnown = busy >= 0
            root.gpuUtil = root.clampPct(busy)
            const used = root.num(vramUsedFile.text())
            const total = root.num(vramTotalFile.text())
            root.vramKnown = used >= 0 && total > 0
            if (root.vramKnown) {
                root.vramUtil = root.clampPct(used * 100 / total)
                root.vramUsedGib = used / root.bytesPerGib
            }
        } else if (root.gpuSource === "intel") {
            const act = root.num(actFile.text())
            const top = root.num(topFile.text())
            root.gpuKnown = act >= 0 && top > 0
            root.gpuUtil = root.gpuKnown ? root.clampPct(act * 100 / top) : 0
            root.vramKnown = false
        }
        const t = root.num(gpuTempFile.text())
        root.gpuTempKnown = t >= 0 && t <= 200000
        if (root.gpuTempKnown)
            root.gpuTemp = Math.round(t / 1000)
    }

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

    // Bus id without its PCI domain, e.g. "01:00.0".
    function busKey(id) {
        return String(id || "").trim().toLowerCase().replace(/^[0-9a-f]+:/, "")
    }

    // One nvidia-smi line: bus id, util, temp, used MiB, total MiB. Lines
    // for other NVIDIA cards are skipped.
    function readGpu(line) {
        const parts = String(line || "").split(",")
        const want = root.gpu ? root.busKey(root.gpu.bus) : ""
        if (want.length && root.busKey(parts[0]) !== want)
            return
        const f = parts.slice(1).map(s => Number(s.trim()))
        if (f.length < 4 || f.some(n => n !== n)) {
            root.gpuKnown = false
            root.vramKnown = false
            return
        }
        root.gpuKnown = true
        root.gpuUtil = root.clampPct(f[0])
        root.gpuTemp = Math.round(f[1])
        root.gpuTempKnown = true
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

    // AMD and Intel files; a path is set only for the card's own driver, so
    // nothing is read while the GPU section is hidden. Missing files read
    // as unknown.
    FileView {
        id: busyFile
        path: root.gpuSource === "amd" ? root.cardDir + "/device/gpu_busy_percent" : ""
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: vramUsedFile
        path: root.gpuSource === "amd" ? root.cardDir + "/device/mem_info_vram_used" : ""
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: vramTotalFile
        path: root.gpuSource === "amd" ? root.cardDir + "/device/mem_info_vram_total" : ""
        printErrors: false
        blockLoading: true
    }

    // i915 has the clocks on the card; xe under tile0/gt0/freq0.
    FileView {
        id: actFile
        path: root.gpuSource !== "intel" ? ""
            : (root.gpu.driver === "xe" ? root.cardDir + "/device/tile0/gt0/freq0/act_freq" : root.cardDir + "/gt_act_freq_mhz")
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: topFile
        path: root.gpuSource !== "intel" ? ""
            : (root.gpu.driver === "xe" ? root.cardDir + "/device/tile0/gt0/freq0/max_freq" : root.cardDir + "/gt_RP0_freq_mhz")
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: gpuTempFile
        path: (root.gpuSource === "amd" || root.gpuSource === "intel") && root.gpu.hwmon.length ? root.gpu.hwmon + "/temp1_input" : ""
        printErrors: false
        blockLoading: true
    }

    onGpuSourceChanged: {
        if (root.gpuSource !== "nvidia") {
            root.gpuKnown = false
            root.gpuTempKnown = false
            root.vramKnown = false
        }
    }

    Process {
        id: gpuProc
        running: root.gpuSource === "nvidia"
        command: ["nvidia-smi",
            "--query-gpu=pci.bus_id,utilization.gpu,temperature.gpu,memory.used,memory.total",
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
            if (root.gpuSource === "amd" || root.gpuSource === "intel") {
                busyFile.reload()
                vramUsedFile.reload()
                vramTotalFile.reload()
                actFile.reload()
                topFile.reload()
                gpuTempFile.reload()
                root.readSysGpu()
            }
        }
    }
}
