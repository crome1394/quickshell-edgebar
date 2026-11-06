pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.theme

// A live level meter for one PipeWire node, one bar per channel. Peaks come
// from PipeWire itself (PwNodePeakMonitor); it runs only while `live`.
Column {
    id: root

    required property var node
    required property var theme
    property bool live: true

    spacing: Theme.borderWidth

    PwNodePeakMonitor {
        id: monitor
        node: root.node
        enabled: root.live && root.node !== null
    }

    Repeater {
        model: monitor.peaks ? monitor.peaks.length : 0
        delegate: Rectangle {
            id: bar
            required property int index
            readonly property real level: Math.max(0, Math.min(1, Number(monitor.peaks[bar.index]) || 0))
            width: root.width
            height: Theme.audioMeterHeight
            radius: height / 2
            color: root.theme.colSurface

            Rectangle {
                width: parent.width * bar.level
                height: parent.height
                radius: parent.radius
                color: bar.level > 0.9 ? root.theme.colDanger : (bar.level > 0.7 ? root.theme.colAccent : root.theme.colOk)
            }
        }
    }
}
