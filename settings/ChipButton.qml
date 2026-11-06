import QtQuick
import qs.theme

// A small labeled button for settings pages. `active` marks a chosen
// option or a toggle that is on.
Rectangle {
    id: root

    required property string label
    property string tip: ""
    property bool active: false
    property bool bold: false
    property bool italic: false
    property int minWidth: Theme.fieldHeight

    signal clicked()

    implicitWidth: Math.max(root.minWidth, caption.implicitWidth + Theme.space * 2)
    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    opacity: root.enabled ? 1 : Theme.widgetOffOpacity
    color: root.active ? Theme.accentDim : (chipMouse.containsMouse && root.enabled ? Theme.hover : Theme.fieldBg)
    border.width: Theme.borderWidth
    border.color: root.active ? Theme.accent : Theme.border

    Text {
        id: caption
        anchors.centerIn: parent
        text: root.label
        color: root.active ? Theme.wsActiveText : Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: root.bold || root.active
        font.italic: root.italic
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()

        HoverTip {
            message: root.tip
            show: chipMouse.containsMouse && root.tip.length > 0
        }
    }
}
