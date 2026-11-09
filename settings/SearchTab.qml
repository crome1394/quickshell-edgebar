pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.theme

// Settings → Applications → Launcher: the Pop Launcher style search.
// Built in or your own command, how it looks, which search modes are on,
// the terminal for commands, launch history, and the web shortcuts.
// Apply saves.
Item {
    id: root

    readonly property var draft: SearchSettings.editor.value
    readonly property string problem: SearchSettings.problem(root.draft)
    property bool confirmClear: false

    Timer {
        id: confirmReset
        interval: Theme.copiedFlashMs * 2
        onTriggered: root.confirmClear = false
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: pageScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: pageScroll.pressed || pageScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: Math.max(0, scroll.width - Theme.space - Theme.tabGap)
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Launcher"
                hint: "A search box like Pop!_OS's launcher: apps, open windows, files, a calculator, commands, and web searches. Open it with a keybind (below)."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                CheckRow {
                    width: parent.width
                    title: "Use the built-in launcher"
                    detail: "Off, the keybind runs your command below instead, such as a rofi script."
                    checked: root.draft.builtIn
                    onToggled: SearchSettings.editor.set("builtIn", !root.draft.builtIn)
                }

                FormRow {
                    width: parent.width
                    label: "Run instead"

                    TextBox {
                        width: parent.width
                        text: root.draft.command
                        placeholderText: "/home/you/.local/bin/rofi-launcher"
                        onTextEdited: SearchSettings.editor.set("command", text)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Results shown"

                    ChoiceChips {
                        width: parent.width
                        values: Theme.searchMaxChoices
                        current: root.draft.maxResults
                        onPicked: (value) => SearchSettings.editor.set("maxResults", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Position"

                    Row {
                        spacing: Theme.space

                        Repeater {
                            model: [{ id: "top", label: "Near the top" }, { id: "center", label: "Centered" }]
                            delegate: ChipButton {
                                required property var modelData
                                label: modelData.label
                                active: root.draft.place === modelData.id
                                onClicked: SearchSettings.editor.set("place", modelData.id)
                            }
                        }
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Dim the screen behind it"
                    detail: "Off, like Pop's launcher, the screen stays as it is."
                    checked: root.draft.dim
                    onToggled: SearchSettings.editor.set("dim", !root.draft.dim)
                }
            }

            SectionHeader {
                width: parent.width
                title: "Search modes"
                hint: "Type ? in the launcher for the prefixes. A mode that is off is never searched."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                Repeater {
                    model: SearchSettings.plugins
                    delegate: CheckRow {
                        required property var modelData
                        width: parent.width
                        title: modelData.label
                        detail: modelData.detail
                        checked: root.draft.plugins[modelData.id] !== false
                        onToggled: SearchSettings.setPlugin(modelData.id, !(root.draft.plugins[modelData.id] !== false))
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Commands and history"
                hint: "t: and : commands, and apps that need a terminal, open in this terminal. Add -e if yours needs it before a command (alacritty -e)."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Terminal"

                    TextBox {
                        width: parent.width
                        text: root.draft.terminal
                        placeholderText: Theme.searchDefaultTerminal
                        onTextEdited: SearchSettings.editor.set("terminal", text)
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Remember what I open"
                    detail: "Apps you open often rank higher, here and in the App Library. Kept in state/search-history.json."
                    checked: root.draft.history
                    onToggled: SearchSettings.editor.set("history", !root.draft.history)
                }

                FormRow {
                    width: parent.width
                    label: "History"

                    ChipButton {
                        label: root.confirmClear ? "Click again to clear" : "Clear history"
                        active: root.confirmClear
                        tip: "Forget which apps you open most. This cannot be undone."
                        onClicked: {
                            if (root.confirmClear) {
                                SearchService.clearHistory()
                                root.confirmClear = false
                            } else {
                                root.confirmClear = true
                                confirmReset.restart()
                            }
                        }
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Web shortcuts"
                hint: "Type a shortcut, a space, and your search: ddg pop launcher. The words are added to the end of the address. Reset (below) brings back Pop's list."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                Row {
                    width: parent.width
                    spacing: Theme.tabGap

                    Repeater {
                        model: [{ t: "Shortcuts", w: 0.18 }, { t: "Name", w: 0.27 }, { t: "Address", w: 0.55 }]
                        delegate: Text {
                            required property var modelData
                            width: Math.round((parent.width - Theme.chip * 2 - Theme.tabGap * 3) * modelData.w)
                            text: modelData.t
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }
                }

                Repeater {
                    model: root.draft.webRules
                    delegate: WebRuleRow {
                        required property var modelData
                        required property int index
                        width: parent.width
                        rule: modelData
                        onEdited: (key, value) => SearchSettings.setRule(index, key, value)
                        onRemoveClicked: SearchSettings.removeRule(index)
                    }
                }

                ChipButton {
                    label: "Add a shortcut"
                    onClicked: SearchSettings.addRule()
                }
            }

            SectionHeader {
                width: parent.width
                title: "Keybind"
                hint: "Add to your Hyprland keybindings. With the built-in launcher off, the same call runs your command."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                TextBox {
                    width: parent.width
                    readOnly: true
                    text: "hl.bind(\"SUPER + SPACE\", hl.dsp.exec_cmd(\"qs ipc call launcher toggle\"))"
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
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: SearchSettings.editor.dirty && !root.problem.length
        undoEnabled: SearchSettings.editor.canUndo
        applyTip: root.problem.length ? root.problem : "Save the launcher settings"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Built in, " + Theme.searchMaxDefault + " results near the top, every mode on, " + Theme.searchDefaultTerminal + ", history on, Pop's web shortcuts. Apply saves it."
        onApplyClicked: SearchSettings.apply()
        onUndoClicked: SearchSettings.editor.undo()
        onResetClicked: SearchSettings.editor.reset()
    }
}
