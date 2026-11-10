import QtQuick
import qs.theme

// One problem card from mimeapps.list, with its fix and, for choices that
// may be on purpose, Keep as is.
Rectangle {
    id: root

    // A DefaultAppsLogic.problemGroups() card:
    // { kind, text, note, types, fixLabel, canKeep }.
    required property var problem

    signal fixClicked()
    signal keepClicked()

    implicitHeight: col.implicitHeight + Theme.space * 2
    radius: Theme.radiusSm
    color: Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: root.problem.kind === "missing" ? Theme.danger : Theme.border

    Column {
        id: col
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        spacing: Theme.tabGap

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: String(root.problem.text)
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        // A one-type card names the type in plain words.
        MimeComment {
            visible: root.problem.types.length === 1 && text.length > 0
            width: parent.width
            type: root.problem.types.length === 1 ? String(root.problem.types[0]) : ""
        }

        Text {
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: String(root.problem.note || "")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            spacing: Theme.tabGap

            ChipButton {
                label: String(root.problem.fixLabel)
                bold: true
                tip: "Changes the draft; Apply saves it"
                onClicked: root.fixClicked()
            }

            ChipButton {
                visible: !!root.problem.canKeep
                label: "Keep as is"
                tip: "Stop warning about this one. Kept problems can be shown again at the bottom of the page."
                onClicked: root.keepClicked()
            }
        }
    }
}
