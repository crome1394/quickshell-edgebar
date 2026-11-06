import QtQuick
import qs.theme

// A button for the footer row of a settings page or the Inspector, bottom
// right. `primary` marks the main action (Apply) when it is enabled.
Rectangle {
    id: root

    required property string label
    property string tip: ""
    property bool primary: false
    property bool bold: false

    readonly property bool lit: root.primary && root.enabled

    signal clicked()

    implicitWidth: buttonLabel.implicitWidth + Theme.space * 2
    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    opacity: root.enabled ? 1 : Theme.widgetOffOpacity
    color: root.lit && buttonMouse.containsMouse
        ? Theme.accentDim
        : (buttonMouse.containsMouse && root.enabled ? Theme.hover : Theme.pillBg)
    border.width: Theme.borderWidth
    border.color: root.lit ? Theme.accent : Theme.border

    Text {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.lit ? Theme.wsActiveText : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
        font.bold: root.bold
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.enabled)
                root.clicked()
        }

        HoverTip {
            message: root.tip
            show: buttonMouse.containsMouse && root.tip.length > 0
        }
    }
}
