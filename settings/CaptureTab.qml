pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.theme

// Tools → Capture: Screen Capture (capture-screenshot) and Capture OCR
// (ocr-region). Apply writes ~/.config/hypr/capture.conf; the scripts read
// it on every run, so nothing needs restarting. The Keys section lists the
// capture keybinds from the Hyprland config, read-only.
Item {
    id: root

    readonly property var draft: CaptureSettings.editor.value
    readonly property bool dirty: CaptureSettings.editor.dirty
    readonly property bool folderBad: !CaptureSettings.folderOk(root.draft.shotDir)
    readonly property bool editorBad: !CaptureSettings.programOk(root.draft.shotEditor)
    readonly property bool commandBad: !CaptureSettings.programOk(root.draft.ocrCommand)
    readonly property bool valid: !root.folderBad && !root.editorBad && !root.commandBad
    readonly property var langChips: {
        const out = CaptureService.langs.slice()
        const chosen = CaptureSettings.langList(root.draft.ocrLang)
        for (let i = 0; i < chosen.length; i++) {
            if (out.indexOf(chosen[i]) < 0)
                out.push(chosen[i])
        }
        return out
    }
    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property string programRule: "One program name or full path, no arguments. Put arguments in a small script and choose that."

    Component.onCompleted: CaptureService.retain()
    Component.onDestruction: CaptureService.release()

    Connections {
        target: CaptureService
        function onPickSerialChanged() {
            CaptureSettings.editor.set(CaptureService.pickedKey, CaptureService.pickedPath)
        }
    }

    component Hint: Text {
        property bool bad: false
        x: Theme.formLabelWidth + Theme.space
        width: parent ? parent.width - x : 0
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        color: bad ? Theme.danger : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusText.top
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
            enabled: CaptureSettings.loaded

            // ── Screen Capture ──────────────────────────────────────────
            SectionHeader {
                width: parent.width
                title: "Screen Capture"
                hint: "Screenshots taken with capture-screenshot (Print and the keys below). Each one is saved, copied, and announced with a toast you can click to edit."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Text {
                    visible: !CaptureService.screenshotScriptOk
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: CaptureSettings.screenshotScript + " is missing, so these settings have no effect."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                CheckRow {
                    width: parent.width
                    title: "Freeze the screen while selecting"
                    detail: "Menus, tooltips, and video hold still until you finish (needs hyprpicker)"
                    checked: root.draft.shotFreeze
                    onToggled: CaptureSettings.editor.set("shotFreeze", !root.draft.shotFreeze)
                }

                FormRow {
                    width: parent.width
                    label: "Save to"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        PathField {
                            width: parent.width - folderBrowse.width - folderOpen.width - parent.spacing * 2
                            value: root.draft.shotDir
                            placeholderText: CaptureSettings.picturesDir
                            bad: root.folderBad
                            tip: "Folder for saved screenshots. Created if missing."
                            onEdited: (text) => CaptureSettings.editor.set("shotDir", text)
                        }

                        ChipButton {
                            id: folderBrowse
                            label: "Browse…"
                            tip: "Pick a folder (needs zenity)"
                            onClicked: CaptureService.pick("folder", "shotDir", root.draft.shotDir)
                        }

                        ChipButton {
                            id: folderOpen
                            label: "Open"
                            tip: "Open the saved folder"
                            onClicked: CaptureService.openFolder(CaptureSettings.saved.shotDir)
                        }
                    }
                }

                Hint {
                    visible: root.folderBad
                    bad: true
                    text: "Use a full path, like ~/Pictures/Screenshots."
                }

                FormRow {
                    width: parent.width
                    label: "Editor"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        PathField {
                            width: parent.width - editorBrowse.width - parent.spacing
                            value: root.draft.shotEditor
                            placeholderText: "No editor found: install satty or swappy, or enter one"
                            bad: root.editorBad
                            tip: "Opens when you click the toast or press Edit. It gets the image path as its only argument."
                            onEdited: (text) => CaptureSettings.editor.set("shotEditor", text)
                        }

                        ChipButton {
                            id: editorBrowse
                            label: "Browse…"
                            tip: "Pick a program or script (needs zenity)"
                            onClicked: CaptureService.pick("program", "shotEditor", root.draft.shotEditor)
                        }
                    }
                }

                Hint {
                    bad: root.editorBad
                    text: {
                        if (root.editorBad)
                            return root.programRule
                        const found = CaptureSettings.editors
                        return found.length
                            ? "Installed: " + found.join(", ") + ". If the editor here is missing, the first installed one is used."
                            : "None of " + CaptureSettings.editorChoices.join(", ") + " is installed; the toast opens the image viewer instead."
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Toast when saved"
                    detail: "Click it to edit, or choose Open for the image viewer"
                    checked: root.draft.shotNotify
                    onToggled: CaptureSettings.editor.set("shotNotify", !root.draft.shotNotify)
                }

                FormRow {
                    width: parent.width
                    label: "Try"

                    Flow {
                        width: parent.width
                        spacing: Theme.tabGap

                        Repeater {
                            model: CaptureSettings.modes
                            delegate: ChipButton {
                                required property var modelData
                                label: String(modelData.label)
                                enabled: !root.dirty
                                tip: root.dirty ? "Apply first: this uses the saved settings" : String(modelData.tip) + ". Saves and copies."
                                onClicked: CaptureService.tryScreenshot(String(modelData.id))
                            }
                        }

                        ChipButton {
                            label: "Edit latest"
                            tip: "Open the newest saved screenshot in the editor"
                            onClicked: CaptureService.editLatest()
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            // ── Capture OCR ─────────────────────────────────────────────
            SectionHeader {
                width: parent.width
                title: "Capture OCR"
                hint: "Text from a screen region, read with tesseract by ocr-region. Drag over the text; it is copied, ready to paste."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Text {
                    visible: !CaptureService.ocrScriptOk || CaptureService.tesseractMissing
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: !CaptureService.ocrScriptOk
                        ? CaptureSettings.ocrScript + " is missing, so these settings have no effect."
                        : "tesseract is not installed (pacman -S tesseract tesseract-data-eng)."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                CheckRow {
                    width: parent.width
                    title: "Freeze the screen while selecting"
                    detail: "Text in video or scrolling windows holds still (needs hyprpicker)"
                    checked: root.draft.ocrFreeze
                    onToggled: CaptureSettings.editor.set("ocrFreeze", !root.draft.ocrFreeze)
                }

                FormRow {
                    width: parent.width
                    label: "Languages"

                    Flow {
                        width: parent.width
                        spacing: Theme.tabGap

                        Repeater {
                            model: root.langChips
                            delegate: ChipButton {
                                required property string modelData
                                readonly property bool installed: CaptureService.langs.indexOf(modelData) >= 0 || !CaptureService.langsLoaded
                                label: CaptureSettings.langLabel(modelData) + (installed ? "" : " (missing)")
                                active: CaptureSettings.langList(root.draft.ocrLang).indexOf(modelData) >= 0
                                tip: installed ? "Code " + modelData + ". Pick several for mixed text; fewer is faster." : "Not installed: pacman -S tesseract-data-" + modelData
                                onClicked: CaptureSettings.toggleLang(modelData)
                            }
                        }
                    }
                }

                Hint {
                    text: "Installed languages are listed. Add more with pacman -S tesseract-data-<code> (for example tesseract-data-deu)."
                }

                CheckRow {
                    width: parent.width
                    title: "Copy the text"
                    detail: "Put it on the clipboard"
                    checked: root.draft.ocrCopy
                    onToggled: CaptureSettings.editor.set("ocrCopy", !root.draft.ocrCopy)
                }

                CheckRow {
                    width: parent.width
                    title: "Toast with the text"
                    detail: "Shows the first 100 characters, or \"No text found\""
                    checked: root.draft.ocrNotify
                    onToggled: CaptureSettings.editor.set("ocrNotify", !root.draft.ocrNotify)
                }

                FormRow {
                    width: parent.width
                    label: "Then run"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        PathField {
                            width: parent.width - commandBrowse.width - parent.spacing
                            value: root.draft.ocrCommand
                            placeholderText: "Optional: a program or script that gets the text"
                            bad: root.commandBad
                            tip: "Runs after each OCR with the text on its standard input, for example a translator or a script that appends to a notes file."
                            onEdited: (text) => CaptureSettings.editor.set("ocrCommand", text)
                        }

                        ChipButton {
                            id: commandBrowse
                            label: "Browse…"
                            tip: "Pick a program or script (needs zenity)"
                            onClicked: CaptureService.pick("program", "ocrCommand", root.draft.ocrCommand)
                        }
                    }
                }

                Hint {
                    bad: root.commandBad
                    text: root.commandBad ? root.programRule : "The text arrives on standard input. Leave blank to only copy it."
                }

                FormRow {
                    width: parent.width
                    label: "Try"

                    ChipButton {
                        label: "OCR a region"
                        enabled: !root.dirty
                        tip: root.dirty ? "Apply first: this uses the saved settings" : "Drag over some text now"
                        onClicked: CaptureService.tryOcr()
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            // ── Keys ────────────────────────────────────────────────────
            SectionHeader {
                width: parent.width
                title: "Keys"
                hint: CaptureService.bindsFile.length
                    ? "From " + CaptureService.bindsFile.replace(CaptureSettings.home, "~") + ". Change them in your Hyprland config."
                    : "No capture keybinds found in your Hyprland config. Bind keys to capture-screenshot and ocr-region there."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                Repeater {
                    model: CaptureService.binds
                    delegate: Row {
                        id: bindRow
                        required property var modelData
                        width: parent.width
                        spacing: Theme.space

                        Rectangle {
                            width: Theme.formLabelWidth * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                text: String(bindRow.modelData.keys)
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontPx
                                font.bold: true
                            }
                        }

                        Text {
                            width: parent.width - Theme.formLabelWidth * 2 - parent.spacing
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            text: String(bindRow.modelData.what)
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }
                    }
                }
            }
        }
    }

    Text {
        id: statusText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        anchors.leftMargin: Theme.sectionInset
        anchors.rightMargin: Theme.sectionInset
        wrapMode: Text.WordWrap
        text: {
            if (CaptureService.error.length)
                return CaptureService.error
            if (CaptureService.notice.length)
                return CaptureService.notice
            return CaptureService.confExists ? "" : "No capture.conf yet: the scripts use the defaults shown here. Apply creates it."
        }
        color: CaptureService.error.length ? Theme.danger : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: (root.dirty || !CaptureService.confExists) && CaptureSettings.loaded && root.valid
        undoEnabled: CaptureSettings.editor.canUndo
        applyTip: root.valid ? "Save to ~/.config/hypr/capture.conf" : "Fix the red fields first"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Freeze on, your Pictures folder, the first installed editor, English, copy and toasts on. Apply saves it."
        onApplyClicked: {
            if (root.dirty)
                CaptureSettings.editor.apply()
            else
                CaptureService.save(root.draft)
        }
        onUndoClicked: CaptureSettings.editor.undo()
        onResetClicked: CaptureSettings.editor.reset()
    }
}
