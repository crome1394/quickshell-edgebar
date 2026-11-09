import QtQuick
import qs.theme

// One app in the App Library grid: its icon and, unless names are off,
// its name under it. A click opens it; right-click asks for its menu;
// pressing and moving drags it (LibraryPanel draws the dragged icon, so
// it can leave the grid and land on a folder).
Item {
    id: root

    required property var app
    required property string iconUrl
    required property bool current
    required property int iconPx
    required property bool showName

    signal hovered(point at)
    signal clicked()
    signal rightClicked(point at)
    // `at` is the pointer on screen.
    signal dragStarted(point at)
    signal dragMoved(point at)
    signal dragEnded()

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.tabGap / 2
        radius: Theme.radius
        color: root.current ? Theme.accentDim : (tileMouse.containsMouse ? Theme.hover : "transparent")
        border.width: root.current ? Theme.borderWidth : 0
        border.color: Theme.accent
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.space
        spacing: Theme.tabGap

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.iconPx
            height: root.iconPx

            Image {
                id: icon
                anchors.fill: parent
                source: root.iconUrl
                sourceSize.width: root.iconPx
                sourceSize.height: root.iconPx
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }

            Text {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: Theme.searchGlyphs.app
                color: Theme.subtext
                font.family: Theme.iconFont
                font.pixelSize: root.iconPx * 0.7
            }
        }

        Text {
            visible: root.showName
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: String(root.app ? root.app.name : "")
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: tileMouse.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point pressAt: Qt.point(0, 0)
        property bool pressed2: false
        property bool dragging: false

        onPressed: (mouse) => {
            tileMouse.pressAt = Qt.point(mouse.x, mouse.y)
            tileMouse.pressed2 = mouse.button === Qt.LeftButton
            tileMouse.dragging = false
        }
        onPositionChanged: (mouse) => {
            const at = tileMouse.mapToGlobal(mouse.x, mouse.y)
            if (!tileMouse.pressed2) {
                root.hovered(at)
                return
            }
            const far = Math.abs(mouse.x - tileMouse.pressAt.x) + Math.abs(mouse.y - tileMouse.pressAt.y) > Theme.space
            if (!tileMouse.dragging && far) {
                tileMouse.dragging = true
                root.dragStarted(at)
            }
            if (tileMouse.dragging)
                root.dragMoved(at)
        }
        onReleased: (mouse) => {
            const wasDragging = tileMouse.dragging
            tileMouse.pressed2 = false
            tileMouse.dragging = false
            if (wasDragging) {
                root.dragEnded()
                return
            }
            if (mouse.button === Qt.RightButton)
                root.rightClicked(tileMouse.mapToGlobal(mouse.x, mouse.y))
            else
                root.clicked()
        }
    }
}
