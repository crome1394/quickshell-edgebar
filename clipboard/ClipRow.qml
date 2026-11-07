import QtQuick
import qs.components
import qs.settings
import qs.theme

// One clipboard entry in the list: a kind tag (or a swatch for a color),
// up to two lines of its text, and its Alt+number for the first nine.
// `current` is the one highlighted row; moving the mouse over a row
// moves it there. A click
// copies; the ✕ deletes.
Rectangle {
    id: root

    required property var entry
    required property bool current
    required property int number

    // The pointer moved over this row; `at` is where, on screen.
    signal hovered(point at)
    signal clicked()
    signal deleteClicked()

    readonly property string kind: String(root.entry.kind || "text")
    readonly property bool pointed: rowMouse.containsMouse || removeMouse.containsMouse
    readonly property var tagText: ({ text: "TEXT", code: "CODE", link: "LINK", path: "PATH", image: "IMAGE", color: "" })

    implicitHeight: Theme.clipboardRowHeight
    radius: Theme.radiusSm
    color: root.current ? Theme.accentDim : "transparent"

    // Cursor bar along the left edge.
    Rectangle {
        visible: root.current
        y: Theme.freshRssRowPad / 2
        width: Theme.freshRssCursorBar
        height: parent.height - Theme.freshRssRowPad
        radius: width / 2
        color: Theme.accent
    }

    Rectangle {
        id: tag
        x: Theme.space + Theme.freshRssCursorBar
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.clipboardTagWidth
        height: Theme.freshRssBadgeHeight
        radius: Theme.radiusSm
        color: root.kind === "color" ? root.entry.preview : (root.current ? Theme.accent : Theme.fieldBg)
        border.width: Theme.borderWidth
        border.color: root.kind === "color" ? Theme.text : Theme.border

        Text {
            anchors.centerIn: parent
            text: root.tagText[root.kind] !== undefined ? root.tagText[root.kind] : "TEXT"
            color: root.current ? Theme.wsActiveText : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx - 2
            font.bold: true
            font.letterSpacing: 0.5
        }
    }

    Column {
        anchors.left: tag.right
        anchors.leftMargin: Theme.space
        anchors.right: side.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            wrapMode: root.kind === "image" ? Text.NoWrap : Text.WrapAnywhere
            maximumLineCount: root.kind === "image" ? 1 : 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.kind === "image" ? "Picture" : root.entry.preview
            color: Theme.text
            font.family: root.kind === "code" || root.kind === "path" || root.kind === "color" ? Theme.fontFamily : Theme.uiFont
            font.pixelSize: Theme.smallPx + 1
        }

        Text {
            visible: text.length > 0
            width: parent.width
            elide: Text.ElideRight
            text: String(root.entry.detail || "")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx - 1
        }
    }

    Item {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.keyCapHeight
        height: Theme.keyCapHeight

        KeyCap {
            anchors.centerIn: parent
            visible: root.number > 0 && root.number <= 9 && !root.pointed
            label: String(root.number)
            dim: true
        }

        Text {
            id: removeMark
            anchors.centerIn: parent
            visible: root.pointed
            text: "✕"
            color: removeMouse.containsMouse ? Theme.danger : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: true
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => root.hovered(rowMouse.mapToGlobal(mouse.x, mouse.y))
        onClicked: root.clicked()
    }

    // Above the row's own MouseArea so the ✕ gets its clicks.
    MouseArea {
        id: removeMouse
        anchors.fill: side
        anchors.margins: -Theme.tabGap
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.deleteClicked()

        HoverTip {
            message: "Delete from history (Shift+Del)"
            show: removeMouse.containsMouse
        }
    }
}
