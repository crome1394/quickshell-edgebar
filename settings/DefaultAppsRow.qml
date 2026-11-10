pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.theme

// One common task on the Default Apps page: what it opens with now, a box
// that opens the app picker, and Details (each type, its app, and why).
Column {
    id: root

    // A DefaultAppsLogic group: { id, label, glyph, key, types }.
    required property var group
    // DefaultAppsLogic.groupState(): { id, mixed, apps, rows }.
    required property var info
    // Picker choices, best first.
    required property var choices
    required property bool open
    required property bool expanded

    signal openToggled()
    signal expandToggled()
    signal picked(string id)

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
            return "from your Open with list"
        if (source === "auto")
            return "first app that opens it"
        return "nothing opens it"
    }

    readonly property var apps: root.info ? root.info.apps : []
    readonly property string summary: {
        if (!root.apps.length)
            return "No installed app opens these."
        if (!root.info.mixed) {
            const n = root.apps[0].count
            return n === 1 ? "" : "Opens all " + n + " types here."
        }
        return root.apps.map((a) => root.nameOf(a.id) + " " + a.count).join(" · ")
    }

    spacing: Theme.tabGap

    Row {
        width: parent.width
        spacing: Theme.space

        Row {
            width: Theme.defaultAppsLabelWidth
            height: Theme.fieldHeight
            spacing: Theme.space

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.chip
                horizontalAlignment: Text.AlignHCenter
                text: String(root.group.glyph || "")
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconPx
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Theme.chip - Theme.space
                elide: Text.ElideRight
                text: String(root.group.label)
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }
        }

        Rectangle {
            id: box
            width: parent.width - Theme.defaultAppsLabelWidth - detailsChip.width - Theme.space * 2
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: boxMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: root.open ? Theme.accent : (root.info && root.info.mixed ? Theme.subtext : Theme.border)

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.tabGap
                anchors.rightMargin: Theme.chip
                spacing: Theme.space

                LaunchIcon {
                    visible: root.info && root.info.id.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.chip
                    name: root.info ? root.nameOf(root.info.id) : ""
                    iconName: root.info ? DefaultAppsService.appIcon(root.info.id) : ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (root.info && root.info.id.length ? Theme.chip + Theme.space : 0)
                    elide: Text.ElideRight
                    text: {
                        if (!root.info || !root.apps.length)
                            return "Not set"
                        if (root.info.mixed)
                            return "Mixed (" + root.apps.length + " apps)"
                        return root.nameOf(root.info.id)
                    }
                    color: root.info && root.info.mixed ? Theme.subtext : Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                    font.italic: !!(root.info && root.info.mixed)
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

                HoverTip {
                    message: "Choose the app for " + String(root.group.label).toLowerCase()
                    show: boxMouse.containsMouse && !root.open
                }
            }
        }

        ChipButton {
            id: detailsChip
            label: root.expanded ? "Hide" : "Details"
            active: root.expanded
            tip: "Each type in this row, the app it opens with, and why"
            onClicked: root.expandToggled()
        }
    }

    Text {
        visible: text.length > 0
        x: Theme.defaultAppsLabelWidth + Theme.space
        width: parent.width - x
        wrapMode: Text.WordWrap
        text: root.summary
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    DefaultAppPicker {
        visible: root.open
        x: Theme.defaultAppsLabelWidth + Theme.space
        width: parent.width - x
        ids: root.choices
        currentId: root.info && !root.info.mixed ? root.info.id : ""
        onPicked: (id) => root.picked(id)
    }

    Column {
        visible: root.expanded
        x: Theme.defaultAppsLabelWidth + Theme.space
        width: parent.width - x
        spacing: Theme.borderWidth

        Repeater {
            model: root.expanded && root.info ? root.info.rows : []
            delegate: Row {
                id: typeRow
                required property var modelData
                width: parent.width
                spacing: Theme.space

                Column {
                    width: Math.round(typeRow.width * 0.5)

                    Text {
                        width: parent.width
                        elide: Text.ElideMiddle
                        text: String(typeRow.modelData.type)
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    MimeComment {
                        width: parent.width
                        type: String(typeRow.modelData.type)
                    }
                }

                Column {
                    width: typeRow.width - Math.round(typeRow.width * 0.5) - Theme.space

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: typeRow.modelData.id.length ? root.nameOf(typeRow.modelData.id) : "—"
                        color: typeRow.modelData.id.length ? Theme.text : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.sourceText(String(typeRow.modelData.source))
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }
        }
    }
}
