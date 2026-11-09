pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.settings
import qs.theme

// History list: expand, copy, mark read, dismiss, DND, and clear.
Item {
    id: root

    required property var theme

    signal closeRequested()

    function focusKeys() {
        Qt.callLater(() => keyGrab.forceActiveFocus())
    }

    function rowColor(index, selected) {
        if (selected)
            return Theme.accentDim
        if (Config.notificationStaggerRows !== false && (index % 2) === 1)
            return Theme.hover
        return root.theme.colSurface
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        const alt = (event.modifiers & Qt.AltModifier) !== 0
        const meta = (event.modifiers & Qt.MetaModifier) !== 0
        if (alt || meta)
            return
        if (ctrl && event.key === Qt.Key_C) {
            NotificationService.copyItem(NotificationService.itemAt(NotificationService.cursor))
            event.accepted = true
            return
        }
        if (ctrl && event.key === Qt.Key_R) {
            NotificationService.markAllRead()
            event.accepted = true
            return
        }
        if (ctrl && event.key === Qt.Key_Delete) {
            NotificationService.clearHistory()
            event.accepted = true
            return
        }
        if (ctrl)
            return
        if (event.key === Qt.Key_A)
            NotificationService.expandAll(true)
        else if (event.key === Qt.Key_C)
            NotificationService.expandAll(false)
        else if (event.key === Qt.Key_D)
            NotificationService.toggleDnd()
        else if (event.key === Qt.Key_R) {
            const row = NotificationService.itemAt(NotificationService.cursor)
            if (row)
                NotificationService.markRead(row.id)
        }
        else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            const row = NotificationService.itemAt(NotificationService.cursor)
            if (row)
                NotificationService.dismiss(row.id)
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
            NotificationService.moveCursor(-1)
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
            NotificationService.moveCursor(1)
        else if (event.key === Qt.Key_Right) {
            const row = NotificationService.itemAt(NotificationService.cursor)
            if (row && !row.expanded)
                NotificationService.setExpanded(NotificationService.cursor, true)
        } else if (event.key === Qt.Key_Left) {
            const row = NotificationService.itemAt(NotificationService.cursor)
            if (row && row.expanded)
                NotificationService.setExpanded(NotificationService.cursor, false)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            const row = NotificationService.itemAt(NotificationService.cursor)
            if (row)
                NotificationService.setExpanded(NotificationService.cursor, !row.expanded)
        } else if (event.key === Qt.Key_Escape) {
            root.closeRequested()
        } else {
            return
        }
        event.accepted = true
    }

    Connections {
        target: NotificationService
        function onCursorChanged() {
            if (NotificationService.count > 0)
                historyList.positionViewAtIndex(NotificationService.cursor, ListView.Contain)
        }
        function onHistoryOpenChanged() {
            if (NotificationService.historyOpen)
                root.focusKeys()
        }
    }

    Item {
        id: keyGrab
        anchors.fill: parent
        focus: true
        Keys.onPressed: (event) => root.handleKey(event)
    }

    Item {
        anchors.fill: parent
        anchors.margins: Theme.space

        Item {
            id: titleRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Theme.fieldHeight

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: root.theme.colFg
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            Text {
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                text: (NotificationService.unread > 0 ? NotificationService.unread + " unread · " : "") + NotificationService.count + " kept"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.chip
                height: Theme.chip
                radius: Theme.radiusSm
                color: closeMouse.containsMouse ? Theme.hover : root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: closeMouse.containsMouse ? Theme.danger : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? Theme.danger : Theme.subtext
                    font.pixelSize: Theme.fontPx
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Text {
            id: keys
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            wrapMode: Text.WordWrap
            text: "↑↓ move · → expand · ← collapse · a all · c collapse all · r read · Ctrl+R all read · d DND · Del remove · Ctrl+C copy · Ctrl+Del clear · Esc close"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            id: actions
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: keys.top
            anchors.bottomMargin: Theme.tabGap
            height: Theme.fieldHeight
            spacing: Theme.tabGap

            Rectangle {
                width: Math.max(Theme.fieldHeight * 3, parent.width - Theme.tabGap * 3 - Theme.historyButtonWidth - Theme.historyWideButtonWidth * 2)
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: NotificationService.count > 0 ? 1 : Theme.widgetOffOpacity
                color: expandMouse.containsMouse ? Theme.hover : root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.allExpanded ? "Collapse all" : "Expand all"
                    color: root.theme.colFg
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                MouseArea {
                    id: expandMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (NotificationService.count > 0)
                            NotificationService.expandAll(!NotificationService.allExpanded)
                        root.focusKeys()
                    }
                }
            }

            Rectangle {
                width: Theme.historyButtonWidth
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: NotificationService.dnd
                       ? Qt.rgba(root.theme.colDanger.r, root.theme.colDanger.g, root.theme.colDanger.b, dndMouse.containsMouse ? 0.45 : 0.28)
                       : (dndMouse.containsMouse ? Theme.hover : root.theme.colSurface)
                border.width: Theme.borderWidth
                border.color: NotificationService.dnd ? root.theme.colDanger : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.dnd ? "DND on" : "DND"
                    color: NotificationService.dnd ? root.theme.colDanger : root.theme.colFg
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.toggleDnd()
                        root.focusKeys()
                    }

                    HoverTip {
                        message: NotificationService.dnd ? "Turn off Do Not Disturb" : "Turn on Do Not Disturb"
                        show: dndMouse.containsMouse
                    }
                }
            }

            Rectangle {
                width: Theme.historyWideButtonWidth
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: NotificationService.unread > 0 ? 1 : Theme.widgetOffOpacity
                color: readAllMouse.containsMouse ? Theme.hover : root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: NotificationService.unread > 0 ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "Mark all read"
                    color: root.theme.colFg
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                MouseArea {
                    id: readAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.markAllRead()
                        root.focusKeys()
                    }
                }
            }

            Rectangle {
                width: Theme.historyWideButtonWidth
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: NotificationService.count > 0 ? 1 : Theme.widgetOffOpacity
                color: clearMouse.containsMouse ? Theme.hover : root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "Clear list"
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (NotificationService.count > 0)
                            NotificationService.clearHistory()
                        root.focusKeys()
                    }
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleRow.bottom
            anchors.bottom: actions.top
            anchors.topMargin: Theme.space
            anchors.bottomMargin: Theme.space

            Text {
                anchors.centerIn: parent
                width: parent.width
                visible: NotificationService.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No notifications captured yet.\nNew ones appear here as they arrive."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            ListView {
                id: historyList
                anchors.fill: parent
                visible: NotificationService.count > 0
                clip: true
                spacing: Theme.tabGap
                model: NotificationService.items
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index

                    readonly property bool selected: row.index === NotificationService.cursor
                    readonly property string thumbUrl: {
                        if (!row.modelData.expanded)
                            return ""
                        const path = NotificationService.imagePathFor(row.modelData)
                        return path.length ? ("file://" + path) : ""
                    }
                    readonly property bool showBody: String(row.modelData.body || "").length > 0
                            && (row.modelData.expanded || String(row.modelData.summary || "").length === 0)

                    width: historyList.width
                    height: rowCol.implicitHeight + Theme.space * 2
                    radius: Theme.radiusSm
                    color: root.rowColor(row.index, row.selected)
                    border.width: row.selected ? 2 : Theme.borderWidth
                    border.color: row.selected ? Theme.accent : Theme.border

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.cursor = row.index
                            NotificationService.setExpanded(row.index, !row.modelData.expanded)
                            root.focusKeys()
                        }
                    }

                    Column {
                        id: rowCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.space
                        spacing: Theme.tabGap

                        Row {
                            width: parent.width
                            spacing: Theme.tabGap

                            Rectangle {
                                visible: !row.modelData.read
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.notificationUnreadDot
                                height: Theme.notificationUnreadDot
                                radius: Theme.notificationUnreadDot / 2
                                color: Theme.accent
                            }

                            Text {
                                width: Math.max(0, parent.width - timeLabel.implicitWidth - Theme.chip * 3 - Theme.tabGap * 4
                                                - (row.modelData.read ? 0 : Theme.notificationUnreadDot + Theme.chip + Theme.tabGap * 2))
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: row.modelData.app || "App"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            Text {
                                id: timeLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: NotificationService.formatTime(row.modelData.ts)
                                color: Theme.subtext
                                font.family: root.theme.fontFamily
                                font.pixelSize: Theme.smallPx
                            }

                            Rectangle {
                                visible: !row.modelData.read
                                width: Theme.chip
                                height: Theme.chip
                                radius: Theme.radiusSm
                                color: readMouse.containsMouse ? Theme.hover : "transparent"
                                border.width: Theme.borderWidth
                                border.color: readMouse.containsMouse ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(0xf012c)
                                    color: root.theme.colFg
                                    font.family: root.theme.iconFont
                                    font.pixelSize: Theme.smallPx
                                }

                                MouseArea {
                                    id: readMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.cursor = row.index
                                        NotificationService.markRead(row.modelData.id)
                                        root.focusKeys()
                                    }

                                    HoverTip {
                                        message: "Mark as read"
                                        show: readMouse.containsMouse
                                    }
                                }
                            }

                            Rectangle {
                                width: Theme.chip
                                height: Theme.chip
                                radius: Theme.radiusSm
                                color: expMouse.containsMouse ? Theme.hover : "transparent"
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.expanded ? "▴" : "▾"
                                    color: root.theme.colFg
                                    font.pixelSize: Theme.smallPx
                                }

                                MouseArea {
                                    id: expMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.cursor = row.index
                                        NotificationService.setExpanded(row.index, !row.modelData.expanded)
                                        root.focusKeys()
                                    }
                                }
                            }

                            Rectangle {
                                width: Theme.chip
                                height: Theme.chip
                                radius: Theme.radiusSm
                                color: copyMouse.containsMouse ? Theme.hover : "transparent"
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(0xf018f)
                                    color: root.theme.colFg
                                    font.family: root.theme.iconFont
                                    font.pixelSize: Theme.smallPx
                                }

                                MouseArea {
                                    id: copyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.cursor = row.index
                                        NotificationService.copyItem(row.modelData)
                                        root.focusKeys()
                                    }

                                    HoverTip {
                                        message: "Copy the image, or the text if there is no image"
                                        show: copyMouse.containsMouse
                                    }
                                }
                            }

                            Rectangle {
                                width: Theme.chip
                                height: Theme.chip
                                radius: Theme.radiusSm
                                color: dismissMouse.containsMouse ? Theme.hover : "transparent"
                                border.width: Theme.borderWidth
                                border.color: dismissMouse.containsMouse ? Theme.danger : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: dismissMouse.containsMouse ? Theme.danger : Theme.subtext
                                    font.pixelSize: Theme.smallPx
                                    font.bold: true
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.cursor = row.index
                                        NotificationService.dismiss(row.modelData.id)
                                        root.focusKeys()
                                    }

                                    HoverTip {
                                        message: "Remove from history"
                                        show: dismissMouse.containsMouse
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.space
                            visible: row.thumbUrl.length > 0 || String(row.modelData.summary || "").length > 0 || row.showBody

                            Rectangle {
                                visible: row.thumbUrl.length > 0 && shot.status !== Image.Error
                                width: Theme.notificationThumbWidth
                                height: Theme.notificationThumbHeight
                                radius: Theme.radiusSm
                                clip: true
                                color: Theme.thumbBackdrop
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                Image {
                                    id: shot
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: Theme.notificationThumbWidth * 2
                                    sourceSize.height: Theme.notificationThumbHeight * 2
                                    source: row.thumbUrl
                                }
                            }

                            Column {
                                width: parent.width - (row.thumbUrl.length > 0 ? Theme.notificationThumbWidth + Theme.space : 0)
                                spacing: Theme.tabGap

                                Text {
                                    width: parent.width
                                    text: row.modelData.summary || "(no title)"
                                    color: root.theme.colFg
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: row.modelData.expanded ? 10000 : 2
                                    elide: row.modelData.expanded ? Text.ElideNone : Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    visible: row.showBody
                                    text: NotificationService.bodyHtml(row.modelData.body)
                                    textFormat: String(row.modelData.body || "").indexOf("<") >= 0 ? Text.RichText : Text.PlainText
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: row.modelData.expanded ? 10000 : 3
                                    elide: row.modelData.expanded ? Text.ElideNone : Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
