pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// Settings → Notifications. Toasts and the history window.
Item {
    id: root

    readonly property bool wide: width >= Theme.settingsTwoColMin
    readonly property var corners: [
        { id: "topLeft", label: "Top left", tip: "Toasts stack downward from the top left" },
        { id: "topRight", label: "Top right", tip: "Toasts stack downward from the top right" },
        { id: "bottomLeft", label: "Bottom left", tip: "Toasts stack upward from the bottom left" },
        { id: "bottomRight", label: "Bottom right", tip: "Toasts stack upward from the bottom right" }
    ]

    Component.onCompleted: Config.ensureNotiEditor()

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "The bell stays off until you enable Notifications under Widgets and press Apply. History opens with qs ipc call notificationBell toggleHistory."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Item {
                width: parent.width
                height: root.wide
                       ? Math.max(toastBlock.implicitHeight, histBlock.implicitHeight)
                       : toastBlock.implicitHeight + Theme.space * 2 + histBlock.implicitHeight

                Column {
                    id: toastBlock
                    width: root.wide ? (parent.width - Theme.space) / 2 : parent.width
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "Toasts"
                        hint: "Where notify-send toasts appear, and how long a normal one stays. Apply writes this to SwayNC."
                    }

                    Item {
                        width: parent.width
                        height: toastCol.implicitHeight

                        Column {
                            id: toastCol
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            spacing: Theme.space

                            Text {
                                width: parent.width
                                text: "Popup corner"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            Flow {
                                width: parent.width
                                spacing: Theme.tabGap

                                Repeater {
                                    model: root.corners
                                    delegate: Rectangle {
                                        id: cornerChip
                                        required property var modelData
                                        required property int index
                                        readonly property string cornerId: String(cornerChip.modelData.id || "")
                                        readonly property bool chosen: Config.notiCornerNorm(Config.editorNotiCorner) === cornerChip.cornerId

                                        width: cornerLabel.implicitWidth + Theme.space * 2
                                        height: Theme.fieldHeight
                                        radius: Theme.radiusSm
                                        color: cornerChip.chosen ? Theme.accentDim : (cornerMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                        border.width: Theme.borderWidth
                                        border.color: cornerChip.chosen ? Theme.accent : Theme.border

                                        Text {
                                            id: cornerLabel
                                            anchors.centerIn: parent
                                            text: String(cornerChip.modelData.label || "")
                                            color: cornerChip.chosen ? Theme.wsActiveText : Theme.subtext
                                            font.family: Theme.uiFont
                                            font.pixelSize: Theme.smallPx
                                            font.bold: cornerChip.chosen
                                        }

                                        MouseArea {
                                            id: cornerMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Config.editNotiCorner(cornerChip.cornerId)

                                            HoverTip {
                                                message: String(cornerChip.modelData.tip || "")
                                                show: cornerMouse.containsMouse
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: "Message timeout"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            IntSlider {
                                width: parent.width
                                from: 0
                                to: Theme.notificationTimeoutMax
                                step: 1
                                value: Config.editorNotiTimeout
                                readout: Config.editorNotiTimeout + "s"
                                tip: "How long a normal toast stays. 0 keeps it up until you close it."
                                onChanged: (value) => Config.editNotiTimeout(value)
                            }
                        }
                    }
                }

                Column {
                    id: histBlock
                    x: root.wide ? toastBlock.width + Theme.space : 0
                    y: root.wide ? 0 : toastBlock.height + Theme.space * 2
                    width: toastBlock.width
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "History"
                        hint: "The list on the bell. Collapse all still closes the rows until the next open."
                    }

                    Item {
                        width: parent.width
                        height: histCol.implicitHeight

                        Column {
                            id: histCol
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            spacing: Theme.space

                            CheckRow {
                                width: parent.width
                                title: "Keep messages expanded"
                                detail: "The list opens fully expanded. New messages stay expanded."
                                tip: "Open the history list with every message expanded"
                                checked: Config.editorNotiExpand
                                onToggled: Config.editNotiExpand(!Config.editorNotiExpand)
                            }

                            CheckRow {
                                width: parent.width
                                title: "Stagger row colors"
                                detail: "Alternate a modest shade between notifications."
                                tip: "Alternate the row background. The selected row still uses the accent."
                                checked: Config.editorNotiStagger
                                onToggled: Config.editNotiStagger(!Config.editorNotiStagger)
                            }

                            CheckRow {
                                width: parent.width
                                title: "Clear history at boot"
                                detail: "Empties the list the next time the computer starts."
                                tip: "A reload in the same boot keeps the list"
                                checked: Config.editorNotiClearBoot
                                onToggled: Config.editNotiClearBoot(!Config.editorNotiClearBoot)
                            }

                            CheckRow {
                                width: parent.width
                                title: "Show counter"
                                detail: "The number on the bell. The list still shows how many are kept."
                                tip: "Show the count badge on the bell"
                                checked: Config.editorNotiShowCount
                                onToggled: Config.editNotiShowCount(!Config.editorNotiShowCount)
                            }
                        }
                    }
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: Config.notiEditorDirty
        undoEnabled: Config.canUndoNoti()
        applyTip: "Save the toast corner, the timeout, and the history options"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore bottom right, 8 seconds, staggered rows, and the counter. Apply saves it."
        onApplyClicked: Config.applyNotiEditor()
        onUndoClicked: Config.undoNotiEditor()
        onResetClicked: Config.resetNotiEditor()
    }
}
