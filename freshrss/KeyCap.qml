import QtQuick
import qs.theme

// One keyboard key drawn as a small cap, for the shortcut sheet, the
// footer, and button hints.
Rectangle {
    id: root

    required property string label
    property bool dim: false

    implicitWidth: Math.max(Theme.keyCapHeight, caption.implicitWidth + Theme.tabGap * 2)
    implicitHeight: Theme.keyCapHeight
    radius: Theme.radiusSm
    color: root.dim ? "transparent" : Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    Text {
        id: caption
        anchors.centerIn: parent
        text: root.label
        color: root.dim ? Theme.subtext : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.smallPx
        font.bold: true
    }
}
