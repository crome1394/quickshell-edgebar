import QtQuick
import qs.theme

// Title band for a settings section. The accent sliver matches the bar headers.
// Use the full page width. Inset the section body by Theme.sectionInset.
Item {
    id: root

    required property string title
    property string hint: ""

    implicitHeight: Math.max(Theme.fieldHeight, titleCol.implicitHeight) + Theme.space

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.sectionBg
    }

    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.tabGap
        anchors.rightMargin: Theme.tabGap
        spacing: Theme.space

        Rectangle {
            id: accent
            width: Theme.dividerThickness + Theme.borderWidth
            height: Theme.fieldHeight
            radius: Theme.borderWidth
            color: Theme.accent
        }

        Column {
            id: titleCol
            width: Math.max(1, titleRow.width - accent.width - titleRow.spacing)
            spacing: Theme.borderWidth

            Text {
                width: titleCol.width
                elide: Text.ElideRight
                text: root.title
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            Text {
                visible: root.hint.length > 0
                width: titleCol.width
                wrapMode: Text.WordWrap
                text: root.hint
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }
    }
}
