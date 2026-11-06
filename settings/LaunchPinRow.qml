pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
    id: root

    required property string name
    required property string iconName
    required property string detail
    required property string pinKey

    signal dragAt(string pinKey, real x, real y)
    signal dragFinished(bool commit)
    signal removeRequested()

    property real pressX: 0
    property real pressY: 0
    property bool armed: false

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

        Rectangle {
            id: grip
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            color: gripMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "||"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: gripMouse
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.SizeAllCursor
                onPressed: (mouse) => {
                    root.pressX = mouse.x
                    root.pressY = mouse.y
                    root.armed = false
                }
                onPositionChanged: (mouse) => {
                    if (!gripMouse.pressed)
                        return
                    const dx = mouse.x - root.pressX
                    const dy = mouse.y - root.pressY
                    const slop = Theme.space * Theme.space
                    if (!root.armed && (dx * dx + dy * dy) < slop)
                        return
                    root.armed = true
                    const point = gripMouse.mapToItem(null, mouse.x, mouse.y)
                    root.dragAt(root.pinKey, point.x, point.y)
                }
                onReleased: {
                    if (root.armed)
                        root.dragFinished(true)
                    root.armed = false
                }
                onCanceled: {
                    if (root.armed)
                        root.dragFinished(false)
                    root.armed = false
                }

                HoverTip {
                    message: "Drag to move this pin"
                    show: gripMouse.containsMouse && !root.armed
                }
            }
        }

        LaunchIcon {
            id: iconBox
            width: Theme.chip
            height: parent.height
            name: root.name
            iconName: root.iconName
        }

        Item {
            id: labelBox
            width: Math.max(1, parent.width - grip.width - iconBox.width - removeButton.width - Theme.tabGap * 3)
            height: parent.height

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 0

                Text {
                    width: parent.width
                    height: Theme.fontPx + Theme.borderWidth
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.name
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }

                Text {
                    visible: root.detail.length > 0
                    width: parent.width
                    height: Theme.smallPx + Theme.borderWidth
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.detail
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }

        Rectangle {
            id: removeButton
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            color: removeMouse.containsMouse ? Theme.hover : "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.danger

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Theme.danger
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            MouseArea {
                id: removeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeRequested()

                HoverTip {
                    message: "Remove this pin"
                    show: removeMouse.containsMouse
                }
            }
        }
    }
}
