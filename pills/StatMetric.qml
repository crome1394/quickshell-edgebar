import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme

// One metric ("cpu", "mem", "gpu", or "vram") from StatsService, with the
// saved font, bars, thresholds, and click commands. StatsPill draws four;
// a StatPill draws one. The owner must hold StatsService (StatsHold).
StatGroup {
    id: root

    required property string metric

    readonly property bool onGpu: root.metric === "gpu" || root.metric === "vram"
    // CPU and Memory share the CPU click commands; GPU and VRAM the GPU ones.
    readonly property string group: root.onGpu ? "gpu" : "cpu"
    readonly property bool hasTemp: root.metric === "cpu" || root.metric === "gpu"

    readonly property real util: {
        if (root.metric === "mem")
            return StatsService.memUtil
        if (root.metric === "gpu")
            return StatsService.gpuUtil
        if (root.metric === "vram")
            return StatsService.vramUtil
        return StatsService.cpuUtil
    }
    readonly property bool knownNow: {
        if (root.metric === "gpu")
            return StatsService.gpuKnown
        if (root.metric === "vram")
            return StatsService.vramKnown
        return true
    }
    readonly property bool tempKnown: root.metric === "cpu" || (root.knownNow && StatsService.gpuTempKnown)
    readonly property int temp: root.metric === "gpu" ? StatsService.gpuTemp : StatsService.cpuTemp
    readonly property color barColor: {
        const bands = StatsSettings.bandsFor(root.metric)
        return ThemeStore.statUtilColor(root.util, root.metric, bands[0], bands[1], bands[2])
    }

    function finite(value) {
        const n = Number(value)
        return n === n ? n : 0
    }

    function usedText() {
        if (!root.knownNow)
            return "N/A"
        if (root.metric === "vram")
            return (Math.round(root.finite(StatsService.vramUsedGib) * 10) / 10).toFixed(1) + "G"
        return String(Math.round(root.finite(StatsService.memUsedGib))) + "G"
    }

    function tempText() {
        if (root.tempKnown)
            return root.temp + "°"
        return root.knownNow ? "—" : "N/A"
    }

    label: ({ cpu: "CPU", mem: "Memory", gpu: "GPU", vram: "VRAM" })[root.metric] || "CPU"
    percentText: root.knownNow ? String(Math.round(root.finite(root.util))) + "%" : "N/A"
    valueText: root.hasTemp ? root.tempText() : root.usedText()
    percentSample: "100%"
    valueSample: root.hasTemp ? "100°" : (root.metric === "vram" ? "99.9G" : "100G")
    percentColor: root.knownNow ? root.barColor : root.theme.colFgMuted
    valueColor: {
        if (root.hasTemp)
            return root.tempKnown ? ThemeStore.statTempColor(root.temp) : root.theme.colFgMuted
        return root.knownNow ? root.theme.colFg : root.theme.colFgMuted
    }
    gaugeColor: root.barColor
    known: root.knownNow
    fraction: root.util / 100
    showGauge: Config.showStatGauges
    gaugeWidth: StatsSettings.gaugeWidthValue()
    faceFont: Config.fontClamp(Config.statFont)
    faceBold: Config.statBold !== false
    faceItalic: !!Config.statItalic
    facePercent: StatsSettings.fontPercentValue()
    tip: StatsSettings.actionHint(root.group)

    onActivated: (button) => {
        const command = StatsSettings.actionArgv(root.group, button === Qt.RightButton ? "right" : "left")
        if (command.length)
            Quickshell.execDetached(command)
    }
}
