import QtQuick
import QtQuick.Controls
import qs.theme

// A one-line text field for a path or program name. `value` comes from the
// page draft; typing sends edited(). `bad` draws a red border.
TextField {
    id: root

    required property string value
    property bool bad: false
    property string tip: ""

    signal edited(string text)

    height: Theme.fieldHeight
    text: root.value
    selectByMouse: true
    leftPadding: Theme.space
    verticalAlignment: Text.AlignVCenter
    color: Theme.text
    placeholderTextColor: Theme.subtext
    font.family: Theme.uiFont
    font.pixelSize: Theme.fontPx
    background: Rectangle {
        radius: Theme.radiusSm
        color: root.activeFocus ? Theme.hover : Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: root.bad ? Theme.danger : (root.activeFocus ? Theme.accent : Theme.border)
    }
    onTextEdited: root.edited(root.text)

    HoverHandler {
        id: hover
    }

    HoverTip {
        message: root.tip
        show: hover.hovered && root.tip.length > 0
    }
}
