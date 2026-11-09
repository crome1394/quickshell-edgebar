pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// A small right-click menu inside the App Library card: a list of items
// { label, action, danger }. A click outside it, or Esc, closes it.
// LibraryPanel fills `items` and runs the picked action.
Item {
    id: root

    property var items: []
    property bool shown: false
    // Where it opens, in the parent's coordinates.
    property point at: Qt.point(0, 0)

    signal picked(string action)

    function openAt(point, list) {
        root.items = list
        root.at = point
        root.shown = list.length > 0
    }

    function close() {
        root.shown = false
    }

    anchors.fill: parent
    visible: root.shown
    z: 10

    // A click anywhere else closes the menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    Rectangle {
        id: box
        readonly property int rowHeight: Theme.fieldHeight
        x: Math.max(0, Math.min(root.at.x, root.width - box.width))
        y: Math.max(0, Math.min(root.at.y, root.height - box.height))
        width: Theme.popupWidth
        height: column.implicitHeight + Theme.tabGap * 2
        radius: Theme.radiusSm
        color: Qt.rgba(Theme.pageBg.r, Theme.pageBg.g, Theme.pageBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: column
            x: Theme.tabGap
            y: Theme.tabGap
            width: box.width - Theme.tabGap * 2

            Repeater {
                model: root.items
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: column.width
                    height: box.rowHeight
                    radius: Theme.radiusSm
                    color: rowMouse.containsMouse ? Theme.hover : "transparent"

                    Text {
                        id: label
                        x: Theme.space
                        width: parent.width - Theme.space * 2
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(row.modelData.label || "")
                        textFormat: Text.PlainText
                        color: row.modelData.danger ? Theme.danger : Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx + 1
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close()
                            root.picked(String(row.modelData.action || ""))
                        }
                    }
                }
            }
        }
    }
}
