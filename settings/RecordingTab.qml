pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs.config
import qs.services
import qs.theme

// Settings → Tools → Recording: where recordings go and how they are made
// (gpu-screen-recorder, encoded on the GPU). Apply saves.
Item {
    id: root

    readonly property var draft: RecorderSettings.editor.value
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    function syncDir() {
        if (dirField.text !== root.draft.dir)
            dirField.text = root.draft.dir
    }

    Component.onCompleted: root.syncDir()

    Connections {
        target: RecorderSettings.editor
        function onValueChanged() {
            if (!dirField.activeFocus)
                root.syncDir()
        }
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
            width: Math.max(0, scroll.width - root.scrollGutter)
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Recording"
                hint: "Screen recording with gpu-screen-recorder, encoded on the GPU. Turn on the Screen Recorder widget under Widgets, or use qs ipc call recorder toggle."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Text {
                    visible: RecorderService.checked && !RecorderService.available
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "gpu-screen-recorder is not installed, so recording is off."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                FormRow {
                    width: parent.width
                    label: "Folder"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        TextBox {
                            id: dirField
                            width: parent.width - browseButton.width - defaultButton.width - parent.spacing * 2
                            placeholderText: RecorderSettings.defaultDir
                            onTextEdited: RecorderSettings.editor.set("dir", text)
                        }

                        ChipButton {
                            id: browseButton
                            label: "Browse…"
                            tip: "Choose the folder"
                            onClicked: folderDialog.open()
                        }

                        ChipButton {
                            id: defaultButton
                            label: "Default"
                            tip: RecorderSettings.defaultDir
                            onClicked: {
                                RecorderSettings.editor.set("dir", RecorderSettings.defaultDir)
                                dirField.text = RecorderSettings.defaultDir
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Codec"

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: RecorderSettings.codecs
                            delegate: ChipButton {
                                required property var modelData
                                readonly property bool unsupported: modelData.id !== "auto" && RecorderService.codecs.length > 0
                                    && RecorderService.codecs.indexOf(modelData.id) < 0
                                label: modelData.label + (unsupported ? " ✕" : "")
                                tip: unsupported ? "This GPU cannot encode " + modelData.label + " in hardware" : modelData.tip
                                active: root.draft.codec === modelData.id
                                onClicked: RecorderSettings.editor.set("codec", modelData.id)
                            }
                        }
                    }
                }

                Text {
                    visible: RecorderService.codecs.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "This GPU encodes " + RecorderService.codecs.map((c) => c.toUpperCase()).join(", ") + " in hardware. Auto uses "
                        + RecorderSettings.resolveCodec("auto", RecorderService.codecs).toUpperCase() + "."
                        + (root.draft.codec !== "auto" && RecorderService.codecs.indexOf(root.draft.codec) < 0 ? " The chosen codec is not one of them, so recording would fail." : "")
                    color: root.draft.codec !== "auto" && RecorderService.codecs.indexOf(root.draft.codec) < 0 ? Theme.danger : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                FormRow {
                    width: parent.width
                    label: "File type"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "MP4"
                            active: root.draft.container === "mp4"
                            tip: "Plays and uploads everywhere"
                            onClicked: RecorderSettings.editor.set("container", "mp4")
                        }

                        ChipButton {
                            label: "MKV"
                            active: root.draft.container === "mkv"
                            tip: "Survives a crash mid-recording; some sites and editors want MP4"
                            onClicked: RecorderSettings.editor.set("container", "mkv")
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Quality"

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: RecorderSettings.qualities
                            delegate: ChipButton {
                                required property var modelData
                                label: modelData.label
                                active: root.draft.quality === modelData.id
                                onClicked: RecorderSettings.editor.set("quality", modelData.id)
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Frame rate"

                    ChoiceChips {
                        width: parent.width
                        values: Theme.recFpsChoices
                        current: root.draft.fps
                        unit: " fps"
                        onPicked: (value) => RecorderSettings.editor.set("fps", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Audio"

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: RecorderSettings.audios
                            delegate: ChipButton {
                                required property var modelData
                                label: modelData.label
                                tip: modelData.tip
                                active: root.draft.audio === modelData.id
                                onClicked: RecorderSettings.editor.set("audio", modelData.id)
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Click records"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "Focused monitor"
                            active: root.draft.target === "screen"
                            tip: "A left click on the widget records the monitor you are on"
                            onClicked: RecorderSettings.editor.set("target", "screen")
                        }

                        ChipButton {
                            label: "Region"
                            active: root.draft.target === "region"
                            tip: "A left click asks you to drag a region first"
                            onClicked: RecorderSettings.editor.set("target", "region")
                        }
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Show the cursor"
                    checked: root.draft.cursor
                    onToggled: RecorderSettings.editor.set("cursor", !root.draft.cursor)
                }

                CheckRow {
                    width: parent.width
                    title: "Notify when saved"
                    detail: "A notification with the file's path"
                    checked: root.draft.notify
                    onToggled: RecorderSettings.editor.set("notify", !root.draft.notify)
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Right-click the widget to record a region; middle-click opens the folder. Files are named Recording_<date>_<time>."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: RecorderSettings.editor.dirty
        undoEnabled: RecorderSettings.editor.canUndo
        applyTip: "Save the recording options"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Auto codec, very high, MP4, 60 fps, system audio, the cursor, the focused monitor, " + RecorderSettings.defaultDir + ". Apply saves it."
        onApplyClicked: RecorderSettings.editor.apply()
        onUndoClicked: RecorderSettings.editor.undo()
        onResetClicked: RecorderSettings.editor.reset()
    }

    FolderDialog {
        id: folderDialog
        title: "Folder for recordings"
        currentFolder: "file://" + root.draft.dir
        onAccepted: {
            const path = decodeURIComponent(String(selectedFolder).replace(/^file:\/\//, ""))
            RecorderSettings.editor.set("dir", path)
            dirField.text = RecorderSettings.editor.value.dir
        }
    }
}
