import QtQuick
import qs.theme

// One checked dependency: a status mark, its name, what it is for, and
// where it was found or which package provides it.
Item {
    id: root

    required property string name
    required property string use
    required property string need
    required property bool ok
    required property bool known
    property string detail: ""

    readonly property color mark: !root.known ? Theme.subtext
        : (root.ok ? Theme.ok : (root.need === "required" ? Theme.danger : Theme.accent))

    implicitHeight: Math.max(Theme.fieldHeight, textCol.implicitHeight + Theme.tabGap)

    Text {
        id: markText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.chip
        horizontalAlignment: Text.AlignHCenter
        text: !root.known ? "…" : (root.ok ? "✓" : "✕")
        color: root.mark
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    Column {
        id: textCol
        anchors.left: markText.right
        anchors.leftMargin: Theme.tabGap
        anchors.right: needText.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.name + "  ·  " + root.use
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Text {
            width: parent.width
            visible: root.detail.length > 0
            elide: Text.ElideMiddle
            text: root.detail
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    Text {
        id: needText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.need === "required" ? "Required" : "Optional"
        color: root.need === "required" ? Theme.text : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }
}
