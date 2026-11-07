pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → Tools → Clipboard: keep a history (with cliphist), how many
// entries, pictures or not, and clearing it. Apply saves.
Item {
    id: root

    readonly property var draft: ClipboardSettings.editor.value
    property bool confirmClear: false

    Component.onCompleted: ClipboardService.recheck()

    Timer {
        id: confirmReset
        interval: Theme.copiedFlashMs * 2
        onTriggered: root.confirmClear = false
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "Clipboard"
            hint: "Keeps a history of what you copy, so you can copy it again later. Open the viewer with a keybind (qs ipc call clipboard toggle), or add the Clipboard widget under Widgets."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            Text {
                visible: ClipboardService.checked && !ClipboardService.available
                width: parent.width
                wrapMode: Text.WordWrap
                text: "cliphist is not installed, so no history is kept. Install it with: sudo pacman -S cliphist"
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            CheckRow {
                width: parent.width
                title: "Keep a clipboard history"
                detail: "One small wl-paste process saves each copy. Copies a password manager marks as secret are skipped."
                checked: root.draft.enabled
                onToggled: ClipboardSettings.editor.set("enabled", !root.draft.enabled)
            }

            FormRow {
                width: parent.width
                label: "Keep the last"

                ChoiceChips {
                    width: parent.width
                    values: Theme.clipboardMaxItemsChoices
                    current: root.draft.maxItems
                    unit: " copies"
                    onPicked: (value) => ClipboardSettings.editor.set("maxItems", value)
                }
            }

            CheckRow {
                width: parent.width
                title: "Keep pictures too"
                detail: "Screenshots and copied images. Off keeps text only."
                checked: root.draft.images
                onToggled: ClipboardSettings.editor.set("images", !root.draft.images)
            }

            FormRow {
                width: parent.width
                label: "History"

                Row {
                    spacing: Theme.space

                    ChipButton {
                        label: root.confirmClear ? "Click again to clear" : "Clear history"
                        active: root.confirmClear
                        enabled: ClipboardService.available
                        tip: "Delete every saved copy. This cannot be undone."
                        onClicked: {
                            if (root.confirmClear) {
                                ClipboardService.wipe()
                                root.confirmClear = false
                            } else {
                                root.confirmClear = true
                                confirmReset.restart()
                            }
                        }
                    }
                }
            }

            FormRow {
                width: parent.width
                label: "Keybind"

                TextBox {
                    width: parent.width
                    readOnly: true
                    text: "hl.bind(\"SUPER + V\", hl.dsp.exec_cmd(\"qs ipc call clipboard toggle\"))"
                }
            }
        }
    }

    DraftFooter {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: ClipboardSettings.editor.dirty
        undoEnabled: ClipboardSettings.editor.canUndo
        applyTip: "Save the clipboard history settings"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "History on, " + Theme.clipboardMaxItemsDefault + " copies, pictures kept. Apply saves it."
        onApplyClicked: ClipboardSettings.editor.apply()
        onUndoClicked: ClipboardSettings.editor.undo()
        onResetClicked: ClipboardSettings.editor.reset()
    }
}
