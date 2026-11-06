pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.theme

// A live level meter for one PipeWire node, one bar per channel, or one bar
// for the loudest channel when `combined`. Peaks come from PipeWire itself
// (PwNodePeakMonitor); it runs only while `live`.
Column {
    id: root

    required property var node
    required property var theme
    property bool live: true
    property bool combined: false

    readonly property int channels: monitor.peaks ? monitor.peaks.length : 0

    function peakAt(index) {
        const peaks = monitor.peaks || []
        if (!root.combined)
            return Number(peaks[index]) || 0
        let top = 0
        for (let i = 0; i < peaks.length; i++)
            top = Math.max(top, Number(peaks[i]) || 0)
        return top
    }

    spacing: Theme.borderWidth

    PwNodePeakMonitor {
        id: monitor
        node: root.node
        enabled: root.live && root.node !== null
    }

    Repeater {
        model: root.combined ? Math.min(1, root.channels) : root.channels
        delegate: Rectangle {
            id: bar
            required property int index
            readonly property real level: Math.max(0, Math.min(1, root.peakAt(bar.index)))
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
