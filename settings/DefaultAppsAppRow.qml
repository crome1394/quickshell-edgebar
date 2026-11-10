pragma ComponentBehavior: Bound
import QtQuick
import qs.defaultapps
import qs.services
import qs.theme

// One app on Default Apps → By app: what it opens by default and what else
// it says it can open, each grouped by family. Make it the default for one
// type or for all of them; give a type back to the system.
Column {
    id: root

    required property string appId
    required property var defaults
    required property var others
    required property var ctx
    required property bool expanded

    signal expandToggled()
    signal makeDefault(var types)
    signal clearDefault(string type)

    property bool confirmAll: false

    readonly property string appName: {
        const name = DefaultAppsService.appName(root.appId)
        return name.length ? name : root.appId.replace(/\.desktop$/, "")
    }

    onExpandedChanged: root.confirmAll = false

    spacing: Theme.tabGap

    Rectangle {
        width: parent.width
        height: Theme.fieldHeight + Theme.tabGap
        radius: Theme.radiusSm
        color: headMouse.containsMouse ? Theme.hover : (root.expanded ? Theme.sectionBg : "transparent")

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.tabGap
            anchors.rightMargin: Theme.tabGap
            spacing: Theme.space

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.smallPx
                text: root.expanded ? "▾" : "▸"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            LaunchIcon {
                anchors.verticalCenter: parent.verticalCenter
                height: Theme.chip
                name: root.appName
                iconName: DefaultAppsService.appIcon(root.appId)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Theme.smallPx - Theme.chip - countText.width - Theme.space * 3
                elide: Text.ElideRight
                text: root.appName
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: root.defaults.length > 0
            }

            Text {
                id: countText
                anchors.verticalCenter: parent.verticalCenter
                text: (root.defaults.length ? "Default for " + root.defaults.length : "Default for none")
                    + (root.others.length ? " · can also open " + root.others.length : "")
                color: root.defaults.length ? Theme.accent : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandToggled()

            HoverTip {
                message: root.appId
                show: headMouse.containsMouse
            }
        }
    }

    Column {
        visible: root.expanded
        x: Theme.chip + Theme.space * 2
        width: parent.width - x
        spacing: Theme.tabGap

        Row {
            visible: root.others.length > 0
            spacing: Theme.space

            ChipButton {
                id: allChip
                label: root.confirmAll ? "Click again to confirm" : "Make default for all " + root.others.length
                active: root.confirmAll
                tip: "Make " + root.appName + " the default for every type below that it can also open. Apply saves it."
                onClicked: {
                    if (root.confirmAll) {
                        root.confirmAll = false
                        root.makeDefault(root.others)
                    } else {
                        root.confirmAll = true
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Opens by default (" + root.defaults.length + ")"
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx + 1
            font.bold: true
        }

        Text {
            visible: root.defaults.length === 0
            width: parent.width
            text: "Nothing yet."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Repeater {
            model: root.expanded ? DefaultAppsLogic.familyRows(root.defaults, {}, true) : []
            delegate: DefaultAppsAppType {
                required property var modelData
                width: parent.width
                row: modelData
                info: modelData.header ? ({ id: "", source: "" }) : DefaultAppsLogic.resolve(String(modelData.type), root.ctx)
                isDefault: true
                onClearClicked: root.clearDefault(String(modelData.type))
            }
        }

        Text {
            visible: root.others.length > 0
            width: parent.width
            text: "Can also open (" + root.others.length + ")"
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx + 1
            font.bold: true
        }

        Repeater {
            model: root.expanded ? DefaultAppsLogic.familyRows(root.others, {}, true) : []
            delegate: DefaultAppsAppType {
                required property var modelData
                width: parent.width
                row: modelData
                info: modelData.header ? ({ id: "", source: "" }) : DefaultAppsLogic.resolve(String(modelData.type), root.ctx)
                isDefault: false
                onMakeClicked: root.makeDefault([String(modelData.type)])
            }
        }
    }
}
