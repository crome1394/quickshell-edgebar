import QtQuick
import QtQuick.Controls
import qs.theme

// A click action in settings: a label, a command line, and whether it runs
// inside the terminal. The command is split on spaces, never run by a shell.
Column {
    id: root

    required property string title
    required property string command
    required property bool inTerminal
    property string placeholder: "Nothing"

    signal commandEdited(string text)
    signal terminalToggled(bool on)

    spacing: Theme.tabGap

    // Undo and Reset change the command; keep the field in step.
    onCommandChanged: {
        if (field.text !== root.command)
            field.text = root.command
    }

    Text {
        width: parent.width
        text: root.title
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    Row {
        width: parent.width
        spacing: Theme.tabGap

        TextField {
            id: field
            width: parent.width - termChip.width - Theme.tabGap
            height: Theme.fieldHeight
            text: root.command
            placeholderText: root.placeholder
            selectByMouse: true
            leftPadding: Theme.space
            verticalAlignment: Text.AlignVCenter
            color: Theme.text
            placeholderTextColor: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            background: Rectangle {
                radius: Theme.radiusSm
                color: field.activeFocus ? Theme.hover : Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: field.activeFocus ? Theme.accent : Theme.border
            }
            onTextEdited: root.commandEdited(field.text)

            HoverHandler {
                id: fieldHover
            }

            HoverTip {
                message: "Program and arguments, or a script path. No shell characters."
                show: fieldHover.hovered
            }
        }

        Rectangle {
            id: termChip
            width: termLabel.implicitWidth + Theme.space * 2
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: root.inTerminal ? Theme.accentDim : (termMouse.containsMouse ? Theme.hover : Theme.pillBg)
            border.width: Theme.borderWidth
            border.color: root.inTerminal ? Theme.accent : Theme.border

            Text {
                id: termLabel
                anchors.centerIn: parent
                text: "Terminal"
                color: root.inTerminal ? Theme.wsActiveText : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: root.inTerminal
            }

            MouseArea {
                id: termMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.terminalToggled(!root.inTerminal)

                HoverTip {
                    message: root.inTerminal ? "Runs inside the terminal chosen below" : "Runs on its own, without a terminal"
                    show: termMouse.containsMouse
                }
            }
        }
    }
}
