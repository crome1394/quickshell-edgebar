pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.settings
import qs.theme

// One application stream in the audio menu: its icon and name, what it is
// playing, its own volume and mute, and a live meter.
Column {
    id: root

    required property var theme
    required property var node
    property bool live: true

    readonly property var props: root.node && root.node.properties ? root.node.properties : ({})
    // A playing app's stream feeds a sink (type has Sink); a recording
    // app's stream takes from a source (type has Source).
    readonly property bool recording: !!root.node && (Number(root.node.type) & PwNodeType.Source) !== 0
    readonly property bool ready: !!(root.node && root.node.ready && root.node.audio)
    readonly property string appName: String(root.props["application.name"] || root.props["application.process.binary"] || root.node.name || "Application")
    readonly property string mediaName: String(root.props["media.name"] || "")
    readonly property string iconSource: IconService.url(String(root.props["application.icon-name"] || root.props["application.process.binary"] || ""))
    readonly property int volume: root.ready ? Math.round(root.node.audio.volume * 100) : 0

    spacing: Theme.borderWidth * 2

    Row {
        width: parent.width
        spacing: Theme.space

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: root.theme.iconPx
            height: root.theme.iconPx

            Image {
                id: appIcon
                anchors.fill: parent
                source: root.iconSource
                visible: root.iconSource.length > 0 && appIcon.status !== Image.Error
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: !appIcon.visible
                text: root.recording ? "󰍬" : "󰕾"
                color: root.theme.colFgMuted
                font.family: root.theme.iconFont
                font.pixelSize: root.theme.iconPx
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.theme.iconPx - muteChip.width - Theme.space * 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.appName + (root.recording ? "  ·  recording" : "")
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                width: parent.width
                visible: root.mediaName.length > 0 && root.mediaName !== root.appName
                elide: Text.ElideRight
                text: root.mediaName
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }
        }

        MenuChip {
            id: muteChip
            anchors.verticalCenter: parent.verticalCenter
            theme: root.theme
            label: root.ready && root.node.audio.muted ? "Unmute" : "Mute"
            accent: root.ready && root.node.audio.muted
            tip: "Mute or unmute " + root.appName
            onClicked: {
                if (root.ready)
                    root.node.audio.muted = !root.node.audio.muted
            }
        }
    }

    IntSlider {
        visible: root.ready
        width: parent.width
        from: 0
        to: Theme.volumeMax
        step: Theme.volumeStep
        value: root.volume
        readout: root.volume + "%"
        tip: "Volume for " + root.appName + " only"
        onChanged: (value) => {
            if (root.ready)
                root.node.audio.volume = value / 100
        }
    }

    LevelMeter {
        width: parent.width
        theme: root.theme
        node: root.node
        live: root.live && !(root.ready && root.node.audio.muted)
    }
}
