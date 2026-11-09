import QtQuick
import qs.theme

// One folder along the bottom of the App Library (or Library Home): a
// folder symbol over its name. Drop a dragged app on it to add it. A
// click shows the folder; right-click asks for its menu.
Item {
    id: root

    required property string label
    required property string glyph
    required property bool selected
    // Library Home takes no drops.
    property bool acceptsDrop: true

    signal clicked()
    signal rightClicked(point at)
    signal dropped()

    readonly property bool dropHot: drop.containsDrag && root.acceptsDrop

    implicitWidth: Math.max(Theme.libraryFolderPx * 2, caption.implicitWidth + Theme.space * 2)
    implicitHeight: Theme.libraryFolderPx + Theme.smallPx + Theme.space * 2

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.dropHot ? Theme.accentDim : (root.selected ? Theme.hover : (tabMouse.containsMouse ? Theme.fieldBg : "transparent"))
        border.width: root.selected || root.dropHot ? Theme.borderWidth : 0
        border.color: Theme.accent
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.borderWidth * 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: root.selected || root.dropHot ? Theme.accent : Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: Theme.libraryFolderPx * 0.8
        }

        Text {
            id: caption
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            textFormat: Text.PlainText
            color: root.selected ? Theme.text : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: root.selected
        }
    }

    MouseArea {
        id: tabMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked(tabMouse.mapToGlobal(mouse.x, mouse.y))
            else
                root.clicked()
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["library-app"]
        onDropped: (event) => {
            if (!root.acceptsDrop)
                return
            event.accept()
            root.dropped()
        }
    }
}
