import QtQuick
import qs.theme

// One exit-node choice: a radio mark, a name, and where it is.
Rectangle {
    id: root

    required property var theme
    required property string label
    required property string detail
    required property bool chosen
    property bool online: true

    signal picked()

    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    color: rowMouse.containsMouse ? root.theme.colHover : "transparent"
    border.width: root.chosen ? Theme.borderWidth : 0
    border.color: root.theme.colAccent
    opacity: root.online ? 1 : Theme.widgetOffOpacity

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.space
        spacing: Theme.space

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.chip / 2
            height: width
            radius: width / 2
            color: root.chosen ? root.theme.colAccent : "transparent"
            border.width: Theme.borderWidth
            border.color: root.chosen ? root.theme.colAccent : root.theme.colFgMuted
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.chip / 2 - detailText.width - Theme.space * 2
            elide: Text.ElideRight
            text: root.label
            color: root.theme.colFg
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
            font.bold: root.chosen
        }

        Text {
            id: detailText
            anchors.verticalCenter: parent.verticalCenter
            text: root.detail
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
