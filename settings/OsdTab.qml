pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import qs.config
import qs.services
import qs.theme

// Settings → Notifications → On-Screen Display: the popup for volume,
// microphone, media, and brightness. Apply saves the page; Preview shows
// the unsaved look.
Item {
    id: root

    readonly property var draft: OsdSettings.editor.value
    property string paintKey: ""

    function pickColor(key) {
        root.paintKey = key
        const now = root.draft[key]
        colorDialog.selectedColor = now === "auto" ? (key === "accent" ? Theme.accent : Theme.text) : now
        colorDialog.open()
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

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Show it for"
                hint: "Any change shows the popup: your keys, the bar's sliders, or another app. Preview shows this page's look before you apply it."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Flow {
                    width: parent.width
                    spacing: Theme.tabGap

                    Repeater {
                        model: [
                            { id: "volume", label: "Preview volume" },
                            { id: "mic", label: "Preview microphone" },
                            { id: "track", label: "Preview media" },
                            { id: "brightness", label: "Preview brightness" }
                        ]
                        delegate: ChipButton {
                            required property var modelData
                            label: String(modelData.label)
                            tip: "Show a sample popup with this page's settings"
                            onClicked: OsdService.preview(String(modelData.id), root.draft)
                        }
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Volume"
                    detail: "Speaker volume and mute, with the sound below"
                    checked: root.draft.volume
                    onToggled: OsdSettings.editor.set("volume", !root.draft.volume)
                }

                CheckRow {
                    width: parent.width
                    title: "Output device"
                    detail: "The name of a new speaker or headset when it takes over"
                    checked: root.draft.device
                    onToggled: OsdSettings.editor.set("device", !root.draft.device)
                }

                CheckRow {
                    width: parent.width
                    title: "Microphone"
                    detail: "Microphone mute and volume"
                    checked: root.draft.mic
                    onToggled: OsdSettings.editor.set("mic", !root.draft.mic)
                }

                CheckRow {
                    width: parent.width
                    title: "New track"
                    detail: "Title, artist, and cover when a player changes song"
                    checked: root.draft.track
                    onToggled: OsdSettings.editor.set("track", !root.draft.track)
                }

                CheckRow {
                    width: parent.width
                    title: "Play and pause"
                    detail: "When a player starts or pauses"
                    checked: root.draft.playback
                    onToggled: OsdSettings.editor.set("playback", !root.draft.playback)
                }

                CheckRow {
                    width: parent.width
                    title: "Brightness"
                    detail: "Laptop screens, when brightness changes through the bar (its widget or qs ipc call brightness)"
                    checked: root.draft.brightness
                    onToggled: OsdSettings.editor.set("brightness", !root.draft.brightness)
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Place and size"
                hint: "Where the popup sits on the main monitor, how far from the edge, how wide, and how long it stays."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Up and down"

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: [{ id: "top", label: "Top" }, { id: "center", label: "Middle" }, { id: "bottom", label: "Bottom" }]
                            delegate: ChipButton {
                                required property var modelData
                                label: String(modelData.label)
                                active: root.draft.vplace === modelData.id
                                onClicked: OsdSettings.editor.set("vplace", String(modelData.id))
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Side to side"

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: [{ id: "left", label: "Left" }, { id: "center", label: "Center" }, { id: "right", label: "Right" }]
                            delegate: ChipButton {
                                required property var modelData
                                label: String(modelData.label)
                                active: root.draft.hplace === modelData.id
                                onClicked: OsdSettings.editor.set("hplace", String(modelData.id))
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Edge gap"

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 400
                        step: 4
                        value: root.draft.margin
                        readout: root.draft.margin + " px"
                        tip: "Distance from the screen edges it is placed against. Default " + Theme.osdMargin + "."
                        onChanged: (value) => OsdSettings.editor.set("margin", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Width"

                    IntSlider {
                        width: parent.width
                        from: 200
                        to: 640
                        step: 20
                        value: root.draft.width
                        readout: root.draft.width + " px"
                        tip: "Default " + Theme.osdWidth + "."
                        onChanged: (value) => OsdSettings.editor.set("width", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Stays for"

                    IntSlider {
                        width: parent.width
                        from: 500
                        to: 6000
                        step: 100
                        value: root.draft.timeout
                        readout: (root.draft.timeout / 1000).toFixed(1) + " s"
                        tip: "How long it stays after the last change. Default " + (Theme.osdTimeoutMs / 1000).toFixed(1) + " s."
                        onChanged: (value) => OsdSettings.editor.set("timeout", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Text size"

                    IntSlider {
                        width: parent.width
                        from: 80
                        to: 160
                        step: 10
                        value: root.draft.textSize
                        readout: root.draft.textSize + "%"
                        tip: "Text and symbol size. The font is the theme's bar font."
                        onChanged: (value) => OsdSettings.editor.set("textSize", value)
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Look"
                hint: "Auto follows the theme and changes with it. A picked color stays the same in every theme."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Glass"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        ChipButton {
                            id: menuGlass
                            label: "Menu glass"
                            active: root.draft.glass === 0
                            tip: "Follow Menu glass (System → Transparency)"
                            onClicked: OsdSettings.editor.set("glass", root.draft.glass === 0 ? 90 : 0)
                        }

                        IntSlider {
                            width: parent.width - menuGlass.width - Theme.tabGap
                            enabled: root.draft.glass > 0
                            opacity: enabled ? 1 : 0.5
                            from: 40
                            to: 100
                            step: 2
                            value: root.draft.glass > 0 ? root.draft.glass : 90
                            readout: root.draft.glass > 0 ? root.draft.glass + "%" : "Theme"
                            tip: "How solid the popup is"
                            onChanged: (value) => OsdSettings.editor.set("glass", value)
                        }
                    }
                }

                Repeater {
                    model: [
                        { key: "accent", label: "Bar color", tip: "The level bar. Auto is the theme accent." },
                        { key: "text", label: "Text color", tip: "Title, percent, and symbol. Auto is the theme text color." }
                    ]
                    delegate: FormRow {
                        id: colorRow
                        required property var modelData
                        width: parent.width
                        label: String(modelData.label)

                        Row {
                            spacing: Theme.tabGap

                            ChipButton {
                                label: "Auto"
                                active: root.draft[colorRow.modelData.key] === "auto"
                                tip: String(colorRow.modelData.tip)
                                onClicked: OsdSettings.editor.set(String(colorRow.modelData.key), "auto")
                            }

                            Rectangle {
                                readonly property string value: String(root.draft[colorRow.modelData.key])
                                width: Theme.chip
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: value === "auto" ? "transparent" : value
                                border.width: Theme.borderWidth
                                border.color: value === "auto" ? Theme.border : Theme.accent

                                Text {
                                    visible: parent.value === "auto"
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: swatchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.pickColor(String(colorRow.modelData.key))

                                    HoverTip {
                                        message: "Pick a fixed color"
                                        show: swatchMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Border"
                    detail: "A thin outline in the theme's border color"
                    checked: root.draft.border
                    onToggled: OsdSettings.editor.set("border", !root.draft.border)
                }

                CheckRow {
                    width: parent.width
                    title: "Cover art"
                    detail: "Show the album cover for media when the player has one, instead of the symbol"
                    checked: root.draft.art
                    onToggled: OsdSettings.editor.set("art", !root.draft.art)
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Symbols"
                hint: "Pick a symbol and type its replacement. The defaults come from the bar's icon font (Symbols Nerd Font)."
            }

            OsdIconOptions {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Sound"
                hint: "Plays when the speaker volume changes, at most once every " + Theme.osdSoundGapMs + " ms so held keys do not pile up."
            }

            OsdSoundOptions {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: OsdSettings.editor.dirty
        undoEnabled: OsdSettings.editor.canUndo
        applyTip: "Save the events, place, look, symbols, and sound"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the defaults: every event on, bottom center, theme colors and symbols, the theme sound. Apply saves it."
        onApplyClicked: OsdSettings.editor.apply()
        onUndoClicked: OsdSettings.editor.undo()
        onResetClicked: OsdSettings.editor.reset()
    }

    ColorDialog {
        id: colorDialog
        title: "On-screen display color"
        onAccepted: OsdSettings.editor.set(root.paintKey, selectedColor)
    }
}
