pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

Item {
    id: root

    required property int launcher
    required property bool dragging
    required property string dragKey
    required property real sceneX
    required property real sceneY

    signal rowDragged(string pinKey, real x, real y)
    signal rowDropped(bool commit)
    signal pinRemoved(int index)

    readonly property var pins: root.boardPins()
    readonly property string title: {
        const count = LauncherSettings.draftSlots()
        if (count <= 1)
            return "App Launcher"
        return "App Launcher " + root.launcher
    }
    readonly property int dropIndex: {
        if (!root.visible || !root.dragging || root.dragKey.length === 0)
            return -1
        return root.indexAt(root.sceneX, root.sceneY)
    }
    readonly property int markerY: {
        if (root.dropIndex < 0)
            return 0
        const count = root.pins.length
        const stop = Math.min(root.dropIndex, count)
        let cursor = 0
        for (let i = 0; i < stop; i++)
            cursor += Theme.dividerRowHeight + Theme.tabGap
        return Math.max(0, cursor - Math.floor(Theme.tabGap / 2))
    }

    function pinDetail(row) {
        if (!row)
            return ""
        const command = row.command || []
        if (command.length) {
            const parts = []
            for (let i = 0; i < command.length; i++)
                parts.push(String(command[i] || ""))
            return parts.join(" ")
        }
        return String(row.id || "")
    }

    function boardPins() {
        const boards = LauncherSettings.draftBoards()
        const row = boards[root.launcher - 1]
        if (!row || row.length === undefined)
            return []
        return row
    }

    function indexAt(sceneX, sceneY) {
        const local = root.mapFromItem(null, sceneX, sceneY)
        if (local.x < 0 || local.y < 0 || local.x > root.width || local.y > root.height)
            return -1
        const rows = listWrap.mapFromItem(null, sceneX, sceneY)
        const count = root.pins.length
        if (count === 0 || rows.y <= 0)
            return 0
        let cursor = 0
        for (let i = 0; i < count; i++) {
            if (rows.y < cursor + Theme.dividerRowHeight / 2)
                return i
            cursor += Theme.dividerRowHeight + Theme.tabGap
        }
        return count
    }

    implicitHeight: body.implicitHeight + Theme.space * 2

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.pillBg
        border.width: Theme.borderWidth
        border.color: root.dropIndex >= 0 ? Theme.accent : Theme.border
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space
        spacing: Theme.space

        Row {
            id: titleRow
            width: parent.width
            height: Theme.fieldHeight
            spacing: Theme.tabGap

            Rectangle {
                id: accent
                width: Theme.dividerThickness + Theme.borderWidth
                height: Theme.fieldHeight
                radius: Theme.borderWidth
                color: Theme.accent
            }

            Text {
                width: Math.max(1, titleRow.width - accent.width - countText.width - Theme.tabGap * 2)
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: root.title
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            Text {
                id: countText
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: String(root.pins.length)
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        Item {
            id: listWrap
            width: parent.width
            implicitHeight: Math.max(listCol.implicitHeight, Theme.dividerRowHeight)
            height: implicitHeight

            Column {
                id: listCol
                width: parent.width
                spacing: Theme.tabGap

                Repeater {
                    model: root.pins
                    delegate: LaunchPinRow {
                        id: pin
                        required property var modelData
                        required property int index
                        width: listCol.width
                        name: String(pin.modelData.name || "")
                        iconName: String(pin.modelData.icon || "")
                        detail: root.pinDetail(pin.modelData)
                        pinKey: root.launcher + ":" + pin.index
                        onDragAt: (pinKey, x, y) => root.rowDragged(pinKey, x, y)
                        onDragFinished: (commit) => root.rowDropped(commit)
                        onRemoveRequested: {
                            const at = pin.index
                            Qt.callLater(() => root.pinRemoved(at))
                        }
                    }
                }

                Text {
                    visible: root.pins.length === 0
                    width: parent.width
                    height: Theme.fieldHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: "Nothing here yet. Drag a row here by ||."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Rectangle {
                visible: root.dropIndex >= 0
                y: root.markerY
                width: parent.width
                height: Theme.dividerThickness
                radius: Theme.borderWidth
                color: Theme.accent
                z: 1
            }
        }
    }
}
