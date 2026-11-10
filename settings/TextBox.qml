import QtQuick
import QtQuick.Controls
import qs.theme

// A one-line text field in the settings style. Edits stay in the field;
// the page reads `text` when it saves. `clearable` adds a small ✕ at the
// right that empties the field.
TextField {
    id: root

    property bool clearable: false

    // Emitted after the ✕ empties the field.
    signal cleared()

    height: Theme.fieldHeight
    verticalAlignment: Text.AlignVCenter
    selectByMouse: true
    leftPadding: Theme.space
    rightPadding: root.clearable ? Theme.chip + Theme.tabGap : Theme.space
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

    Rectangle {
        visible: root.clearable && root.text.length > 0 && !root.readOnly
        anchors.right: parent.right
        anchors.rightMargin: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.chip
        height: Theme.chip
        radius: Theme.radiusSm
        color: clearMouse.containsMouse ? Theme.hover : "transparent"

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: clearMouse.containsMouse ? Theme.text : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clear()
                root.forceActiveFocus()
                root.cleared()
            }

            HoverTip {
                message: "Clear"
                show: clearMouse.containsMouse
            }
        }
    }
}
