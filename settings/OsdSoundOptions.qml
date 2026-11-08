pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import qs.config
import qs.services
import qs.theme

// On-Screen Display → Sound: the click on a volume change. The theme
// sound plays with canberra-gtk-play; a file with pw-play (PipeWire).
Column {
    id: root

    readonly property var draft: OsdSettings.editor.value
    readonly property bool fileMissing: root.draft.sound === "file" && !root.draft.soundFile.length

    spacing: Theme.space

    Row {
        width: root.width
        spacing: Theme.tabGap

        ChipButton {
            label: "Theme sound"
            active: root.draft.sound === "theme"
            tip: "Your sound theme's volume-change sound (needs canberra-gtk-play)"
            onClicked: OsdSettings.editor.set("sound", "theme")
        }

        ChipButton {
            label: "Sound file"
            active: root.draft.sound === "file"
            tip: "A sound file of your own, played with pw-play"
            onClicked: OsdSettings.editor.set("sound", "file")
        }

        ChipButton {
            label: "Off"
            active: root.draft.sound === "off"
            tip: "No sound"
            onClicked: OsdSettings.editor.set("sound", "off")
        }

        ChipButton {
            label: "Test"
            enabled: root.draft.sound !== "off" && !root.fileMissing
            opacity: enabled ? 1 : 0.5
            tip: "Play it now"
            onClicked: OsdService.playSound(root.draft)
        }
    }

    Row {
        visible: root.draft.sound === "file"
        width: root.width
        spacing: Theme.tabGap

        PathField {
            width: root.width - browse.width - Theme.tabGap
            value: root.draft.soundFile
            placeholderText: "/path/to/sound.oga"
            bad: root.fileMissing
            tip: "Full path to a .wav, .oga, .ogg, or .flac file"
            onEdited: (text) => OsdSettings.editor.set("soundFile", text)
        }

        ChipButton {
            id: browse
            label: "Browse"
            tip: "Pick a sound file"
            onClicked: soundDialog.open()
        }
    }

    Column {
        visible: root.draft.sound !== "off"
        width: root.width
        spacing: Theme.tabGap

        Text {
            width: parent.width
            text: "Sound volume"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        IntSlider {
            width: parent.width
            from: 0
            to: 100
            step: 5
            value: root.draft.soundVolume
            readout: root.draft.soundVolume + "%"
            tip: "How loud the click is, before your speaker volume"
            onChanged: (value) => OsdSettings.editor.set("soundVolume", value)
        }
    }

    FileDialog {
        id: soundDialog
        title: "Volume sound"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Sounds (*.wav *.oga *.ogg *.flac *.mp3)", "All files (*)"]
        onAccepted: OsdSettings.editor.set("soundFile", decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }
}
