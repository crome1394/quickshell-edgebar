pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services
import qs.settings
import qs.theme

// One application stream in the audio menu, on one line: icon, name and
// what it plays, its own volume slider with − and +, and mute. A combined
// level meter sits just below when `meter` is on. The height is fixed
// (rowHeight) so the menu can show an exact number of rows.
Item {
    id: root

    required property var theme
    required property var node
    property bool live: true
    property bool meter: true

    readonly property var props: root.node && root.node.properties ? root.node.properties : ({})
    // A playing app's stream feeds a sink (type has Sink); a recording
    // app's stream takes from a source (type has Source).
    readonly property bool recording: !!root.node && (Number(root.node.type) & PwNodeType.Source) !== 0
    readonly property bool ready: !!(root.node && root.node.ready && root.node.audio)
    readonly property bool muted: root.ready && root.node.audio.muted
    readonly property string appName: String(root.props["application.name"] || root.props["application.process.binary"] || root.node.name || "Application")
    readonly property string mediaName: String(root.props["media.name"] || "")
    readonly property bool showMedia: root.mediaName.length > 0 && root.mediaName !== root.appName
    readonly property string iconSource: IconService.url(String(root.props["application.icon-name"] || root.props["application.process.binary"] || ""))
    readonly property int volume: root.ready ? Math.round(root.node.audio.volume * 100) : 0

    // The menu uses the same numbers to size the list.
    readonly property int lineHeight: Theme.fieldHeight + Theme.tabGap
    readonly property int meterGap: Theme.borderWidth * 2

    implicitHeight: root.lineHeight + (root.meter ? root.meterGap + Theme.audioMeterHeight : 0)

    Item {
        id: line
        width: parent.width
        height: root.lineHeight

        Item {
            id: iconBox
            anchors.left: parent.left
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
            id: names
            anchors.left: iconBox.right
            anchors.leftMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.audioStreamNameWidth

            Text {
                width: parent.width
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.appName
                color: root.muted ? root.theme.colFgMuted : root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                width: parent.width
                visible: root.showMedia || root.recording
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.recording ? (root.showMedia ? "Recording · " + root.mediaName : "Recording") : root.mediaName
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            HoverHandler {
                id: nameHover
            }

            HoverTip {
                message: root.appName + (root.showMedia ? "\n" + root.mediaName : "")
                show: nameHover.hovered
            }
        }

        IntSlider {
            id: slider
            anchors.left: names.right
            anchors.leftMargin: Theme.space
            anchors.right: muteChip.left
            anchors.rightMargin: Theme.tabGap
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.ready
            opacity: root.ready ? 1 : Theme.widgetOffOpacity
            from: 0
            to: AudioSettings.volumeCap()
            step: Theme.volumeStep
            value: Math.min(root.volume, AudioSettings.volumeCap())
            readout: root.volume + "%"
            tip: "Volume for " + root.appName + " only"
            onChanged: (value) => {
                if (root.ready)
                    root.node.audio.volume = AudioSettings.limitRaise(root.volume, value) / 100
            }
        }

        MenuChip {
            id: muteChip
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.audioMuteChipWidth
            theme: root.theme
            label: root.muted ? "Unmute" : "Mute"
            accent: root.muted
            tip: "Mute or unmute " + root.appName
            onClicked: {
                if (root.ready)
                    root.node.audio.muted = !root.node.audio.muted
            }
        }
    }

    LevelMeter {
        visible: root.meter
        anchors.top: line.bottom
        anchors.topMargin: root.meterGap
        anchors.left: parent.left
        anchors.right: parent.right
        theme: root.theme
        node: root.node
        combined: true
        live: root.meter && root.live && !root.muted
    }
}
