pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.theme

Item {
    id: root

    readonly property var sink: levels.sink
    readonly property var source: levels.source
    readonly property bool wide: width >= Theme.settingsTwoColMin
    property int paintSlot: 0

    AudioLevels {
        id: levels
    }

    function nodeLabel(node) {
        if (!node)
            return "No device"
        const nick = String(node.nickname || "")
        if (nick.length)
            return nick
        const desc = String(node.description || "")
        if (desc.length)
            return desc
        return String(node.name || "Device")
    }

    function percent(kind) {
        if (kind === "in")
            return levels.inOk ? levels.inVol : 0
        return levels.outOk ? levels.outVol : 0
    }

    function setVolume(kind, value) {
        levels.setVolume(kind, value)
    }

    function pickAudioColor(slot) {
        root.paintSlot = slot
        audioColors.selectedColor = AudioSettings.colorAt(slot)
        audioColors.open()
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
                title: "On the bar"
                hint: "Right-click a side to mute it. The wheel changes that side. The pill stays off until you enable Audio under Widgets and press Apply."
            }

            Item {
                width: parent.width
                height: barCol.implicitHeight

                Column {
                    id: barCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        text: "Scroll step"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: Theme.audioScrollMin
                        to: Theme.audioScrollMax
                        step: 1
                        value: AudioSettings.editor.value.step
                        readout: String(AudioSettings.editor.value.step)
                        tip: "How many percent one wheel notch moves"
                        onChanged: (value) => AudioSettings.editor.set("step", value)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Show percent"
                        detail: "The number beside each symbol"
                        tip: "Show the volume percent on the pill"
                        checked: AudioSettings.editor.value.percent
                        onToggled: AudioSettings.editor.set("percent", !AudioSettings.editor.value.percent)
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Thresholds"
                hint: "Speaker and microphone colors for each level. The chip sits to the left of the buttons. Apply stores the steps and colors in the theme."
            }

            Item {
                width: parent.width
                height: tierCol.implicitHeight

                Column {
                    id: tierCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        text: "Up to low"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: 5
                        value: AudioSettings.bandAt(0)
                        readout: AudioSettings.bandAt(0) + "%"
                        tip: "Percent at or under this uses the low color"
                        showSwatch: true
                        swatch: AudioSettings.colorAt(0)
                        onChanged: (value) => AudioSettings.setBand(0, value)
                        onSwatchClicked: root.pickAudioColor(0)
                    }

                    Text {
                        width: parent.width
                        text: "Up to mid"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: 5
                        value: AudioSettings.bandAt(1)
                        readout: AudioSettings.bandAt(1) + "%"
                        tip: "Percent at or under this uses the mid color"
                        showSwatch: true
                        swatch: AudioSettings.colorAt(1)
                        onChanged: (value) => AudioSettings.setBand(1, value)
                        onSwatchClicked: root.pickAudioColor(1)
                    }

                    Text {
                        width: parent.width
                        text: "Up to high"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: 5
                        value: AudioSettings.bandAt(2)
                        readout: AudioSettings.bandAt(2) + "%"
                        tip: "Percent at or under this uses the high color. Above it uses the peak color"
                        showSwatch: true
                        swatch: AudioSettings.colorAt(2)
                        onChanged: (value) => AudioSettings.setBand(2, value)
                        onSwatchClicked: root.pickAudioColor(2)
                    }

                    Row {
                        width: parent.width
                        height: Theme.fieldHeight
                        spacing: Theme.tabGap

                        Text {
                            width: parent.width - Theme.chip - Theme.tabGap
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: "Above high"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Rectangle {
                            width: Theme.chip
                            height: parent.height
                            radius: Theme.radiusSm
                            color: AudioSettings.colorAt(3)
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            MouseArea {
                                id: peakMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pickAudioColor(3)

                                HoverTip {
                                    message: "Color above the high step"
                                    show: peakMouse.containsMouse
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            Item {
                width: parent.width
                height: root.wide
                       ? Math.max(outBlock.implicitHeight, inBlock.implicitHeight)
                       : outBlock.implicitHeight + Theme.space * 2 + inBlock.implicitHeight

                Column {
                    id: outBlock
                    width: root.wide ? (parent.width - Theme.space) / 2 : parent.width
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "Output"
                        hint: "Default speakers. The level can go past 100%. Mute and the device apply immediately."
                    }

                    Item {
                        width: parent.width
                        height: outCol.implicitHeight

                        Column {
                            id: outCol
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            spacing: Theme.space

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.nodeLabel(root.sink)
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        CheckRow {
                            width: parent.width
                            title: "Mute output"
                            tip: "Silence the default speakers"
                            checked: levels.outMute
                            onToggled: levels.toggleMute("out")
                        }

                        IntSlider {
                            width: parent.width
                            from: 0
                            to: Theme.volumeMax
                            step: Theme.volumeStep
                            value: root.percent("out")
                            readout: root.percent("out") + "%"
                            tip: "Output volume"
                            onChanged: (value) => root.setVolume("out", value)
                        }

                        Repeater {
                            model: Pipewire.nodes
                            delegate: Rectangle {
                                id: outRow
                                required property var modelData
                                required property int index
                                readonly property bool usable: !!(outRow.modelData && outRow.modelData.audio && outRow.modelData.isSink && !outRow.modelData.isStream)
                                visible: outRow.usable
                                width: parent.width
                                height: outRow.usable ? Theme.fieldHeight : 0
                                radius: Theme.radiusSm
                                color: outMouse.containsMouse ? Theme.hover : Theme.pillBg
                                border.width: Theme.borderWidth
                                border.color: outRow.modelData === root.sink ? Theme.accent : Theme.border

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space
                                    anchors.rightMargin: Theme.space
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: root.nodeLabel(outRow.modelData)
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: outMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Pipewire.preferredDefaultAudioSink = outRow.modelData

                                    HoverTip {
                                        message: "Use this output"
                                        show: outMouse.containsMouse
                                    }
                                }
                            }
                        }
                        }
                    }
                }

                Column {
                    id: inBlock
                    x: root.wide ? outBlock.width + Theme.space : 0
                    y: root.wide ? 0 : outBlock.height + Theme.space * 2
                    width: outBlock.width
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "Input"
                        hint: "Default microphone. Mute and the device apply immediately."
                    }

                    Item {
                        width: parent.width
                        height: inCol.implicitHeight

                        Column {
                            id: inCol
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            spacing: Theme.space

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.nodeLabel(root.source)
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        CheckRow {
                            width: parent.width
                            title: "Mute input"
                            tip: "Silence the default microphone"
                            checked: levels.inMute
                            onToggled: levels.toggleMute("in")
                        }

                        IntSlider {
                            width: parent.width
                            from: 0
                            to: Theme.volumeMax
                            step: Theme.volumeStep
                            value: root.percent("in")
                            readout: root.percent("in") + "%"
                            tip: "Input volume"
                            onChanged: (value) => root.setVolume("in", value)
                        }

                        Repeater {
                            model: Pipewire.nodes
                            delegate: Rectangle {
                                id: inRow
                                required property var modelData
                                required property int index
                                readonly property bool usable: !!(inRow.modelData && inRow.modelData.audio && !inRow.modelData.isSink && !inRow.modelData.isStream)
                                visible: inRow.usable
                                width: parent.width
                                height: inRow.usable ? Theme.fieldHeight : 0
                                radius: Theme.radiusSm
                                color: inMouse.containsMouse ? Theme.hover : Theme.pillBg
                                border.width: Theme.borderWidth
                                border.color: inRow.modelData === root.source ? Theme.accent : Theme.border

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space
                                    anchors.rightMargin: Theme.space
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: root.nodeLabel(inRow.modelData)
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: inMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Pipewire.preferredDefaultAudioSource = inRow.modelData

                                    HoverTip {
                                        message: "Use this input"
                                        show: inMouse.containsMouse
                                    }
                                }
                            }
                        }
                        }
                    }
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: AudioSettings.editor.dirty
        undoEnabled: AudioSettings.editor.canUndo
        applyTip: "Save the scroll step, the percent, and the level threshold steps and colors"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore a step of " + Theme.volumeStep + ", the percent, and the theme level colors. Apply saves it."
        onApplyClicked: AudioSettings.editor.apply()
        onUndoClicked: AudioSettings.editor.undo()
        onResetClicked: AudioSettings.editor.reset()
    }

    ColorDialog {
        id: audioColors
        title: "Threshold color"
        onAccepted: AudioSettings.setColor(root.paintSlot, selectedColor)
    }
}
