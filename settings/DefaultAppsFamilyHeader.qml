import QtQuick
import qs.theme

// A collapsible family header on Default Apps → All file types
// ("Video · 42"). Click to show or hide its types.
Rectangle {
    id: root

    // A DefaultAppsLogic.familyRows() header row: { label, glyph, count, open }.
    required property var row

    signal toggled()

    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    color: headMouse.containsMouse ? Theme.hover : Theme.sectionBg

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.space
        spacing: Theme.space

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.smallPx
            text: root.row.open ? "▾" : "▸"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.chip
            horizontalAlignment: Text.AlignHCenter
            text: String(root.row.glyph || "")
            color: Theme.accent
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconPx
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.row.label || "")
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.row.count)
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    MouseArea {
        id: headMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
