import QtQuick
import qs.services
import qs.theme

// One System Stats metric as its own widget, used when Widgets → System
// Stats has "Combine into one widget" off. Loaded only while it is on a
// bar; it holds the shared sampler while loaded.
Rectangle {
    id: root

    required property var theme
    required property string metric
    property string edge: "top"
    property real widthFactor: 1

    // A grown section lifts the pill above its neighbors on the bar.
    property bool dockHot: face.dockHot

    readonly property real ui: WidgetService.uiScale
    readonly property int sectionHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int pad: Math.max(4, Math.round(Theme.statPadH * root.ui * root.widthFactor))

    implicitWidth: face.implicitWidth + root.pad * 2
    implicitHeight: root.sectionHeight
    width: root.implicitWidth
    height: root.implicitHeight
    radius: Theme.radiusSm
    color: root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
    clip: !root.dockHot

    StatsHold {
        gpu: root.metric === "gpu" || root.metric === "vram"
    }

    StatMetric {
        id: face
        anchors.centerIn: parent
        metric: root.metric
        theme: root.theme
        edge: root.edge
        sectionHeight: root.sectionHeight
        ui: root.ui
        widthFactor: root.widthFactor
    }
}
