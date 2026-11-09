pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.theme

// Settings → Wallpaper → Monitor: pick a monitor, see its wallpaper, and
// set how the image fits it. Clicking an image on this page sets it on the
// monitor picked here. Each monitor keeps its own wallpaper and fit in
// the bar's saved state. Changes save at once.
Column {
    id: root

    // The monitor this page sets; starts on the focused one.
    property string monitor: ""

    readonly property var names: Quickshell.screens.map(s => String(s.name))
    readonly property string path: WallpaperService.pathFor(root.monitor)
    readonly property string fit: WallpaperService.fitFor(root.monitor)

    readonly property var fitChoices: [
        { id: "cover", label: "Cover", tip: "Fill the screen, cropping the edges that do not fit" },
        { id: "contain", label: "Contain", tip: "Show the whole image, with bars where it does not fill" },
        { id: "center", label: "Center", tip: "Show the image at its own size in the middle" },
        { id: "fill", label: "Fill", tip: "Stretch to the screen, changing its shape" }
    ]

    Component.onCompleted: {
        const focused = WallpaperService.focusedName()
        root.monitor = root.names.indexOf(focused) >= 0 ? focused : (root.names[0] || "")
        WallpaperService.loadStatus()
    }

    spacing: Theme.space

    Row {
        width: root.width
        spacing: Theme.space

        Rectangle {
            id: thumb
            width: Math.round(Theme.wallpaperTile * 1.4)
            height: Math.round(width * 9 / 16)
            radius: Theme.radiusSm
            color: Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                visible: root.path.length > 0
                source: root.path.length ? IconService.fileUrl(root.path) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.height: thumb.height
            }

            Text {
                visible: !root.path.length
                anchors.centerIn: parent
                text: "None yet"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        Column {
            width: root.width - thumb.width - Theme.space
            spacing: Theme.tabGap

            SelectBox {
                width: parent.width
                choices: root.names.map(n => ({ id: n, label: n, tip: "Set the wallpaper and fit of " + n }))
                currentId: root.monitor
                emptyLabel: "No monitor"
                tip: "Which monitor this page sets"
                onPicked: (id) => root.monitor = id
            }

            Text {
                width: parent.width
                elide: Text.ElideMiddle
                text: root.path.length ? root.path : "No wallpaper saved for this monitor"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Row {
                spacing: Theme.tabGap

                Repeater {
                    model: root.fitChoices
                    delegate: ChipButton {
                        required property var modelData
                        label: String(modelData.label)
                        tip: String(modelData.tip)
                        active: root.fit === modelData.id
                        enabled: root.path.length > 0 && !WallpaperService.busy
                        opacity: enabled ? 1 : 0.5
                        onClicked: WallpaperService.setFit(root.monitor, String(modelData.id))
                    }
                }
            }
        }
    }
}
