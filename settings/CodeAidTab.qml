pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → Tools → Code Aid: the snippet picker. Built in or your own
// command, the snippet folder, closing after a copy, and recent snippets
// first. Apply saves.
Item {
    id: root

    readonly property var draft: CodeAidSettings.editor.value
    readonly property string problem: CodeAidSettings.problem(root.draft)

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "Code Aid"
            hint: "Copy a code snippet: pick one, fill in its blanks, and paste. Snippets are plain files, one each, in the folder below; add and edit them in Code Aid itself."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            CheckRow {
                width: parent.width
                title: "Use the built-in Code Aid"
                detail: "Off, the keybind runs your command below instead, such as rofi-code-aid."
                checked: root.draft.builtIn
                onToggled: CodeAidSettings.editor.set("builtIn", !root.draft.builtIn)
            }

            FormRow {
                width: parent.width
                label: "Run instead"

                TextBox {
                    width: parent.width
                    text: root.draft.command
                    placeholderText: "/home/you/.local/bin/rofi-code-aid"
                    onTextEdited: CodeAidSettings.editor.set("command", text)
                }
            }

            FormRow {
                width: parent.width
                label: "Snippet folder"

                TextBox {
                    width: parent.width
                    text: root.draft.dir
                    placeholderText: Theme.codeAidDefaultDir
                    onTextEdited: CodeAidSettings.editor.set("dir", text)
                }
            }

            CheckRow {
                width: parent.width
                title: "Close after copying"
                detail: "Off keeps Code Aid open, to copy several snippets in a row."
                checked: root.draft.closeOnCopy
                onToggled: CodeAidSettings.editor.set("closeOnCopy", !root.draft.closeOnCopy)
            }

            CheckRow {
                width: parent.width
                title: "Recent snippets first"
                detail: "The last " + Theme.codeAidRecentMax + " you copied, above the languages. Uses the launcher's history setting."
                checked: root.draft.recent
                onToggled: CodeAidSettings.editor.set("recent", !root.draft.recent)
            }
        }

        SectionHeader {
            width: parent.width
            title: "Snippet files"
            hint: "Line 1 is the label, \"language · name\". Then a line that is just ---, then the code. Blanks: {{name}} or {{name:default}}; {{clipboard}} puts in what you last copied."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            TextBox {
                width: parent.width
                readOnly: true
                text: "hl.bind(\"SUPER + SEMICOLON\", hl.dsp.exec_cmd(\"qs ipc call codeAid toggle\"))"
            }

            ChipButton {
                label: "Open Code Aid"
                onClicked: CodeAidService.show()
            }
        }

        Text {
            visible: root.problem.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.problem
            color: Theme.danger
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    DraftFooter {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: CodeAidSettings.editor.dirty && !root.problem.length
        undoEnabled: CodeAidSettings.editor.canUndo
        applyTip: root.problem.length ? root.problem : "Save the Code Aid settings"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Built in, snippets in " + Theme.codeAidDefaultDir + ", close after copying, recent first. Apply saves it."
        onApplyClicked: CodeAidSettings.apply()
        onUndoClicked: CodeAidSettings.editor.undo()
        onResetClicked: CodeAidSettings.editor.reset()
    }
}
