pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.settings
import qs.theme

// Add or edit a snippet, over the Code Aid card: its language, name, and
// code. Ctrl+S or Save keeps it; Esc or Cancel drops the changes.
// CodeAidPanel saves through CodeAidService and shows any problem here.
Item {
    id: root

    property bool shown: false
    // The snippet being edited, or null for a new one.
    property var snip: null
    property var languages: []
    property string problem: ""

    signal saveRequested(var snip, string language, string name, string body)
    signal cancelled()

    function openFor(snip, language) {
        root.snip = snip
        root.problem = ""
        langField.text = snip ? snip.language : String(language || "")
        nameField.text = snip ? snip.name : ""
        codeArea.text = snip ? snip.body : ""
        root.shown = true
        if (snip)
            codeArea.forceActiveFocus()
        else
            nameField.forceActiveFocus()
    }

    function close() {
        root.shown = false
    }

    function save() {
        root.saveRequested(root.snip, langField.text, nameField.text, codeArea.text)
    }

    anchors.fill: parent
    visible: root.shown
    z: 20

    // Esc cancels and Ctrl+S saves from any field.
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            root.cancelled()
            event.accepted = true
        } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
            root.save()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, 1)
    }

    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: form
        x: Theme.space * 2
        y: Theme.space * 2
        width: parent.width - Theme.space * 4
        spacing: Theme.space

        Text {
            text: root.snip ? "Edit snippet" : "New snippet"
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx + 2
            font.bold: true
        }

        Row {
            width: parent.width
            spacing: Theme.space

            Column {
                width: Math.round(parent.width * 0.3)
                spacing: Theme.tabGap

                Text {
                    text: "Language"
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                TextBox {
                    id: langField
                    width: parent.width
                    placeholderText: "bash"
                    maximumLength: 30
                    KeyNavigation.tab: nameField
                    Keys.onPressed: (event) => root.handleKey(event)
                }
            }

            Column {
                width: parent.width - Math.round(parent.width * 0.3) - Theme.space
                spacing: Theme.tabGap

                Text {
                    text: "Name"
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                TextBox {
                    id: nameField
                    width: parent.width
                    placeholderText: "for loop"
                    maximumLength: 80
                    KeyNavigation.tab: codeArea
                    Keys.onPressed: (event) => root.handleKey(event)
                }
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.tabGap

            Repeater {
                model: root.languages
                delegate: ChipButton {
                    required property string modelData
                    label: modelData
                    active: langField.text.trim().toLowerCase() === modelData
                    onClicked: langField.text = modelData
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Blanks to fill before copying: {{name}}, or {{name:default}}. The same name fills every place it appears. {{clipboard}} puts in what you last copied."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    ScrollView {
        id: codeScroll
        x: Theme.space * 2
        anchors.top: form.bottom
        anchors.topMargin: Theme.space
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        width: parent.width - Theme.space * 4

        TextArea {
            id: codeArea
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallPx + 1
            placeholderText: "The code to copy"
            placeholderTextColor: Theme.subtext
            background: Rectangle {
                radius: Theme.radiusSm
                color: Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: codeArea.activeFocus ? Theme.accent : Theme.border
            }
            // Tab indents with four spaces instead of leaving the box.
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Tab && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                    codeArea.insert(codeArea.cursorPosition, "    ")
                    event.accepted = true
                    return
                }
                root.handleKey(event)
            }
        }
    }

    Row {
        id: footer
        anchors.right: parent.right
        anchors.rightMargin: Theme.space * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space * 2
        spacing: Theme.space

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.problem.length > 0
            text: root.problem
            color: Theme.danger
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ChipButton {
            label: "Cancel"
            tip: "Esc"
            onClicked: root.cancelled()
        }

        ChipButton {
            label: "Save"
            tip: "Ctrl+S"
            active: true
            onClicked: root.save()
        }
    }
}
