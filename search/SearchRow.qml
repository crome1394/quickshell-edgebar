import QtQuick
import qs.components
import qs.theme

// One launcher result: its icon, name, and a line under it (category and
// description, a path, a window's app), with Alt+number for the first
// nine. `current` is the one highlighted row; moving the mouse over a row
// moves it there.
Rectangle {
    id: root

    required property var row
    required property bool current
    required property int number
    // The symbol shown when the icon theme has no icon for this row.
    property string glyph: Theme.searchGlyph

    // The pointer moved over this row; `at` is where, on screen.
    signal hovered(point at)
    signal clicked()
    signal rightClicked()

    implicitHeight: Theme.searchRowHeight
    radius: Theme.radiusSm
    color: root.current ? Theme.accentDim : "transparent"

    Rectangle {
        visible: root.current
        y: Theme.freshRssRowPad / 2
        width: Theme.freshRssCursorBar
        height: parent.height - Theme.freshRssRowPad
        radius: width / 2
        color: Theme.accent
    }

    Item {
        id: iconBox
        x: Theme.space + Theme.freshRssCursorBar
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.searchIconPx
        height: Theme.searchIconPx

        Image {
            id: icon
            anchors.fill: parent
            source: String(root.row.icon || "")
            sourceSize.width: Theme.searchIconPx
            sourceSize.height: Theme.searchIconPx
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        Text {
            anchors.centerIn: parent
            visible: icon.status !== Image.Ready
            text: String(root.glyph)
            color: root.current ? Theme.accent : Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: Theme.searchIconPx * 0.7
        }
    }

    Column {
        anchors.left: iconBox.right
        anchors.leftMargin: Theme.space * 1.5
        anchors.right: numberCap.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.borderWidth

        Text {
            width: parent.width
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: String(root.row.name || "")
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            font.bold: true
        }

        Text {
            width: parent.width
            visible: text.length > 0
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: String(root.row.desc || "")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    KeyCap {
        id: numberCap
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        visible: root.number <= 9
        label: "Alt " + root.number
        opacity: root.current ? 1 : 0.6
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => root.hovered(mapToGlobal(mouse.x, mouse.y))
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.clicked()
        }
    }
}
