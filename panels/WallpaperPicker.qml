pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// The wallpaper picker (Ctrl+Super+Space, qs ipc call wallpaper toggle):
// a strip of thumbnails from the wallpaper folder on the focused monitor.
// Moving previews the image on that monitor after a short rest (Settings →
// Wallpaper → Picker); Enter or a click saves it for that monitor only;
// Esc puts the old one back. Exists only while open.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    readonly property string monitor: WallpaperService.pickerMonitor
    readonly property var opts: WallpaperSettings.picker
    readonly property string filter: search.text.trim().toLowerCase()
    readonly property var shown: WallpaperService.images.filter(img => !root.filter.length || String(img.name).toLowerCase().indexOf(root.filter) >= 0)
    readonly property real aspect: root.screen ? Math.min(2, Math.max(1, root.screen.width / Math.max(1, root.screen.height))) : 16 / 9
    readonly property int thumbH: root.opts.height
    readonly property int thumbW: Math.round(root.thumbH * root.aspect)

    // The wallpaper when the picker opened, put back on Esc.
    property string original: ""
    property bool previewed: false
    // False until a key or the wheel moves, so a late folder list can still
    // land on the current image.
    property bool moved: false

    function indexOfPath(path) {
        for (let i = 0; i < root.shown.length; i++) {
            if (String(root.shown[i].path) === path)
                return i
        }
        return -1
    }

    function settle() {
        if (!root.previewed)
            root.original = WallpaperService.pathFor(root.monitor)
        if (!root.moved) {
            const at = root.indexOfPath(root.original)
            strip.currentIndex = at >= 0 ? at : 0
            strip.positionViewAtIndex(strip.currentIndex, ListView.Center)
        }
    }

    function move(delta) {
        if (!root.shown.length)
            return
        root.moved = true
        strip.currentIndex = Math.max(0, Math.min(root.shown.length - 1, strip.currentIndex + delta))
        if (root.opts.live)
            previewTimer.restart()
    }

    function selected() {
        const img = root.shown[strip.currentIndex]
        return img ? String(img.path) : ""
    }

    function choose() {
        const path = root.selected()
        if (!path.length)
            return
        previewTimer.stop()
        WallpaperService.applyTo(path, root.monitor, "")
        root.original = path
        root.previewed = false
        if (root.opts.close)
            WallpaperService.closePicker()
    }

    function cancel() {
        previewTimer.stop()
        if (root.previewed && root.original.length)
            WallpaperService.preview(root.original, root.monitor)
        WallpaperService.closePicker()
    }

    Component.onCompleted: root.settle()
    onShownChanged: root.settle()

    Connections {
        target: WallpaperService
        function onMonitorsChanged() {
            root.settle()
        }
    }

    Timer {
        id: previewTimer
        interval: root.opts.delay
        onTriggered: {
            const path = root.selected()
            if (!path.length)
                return
            root.previewed = true
            WallpaperService.preview(path, root.monitor)
        }
    }

    screen: ScreenService.screenNamed(root.monitor) || ScreenService.mainScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // A click beside the strip cancels.
    MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.round(parent.width * 0.9)
        height: column.implicitHeight + Theme.space * 3
        radius: Theme.radius
        color: Theme.barBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        // Clicks on the card stay on the card.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: Theme.space * 1.5
            y: Theme.space * 1.5
            width: parent.width - Theme.space * 3
            spacing: Theme.space

            Row {
                width: parent.width
                height: Theme.fieldHeight
                spacing: Theme.space

                Text {
                    id: title
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Wallpaper · " + (root.monitor.length ? root.monitor : "this monitor")
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                    font.bold: true
                }

                Rectangle {
                    width: parent.width - title.width - count.width - Theme.space * 2
                    height: parent.height
                    radius: Theme.radiusSm
                    color: Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: search.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space
                        anchors.rightMargin: Theme.space
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        clip: true
                        onTextChanged: root.moved = false
                        Keys.onPressed: (event) => {
                            const k = event.key
                            if (k === Qt.Key_Right || k === Qt.Key_Down) {
                                root.move(1)
                            } else if (k === Qt.Key_Left || k === Qt.Key_Up) {
                                root.move(-1)
                            } else if (k === Qt.Key_PageDown) {
                                root.move(5)
                            } else if (k === Qt.Key_PageUp) {
                                root.move(-5)
                            } else if (k === Qt.Key_Home && (event.modifiers & Qt.ControlModifier)) {
                                root.move(-root.shown.length)
                            } else if (k === Qt.Key_End && (event.modifiers & Qt.ControlModifier)) {
                                root.move(root.shown.length)
                            } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                                root.choose()
                            } else if (k === Qt.Key_Escape) {
                                if (search.text.length)
                                    search.text = ""
                                else
                                    root.cancel()
                            } else {
                                return
                            }
                            event.accepted = true
                        }

                        Text {
                            visible: !search.text.length
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type to filter by name"
                            color: Theme.subtext
                            font: search.font
                        }
                    }
                }

                Text {
                    id: count
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: WallpaperService.loading ? "Reading…" : (root.shown.length + " of " + WallpaperService.images.length)
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            ListView {
                id: strip
                width: parent.width
                height: root.thumbH + Theme.space * 3
                orientation: ListView.Horizontal
                spacing: Theme.wallpaperPickGap
                clip: true
                model: root.shown
                highlightMoveDuration: Theme.osdFadeMs
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: (width - root.thumbW) / 2
                preferredHighlightEnd: (width + root.thumbW) / 2
                cacheBuffer: root.thumbW * 2
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    onWheel: (event) => root.move(event.angleDelta.y > 0 || event.angleDelta.x > 0 ? -1 : 1)
                }

                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property bool saved: String(tile.modelData.path) === WallpaperService.pathFor(root.monitor)

                    width: root.thumbW
                    height: strip.height

                    Rectangle {
                        id: frame
                        anchors.top: parent.top
                        width: parent.width
                        height: root.thumbH
                        radius: Theme.radiusSm
                        color: Theme.fieldBg
                        border.width: tile.current ? Theme.borderWidth * 3 : Theme.borderWidth
                        border.color: tile.current ? Theme.accent : (tile.saved ? Theme.subtext : Theme.border)
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: frame.border.width
                            source: IconService.fileUrl(String(tile.modelData.path))
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.height: root.thumbH
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.moved = true
                                strip.currentIndex = tile.index
                                root.choose()
                            }
                        }
                    }

                    Text {
                        anchors.top: frame.bottom
                        anchors.topMargin: Theme.tabGap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        text: (tile.saved ? "● " : "") + String(tile.modelData.name)
                        color: tile.current ? Theme.text : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                        font.bold: tile.current
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: (WallpaperService.error.length ? WallpaperService.error + " · " : "")
                    + "← → move · type to filter · Enter " + (root.opts.close ? "set and close" : "set") + " · Esc " + (root.previewed ? "put back and close" : "close")
                    + (root.opts.live ? "" : " · preview is off (Settings → Wallpaper)")
                color: WallpaperService.error.length ? Theme.danger : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }
    }
}
