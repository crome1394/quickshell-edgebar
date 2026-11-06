import QtQuick
import qs.config
import qs.theme

// One resolution on the Display page: a small screen drawn at the mode's
// own aspect ratio, the size, the ratio, and the fastest refresh rate.
Rectangle {
    id: root

    required property int modeWidth
    required property int modeHeight
    required property string topRate
    property bool selected: false
    property bool current: false
    property bool largest: false

    signal clicked()

    readonly property real aspect: root.modeHeight > 0 ? root.modeWidth / root.modeHeight : 16 / 9
    readonly property int screenBox: Theme.displayTileHeight - Theme.space * 2 - Theme.fontPx * 2 - Theme.tabGap

    implicitWidth: Theme.displayTileWidth
    implicitHeight: Theme.displayTileHeight
    radius: Theme.radiusSm
    color: root.selected ? Theme.accentDim : (tileMouse.containsMouse ? Theme.hover : Theme.fieldBg)
    border.width: root.selected ? Theme.borderWidth * 2 : Theme.borderWidth
    border.color: root.selected ? Theme.accent : (tileMouse.containsMouse ? Theme.accent : Theme.border)

    Behavior on color {
        ColorAnimation { duration: Theme.colorAnimMs }
    }

    // The screen outline, fitted inside its box at the right shape.
    Item {
        id: screenArea
        anchors.top: parent.top
        anchors.topMargin: Theme.space
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width - Theme.space * 2
        height: root.screenBox

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height * root.aspect)
            height: Math.min(parent.height, parent.width / root.aspect)
            radius: 2
            color: root.selected ? Theme.accent : Theme.pillBg
            opacity: root.selected ? 0.85 : 1
            border.width: Theme.borderWidth
            border.color: root.selected ? Theme.accent : Theme.subtext
        }
    }

    Column {
        anchors.top: screenArea.bottom
        anchors.topMargin: Theme.tabGap
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.modeWidth + " × " + root.modeHeight
            color: root.selected ? Theme.wsActiveText : Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DisplaySettings.ratioLabel(root.modeWidth, root.modeHeight) + " · up to " + root.topRate + " Hz"
            color: root.selected ? Theme.wsActiveText : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    // Native / Current badges in the corner.
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.borderWidth * 3
        spacing: Theme.borderWidth * 2

        Repeater {
            model: [
                { show: root.largest, label: "Native", ok: false },
                { show: root.current, label: "Current", ok: true }
            ]
            delegate: Rectangle {
                id: badge
                required property var modelData
                visible: badge.modelData.show
                width: badgeText.implicitWidth + Theme.tabGap * 2
                height: badgeText.implicitHeight + 2
                radius: height / 2
                color: badge.modelData.ok ? Theme.ok : Theme.accent

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: badge.modelData.label
                    color: Theme.pageBg
                    font.family: Theme.uiFont
                    font.pixelSize: Math.max(8, Theme.smallPx - 2)
                    font.bold: true
                }
            }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
