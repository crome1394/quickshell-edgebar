pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Keeps the cropped edges of one monitor clear (System → Display → Edges,
// for a TV with overscan): one invisible strip per edge with an inset that
// only reserves space. They sit on the background layer, which Hyprland
// lays out first, so bars, popups, and windows all land inside them.
// Clicks pass through. Works the same on any GPU: plain layer-shell
// space, not a driver setting.
Scope {
    id: root

    required property ShellScreen modelData

    readonly property string name: String(root.modelData.name)
    readonly property var inset: DisplaySettings.insetsFor(root.name)

    function needed(edge) {
        return Number(root.inset[edge]) > 0
    }

    // One invisible strip per edge that needs one.
    Variants {
        model: ["top", "bottom", "left", "right"].filter((e) => root.needed(e))

        // qmllint disable uncreatable-type
        PanelWindow {
        // qmllint enable uncreatable-type
            id: win

            required property string modelData

            screen: root.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Number(root.inset[win.modelData]) || 0
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-inset"
            anchors.top: win.modelData !== "bottom"
            anchors.bottom: win.modelData !== "top"
            anchors.left: win.modelData !== "right"
            anchors.right: win.modelData !== "left"
            implicitWidth: 1
            implicitHeight: 1
            mask: Region {}
        }
    }
}
