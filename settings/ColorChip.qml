import QtQuick
import qs.theme

// A color swatch with its hex code. Clicking asks the page for a picker.
Rectangle {
    id: root

    required property color value
    property string tip: ""
    // Shown instead of a hex code when `value` is fully transparent.
    property string emptyText: ""
    readonly property bool empty: root.value.a === 0 && root.emptyText.length > 0

    signal clicked()

    implicitWidth: Theme.chip + hexText.implicitWidth + Theme.space * 3
    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    color: chipMouse.containsMouse ? Theme.hover : Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: chipMouse.containsMouse ? Theme.accent : Theme.border

    Rectangle {
        id: swatch
        x: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.chip - Theme.tabGap
        height: Theme.chip - Theme.tabGap
        radius: Theme.radiusSm
        color: root.value
        border.width: Theme.borderWidth
        border.color: Theme.border
    }

    Text {
        id: hexText
        anchors.left: swatch.right
        anchors.leftMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        text: root.empty ? root.emptyText : ThemeBuilder.rgbText(root.value)
        color: root.empty ? Theme.subtext : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.smallPx
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        HoverTip {
            message: root.tip
            show: chipMouse.containsMouse && root.tip.length > 0
        }
    }
}
