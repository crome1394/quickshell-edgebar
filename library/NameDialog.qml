import QtQuick
import QtQuick.Controls
import qs.settings
import qs.theme

// A folder name box over the App Library card, for a new folder or a
// rename. Enter saves, Esc cancels. LibraryPanel says whether the name is
// taken; a taken or empty name cannot be saved.
Item {
    id: root

    property bool shown: false
    property string title: ""
    property string actionLabel: "Save"
    // Returns "" when the name is fine, or why it is not.
    property var check: null

    signal accepted(string name)
    signal cancelled()

    readonly property string problem: root.check ? String(root.check(field.text) || "") : ""

    function openWith(title, actionLabel, text) {
        root.title = title
        root.actionLabel = actionLabel
        field.text = text
        root.shown = true
        field.selectAll()
        field.forceActiveFocus()
    }

    function close() {
        root.shown = false
    }

    function confirm() {
        if (root.problem.length)
            return
        root.close()
        root.accepted(field.text.trim())
    }

    function cancel() {
        root.close()
        root.cancelled()
    }

    anchors.fill: parent
    visible: root.shown
    z: 20

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.freshRssScrim
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
    }

    Rectangle {
        id: box
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.space * 4, Theme.popupWidth * 1.4)
        height: column.implicitHeight + Theme.space * 3
        radius: Theme.radius
        color: Qt.rgba(Theme.pageBg.r, Theme.pageBg.g, Theme.pageBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: Theme.space * 1.5
            y: Theme.space * 1.5
            width: box.width - Theme.space * 3
            spacing: Theme.space

            Text {
                text: root.title
                textFormat: Text.PlainText
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            TextField {
                id: field
                width: parent.width
                height: Theme.fieldHeight
                maximumLength: Theme.libraryFolderNameMax
                verticalAlignment: Text.AlignVCenter
                leftPadding: Theme.space
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: root.problem.length ? Theme.danger : (field.activeFocus ? Theme.accent : Theme.border)
                }
                Keys.onReturnPressed: root.confirm()
                Keys.onEnterPressed: root.confirm()
                Keys.onEscapePressed: root.cancel()
            }

            Text {
                width: parent.width
                visible: root.problem.length > 0
                wrapMode: Text.WordWrap
                text: root.problem
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Row {
                anchors.right: parent.right
                spacing: Theme.space

                ChipButton {
                    label: "Cancel"
                    onClicked: root.cancel()
                }

                ChipButton {
                    label: root.actionLabel
                    active: true
                    enabled: !root.problem.length
                    onClicked: root.confirm()
                }
            }
        }
    }
}
