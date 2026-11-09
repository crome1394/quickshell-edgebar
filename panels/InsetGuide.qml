import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme

// A frame drawn on one monitor at its edge inset while you adjust it
// (System → Display → Edges → Show guide). Move the sliders until the
// frame just fits inside the picture the TV shows. Clicks pass through.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    readonly property string name: DisplaySettings.guideMonitor
    readonly property var inset: DisplaySettings.insetsFor(root.name)

    function screenFor(name) {
        const list = Quickshell.screens
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].name) === name)
                return list[i]
        }
        return null
    }

    screen: root.screenFor(root.name)
    visible: root.screen !== null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-inset-guide"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    mask: Region {}

    // Dims what the inset hides, so the kept area stands out.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 0

        Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: Number(root.inset.top) || 0
            color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.35)
        }

        Rectangle {
            x: 0
            y: parent.height - height
            width: parent.width
            height: Number(root.inset.bottom) || 0
            color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.35)
        }

        Rectangle {
            x: 0
            y: 0
            width: Number(root.inset.left) || 0
            height: parent.height
            color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.35)
        }

        Rectangle {
            x: parent.width - width
            y: 0
            width: Number(root.inset.right) || 0
            height: parent.height
            color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.35)
        }
    }

    // The frame: everything inside it should be visible on the TV.
    Rectangle {
        x: Number(root.inset.left) || 0
        y: Number(root.inset.top) || 0
        width: parent.width - x - (Number(root.inset.right) || 0)
        height: parent.height - y - (Number(root.inset.bottom) || 0)
        color: "transparent"
        border.width: Theme.displayGuidePx
        border.color: Theme.ok

        Text {
            anchors.centerIn: parent
            width: Math.min(parent.width - Theme.space * 4, Theme.fieldHeight * 18)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.name + "\nMove the sliders until this green frame just fits inside the picture, with all four sides showing."
            color: Theme.ok
            style: Text.Outline
            styleColor: Theme.pageBg
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx * 1.5
            font.bold: true
        }
    }
}
