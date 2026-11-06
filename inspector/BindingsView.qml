pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.settings
import qs.theme

// Inspector → Bindings: the keybinds from the Hyprland config in columns,
// grouped by their --#Category# comments. A group title collapses it.
// Click a binding to run it (the Inspector closes first); right-click
// copies its keys.
Item {
    id: root

    required property string query

    signal copied(string text)

    readonly property bool searching: root.query.trim().length > 0
    readonly property var groups: BindingsService.groups(root.query)
    readonly property int shown: root.groups.reduce((n, g) => n + g.binds.length, 0)
    readonly property int columns: Math.max(1, Math.min(Theme.inspectorColumnsMax, Math.floor(scroll.width / Theme.inspectorColumnMin)))
    readonly property var groupNames: root.groups.map((g) => g.category)

    function chipColor(part) {
        const p = String(part).toUpperCase()
        if (p === "SUPER" || p === "MOD4" || p === "WIN")
            return Theme.keySuper
        if (p === "ALT" || p === "MOD1")
            return Theme.keyAlt
        if (p === "SHIFT")
            return Theme.keyShift
        if (p === "CTRL" || p === "CONTROL")
            return Theme.keyCtrl
        if (/CLICK$|BUTTON$|^WHEEL |^MOUSE/.test(p))
            return Theme.keyMouse
        return Theme.keyOther
    }

    function chipText(part) {
        return root.chipColor(part) === Theme.keyOther ? Theme.keyOtherText : Theme.keyText
    }

    Component.onCompleted: BindingsService.retain()
    Component.onDestruction: BindingsService.release()

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
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: bar.pressed || bar.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: scroll.width - Theme.space - Theme.tabGap
            spacing: Theme.tabGap

            Text {
                visible: BindingsService.loaded && (root.shown === 0 || !BindingsService.file.length)
                width: parent.width
                wrapMode: Text.WordWrap
                text: BindingsService.binds.length
                    ? "Nothing matches the search."
                    : "No described keybinds found. Add a --# description after hl.bind(...) in your Hyprland config."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            Repeater {
                model: root.groups
                delegate: Column {
                    id: group
                    required property var modelData
                    readonly property string name: String(group.modelData.category)
                    // A search shows every match, collapsed or not.
                    readonly property bool open: root.searching || !BindingsService.isCollapsed(group.name)
                    width: body.width
                    spacing: Theme.borderWidth

                    // Group title: click to collapse or expand.
                    Rectangle {
                        visible: group.name.length > 0
                        width: parent.width
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: headMouse.containsMouse ? Theme.hover : Theme.sectionBg

                        Rectangle {
                            id: sliver
                            x: Theme.tabGap
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.dividerThickness + Theme.borderWidth
                            height: parent.height - Theme.tabGap * 2
                            radius: Theme.borderWidth
                            color: Theme.accent
                        }

                        Text {
                            id: chevron
                            anchors.left: sliver.right
                            anchors.leftMargin: Theme.space
                            anchors.verticalCenter: parent.verticalCenter
                            text: group.open ? "▾" : "▸"
                            color: Theme.accent
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        Text {
                            anchors.left: chevron.right
                            anchors.leftMargin: Theme.tabGap
                            anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.PlainText
                            text: group.name
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                            font.bold: true
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.space
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(height, countText.implicitWidth + Theme.space)
                            height: Theme.inspectorKeyHeight
                            radius: height / 2
                            color: Theme.accentDim
                            border.width: Theme.borderWidth
                            border.color: Theme.accent

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: String(group.modelData.binds.length)
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: headMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: root.searching ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!root.searching)
                                    BindingsService.toggleGroup(group.name)
                            }
                        }
                    }

                    Grid {
                        id: grid
                        visible: group.open
                        width: parent.width
                        columns: root.columns
                        columnSpacing: Theme.space
                        rowSpacing: Theme.borderWidth
                        topPadding: Theme.borderWidth

                        Repeater {
                            model: group.open ? group.modelData.binds : []
                            delegate: Rectangle {
                                id: cell
                                required property var modelData
                                width: (grid.width - grid.columnSpacing * (grid.columns - 1)) / grid.columns
                                height: Theme.inspectorRowHeight
                                radius: Theme.radiusSm
                                color: cellMouse.containsMouse ? Theme.hover : "transparent"

                                Row {
                                    id: chips
                                    x: Theme.tabGap
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.borderWidth * 3

                                    Repeater {
                                        model: cell.modelData.keys
                                        delegate: Rectangle {
                                            id: chip
                                            required property string modelData
                                            width: chipLabel.implicitWidth + Theme.space
                                            height: Theme.inspectorKeyHeight
                                            radius: Theme.radiusSm
                                            color: root.chipColor(chip.modelData)

                                            Text {
                                                id: chipLabel
                                                anchors.centerIn: parent
                                                textFormat: Text.PlainText
                                                text: chip.modelData
                                                color: root.chipText(chip.modelData)
                                                font.family: Theme.uiFont
                                                font.pixelSize: Theme.smallPx
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.left: chips.right
                                    anchors.leftMargin: Theme.space
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.tabGap
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    text: String(cell.modelData.action)
                                    color: cell.modelData.runnable ? Theme.text : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: cell.modelData.runnable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton)
                                            root.copied(String(cell.modelData.key))
                                        else
                                            BindingsService.run(cell.modelData)
                                    }

                                    HoverTip {
                                        message: (cell.modelData.runnable
                                            ? "Click to run  ·  " + cell.modelData.dispatch
                                            : "Hold " + cell.modelData.key + " and drag to use this")
                                            + "\nRight-click copies the keys  ·  line " + cell.modelData.line
                                        show: cellMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Always visible, like the footer of a settings page.
    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.fieldHeight

        Text {
            anchors.left: parent.left
            anchors.right: buttons.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideMiddle
            textFormat: Text.PlainText
            text: {
                if (!BindingsService.loaded)
                    return "Reading keybinds…"
                if (!BindingsService.file.length)
                    return ""
                const total = BindingsService.binds.length
                const count = root.searching ? root.shown + " of " + total : String(total)
                return count + " bindings  ·  " + BindingsService.file.replace(BindingsService.home, "~")
            }
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Theme.sectionInset
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.tabGap

            FooterButton {
                label: "Expand all"
                enabled: !root.searching && root.groupNames.some((n) => BindingsService.isCollapsed(n))
                tip: "Open every group"
                onClicked: BindingsService.setAll(root.groupNames, false)
            }

            FooterButton {
                label: "Collapse all"
                enabled: !root.searching && root.groupNames.some((n) => !BindingsService.isCollapsed(n))
                tip: "Close every group to its title"
                onClicked: BindingsService.setAll(root.groupNames, true)
            }
        }
    }
}
