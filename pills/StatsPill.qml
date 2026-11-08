import QtQuick
import qs.config
import qs.services
import qs.theme

// CPU, Memory, GPU, and VRAM in one pill. Loaded only while the widget is
// on the bar, "Combine into one widget" is on, and at least one section is
// on. It holds the shared sampler while loaded.
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
    readonly property int dividerHeight: Math.max(12, Math.round(15 * root.ui))
    readonly property bool showCpu: Config.showStatCpu
    readonly property bool showMem: Config.showStatMem
    readonly property bool showGpu: Config.showStatGpu
    readonly property bool showVram: Config.showStatVram

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

    StatsHold {
        gpu: root.showGpu || root.showVram
    }

    Row {
        id: cluster
        anchors.centerIn: parent
        spacing: 0

        StatMetric {
            id: cpuGroup
            visible: root.showCpu
            metric: "cpu"
            theme: root.theme
            edge: root.edge
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
        }

        Item {
            visible: root.showCpu && (root.showMem || root.showGpu || root.showVram)
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: root.dividerHeight
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatMetric {
            id: memGroup
            visible: root.showMem
            metric: "mem"
            theme: root.theme
            edge: root.edge
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
        }

        Item {
            visible: root.showMem && (root.showGpu || root.showVram)
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: root.dividerHeight
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatMetric {
            id: gpuGroup
            visible: root.showGpu
            metric: "gpu"
            theme: root.theme
            edge: root.edge
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
        }

        Item {
            visible: root.showGpu && root.showVram
            width: root.sep
            height: root.sectionHeight

            Rectangle {
                width: Theme.borderWidth
                height: root.dividerHeight
                anchors.centerIn: parent
                color: root.theme.colStatDivider
            }
        }

        StatMetric {
            id: vramGroup
            visible: root.showVram
            metric: "vram"
            theme: root.theme
            edge: root.edge
            sectionHeight: root.sectionHeight
            ui: root.ui
            widthFactor: root.widthFactor
        }
    }
}
