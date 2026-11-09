pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.library
import qs.services
import qs.theme

// Settings → Applications → App Library: Pop's application library.
// Built in or the Application Menu command, the grid's size, and Library
// Home. Folders are made and filled in the library itself; this page can
// put back Pop's three. Apply saves everything but the folders.
Item {
    id: root

    readonly property var draft: LibrarySettings.editor.value
    readonly property var folders: LibraryLogic.foldersFrom(Config.libraryFoldersJson)
    property bool confirmReset: false

    Timer {
        id: confirmTimer
        interval: Theme.copiedFlashMs * 2
        onTriggered: root.confirmReset = false
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "App Library"
            hint: "A grid of your apps with folders, like Pop!_OS's. Open it from the Application Menu widget or a keybind (below). Make folders with New folder, drag apps onto them, and right-click for more."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            CheckRow {
                width: parent.width
                title: "Use the built-in App Library"
                detail: "Off, the Application Menu widget and the keybind run the command set under Application Menu instead."
                checked: root.draft.builtIn
                onToggled: LibrarySettings.editor.set("builtIn", !root.draft.builtIn)
            }

            Text {
                visible: !root.draft.builtIn && !(MenuSettings.savedArgv() || []).length
                width: parent.width
                wrapMode: Text.WordWrap
                text: "No command is set under Application Menu, so nothing will open."
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            FormRow {
                width: parent.width
                label: "Columns"

                ChoiceChips {
                    width: parent.width
                    values: Theme.libraryColumnChoices
                    current: root.draft.columns
                    onPicked: (value) => LibrarySettings.editor.set("columns", value)
                }
            }

            FormRow {
                width: parent.width
                label: "Icon size"

                ChoiceChips {
                    width: parent.width
                    values: Theme.libraryIconChoices
                    current: root.draft.iconPx
                    unit: " px"
                    onPicked: (value) => LibrarySettings.editor.set("iconPx", value)
                }
            }

            CheckRow {
                width: parent.width
                title: "Show app names"
                detail: "Off shows icons only; hover or search to find an app by name."
                checked: root.draft.showNames
                onToggled: LibrarySettings.editor.set("showNames", !root.draft.showNames)
            }

            CheckRow {
                width: parent.width
                title: "Library Home leaves out apps in a folder"
                detail: "As in Pop's library. Off, Library Home lists every app."
                checked: root.draft.hideFoldered
                onToggled: LibrarySettings.editor.set("hideFoldered", !root.draft.hideFoldered)
            }
        }

        SectionHeader {
            width: parent.width
            title: "Folders"
            hint: "A folder holds the apps you add plus, like Pop's, every app in its categories. These save as soon as you change them in the library."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: root.folders.length ? root.folders.map((f) => f.name).join(", ") : "No folders."
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx + 1
            }

            Row {
                spacing: Theme.space

                ChipButton {
                    label: "Open the App Library"
                    onClicked: LibraryService.show()
                }

                ChipButton {
                    label: root.confirmReset ? "Click again to reset" : "Reset to Pop's folders"
                    active: root.confirmReset
                    tip: "Office, System, and Utilities, by category. Your own folders are removed; the apps stay installed."
                    onClicked: {
                        if (root.confirmReset) {
                            LibrarySettings.resetFolders()
                            root.confirmReset = false
                        } else {
                            root.confirmReset = true
                            confirmTimer.restart()
                        }
                    }
                }
            }
        }

        SectionHeader {
            width: parent.width
            title: "Keybind"
            hint: "Add to your Hyprland keybindings. With the built-in library off, the same call runs the Application Menu command."
        }

        TextBox {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            readOnly: true
            text: "hl.bind(\"SUPER + A\", hl.dsp.exec_cmd(\"qs ipc call appLibrary toggle\"))"
        }
    }

    DraftFooter {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: LibrarySettings.editor.dirty
        undoEnabled: LibrarySettings.editor.canUndo
        applyTip: "Save the App Library settings"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Built in, " + Theme.libraryColumnsDefault + " columns, " + Theme.libraryIconDefault + " px icons, names shown, Library Home without foldered apps. Apply saves it."
        onApplyClicked: LibrarySettings.editor.apply()
        onUndoClicked: LibrarySettings.editor.undo()
        onResetClicked: LibrarySettings.editor.reset()
    }
}
