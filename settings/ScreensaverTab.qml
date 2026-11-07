pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.theme

// Settings → Tools → Screensaver: which program runs after idle, how long
// to wait, and whether it ignores fullscreen video and idle-inhibits. The
// Look and Brightness sections drive the built-in screensaver.sh. Apply
// saves through screensaver-config.sh, which restarts hypridle.
Item {
    id: root

    readonly property var draft: ScreensaverSettings.editor.value
    readonly property bool builtIn: ScreensaverSettings.isBuiltIn(root.draft.program)
    readonly property bool programValid: ScreensaverSettings.programOk(root.draft.program)
    readonly property bool programSaved: ScreensaverSettings.pathArg(root.draft.program) === ScreensaverSettings.pathArg(ScreensaverSettings.saved.program)
        || (root.builtIn && ScreensaverSettings.isBuiltIn(ScreensaverSettings.saved.program))
    readonly property bool videoSaved: ScreensaverSettings.pathArg(root.draft.video) === ScreensaverSettings.pathArg(ScreensaverSettings.saved.video)
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    function programStatus() {
        if (!root.programValid)
            return { text: "Use a full path, like ~/.local/bin/my-saver.sh. It runs as \"<program> start\" and \"<program> stop\".", bad: true }
        if (!root.programSaved)
            return { text: "Apply to check this program.", bad: false }
        if (!ScreensaverService.programOk)
            return { text: "Not found, or not executable (chmod +x).", bad: true }
        return { text: root.builtIn ? "Built-in screensaver.sh. Found." : "Found and executable.", bad: false }
    }

    Component.onCompleted: ScreensaverService.retain()
    Component.onDestruction: ScreensaverService.release()

    Connections {
        target: ScreensaverService
        function onPickSerialChanged() {
            const key = ScreensaverService.pickedKind === "script" ? "program" : "video"
            ScreensaverSettings.editor.set(key, ScreensaverService.pickedPath)
        }
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
            enabled: ScreensaverSettings.loaded

            SectionHeader {
                width: parent.width
                title: "Screensaver"
                hint: "Runs a fullscreen screensaver after you stop using the computer. Moving the mouse or pressing a key stops it. Apply saves to ~/.config/hypr/screensaver.conf and restarts hypridle."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                CheckRow {
                    width: parent.width
                    title: "Start after idle"
                    detail: "Off: hypridle stops, and the screensaver only runs when started by hand"
                    tip: "Turn the idle screensaver on or off"
                    checked: root.draft.enabled
                    onToggled: ScreensaverSettings.editor.set("enabled", !root.draft.enabled)
                }

                FormRow {
                    width: parent.width
                    label: "Program"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        PathField {
                            id: programField
                            width: parent.width - browseProgram.width - builtInButton.width - parent.spacing * 2
                            value: root.draft.program
                            placeholderText: "Blank runs the built-in screensaver.sh"
                            bad: root.programStatus().bad
                            tip: "A script or program, by full path. It is run as \"<program> start\" after idle and \"<program> stop\" on activity."
                            onEdited: (text) => ScreensaverSettings.editor.set("program", text)
                        }

                        ChipButton {
                            id: browseProgram
                            label: "Browse…"
                            tip: "Pick a file (needs zenity)"
                            onClicked: ScreensaverService.pick("script")
                        }

                        ChipButton {
                            id: builtInButton
                            label: "Built-in"
                            active: root.builtIn
                            tip: "Use the built-in player (scripts/screensaver.sh)"
                            onClicked: ScreensaverSettings.editor.set("program", ScreensaverSettings.builtInProgram)
                        }
                    }
                }

                Text {
                    x: Theme.formLabelWidth + Theme.space
                    width: parent.width - x
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    text: root.programStatus().text
                    color: root.programStatus().bad ? Theme.danger : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                FormRow {
                    width: parent.width
                    label: "Start after"

                    IntSlider {
                        width: parent.width
                        from: Theme.screensaverMinutesMin
                        to: Theme.screensaverMinutesMax
                        value: root.draft.timeoutMin
                        readout: ScreensaverSettings.timeoutLabel(root.draft.timeoutMin)
                        tip: "Minutes of idle before the screensaver starts, " + Theme.screensaverMinutesMin + " to " + Theme.screensaverMinutesMax
                        onChanged: (value) => ScreensaverSettings.editor.set("timeoutMin", value)
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Always start after idle"
                    detail: "Ignore fullscreen video and browser idle-inhibits"
                    tip: "Off: a fullscreen window (a video, a game) keeps the screensaver away. Video playing in a browser tab never blocks it."
                    checked: root.draft.ignoreInhibit
                    onToggled: ScreensaverSettings.editor.set("ignoreInhibit", !root.draft.ignoreInhibit)
                }

                Row {
                    spacing: Theme.space

                    ChipButton {
                        label: "Start now"
                        enabled: !ScreensaverService.busy && !ScreensaverSettings.editor.dirty
                        tip: ScreensaverSettings.editor.dirty ? "Apply first: this runs the saved settings" : "Run the screensaver now with the saved settings"
                        onClicked: ScreensaverService.startNow()
                    }

                    ChipButton {
                        label: "Reload"
                        enabled: !ScreensaverService.busy
                        tip: "Read screensaver.conf again"
                        onClicked: ScreensaverService.refresh()
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            SectionHeader {
                width: parent.width
                title: "Look"
                hint: root.builtIn
                    ? "What the built-in screensaver.sh shows: a looping video, or a text style in a fullscreen terminal."
                    : "These apply to the built-in screensaver.sh. Your program may ignore them."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space
                opacity: root.builtIn ? 1 : Theme.widgetOffOpacity

                FormRow {
                    width: parent.width
                    label: "Style"
                    z: 2

                    SelectBox {
                        width: parent.width
                        choices: ScreensaverSettings.styles
                        currentId: ScreensaverSettings.lookId(root.draft)
                        tip: "Video, or a text style"
                        onPicked: (id) => {
                            if (id === "video")
                                ScreensaverSettings.editor.set("mode", "video")
                            else
                                ScreensaverSettings.editor.edit({ mode: "text", style: id })
                        }
                    }
                }

                FormRow {
                    visible: root.draft.mode === "video"
                    width: parent.width
                    label: "Video"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        PathField {
                            id: videoField
                            width: parent.width - browseVideo.width - parent.spacing
                            value: root.draft.video
                            placeholderText: ScreensaverSettings.defaultVideo
                            bad: root.videoSaved && !ScreensaverService.videoOk
                            onEdited: (text) => ScreensaverSettings.editor.set("video", text)
                        }

                        ChipButton {
                            id: browseVideo
                            label: "Browse…"
                            tip: "Pick a video (needs zenity)"
                            onClicked: ScreensaverService.pick("video")
                        }
                    }
                }

                Text {
                    visible: root.draft.mode === "video" && root.videoSaved && !ScreensaverService.videoOk
                    x: Theme.formLabelWidth + Theme.space
                    width: parent.width - x
                    wrapMode: Text.WordWrap
                    text: "This video file is missing."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                CheckRow {
                    visible: root.draft.mode === "text"
                    width: parent.width
                    title: "Clock"
                    detail: "Time and date in the center"
                    checked: root.draft.clock
                    onToggled: ScreensaverSettings.editor.set("clock", !root.draft.clock)
                }

                Repeater {
                    model: root.draft.mode === "text" && root.draft.style === "warp"
                        ? [
                            { key: "warpSpeed", label: "Warp speed" },
                            { key: "warpDensity", label: "Star density" },
                            { key: "warpStreak", label: "Streak length" }
                        ]
                        : []
                    delegate: FormRow {
                        id: warpRow
                        required property var modelData
                        width: parent.width
                        label: String(warpRow.modelData.label)

                        IntSlider {
                            width: parent.width
                            from: 1
                            to: 10
                            value: Number(root.draft[warpRow.modelData.key])
                            readout: String(root.draft[warpRow.modelData.key])
                            tip: warpRow.modelData.label + ", 1 to 10"
                            onChanged: (value) => ScreensaverSettings.editor.set(warpRow.modelData.key, value)
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            SectionHeader {
                width: parent.width
                title: "Brightness"
                hint: "Dim the monitor over DDC/CI while the built-in screensaver.sh runs, and set it back when it stops. Needs ddcutil and DDC/CI on in the monitor menu."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space
                opacity: root.builtIn && ScreensaverService.ddcutilOk ? 1 : Theme.widgetOffOpacity

                Text {
                    visible: !ScreensaverService.ddcutilOk
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "ddcutil is not installed, so brightness is left alone."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                CheckRow {
                    width: parent.width
                    title: "Dim while running"
                    detail: "Brightness while the screensaver is up"
                    checked: root.draft.dimEnable
                    onToggled: ScreensaverSettings.editor.set("dimEnable", !root.draft.dimEnable)
                }

                FormRow {
                    visible: root.draft.dimEnable
                    width: parent.width
                    label: "Dim to"

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: 5
                        value: root.draft.dimLevel
                        readout: root.draft.dimLevel + "%"
                        tip: "Monitor brightness while the screensaver runs"
                        onChanged: (value) => ScreensaverSettings.editor.set("dimLevel", value)
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Set a level on stop"
                    detail: "Off: put back the brightness from before"
                    checked: root.draft.restoreEnable
                    onToggled: ScreensaverSettings.editor.set("restoreEnable", !root.draft.restoreEnable)
                }

                FormRow {
                    visible: root.draft.restoreEnable
                    width: parent.width
                    label: "Set to"

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: 5
                        value: root.draft.restoreLevel
                        readout: root.draft.restoreLevel + "%"
                        tip: "Monitor brightness after the screensaver stops"
                        onChanged: (value) => ScreensaverSettings.editor.set("restoreLevel", value)
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
            if (ScreensaverService.error.length)
                return ScreensaverService.error
            if (ScreensaverService.loading)
                return "Reading screensaver settings…"
            return ScreensaverService.notice
        }
        color: ScreensaverService.error.length ? Theme.danger : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: ScreensaverSettings.editor.dirty && ScreensaverSettings.loaded && root.programValid && !ScreensaverService.busy
        undoEnabled: ScreensaverSettings.editor.canUndo && !ScreensaverService.busy
        applyTip: root.programValid ? "Save, and restart hypridle with these settings" : "Fix the program path first"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Built-in screensaver, " + ScreensaverSettings.timeoutLabel(Theme.screensaverMinutesDefault) + ", Night watch, no dimming. Apply saves it."
        onApplyClicked: ScreensaverSettings.editor.apply()
        onUndoClicked: ScreensaverSettings.editor.undo()
        onResetClicked: ScreensaverSettings.editor.reset()
    }
}
