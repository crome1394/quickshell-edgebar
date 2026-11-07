import QtQuick
import Quickshell
import Quickshell.Wayland

// Holds the idle inhibitor for Caffeine: a 1×1 transparent layer surface
// that ignores input. shell.qml creates it only while Caffeine is on, so
// closing it ends the inhibit.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    color: "transparent"
    implicitWidth: 1
    implicitHeight: 1
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-caffeine"
    mask: Region {}

    IdleInhibitor {
        window: root
        enabled: true
    }
}
