pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.theme

// Left-click menu for the audio pill: active streams, playback, recording,
// and pw-top and Restart Audio pinned along the bottom.
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()

    // Lists are rebuilt in a function, never bound to a default node:
    // a binding to one crashes when that device disappears.
    property var sinks: []
    property var sources: []
    property var streams: []
    property var currentSink: null
    property var currentSource: null
    property string notice: ""

    readonly property int scrollGutter: Theme.space + Theme.tabGap
    // Matches AudioStreamRow's height, so the list shows whole rows.
    readonly property int streamSpacing: Theme.tabGap
    readonly property int streamRowHeight: Theme.fieldHeight + Theme.tabGap
        + (Config.audioMeterStreams ? Theme.borderWidth * 2 + Theme.audioMeterHeight : 0)
    readonly property int streamListMax: Theme.audioStreamRowsMax * root.streamRowHeight
        + (Theme.audioStreamRowsMax - 1) * root.streamSpacing

    // The bar's own level meters show up as capture streams; leave them out.
    function isOwnStream(node) {
        const p = node.properties || {}
        const bin = String(p["application.process.binary"] || "")
        return bin === "qs" || bin === "quickshell" || String(node.name || "").startsWith("quickshell")
    }

    function has(node, flag) {
        return (Number(node.type) & flag) === flag
    }

    function rebuild() {
        // qmllint disable missing-property
        const all = Pipewire.nodes ? Pipewire.nodes.values : []
        // qmllint enable missing-property
        const sinks = []
        const sources = []
        const streams = []
        for (let i = 0; i < all.length; i++) {
            const n = all[i]
            // Sort by type flags: properties stay empty until the tracker
            // below binds a node, but its type is known from the start.
            if (!n || !root.has(n, PwNodeType.Audio))
                continue
            if (root.has(n, PwNodeType.Stream)) {
                if (!root.isOwnStream(n))
                    streams.push(n)
            } else {
                if (root.has(n, PwNodeType.Sink))
                    sinks.push(n)
                if (root.has(n, PwNodeType.Source))
                    sources.push(n)
            }
        }
        root.sinks = sinks
        root.sources = sources
        root.streams = streams
        root.currentSink = Pipewire.defaultAudioSink || null
        root.currentSource = Pipewire.defaultAudioSource || null
    }

    function openPwTop() {
        Quickshell.execDetached(StatsSettings.terminalArgv(["pw-top"]))
    }

    function restartAudio() {
        restartProc.running = true
        root.notice = "Restarting audio…"
    }

    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 3

    onOpenChanged: {
        if (root.open) {
            root.rebuild()
            AudioCardService.refresh()
            root.forceActiveFocus()
        } else {
            root.notice = ""
        }
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = true
        root.closeRequested()
    }

    // Volume, mute, and channels need the nodes bound while the menu is open.
    PwObjectTracker {
        objects: root.open ? root.sinks.concat(root.sources, root.streams) : []
    }

    Connections {
        // qmllint disable incompatible-type
        target: Pipewire.nodes
        // qmllint enable incompatible-type
        function onValuesChanged() {
            if (root.open)
                root.rebuild()
        }
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            if (root.open)
                Qt.callLater(root.rebuild)
        }
        function onDefaultAudioSourceChanged() {
            if (root.open)
                Qt.callLater(root.rebuild)
        }
    }

    // A profile change adds and removes nodes; read the cards again then.
    Connections {
        target: AudioCardService
        function onCardsChanged() {
            if (root.open)
                Qt.callLater(root.rebuild)
        }
    }

    Process {
        id: restartProc
        command: ["systemctl", "--user", "restart", "wireplumber", "pipewire", "pipewire-pulse"]
        onExited: (code) => {
            root.notice = code === 0 ? "Audio restarted" : "Could not restart audio"
            Qt.callLater(root.rebuild)
            AudioCardService.refresh()
        }
    }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerRow.top
        anchors.margins: Theme.space
        anchors.bottomMargin: Theme.tabGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: column.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: scrollBar.pressed || scrollBar.hovered ? root.theme.colAccent : root.theme.colFgMuted
            }
        }

        Column {
            id: column
            width: Math.max(0, flick.width - root.scrollGutter)
            spacing: Theme.space * 2

            Text {
                visible: root.notice.length > 0 || AudioCardService.lastError.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: AudioCardService.lastError.length ? AudioCardService.lastError : root.notice
                color: AudioCardService.lastError.length ? root.theme.colDanger : root.theme.colOk
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            Column {
                width: parent.width
                spacing: Theme.space

                Text {
                    width: parent.width
                    text: "Active Streams" + (root.streams.length ? "  (" + root.streams.length + ")" : "")
                    color: root.theme.colAccent
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                }

                Text {
                    visible: root.streams.length === 0
                    width: parent.width
                    text: "Nothing is playing or recording."
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                // Up to audioStreamRowsMax rows, then this list scrolls.
                Flickable {
                    id: streamFlick
                    readonly property bool scrolls: streamCol.implicitHeight > root.streamListMax
                    visible: root.streams.length > 0
                    width: parent.width
                    height: Math.min(streamCol.implicitHeight, root.streamListMax)
                    contentWidth: width
                    contentHeight: streamCol.implicitHeight
                    clip: true
                    interactive: streamFlick.scrolls
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    ScrollBar.vertical: ScrollBar {
                        id: streamBar
                        policy: streamFlick.scrolls ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        width: Theme.scrollBarWidth
                        padding: 0
                        background: Item {}
                        contentItem: Rectangle {
                            implicitWidth: Theme.scrollBarWidth
                            radius: width / 2
                            color: streamBar.pressed || streamBar.hovered ? root.theme.colAccent : root.theme.colFgMuted
                        }
                    }

                    Column {
                        id: streamCol
                        width: streamFlick.width - (streamFlick.scrolls ? root.scrollGutter : 0)
                        spacing: root.streamSpacing

                        Repeater {
                            model: root.streams
                            delegate: AudioStreamRow {
                                required property var modelData
                                width: streamCol.width
                                height: root.streamRowHeight
                                theme: root.theme
                                node: modelData
                                live: root.open
                                meter: Config.audioMeterStreams
                            }
                        }
                    }
                }
            }

            AudioDeviceSection {
                width: parent.width
                theme: root.theme
                title: "Playback"
                sink: true
                devices: root.sinks
                current: root.currentSink
                live: root.open
                expanded: Config.audioPlaybackOpen
                meter: Config.audioMeterDevices
                onToggleRequested: AudioSettings.setSectionOpen(true, !Config.audioPlaybackOpen)
            }

            AudioDeviceSection {
                width: parent.width
                theme: root.theme
                title: "Recording"
                sink: false
                devices: root.sources
                current: root.currentSource
                live: root.open
                expanded: Config.audioRecordingOpen
                meter: Config.audioMeterDevices
                onToggleRequested: AudioSettings.setSectionOpen(false, !Config.audioRecordingOpen)
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Right-click the speaker or microphone on the bar to mute it; scroll to change its volume. Escape closes this menu."
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }
        }
    }

    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        spacing: Theme.tabGap
        height: Theme.chip

        MenuChip {
            theme: root.theme
            label: "pw-top"
            tip: "Open pw-top in your terminal"
            onClicked: root.openPwTop()
        }

        MenuChip {
            theme: root.theme
            label: "Restart Audio"
            tip: "Restart PipeWire, PipeWire Pulse, and WirePlumber"
            onClicked: root.restartAudio()
        }

        MenuChip {
            theme: root.theme
            label: "Close"
            tip: "Close this menu"
            onClicked: root.closeRequested()
        }
    }
}
