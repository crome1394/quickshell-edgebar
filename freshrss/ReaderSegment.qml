pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.theme

// A segmented picker: options side by side in one rounded track, the
// chosen one filled. Options are { id, label, tip }.
Rectangle {
    id: root

    required property var options
    required property string current

    signal picked(string id)

    implicitWidth: track.implicitWidth + Theme.borderWidth * 4
    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm + Theme.borderWidth * 2
    color: Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    Row {
        id: track
        anchors.centerIn: parent

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: segment
                required property var modelData
                readonly property bool chosen: root.current === segment.modelData.id

                width: caption.implicitWidth + Theme.space * 2
                height: root.height - Theme.borderWidth * 4
                radius: Theme.radiusSm
                color: segment.chosen ? Theme.accentDim : (segmentMouse.containsMouse ? Theme.hover : "transparent")

                Text {
                    id: caption
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: segment.chosen ? Theme.wsActiveText : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: segment.chosen
                }

                MouseArea {
                    id: segmentMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(segment.modelData.id)

                    HoverTip {
                        message: String(segment.modelData.tip || "")
                        show: segmentMouse.containsMouse && message.length > 0
                    }
                }
            }
        }
    }
}
