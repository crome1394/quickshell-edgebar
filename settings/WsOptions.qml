import QtQuick
import qs.config
import qs.theme

Item {
    id: root

    required property int draftCount
    signal countEdited(int value)

    implicitHeight: columns.implicitHeight

    Row {
        id: columns
        width: parent.width
        spacing: Theme.space

        Column {
            width: (parent.width - Theme.space) / 2
            spacing: Theme.space

            CheckRow {
                width: parent.width
                title: "Special workspace pill"
                tip: "Show the special workspace on the bar"
                checked: Config.showSpecial
                onToggled: WorkspaceSettings.setShowSpecial(!Config.showSpecial)
            }
            CheckRow {
                width: parent.width
                title: "Show only active workspace"
                detail: "Hide empty numbered pills"
                tip: "Hide an empty numbered pill until that workspace is focused or has a window"
                checked: Config.showOnlyActive
                onToggled: WorkspaceSettings.setShowOnlyActive(!Config.showOnlyActive)
            }
            CheckRow {
                width: parent.width
                title: "Show workspace numbers"
                detail: "Off leaves the symbol and label"
                tip: "Show the workspace number. Off leaves the symbol and label."
                checked: Config.showNumbers
                onToggled: WorkspaceSettings.setShowNumbers(!Config.showNumbers)
            }
            CheckRow {
                width: parent.width
                title: "Close special on startup"
                detail: "Only when startup workspace is above 0"
                tip: "Close the special workspace on startup when startup workspace is above 0"
                checked: Config.startupCloseSpecial
                onToggled: WorkspaceSettings.setStartupCloseSpecial(!Config.startupCloseSpecial)
            }
        }

        Column {
            width: (parent.width - Theme.space) / 2
            spacing: Theme.space

            Rectangle {
                width: parent.width
                height: countCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: Theme.pillBg
                border.width: Theme.borderWidth
                border.color: Theme.border
                Column {
                    id: countCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    HoverHandler {
                        id: countHover
                    }

                    HoverTip {
                        message: "How many numbered workspaces to keep"
                        show: countHover.hovered && !countSlider.hovered
                    }

                    Text {
                        text: "Default workspaces  " + root.draftCount
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }
                    IntSlider {
                        id: countSlider
                        width: parent.width
                        from: 1
                        to: 10
                        value: root.draftCount
                        tip: "How many numbered workspaces to keep"
                        onChanged: (value) => root.countEdited(value)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: startupCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: Theme.pillBg
                border.width: Theme.borderWidth
                border.color: Theme.border
                Column {
                    id: startupCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    HoverHandler {
                        id: startupHover
                    }

                    HoverTip {
                        message: "Workspace to open on startup. 0 leaves it unchanged."
                        show: startupHover.hovered && !startupSlider.hovered
                    }

                    Text {
                        text: "Startup workspace  " + (Config.startupWorkspace > 0 ? Config.startupWorkspace : "off")
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }
                    IntSlider {
                        id: startupSlider
                        width: parent.width
                        from: 0
                        to: 10
                        value: Config.startupWorkspace
                        tip: "Workspace to open on startup. 0 leaves it unchanged."
                        onChanged: (value) => WorkspaceSettings.setStartupWorkspace(value)
                    }
                }
            }
        }
    }
}
