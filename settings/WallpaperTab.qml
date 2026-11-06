pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    property string selectedName: ""
    property string selectedPath: ""
    property string renamingName: ""
    property string confirmName: ""

    function choose(path, name, applyNow) {
        root.selectedPath = String(path || "")
        root.selectedName = String(name || "")
        root.confirmName = ""
        if (applyNow)
            WallpaperService.apply(root.selectedPath)
    }

    function startRename(path, name) {
        root.confirmName = ""
        root.selectedPath = String(path || "")
        root.selectedName = String(name || "")
        root.renamingName = root.selectedName
        renameField.text = root.selectedName
        Qt.callLater(() => {
            renameField.forceActiveFocus()
            renameField.selectAll()
        })
    }

    function commitRename() {
        const next = renameField.text.trim()
        const current = root.renamingName
        if (!current.length)
            return
        root.renamingName = ""
        if (!next.length || next === current)
            return
        WallpaperService.rename(current, next)
    }

    function askDelete(name) {
        const current = String(name || "")
        if (!current.length)
            return
        if (root.confirmName === current) {
            root.confirmName = ""
            if (root.renamingName === current)
                root.renamingName = ""
            WallpaperService.remove(current)
            return
        }
        root.confirmName = current
    }

    Component.onCompleted: WallpaperService.refresh()

    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Wallpaper"
                hint: "Click an image to set it. The pencil renames the file, and ✕ deletes it."
            }

            Item {
                width: parent.width
                height: folderCol.implicitHeight

                Column {
                    id: folderCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        TextField {
                            id: dirField
                            width: parent.width - browseButton.width - refreshButton.width - Theme.tabGap * 2
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: Config.wallpaperDirValue()
                            placeholderText: "Wallpaper folder"
                            leftPadding: Theme.space
                            color: Theme.text
                            placeholderTextColor: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: dirField.activeFocus ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: dirField.activeFocus ? Theme.accent : Theme.border
                            }
                            onEditingFinished: {
                                Config.setWallpaperDir(text)
                                WallpaperService.refresh()
                            }

                            HoverHandler {
                                id: dirHover
                            }

                            HoverTip {
                                message: "Folder of wallpaper images"
                                show: dirHover.hovered
                            }
                        }

                        Rectangle {
                            id: browseButton
                            width: browseLabel.implicitWidth + Theme.space * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: browseMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Text {
                                id: browseLabel
                                anchors.centerIn: parent
                                text: "Browse"
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: browseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    folderDialog.currentFolder = "file://" + Config.wallpaperDirValue()
                                    folderDialog.open()
                                }

                                HoverTip {
                                    message: "Choose the wallpaper folder"
                                    show: browseMouse.containsMouse
                                }
                            }
                        }

                        Rectangle {
                            id: refreshButton
                            width: refreshLabel.implicitWidth + Theme.space * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: refreshMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Text {
                                id: refreshLabel
                                anchors.centerIn: parent
                                text: "Refresh"
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.refresh()

                                HoverTip {
                                    message: "Read the folder again"
                                    show: refreshMouse.containsMouse
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        Rectangle {
                            id: addButton
                            width: addLabel.implicitWidth + Theme.space * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: addMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.accent

                            Text {
                                id: addLabel
                                anchors.centerIn: parent
                                text: "Add images"
                                color: Theme.wsActiveText
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: addMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fileDialog.currentFolder = "file://" + Config.wallpaperDirValue()
                                    fileDialog.open()
                                }

                                HoverTip {
                                    message: "Copy images into the wallpaper folder"
                                    show: addMouse.containsMouse
                                }
                            }
                        }

                        Text {
                            width: parent.width - addButton.width - Theme.tabGap
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: WallpaperService.error.length ? WallpaperService.error : WallpaperService.status
                            color: WallpaperService.error.length ? Theme.danger : Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        Text {
                            id: previewLabel
                            width: previewLabel.implicitWidth
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            text: "Preview"
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        IntSlider {
                            width: parent.width - previewLabel.width - Theme.tabGap
                            from: Theme.wallpaperTileMin
                            to: Theme.wallpaperTileMax
                            step: Theme.wallpaperTileStep
                            value: Config.wallpaperTileValue()
                            readout: Config.wallpaperTileValue() + " px"
                            tip: "Wallpaper preview size, from " + Theme.wallpaperTileMin + " to " + Theme.wallpaperTileMax + " px"
                            onChanged: (value) => Config.setWallpaperTileSize(value)
                        }
                    }

                    Row {
                        visible: root.renamingName.length > 0
                        width: parent.width
                        spacing: Theme.tabGap

                        TextField {
                            id: renameField
                            width: parent.width - renameButton.width - Theme.tabGap
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            leftPadding: Theme.space
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: renameField.activeFocus ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: renameField.activeFocus ? Theme.accent : Theme.border
                            }
                            onAccepted: root.commitRename()
                            Keys.onEscapePressed: root.renamingName = ""

                            HoverHandler {
                                id: renameHover
                            }

                            HoverTip {
                                message: "New file name. Enter saves it."
                                show: renameHover.hovered
                            }
                        }

                        Rectangle {
                            id: renameButton
                            width: renameLabel.implicitWidth + Theme.space * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: renameMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.accent

                            Text {
                                id: renameLabel
                                anchors.centerIn: parent
                                text: "Rename"
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: renameMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.commitRename()

                                HoverTip {
                                    message: "Rename " + root.renamingName
                                    show: renameMouse.containsMouse
                                }
                            }
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: Theme.space

                        Repeater {
                            model: WallpaperService.images
                            delegate: Rectangle {
                                id: tile
                                required property var modelData
                                required property int index
                                readonly property string path: String(tile.modelData.path || "")
                                readonly property string name: String(tile.modelData.name || "")
                                readonly property int preview: Config.wallpaperTileValue()
                                readonly property bool current: path.length > 0 && path === Config.wallpaperCurrent
                                readonly property bool picked: path === root.selectedPath
                                readonly property bool confirming: name === root.confirmName
                                width: tile.preview
                                height: tile.preview + Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: tile.confirming ? Theme.danger : (tile.current || tile.picked ? Theme.accent : Theme.border)
                                clip: true

                                Image {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: tile.preview
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    source: tile.path.length ? "file://" + tile.path : ""
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: Theme.fieldHeight
                                    leftPadding: Theme.space
                                    rightPadding: Theme.space
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: tile.name
                                    color: tile.current ? Theme.accent : Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => root.choose(tile.path, tile.name, mouse.button === Qt.LeftButton)

                                    HoverTip {
                                        message: tile.current ? "Current wallpaper" : "Set this wallpaper"
                                        show: tileMouse.containsMouse && !pencilMouse.containsMouse && !deleteMouse.containsMouse
                                    }
                                }

                                Rectangle {
                                    id: pencilButton
                                    z: 2
                                    x: Theme.tabGap
                                    y: Theme.tabGap
                                    width: Theme.chip
                                    height: Theme.chip
                                    radius: Theme.radiusSm
                                    color: pencilMouse.containsMouse ? Theme.hover : Theme.pillBg
                                    border.width: Theme.borderWidth
                                    border.color: Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✎"
                                        color: Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                    }

                                    MouseArea {
                                        id: pencilMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.startRename(tile.path, tile.name)

                                        HoverTip {
                                            message: "Rename this file"
                                            show: pencilMouse.containsMouse
                                        }
                                    }
                                }

                                Rectangle {
                                    id: deleteMark
                                    z: 2
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Theme.tabGap
                                    width: Theme.chip
                                    height: Theme.chip
                                    radius: Theme.radiusSm
                                    color: tile.confirming ? Theme.danger : (deleteMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                    border.width: Theme.borderWidth
                                    border.color: Theme.danger

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: tile.confirming ? Theme.pageBg : Theme.danger
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.askDelete(tile.name)

                                        HoverTip {
                                            message: tile.confirming ? "Delete this file" : "Ask once more before deleting"
                                            show: deleteMouse.containsMouse
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: !WallpaperService.loading && (!WallpaperService.images || WallpaperService.images.length === 0)
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Nothing in this folder yet. Add images, or point the folder at the ones you already have."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }


                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Wallpaper folder"
        onAccepted: {
            const path = WallpaperService.urlToPath(selectedFolder)
            if (!path.length)
                return
            Config.setWallpaperDir(path)
            WallpaperService.refresh()
        }
    }

    FileDialog {
        id: fileDialog
        title: "Add wallpapers"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp *.jxl)"]
        onAccepted: WallpaperService.add(selectedFiles)
    }
}
