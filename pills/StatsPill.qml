import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// CPU, Memory, GPU, and VRAM. Loaded only while the widget is on the bar
// and at least one section is on. Sampling stops when this pill unloads.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1

    // A grown section lifts the pill above its neighbors on the bar.
    property bool dockHot: cpuGroup.dockHot || memGroup.dockHot || gpuGroup.dockHot || vramGroup.dockHot

    readonly property real ui: WidgetService.uiScale
    readonly property int sectionHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int pad: Math.max(4, Math.round(Theme.statPadH * root.ui * root.widthFactor))
    readonly property int sep: Math.max(6, Math.round(Theme.statSep * root.ui * root.widthFactor))
    readonly property bool showCpu: Config.showStatCpu
    readonly property bool showMem: Config.showStatMem
    readonly property bool showGpu: Config.showStatGpu
    readonly property bool showVram: Config.showStatVram
    readonly property bool showGauges: Config.showStatGauges
    readonly property int gaugeWidth: StatsSettings.gaugeWidthValue()
    readonly property color face: root.theme.colFg
    readonly property string faceFont: Config.fontClamp(Config.statFont)
    readonly property bool faceBold: Config.statBold !== false
    readonly property bool faceItalic: !!Config.statItalic
    readonly property int facePercent: StatsSettings.fontPercentValue()

    function utilColor(util, metric) {
        const bands = StatsSettings.bandsFor(metric)
        return Theme.statUtilColor(util, metric, bands[0], bands[1], bands[2])
    }

    readonly property real cpuUtil: stats.cpuUtil
    readonly property int cpuTemp: stats.cpuTemp
    readonly property real memUtil: stats.memUtil
    readonly property real memUsedGib: stats.memUsedGib
    readonly property real gpuUtil: stats.gpuUtil
    readonly property int gpuTemp: stats.gpuTemp
    readonly property bool gpuKnown: stats.gpuKnown
    readonly property real vramUtil: stats.vramUtil
    readonly property real vramUsedGib: stats.vramUsedGib
    readonly property bool vramKnown: stats.vramKnown

    function finite(value, fallback) {
        const n = Number(value)
        return n === n ? n : fallback
    }

    function pct(value) {
        return String(Math.round(root.finite(value, 0))) + "%"
    }

    function wholeGib(value) {
        return String(Math.round(root.finite(value, 0))) + "G"
    }

    function tenthGib(value) {
        const n = root.finite(value, 0)
        return (Math.round(n * 10) / 10).toFixed(1) + "G"
    }

    // group is "cpu" (CPU and Memory) or "gpu" (GPU and VRAM).
    function hint(group) {
        return StatsSettings.actionHint(group)
    }

    function launch(group, button) {
        const command = StatsSettings.actionArgv(group, button === Qt.RightButton ? "right" : "left")
        if (command.length)
            Quickshell.execDetached(command)
    }

    implicitWidth: cluster.implicitWidth + root.pad * 2
    implicitHeight: root.sectionHeight
    width: root.implicitWidth
    height: root.implicitHeight
    radius: Theme.radiusSm
    color: root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
    // A grown section may reach past the pill, so clip only while none is.
    clip: !root.dockHot

    SystemStats {
        id: stats
        gpuWanted: root.showGpu || root.showVram
    }

    Row {
        id: cluster
        anchors.centerIn: parent
        spacing: 0

        StatGroup {
            id: cpuGroup
            visible: root.showCpu
            theme: root.theme
            edge: root.edge
            label: "CPU"
            percentText: root.pct(root.cpuUtil)
            valueText: root.cpuTemp + "°"
            percentSample: "100%"
            valueSample: "100°"
            percentColor: root.utilColor(root.cpuUtil, "cpu")
            valueColor: Theme.statTempColor(root.cpuTemp)
            gaugeColor: root.utilColor(root.cpuUtil, "cpu")
            faceFont: root.faceFont
            faceBold: root.faceBold
            faceItalic: root.faceItalic
            facePercent: root.facePercent
            showGauge: root.showGauges
            gaugeWidth: root.gaugeWidth
            known: true
            fraction: root.cpuUtil / 100
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
            tip: root.hint("cpu")
            onActivated: (button) => root.launch("cpu", button)
        }

        Item {
            visible: root.showCpu && (root.showMem || root.showGpu || root.showVram)
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: Math.max(12, Math.round(15 * root.ui))
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatGroup {
            id: memGroup
            visible: root.showMem
            theme: root.theme
            edge: root.edge
            label: "Memory"
            percentText: root.pct(root.memUtil)
            valueText: root.wholeGib(root.memUsedGib)
            percentSample: "100%"
            valueSample: "100G"
            percentColor: root.utilColor(root.memUtil, "mem")
            valueColor: root.face
            gaugeColor: root.utilColor(root.memUtil, "mem")
            faceFont: root.faceFont
            faceBold: root.faceBold
            faceItalic: root.faceItalic
            facePercent: root.facePercent
            showGauge: root.showGauges
            gaugeWidth: root.gaugeWidth
            known: true
            fraction: root.memUtil / 100
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
            tip: root.hint("cpu")
            onActivated: (button) => root.launch("cpu", button)
        }

        Item {
            visible: root.showMem && (root.showGpu || root.showVram)
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: Math.max(12, Math.round(15 * root.ui))
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatGroup {
            id: gpuGroup
            visible: root.showGpu
            theme: root.theme
            edge: root.edge
            label: "GPU"
            percentText: root.gpuKnown ? root.pct(root.gpuUtil) : "N/A"
            valueText: root.gpuKnown ? (root.gpuTemp + "°") : "N/A"
            percentSample: "100%"
            valueSample: "100°"
            percentColor: root.gpuKnown ? root.utilColor(root.gpuUtil, "gpu") : root.theme.colFgMuted
            valueColor: root.gpuKnown ? Theme.statTempColor(root.gpuTemp) : root.theme.colFgMuted
            gaugeColor: root.utilColor(root.gpuUtil, "gpu")
            faceFont: root.faceFont
            faceBold: root.faceBold
            faceItalic: root.faceItalic
            facePercent: root.facePercent
            showGauge: root.showGauges
            gaugeWidth: root.gaugeWidth
            known: root.gpuKnown
            fraction: root.gpuUtil / 100
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
            tip: root.hint("gpu")
            onActivated: (button) => root.launch("gpu", button)
        }

        Item {
            visible: root.showGpu && root.showVram
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: Math.max(12, Math.round(15 * root.ui))
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatGroup {
            id: vramGroup
            visible: root.showVram
            theme: root.theme
            edge: root.edge
            label: "VRAM"
            percentText: root.vramKnown ? root.pct(root.vramUtil) : "N/A"
            valueText: root.vramKnown ? root.tenthGib(root.vramUsedGib) : "N/A"
            percentSample: "100%"
            valueSample: "99.9G"
            percentColor: root.vramKnown ? root.utilColor(root.vramUtil, "vram") : root.theme.colFgMuted
            valueColor: root.vramKnown ? root.face : root.theme.colFgMuted
            gaugeColor: root.utilColor(root.vramUtil, "vram")
            faceFont: root.faceFont
            faceBold: root.faceBold
            faceItalic: root.faceItalic
            facePercent: root.facePercent
            showGauge: root.showGauges
            gaugeWidth: root.gaugeWidth
            known: root.vramKnown
            fraction: root.vramUtil / 100
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
            tip: root.hint("gpu")
            onActivated: (button) => root.launch("gpu", button)
        }
    }
}
