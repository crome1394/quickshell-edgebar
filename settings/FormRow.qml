import QtQuick
import qs.theme

// One labeled row on a form-style settings page: the label on the left in
// a fixed column, the controls on the right. Children go in the right side
// and can use `parent.width`.
Item {
    id: root

    required property string label
    default property alias content: slot.data

    implicitHeight: Math.max(Theme.fieldHeight, slot.childrenRect.height)

    Text {
        id: caption
        width: Theme.formLabelWidth
        height: Theme.fieldHeight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: root.label
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
    }

    Item {
        id: slot
        x: caption.width + Theme.space
        width: Math.max(0, root.width - slot.x)
        height: root.implicitHeight
    }
}
