pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.theme

// One type on Default Apps → All file types: what it opens with and why,
// the app picker, and your Open with list for it (reorder or take out).
Column {
    id: root

    required property string type
    // DefaultAppsLogic.resolve(): { id, source }.
    required property var info
    // Your [Added Associations] list for this type.
    required property var openWith
    required property var choices
    required property bool open
    required property bool expanded

    signal openToggled()
    signal expandToggled()
    signal picked(string id)
    signal resetClicked()
    signal moveClicked(string id, int delta)

    function nameOf(id) {
        const name = DefaultAppsService.appName(id)
        return name.length ? name : String(id || "").replace(/\.desktop$/, "")
    }

    function sourceText(source) {
        if (source === "you")
            return "your choice"
        if (source === "system")
            return "system default"
        if (source === "added")
            return "first in an Open with list"
        if (source === "auto")
            return "first app that opens it"
        return "nothing opens it"
    }

    spacing: Theme.tabGap

    Row {
        width: parent.width
        spacing: Theme.space

        Column {
            width: Theme.defaultAppsLabelWidth * 2
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                elide: Text.ElideMiddle
                text: root.type
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx + 1
            }

            MimeComment {
                width: parent.width
                type: root.type
            }
        }

        Rectangle {
            width: parent.width - Theme.defaultAppsLabelWidth * 2 - withChip.width - Theme.space * 2
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: boxMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: root.open ? Theme.accent : Theme.border

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.tabGap
                anchors.rightMargin: Theme.chip
                spacing: Theme.space

                LaunchIcon {
                    visible: root.info.id.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.chip
                    name: root.nameOf(root.info.id)
                    iconName: DefaultAppsService.appIcon(root.info.id)
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (root.info.id.length ? Theme.chip + Theme.space : 0)

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.info.id.length ? root.nameOf(root.info.id) : "Nothing"
                        color: root.info.id.length ? Theme.text : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx + 1
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.sourceText(root.info.source)
                        color: root.info.source === "you" ? Theme.accent : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                text: root.open ? "▴" : "▾"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            MouseArea {
                id: boxMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openToggled()
            }
        }

        ChipButton {
            id: withChip
            label: "Open with" + (root.openWith.length ? " (" + root.openWith.length + ")" : "")
            active: root.expanded
            tip: "Your Open with list for this type: the apps offered after the default, in order"
            onClicked: root.expandToggled()
        }
    }

    Column {
        visible: root.open
        x: Theme.defaultAppsLabelWidth * 2 + Theme.space
        width: parent.width - x
        spacing: Theme.tabGap

        ChipButton {
            visible: root.info.source === "you"
            label: "Use the system default"
            tip: "Remove your line for this type, so the system decides"
            onClicked: root.resetClicked()
        }

        DefaultAppPicker {
            width: parent.width
            ids: root.choices
            currentId: root.info.id
            onPicked: (id) => root.picked(id)
        }
    }

    Column {
        visible: root.expanded
        x: Theme.defaultAppsLabelWidth * 2 + Theme.space
        width: parent.width - x
        spacing: Theme.borderWidth

        Text {
            visible: root.openWith.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Your Open with list for this type is empty. Apps add themselves when you pick them in a file manager's Open with."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Repeater {
            model: root.expanded ? root.openWith : []
            delegate: Row {
                id: entry
                required property var modelData
                required property int index
                width: parent.width
                spacing: Theme.tabGap

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (upChip.width + downChip.width + outChip.width + Theme.tabGap * 3)
                    elide: Text.ElideRight
                    text: (entry.index + 1) + ". " + root.nameOf(String(entry.modelData))
                    color: DefaultAppsService.installed(String(entry.modelData)) ? Theme.text : Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx + 1
                }

                ChipButton {
                    id: upChip
                    label: "▲"
                    enabled: entry.index > 0
                    tip: "Move up"
                    onClicked: root.moveClicked(String(entry.modelData), -1)
                }

                ChipButton {
                    id: downChip
                    label: "▼"
                    enabled: entry.index < root.openWith.length - 1
                    tip: "Move down"
                    onClicked: root.moveClicked(String(entry.modelData), 1)
                }

                ChipButton {
                    id: outChip
                    label: "✕"
                    tip: "Take out of the list"
                    onClicked: root.moveClicked(String(entry.modelData), 0)
                }
            }
        }
    }
}
