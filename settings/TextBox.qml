import QtQuick
import QtQuick.Controls
import qs.theme

// A one-line text field in the settings style. Edits stay in the field;
// the page reads `text` when it saves.
TextField {
    id: root

    height: Theme.fieldHeight
    verticalAlignment: Text.AlignVCenter
    selectByMouse: true
    leftPadding: Theme.space
    color: Theme.text
    placeholderTextColor: Theme.subtext
    font.family: Theme.uiFont
    font.pixelSize: Theme.fontPx
    background: Rectangle {
        radius: Theme.radiusSm
        color: root.activeFocus ? Theme.hover : Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: root.activeFocus ? Theme.accent : Theme.border
    }
}
