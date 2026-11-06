import QtQuick
import qs.settings
import qs.theme

// One on/off row in the Tailscale menu: a label and a sliding switch.
Item {
    id: root

    required property var theme
    required property string label
    required property bool on
    property string tip: ""
    property bool bold: false

    signal toggled(bool on)

    implicitHeight: Theme.fieldHeight

    Text {
        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.label
        color: root.theme.colFg
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.fontPx
        font.bold: root.bold
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.toggleWidth + Theme.space
        height: Theme.chip - Theme.tabGap
        radius: height / 2
        color: root.on ? root.theme.colAccentDim : root.theme.colSurface
        border.width: Theme.borderWidth
        border.color: root.on ? root.theme.colAccent : root.theme.colBorder

        Rectangle {
            width: parent.height - Theme.tabGap * 2
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.on ? parent.width - width - Theme.tabGap : Theme.tabGap
            color: root.on ? root.theme.colAccent : root.theme.colFgMuted

            Behavior on x {
                NumberAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
            }
        }
    }

    MouseArea {
        id: switchMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.on)

        HoverTip {
            message: root.tip
            show: switchMouse.containsMouse && root.tip.length > 0
        }
    }
}
