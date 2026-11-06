pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services
import qs.settings
import qs.theme

// Playback or Recording in the audio menu: pick a detected device, its card
// profile, volume and mute, each channel's level, and a live meter. The
// title collapses it to one line showing the chosen device and its volume.
Column {
    id: root

    required property var theme
    required property string title
    required property bool sink
    required property var devices
    required property var current
    property bool live: true
    property bool expanded: true
    property bool meter: true

    signal toggleRequested()

    readonly property var card: AudioCardService.cardFor(root.current)
    readonly property var profileChoices: AudioCardService.choicesFor(root.card)
    readonly property bool ready: !!(root.current && root.current.ready && root.current.audio)
    readonly property var volumes: root.ready ? root.current.audio.volumes : []

    function label(node) {
        if (!node)
            return ""
        return String(node.description || node.nickname || node.name || "Device")
    }

    function percent(v) {
        return Math.round(Math.max(0, Number(v) || 0) * 100)
    }

    // The loudest channel is the device volume.
    function masterPercent() {
        let top = 0
        for (let i = 0; i < root.volumes.length; i++)
            top = Math.max(top, Number(root.volumes[i]) || 0)
        return root.percent(top)
    }

    // Scale every channel together so the left/right balance is kept.
    function setMaster(pct) {
        if (!root.ready)
            return
        const target = Math.max(0, Math.min(Theme.volumeMax, AudioSettings.limitRaise(root.masterPercent(), pct))) / 100
        const now = root.volumes.slice()
        const top = Math.max(...now.map(v => Number(v) || 0), 0)
        root.current.audio.volumes = top > 0 ? now.map(v => (Number(v) || 0) * target / top) : now.map(() => target)
    }

    function setChannel(index, pct) {
        if (!root.ready)
            return
        const next = root.volumes.slice()
        next[index] = Math.max(0, Math.min(Theme.volumeMax, AudioSettings.limitRaise(root.percent(next[index]), pct))) / 100
        root.current.audio.volumes = next
    }

    function channelName(index) {
        if (root.volumes.length === 2)
            return index === 0 ? "Left" : "Right"
        return "Channel " + (index + 1)
    }

    function choose(node) {
        if (!node || node === root.current)
            return
        if (root.sink)
            Pipewire.preferredDefaultAudioSink = node
        else
            Pipewire.preferredDefaultAudioSource = node
    }

    function summary() {
        if (!root.current)
            return root.sink ? "No output" : "No input"
        const level = root.ready ? (root.current.audio.muted ? "Muted" : root.masterPercent() + "%") : ""
        return root.label(root.current) + (level.length ? "  ·  " + level : "")
    }

    spacing: Theme.tabGap

    // Title row: click to collapse or expand.
    Rectangle {
        width: parent.width
        height: Theme.chip
        radius: Theme.radiusSm
        color: headerMouse.containsMouse ? root.theme.colHover : "transparent"

        Text {
            id: chevron
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.chip / 2 + Theme.tabGap
            text: root.expanded ? "▾" : "▸"
            color: root.theme.colAccent
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
        }

        Text {
            id: titleText
            anchors.left: chevron.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: root.theme.colAccent
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
            font.bold: true
        }

        Text {
            visible: !root.expanded
            anchors.left: titleText.right
            anchors.leftMargin: Theme.space * 2
            anchors.right: parent.right
            anchors.rightMargin: Theme.tabGap
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.summary()
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()

            HoverTip {
                message: root.expanded ? "Collapse " + root.title : "Expand " + root.title
                show: headerMouse.containsMouse
            }
        }
    }

    Text {
        visible: root.expanded && root.devices.length === 0
        width: parent.width
        text: root.sink ? "No playback devices found." : "No recording devices found."
        color: root.theme.colFgMuted
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    // Detected devices only. The chosen one is the default.
    Repeater {
        model: root.expanded ? root.devices : []
        delegate: Rectangle {
            id: deviceRow
            required property var modelData
            readonly property bool chosen: deviceRow.modelData === root.current
            width: root.width
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: deviceMouse.containsMouse ? root.theme.colHover : "transparent"
            border.width: deviceRow.chosen ? Theme.borderWidth : 0
            border.color: root.theme.colAccent

            Rectangle {
                id: radio
                anchors.left: parent.left
                anchors.leftMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.chip / 2
                height: width
                radius: width / 2
                color: deviceRow.chosen ? root.theme.colAccent : "transparent"
                border.width: Theme.borderWidth
                border.color: deviceRow.chosen ? root.theme.colAccent : root.theme.colFgMuted
            }

            Text {
                anchors.left: radio.right
                anchors.leftMargin: Theme.space
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.label(deviceRow.modelData)
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: deviceRow.chosen
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.choose(deviceRow.modelData)
            }
        }
    }

    // Controls for the chosen device.
    Column {
        visible: root.expanded && root.ready
        width: parent.width
        spacing: Theme.tabGap

        SelectBox {
            visible: root.profileChoices.length > 1
            width: parent.width
            choices: root.profileChoices
            currentId: root.card ? root.card.active : ""
            emptyLabel: "Profile"
            tip: "Sound profile for " + (root.card ? root.card.description : "this card")
            onPicked: (id) => AudioCardService.setProfile(root.card, id)
        }

        Row {
            width: parent.width
            spacing: Theme.tabGap

            MenuChip {
                id: muteChip
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                label: root.ready && root.current.audio.muted ? "Unmute" : "Mute"
                accent: root.ready && root.current.audio.muted
                tip: root.sink ? "Mute or unmute this output" : "Mute or unmute this input"
                onClicked: {
                    if (root.ready)
                        root.current.audio.muted = !root.current.audio.muted
                }
            }

            IntSlider {
                width: parent.width - muteChip.width - Theme.tabGap
                from: 0
                to: AudioSettings.volumeCap()
                step: Theme.volumeStep
                value: Math.min(root.masterPercent(), AudioSettings.volumeCap())
                readout: root.masterPercent() + "%"
                tip: "Volume. Moves every channel together, keeping the balance."
                onChanged: (value) => root.setMaster(value)
            }
        }

        Repeater {
            model: root.volumes.length > 1 ? root.volumes.length : 0
            delegate: Row {
                id: channelRow
                required property int index
                width: root.width
                spacing: Theme.tabGap

                Text {
                    id: channelLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: muteChip.width
                    text: root.channelName(channelRow.index)
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                IntSlider {
                    width: parent.width - channelLabel.width - Theme.tabGap
                    from: 0
                    to: AudioSettings.volumeCap()
                    step: Theme.volumeStep
                    value: Math.min(root.percent(root.volumes[channelRow.index]), AudioSettings.volumeCap())
                    readout: root.percent(root.volumes[channelRow.index]) + "%"
                    tip: root.channelName(channelRow.index) + " channel only"
                    onChanged: (value) => root.setChannel(channelRow.index, value)
                }
            }
        }

        LevelMeter {
            visible: root.meter
            width: parent.width
            theme: root.theme
            node: root.current
            live: root.meter && root.expanded && root.live && !(root.ready && root.current.audio.muted)
        }
    }
}
