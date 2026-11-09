pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → Wallpaper → Picker: how the Ctrl+Super+Space strip behaves.
// Changes save at once.
Column {
    id: root

    readonly property var opts: WallpaperSettings.picker

    spacing: Theme.space

    Row {
        spacing: Theme.tabGap

        ChipButton {
            label: "Open the picker"
            tip: "The same as Ctrl+Super+Space"
            onClicked: WallpaperService.openPicker()
        }

        ChipButton {
            label: "Previous"
            tip: "The previous image in the folder on the focused monitor (qs ipc call wallpaper previous)"
            onClicked: WallpaperService.cycle(-1)
        }

        ChipButton {
            label: "Next"
            tip: "The next image in the folder on the focused monitor (qs ipc call wallpaper next)"
            onClicked: WallpaperService.cycle(1)
        }
    }

    CheckRow {
        width: root.width
        title: "Live preview"
        detail: "Show each image on the screen as you move to it. Esc puts the old one back; only Enter or a click saves."
        checked: root.opts.live
        onToggled: WallpaperSettings.setPicker("live", !root.opts.live)
    }

    FormRow {
        visible: root.opts.live
        width: root.width
        label: "Preview after"

        IntSlider {
            width: parent.width
            from: 0
            to: 1500
            step: 50
            value: root.opts.delay
            readout: root.opts.delay + " ms"
            tip: "How long to rest on an image before it shows. Longer keeps held arrow keys from loading every image. Default " + Theme.wallpaperPickDelay + " ms."
            onChanged: (value) => WallpaperSettings.setPicker("delay", value)
        }
    }

    FormRow {
        width: root.width
        label: "Thumbnail size"

        IntSlider {
            width: parent.width
            from: 120
            to: 400
            step: 20
            value: root.opts.height
            readout: root.opts.height + " px"
            tip: "Height of each thumbnail in the strip. Default " + Theme.wallpaperPickHeight + " px."
            onChanged: (value) => WallpaperSettings.setPicker("height", value)
        }
    }

    CheckRow {
        width: root.width
        title: "Close after setting"
        detail: "Off keeps the picker open after Enter or a click, to try more"
        checked: root.opts.close
        onToggled: WallpaperSettings.setPicker("close", !root.opts.close)
    }
}
