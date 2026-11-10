pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.theme

// The app list under a Default Apps row. Shows the apps that say they
// open the row's types; "Show all apps" lists every app in the menu, with
// a filter. Scrolls after Theme.defaultAppsPickerRows rows.
Rectangle {
    id: root

    // Desktop ids ("mpv.desktop"), best first.
    required property var ids
    required property string currentId

    signal picked(string id)

    property bool showAll: false
    property string filter: ""

    readonly property var shown: {
        const base = root.showAll ? DefaultAppsService.allApps() : (root.ids || [])
        const want = root.filter.trim().toLowerCase()
        if (!want.length)
            return base
        return base.filter((id) => DefaultAppsService.appName(id).toLowerCase().indexOf(want) >= 0
            || id.toLowerCase().indexOf(want) >= 0)
    }

    implicitHeight: col.implicitHeight + Theme.tabGap * 2
    radius: Theme.radiusSm
    color: Theme.pageBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    Column {
        id: col
        x: Theme.tabGap
        y: Theme.tabGap
        width: parent.width - Theme.tabGap * 2
        spacing: Theme.tabGap

        Row {
            width: parent.width
            spacing: Theme.tabGap

            TextBox {
                id: filterBox
                width: parent.width - allChip.width - Theme.tabGap
                placeholderText: root.showAll ? "Filter every app" : "Filter"
                clearable: true
                onTextChanged: root.filter = filterBox.text
            }

            ChipButton {
                id: allChip
                label: root.showAll ? "Matching apps" : "Show all apps"
                tip: root.showAll ? "Only apps that say they open these files" : "Every app in the menu, for an app that does not list this type"
                onClicked: root.showAll = !root.showAll
            }
        }

        Text {
            visible: root.shown.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.showAll || root.filter.length ? "No app matches." : "No installed app says it opens these files. Try Show all apps."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ListView {
            id: list
            visible: root.shown.length > 0
            width: parent.width
            height: Math.min(root.shown.length, Theme.defaultAppsPickerRows) * Theme.fieldHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.shown

            ScrollBar.vertical: ScrollBar {
                id: pickScroll
                policy: ScrollBar.AsNeeded
                width: Theme.scrollBarWidth
                padding: 0
                background: Item {}
                contentItem: Rectangle {
                    implicitWidth: Theme.scrollBarWidth
                    radius: width / 2
                    color: pickScroll.pressed || pickScroll.hovered ? Theme.accent : Theme.subtext
                }
            }

            delegate: Rectangle {
                id: option
                required property var modelData
                readonly property string appId: String(option.modelData)
                readonly property string appName: DefaultAppsService.appName(option.appId)
                readonly property bool chosen: option.appId === root.currentId

                width: list.width - Theme.scrollBarWidth
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: option.chosen ? Theme.accentDim : (optionMouse.containsMouse ? Theme.hover : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.tabGap
                    anchors.rightMargin: Theme.tabGap
                    spacing: Theme.space

                    LaunchIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        height: Theme.chip
                        name: option.appName
                        iconName: DefaultAppsService.appIcon(option.appId)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Theme.chip - Theme.space
                        elide: Text.ElideRight
                        text: option.appName.length ? option.appName : option.appId
                        color: option.chosen ? Theme.wsActiveText : Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: option.chosen
                    }
                }

                MouseArea {
                    id: optionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(option.appId)

                    HoverTip {
                        message: option.appId
                        show: optionMouse.containsMouse
                    }
                }
            }
        }
    }
}
