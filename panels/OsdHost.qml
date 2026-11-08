pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.components
import qs.config
import qs.services
import qs.theme

// The on-screen display (replaces swayosd). Always loaded; it watches the
// default speaker and microphone through PipeWire, media players through
// MPRIS, and laptop brightness, all by change signals with no polling. Any
// change shows the popup: keys, the bar's own sliders, or another app. The
// popup window exists only while it shows (OsdPanel).
//
// qs ipc call osd preview volume|mic|track|brightness   a sample popup,
//   the same function as the settings page's Preview buttons
Item {
    id: root

    readonly property var look: OsdSettings.live

    property var current: ({})
    property var currentLook: null
    property bool showing: false
    property bool fading: false
    // False for a moment after start, so reading the first levels is quiet.
    property bool settled: false
    property string outKey: ""
    property string inKey: ""
    property string lastTrack: ""

    function present(item) {
        root.current = item
        root.currentLook = item.look || null
        root.showing = true
        root.fading = false
        fadeTimer.stop()
        hideTimer.restart()
    }

    function nodeName(node) {
        try {
            return String(node.description || node.nickname || node.name || "Device")
        } catch (e) {
            return "Device"
        }
    }

    function volumeGlyph(level, muted) {
        if (muted)
            return OsdSettings.glyph("volMuted", root.look)
        if (level > 66)
            return OsdSettings.glyph("volHigh", root.look)
        if (level > 33)
            return OsdSettings.glyph("volMid", root.look)
        return OsdSettings.glyph("volLow", root.look)
    }

    function levelItem(kind, glyph, title, detail, level, muted) {
        return {
            kind: kind,
            glyph: glyph,
            title: title,
            detail: detail,
            value: muted ? 0 : Math.min(100, level) / 100,
            percent: muted ? "Muted" : level + "%",
            muted: muted,
            art: ""
        }
    }

    function outChanged() {
        if (!levels.outOk || !root.settled || !root.look.volume || deviceTimer.running)
            return
        root.present(root.levelItem("volume", root.volumeGlyph(levels.outVol, levels.outMute), "Volume", "", levels.outVol, levels.outMute))
        OsdService.playSound(null)
    }

    function showDevice() {
        const key = levels.nodeKey(levels.sink)
        const changed = key.length && key !== root.outKey
        root.outKey = key
        if (!changed || !levels.outOk || !root.settled || !root.look.device)
            return
        root.present(root.levelItem("device", OsdSettings.glyph("device", root.look), root.nodeName(levels.sink), "Output", levels.outVol, levels.outMute))
    }

    function inChanged(muteOnly) {
        if (!levels.inOk || !root.settled || !root.look.mic || sourceTimer.running)
            return
        const glyph = OsdSettings.glyph(levels.inMute ? "micMuted" : "mic", root.look)
        if (muteOnly)
            root.present({ kind: "mic", glyph: glyph, title: "Microphone", detail: levels.inMute ? "Muted" : "On", value: -1, percent: "", muted: levels.inMute, art: "" })
        else
            root.present(root.levelItem("mic", glyph, "Microphone", "", levels.inVol, levels.inMute))
    }

    function trackText(player) {
        const artist = String(player.trackArtist || "")
        const album = String(player.trackAlbum || "")
        return artist.length && album.length ? artist + " · " + album : (artist || album)
    }

    function trackChanged(player) {
        const title = String(player.trackTitle || "")
        const key = String(player.dbusName) + "\n" + title + "\n" + String(player.trackArtist || "")
        if (!title.length || key === root.lastTrack)
            return
        root.lastTrack = key
        if (!root.settled || !root.look.track)
            return
        root.present({ kind: "track", glyph: OsdSettings.glyph("track", root.look), title: title, detail: root.trackText(player), value: -1, percent: "", muted: false, art: String(player.trackArtUrl || "") })
    }

    function playbackChanged(player) {
        if (!root.settled || !root.look.playback)
            return
        const playing = !!player.isPlaying
        const title = String(player.trackTitle || "")
        root.present({
            kind: "playback",
            glyph: OsdSettings.glyph(playing ? "play" : "pause", root.look),
            title: playing ? "Playing" : "Paused",
            detail: title.length ? title + (player.trackArtist ? " · " + player.trackArtist : "") : String(player.identity || ""),
            value: -1,
            percent: "",
            muted: !playing,
            art: String(player.trackArtUrl || "")
        })
    }

    Component.onCompleted: settleTimer.start()

    // Keeps the default speaker and microphone tracked.
    AudioLevels {
        id: levels
        onOutVolChanged: root.outChanged()
        onOutMuteChanged: root.outChanged()
        onInMuteChanged: root.inChanged(true)
        onInVolChanged: root.inChanged(false)
        onSinkChanged: deviceTimer.restart()
        onSourceChanged: sourceTimer.restart()
    }

    // One watcher per media player.
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData
            function onPostTrackChanged() {
                root.trackChanged(modelData)
            }
            function onIsPlayingChanged() {
                root.playbackChanged(modelData)
            }
        }
    }

    Connections {
        target: BrightnessService
        function onPercentChanged() {
            if (BrightnessService.available && root.settled && root.look.brightness)
                root.present(root.levelItem("brightness", OsdSettings.glyph("brightness", root.look), "Brightness", "", BrightnessService.percent, false))
        }
    }

    Connections {
        target: OsdService
        function onRequested(item) {
            root.present(item)
        }
    }

    Timer {
        id: settleTimer
        interval: Theme.osdSettleMs
        onTriggered: {
            root.outKey = levels.nodeKey(levels.sink)
            root.inKey = levels.nodeKey(levels.source)
            root.settled = true
        }
    }

    // A new output device: wait for it to be read, then name it.
    Timer {
        id: deviceTimer
        interval: Theme.osdSettleMs / 3
        onTriggered: root.showDevice()
    }

    // A new microphone: its first reading is not a change.
    Timer {
        id: sourceTimer
        interval: Theme.osdSettleMs / 3
        onTriggered: root.inKey = levels.nodeKey(levels.source)
    }

    Timer {
        id: hideTimer
        interval: (root.currentLook || root.look).timeout
        onTriggered: {
            root.showing = false
            root.fading = true
            fadeTimer.start()
        }
    }

    Timer {
        id: fadeTimer
        interval: Theme.osdFadeMs
        onTriggered: root.fading = false
    }

    LazyLoader {
        active: root.showing || root.fading
        OsdPanel {
            item: root.current
            look: root.currentLook || root.look
            showing: root.showing
        }
    }

    IpcHandler {
        target: "osd"
        function preview(kind: string): string {
            const k = String(kind || "")
            if (["volume", "mic", "track", "brightness"].indexOf(k) < 0)
                return "kind must be volume, mic, track, or brightness"
            OsdService.preview(k, null)
            return "ok"
        }
    }
}
