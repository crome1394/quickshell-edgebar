import QtQuick
import qs.settings
import qs.theme

// A small text button for bar menus (Tailscale, audio).
Rectangle {
    id: root

    required property var theme
    required property string label
    property string tip: ""
    property bool accent: false

    signal clicked()

    implicitWidth: chipText.implicitWidth + Theme.space * 2
    implicitHeight: Theme.chip
    radius: Theme.radiusSm
    color: chipMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.accent || chipMouse.containsMouse ? root.theme.colAccent : root.theme.colBorder

    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.theme.colFg
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
        font.bold: true
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        HoverTip {
            message: root.tip
            show: chipMouse.containsMouse
        }
    }
}
