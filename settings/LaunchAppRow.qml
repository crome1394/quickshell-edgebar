pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
    id: root

    required property string name
    required property string iconName

    signal pinRequested()

    implicitHeight: Theme.dividerRowHeight
    height: Theme.dividerRowHeight
    radius: Theme.radiusSm
    color: Theme.pillBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.tabGap
        spacing: Theme.tabGap

        LaunchIcon {
            id: iconBox
            width: Theme.chip
            height: parent.height
            name: root.name
            iconName: root.iconName
        }

        Text {
            width: Math.max(1, parent.width - iconBox.width - pinButton.width - Theme.tabGap * 2)
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.name
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Rectangle {
            id: pinButton
            width: pinLabel.implicitWidth + Theme.space * 2
            height: parent.height
            radius: Theme.radiusSm
            color: pinMouse.containsMouse ? Theme.accentDim : Theme.fieldBg

            Text {
                id: pinLabel
                anchors.centerIn: parent
                text: "Pin"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pinRequested()

                HoverTip {
                    message: "Pin this app to Launcher 1"
                    show: pinMouse.containsMouse
                }
            }
        }
    }
}
