pragma ComponentBehavior: Bound
import QtQuick
import qs.components
import qs.theme

// A reader button with its keyboard key shown beside the label, so the
// mouse and the keyboard teach each other. `caps` are the key caps.
Rectangle {
    id: root

    required property string label
    property var caps: []
    property string tip: ""
    property bool active: false

    signal clicked()

    implicitWidth: content.implicitWidth + Theme.space * 2
    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    opacity: root.enabled ? 1 : Theme.widgetOffOpacity
    color: root.active ? Theme.accentDim : (chipMouse.containsMouse && root.enabled ? Theme.hover : Theme.fieldBg)
    border.width: Theme.borderWidth
    border.color: root.active ? Theme.accent : Theme.border

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.tabGap

        // Same height as a key cap, so the row lines up without anchors.
        Text {
            height: Theme.keyCapHeight
            verticalAlignment: Text.AlignVCenter
            text: root.label
            color: root.active ? Theme.wsActiveText : Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: root.active
        }

        Repeater {
            model: root.caps
            delegate: KeyCap {
                required property string modelData
                label: modelData
                dim: true
            }
        }
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
