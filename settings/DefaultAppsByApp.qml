pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.defaultapps
import qs.services
import qs.theme

// Default Apps → By app: every installed app that opens something, with
// what it opens by default and what else it can open. Searchable by app
// name. Rows are made only while on screen. Changes go to the page's draft.
Item {
    id: root

    required property var ctx
    required property bool ready

    property string filter: ""
    property bool onlyDefaults: false
    property string expandedApp: ""

    readonly property var summary: root.ready
        ? DefaultAppsLogic.appsSummary(DefaultAppsLogic.allTypes(DefaultAppsService.knownTypes, root.ctx), root.ctx) : []

    readonly property var apps: {
        const want = root.filter.trim().toLowerCase()
        return root.summary.filter((a) => {
            if (root.onlyDefaults && !a.defaults.length)
                return false
            if (!want.length)
                return true
            return DefaultAppsService.appName(a.id).toLowerCase().indexOf(want) >= 0 || a.id.toLowerCase().indexOf(want) >= 0
        })
    }

    function edit(next) {
        DefaultAppsSettings.editor.edit(next)
    }

    function makeDefault(id, types) {
        let next = root.ctx.state
        // A list that came through a signal is array-like.
        for (const t of Array.prototype.slice.call(types))
            next = DefaultAppsLogic.setDefault(next, t, [id])
        root.edit(next)
    }

    Column {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.tabGap

        Row {
            width: parent.width
            spacing: Theme.tabGap

            TextBox {
                id: filterBox
                width: parent.width - defaultsChip.width - Theme.tabGap
                placeholderText: "Search apps, such as mpv or Brave"
                clearable: true
                onTextChanged: root.filter = filterBox.text
            }

            ChipButton {
                id: defaultsChip
                label: "Only default apps"
                active: root.onlyDefaults
                tip: "List only apps that open at least one type by default"
                onClicked: root.onlyDefaults = !root.onlyDefaults
            }
        }

        Text {
            width: parent.width
            text: root.ready ? root.apps.length + (root.apps.length === 1 ? " app" : " apps") : "Reading…"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        clip: true
        spacing: Theme.borderWidth
        boundsBehavior: Flickable.StopAtBounds
        model: root.apps

        ScrollBar.vertical: ScrollBar {
            id: listScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: listScroll.pressed || listScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        delegate: DefaultAppsAppRow {
            id: row
            required property var modelData
            width: list.width - Theme.scrollBarWidth - Theme.tabGap
            appId: String(row.modelData.id)
            defaults: row.modelData.defaults
            others: row.modelData.others
            ctx: root.ctx
            expanded: root.expandedApp === row.appId
            onExpandToggled: root.expandedApp = row.expanded ? "" : row.appId
            onMakeDefault: (types) => root.makeDefault(row.appId, types)
            onClearDefault: (type) => root.edit(DefaultAppsLogic.setDefault(root.ctx.state, type, null))
        }
    }
}
