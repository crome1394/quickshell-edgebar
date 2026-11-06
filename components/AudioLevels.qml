import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.theme

// Held sink and source for one open pill or the Audio page.
// The default node is copied in a function. A binding to
// Pipewire.defaultAudioSink crashes when that device disappears.
Item {
    id: root

    property var sink: null
    property var source: null
    property var tracked: []
    property int outVol: 0
    property bool outMute: false
    property bool outOk: false
    property int inVol: 0
    property bool inMute: false
    property bool inOk: false
    property string osdKind: "out"
    property int osdLevel: 0
    property bool osdMuted: false

    function clampVol(value) {
        let n = Math.round(Number(value))
        if (!(n >= 0))
            n = 0
        if (n > Theme.volumeMax)
            n = Theme.volumeMax
        return n
    }

    function volumeOf(node) {
        if (!node)
            return -1
        try {
            if (!node.ready || !node.audio)
                return -1
            const channels = node.audio.volumes
            const hasChannels = !!(channels && channels.length)
            let level = Number(node.audio.volume)
            if (!hasChannels && !(level > 0))
                return -1
            if (!(level > 0) && hasChannels) {
                let sum = 0
                let count = 0
                for (let i = 0; i < node.audio.volumes.length; i++) {
                    const channel = Number(node.audio.volumes[i])
                    if (channel >= 0) {
                        sum += channel
                        count += 1
                    }
                }
                if (count > 0)
                    level = sum / count
            }
            if (!(level >= 0))
                return -1
            return root.clampVol(level * 100)
        } catch (e) {
            return -1
        }
    }

    function nodeKey(node) {
        if (!node)
            return ""
        try {
            if (node.id !== undefined)
                return "id:" + String(node.id)
            return "name:" + String(node.name || "")
        } catch (e) {
            return ""
        }
    }

    function capture() {
        let nextSink = null
        let nextSource = null
        try {
            nextSink = Pipewire.defaultAudioSink
        } catch (e) {
            nextSink = null
        }
        try {
            nextSource = Pipewire.defaultAudioSource
        } catch (e2) {
            nextSource = null
        }
        if (root.nodeKey(nextSink) !== root.nodeKey(root.sink))
            root.sink = nextSink || null
        if (root.nodeKey(nextSource) !== root.nodeKey(root.source))
            root.source = nextSource || null
        const list = []
        if (root.sink)
            list.push(root.sink)
        if (root.source)
            list.push(root.source)
        let changed = list.length !== root.tracked.length
        if (!changed) {
            for (let i = 0; i < list.length; i++) {
                if (list[i] !== root.tracked[i])
                    changed = true
            }
        }
        if (changed)
            root.tracked = list
        root.readOut()
        root.readIn()
    }

    function readOut() {
        const level = root.volumeOf(root.sink)
        if (level < 0) {
            if (!root.sink)
                root.outOk = false
            return
        }
        root.outVol = level
        try {
            root.outMute = !!(root.sink && root.sink.audio && root.sink.audio.muted)
        } catch (e) {
            root.outMute = false
        }
        root.outOk = true
    }

    function readIn() {
        const level = root.volumeOf(root.source)
        if (level < 0) {
            if (!root.source)
                root.inOk = false
            return
        }
        root.inVol = level
        try {
            root.inMute = !!(root.source && root.source.audio && root.source.audio.muted)
        } catch (e) {
            root.inMute = false
        }
        root.inOk = true
    }

    function commit(node, kind, percent) {
        const level = root.clampVol(percent)
        const unit = level / 100
        try {
            if (node && node.audio)
                node.audio.volume = unit
        } catch (e) {}
        const target = kind === "in" ? "@DEFAULT_AUDIO_SOURCE@" : "@DEFAULT_AUDIO_SINK@"
        Quickshell.execDetached(["wpctl", "set-volume", target, level + "%"])
        if (kind === "in") {
            root.inVol = level
            root.inOk = !!node
        } else {
            root.outVol = level
            root.outOk = !!node
        }
        let muted = false
        try {
            muted = !!(node && node.audio && node.audio.muted)
        } catch (e2) {
            muted = false
        }
        root.queueOsd(kind, level, muted)
    }

    // Same click and swayOSD popup as ~/.local/bin/volume.sh.
    function queueOsd(kind, percent, muted) {
        root.osdKind = kind === "in" ? "in" : "out"
        root.osdLevel = root.clampVol(percent)
        root.osdMuted = !!muted
        osdDelay.restart()
    }

    function osdIcon() {
        if (root.osdMuted)
            return root.osdKind === "in" ? "microphone-sensitivity-muted" : "audio-volume-muted"
        if (root.osdKind === "in")
            return "audio-input-microphone"
        if (root.osdLevel > 66)
            return "audio-volume-high"
        if (root.osdLevel > 33)
            return "audio-volume-medium"
        return "audio-volume-low"
    }

    function osdProgress() {
        if (root.osdMuted)
            return "0.00"
        let unit = root.osdLevel / 100
        if (!(unit >= 0))
            unit = 0
        const cap = Theme.volumeMax / 100
        if (unit > cap)
            unit = cap
        return unit.toFixed(2)
    }

    function flushOsd() {
        const text = root.osdMuted ? "Muted" : (root.osdLevel + "%")
        Quickshell.execDetached([
            "canberra-gtk-play",
            "-i",
            "audio-volume-change",
            "--volume=0.6"
        ])
        Quickshell.execDetached([
            "swayosd-client",
            "--custom-icon",
            root.osdIcon(),
            "--custom-progress",
            root.osdProgress(),
            "--custom-progress-text",
            text
        ])
    }

    function nudge(kind, dir) {
        const node = kind === "in" ? root.source : root.sink
        const current = root.volumeOf(node)
        if (current < 0)
            return
        root.commit(node, kind, current + dir * AudioSettings.scrollStepValue())
    }

    function setVolume(kind, percent) {
        const node = kind === "in" ? root.source : root.sink
        if (!node)
            return
        root.commit(node, kind, percent)
    }

    function toggleMute(kind) {
        const node = kind === "in" ? root.source : root.sink
        if (!node)
            return
        let muted = false
        try {
            if (!node.audio)
                return
            muted = !node.audio.muted
            node.audio.muted = muted
        } catch (e) {
            return
        }
        if (kind === "in") {
            root.inMute = muted
            root.inOk = true
        } else {
            root.outMute = muted
            root.outOk = true
        }
    }

    function dropSink() {
        root.sink = null
        root.outOk = false
        root.tracked = root.source ? [root.source] : []
        Qt.callLater(root.capture)
    }

    function dropSource() {
        root.source = null
        root.inOk = false
        root.tracked = root.sink ? [root.sink] : []
        Qt.callLater(root.capture)
    }

    Component.onCompleted: root.capture()

    PwObjectTracker {
        objects: root.tracked
    }

    // No poll: the Connections below cover default-device, ready, volume,
    // and mute changes.
    Timer {
        id: osdDelay
        interval: Theme.volumeOsdMs
        repeat: false
        onTriggered: root.flushOsd()
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root.dropSink()
        }
        function onDefaultAudioSourceChanged() {
            root.dropSource()
        }
    }

    Connections {
        target: root.sink
        function onReadyChanged() {
            root.readOut()
        }
    }

    Connections {
        target: root.source
        function onReadyChanged() {
            root.readIn()
        }
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        function onVolumesChanged() {
            root.readOut()
        }
        function onMutedChanged() {
            root.readOut()
        }
    }

    Connections {
        target: root.source && root.source.audio ? root.source.audio : null
        function onVolumesChanged() {
            root.readIn()
        }
        function onMutedChanged() {
            root.readIn()
        }
    }
}
