import QtQuick
import qs.theme

Rectangle {
    id: root

    required property string title
    property string detail: ""
    property string tip: ""
    required property bool checked

    signal toggled()

    implicitHeight: root.detail.length ? 48 : 36
    radius: Theme.radiusSm
    color: Theme.pillBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    HoverHandler {
        id: rowHover
    }

    HoverTip {
        message: root.tip
        show: rowHover.hovered || boxMouse.containsMouse
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: Theme.space

        Column {
            width: parent.width - box.width - Theme.space
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.title
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }
            Text {
                visible: root.detail.length > 0
                width: parent.width
                elide: Text.ElideRight
                text: root.detail
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        Rectangle {
            id: box
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.checkBoxWidth
            height: Theme.checkBoxHeight
            radius: 4
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: root.checked ? Theme.ok : Theme.danger

            Text {
                anchors.centerIn: parent
                text: root.checked ? "✓" : "✕"
                color: root.checked ? Theme.ok : Theme.danger
                font.pixelSize: Theme.checkGlyphPx
                font.bold: true
            }

            MouseArea {
                id: boxMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }
    }
}
