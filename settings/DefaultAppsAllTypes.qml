pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.defaultapps
import qs.services
import qs.theme

// Default Apps → All file types: every type with its app, grouped by
// family (Links, Text and code, Images, …), searchable, and Test a file
// (which app would open it, and why). Families open on click; a search
// opens them all. Rows are made only while on screen. Changes go to the
// page's draft.
Item {
    id: root

    required property var ctx
    required property bool ready

    property string filter: ""
    property bool onlyYours: false
    property string openType: ""
    property string expandedType: ""
    property var openFamilies: ({})

    readonly property var types: {
        if (!root.ready)
            return []
        const base = root.onlyYours ? DefaultAppsLogic.yourTypes(root.ctx.state)
            : DefaultAppsLogic.allTypes(DefaultAppsService.knownTypes, root.ctx)
        const want = root.filter.trim().toLowerCase()
        if (!want.length)
            return base
        return base.filter((t) => {
            if (t.indexOf(want) >= 0)
                return true
            const id = DefaultAppsLogic.resolve(t, root.ctx).id
            return id.length > 0 && DefaultAppsService.appName(id).toLowerCase().indexOf(want) >= 0
        })
    }

    // A search or Only types you set lists every match without opening families.
    readonly property bool showAll: root.filter.trim().length > 0 || root.onlyYours
    readonly property var rows: DefaultAppsLogic.familyRows(root.types, root.openFamilies, root.showAll)

    function toggleFamily(id) {
        const next = Object.assign({}, root.openFamilies)
        next[id] = !next[id]
        root.openFamilies = next
    }

    function setAllFamilies(open) {
        const next = {}
        if (open) {
            for (const f of DefaultAppsLogic.families)
                next[f.id] = true
        }
        root.openFamilies = next
    }

    readonly property var test: DefaultAppsService.test
    readonly property var testInfo: root.test.type.length ? DefaultAppsLogic.resolve(root.test.type, root.ctx) : ({ id: "", source: "" })

    function edit(next) {
        DefaultAppsSettings.editor.edit(next)
    }

    function fileName(path) {
        const parts = String(path || "").split("/")
        return parts[parts.length - 1] || String(path || "")
    }

    function sourceText(source) {
        if (source === "you")
            return "your choice"
        if (source === "system")
            return "the system default"
        if (source === "added")
            return "first in an Open with list"
        if (source === "auto")
            return "the first app that opens it"
        return ""
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
                id: testBox
                width: parent.width - testChip.width - Theme.tabGap
                placeholderText: "Test a file: type its full path, such as ~/Videos/clip.mkv"
                clearable: true
                onAccepted: DefaultAppsService.testFile(testBox.text)
                onCleared: DefaultAppsService.clearTest()
            }

            ChipButton {
                id: testChip
                label: "Test"
                bold: true
                tip: "Which app would open this file, and why"
                onClicked: DefaultAppsService.testFile(testBox.text)
            }
        }

        Rectangle {
            visible: root.test.path.length > 0
            width: parent.width
            implicitHeight: testCol.implicitHeight + Theme.space * 2
            radius: Theme.radiusSm
            color: Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: root.test.error.length ? Theme.danger : Theme.border

            Column {
                id: testCol
                x: Theme.space
                y: Theme.space
                width: parent.width - Theme.space * 2
                spacing: Theme.borderWidth

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: {
                        if (root.test.error.length)
                            return root.test.error
                        if (!root.test.type.length)
                            return "Looking at " + root.fileName(root.test.path) + "…"
                        const name = root.fileName(root.test.path)
                        if (!root.testInfo.id.length)
                            return name + " is " + root.test.type + ". No installed app opens it."
                        return name + " is " + root.test.type + ". It opens with "
                            + DefaultAppsService.appName(root.testInfo.id) + ", " + root.sourceText(root.testInfo.source) + "."
                    }
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }

                Row {
                    visible: root.test.type.length > 0
                    width: parent.width
                    spacing: Theme.space

                    MimeComment {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - showChip.width - Theme.space
                        type: root.test.type
                    }

                    ChipButton {
                        id: showChip
                        label: "Show this type"
                        tip: "List only this type below, to change its app"
                        onClicked: {
                            root.onlyYours = false
                            filterBox.text = root.test.type
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.tabGap

            TextBox {
                id: filterBox
                width: parent.width - yoursChip.width - Theme.tabGap
                placeholderText: "Search types or apps, such as matroska or mpv"
                clearable: true
                onTextChanged: root.filter = filterBox.text
            }

            ChipButton {
                id: yoursChip
                label: "Only types you set"
                active: root.onlyYours
                tip: "List only the types your mimeapps.list names"
                onClicked: root.onlyYours = !root.onlyYours
            }
        }

        Row {
            width: parent.width
            spacing: Theme.tabGap

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - openAll.width - closeAll.width - Theme.tabGap * 2
                text: root.ready ? root.types.length + (root.types.length === 1 ? " type" : " types") : "Reading…"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            ChipButton {
                id: openAll
                visible: !root.showAll
                label: "Open all"
                tip: "Show every family's types"
                onClicked: root.setAllFamilies(true)
            }

            ChipButton {
                id: closeAll
                visible: !root.showAll
                label: "Close all"
                tip: "Show only the family headers"
                onClicked: root.setAllFamilies(false)
            }
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
        spacing: Theme.space
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows

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

        delegate: Loader {
            id: cell
            required property var modelData
            width: list.width - Theme.scrollBarWidth - Theme.tabGap
            sourceComponent: cell.modelData.header ? cell.headerPart : cell.typePart

            property Component headerPart: DefaultAppsFamilyHeader {
                width: cell.width
                row: cell.modelData
                onToggled: root.toggleFamily(String(cell.modelData.family))
            }

            property Component typePart: DefaultAppsTypeRow {
                id: row
                width: cell.width
                type: String(cell.modelData.type)
                info: DefaultAppsLogic.resolve(row.type, root.ctx)
                openWith: root.ctx.state.added[row.type] || []
                open: root.openType === row.type
                expanded: root.expandedType === row.type
                choices: row.open ? DefaultAppsLogic.typeCandidates(row.type, root.ctx) : []
                onOpenToggled: root.openType = row.open ? "" : row.type
                onExpandToggled: root.expandedType = row.expanded ? "" : row.type
                onPicked: (id) => {
                    root.edit(DefaultAppsLogic.setDefault(root.ctx.state, row.type, [id]))
                    root.openType = ""
                }
                onResetClicked: {
                    root.edit(DefaultAppsLogic.setDefault(root.ctx.state, row.type, null))
                    root.openType = ""
                }
                onMoveClicked: (id, delta) => root.edit(DefaultAppsLogic.moveAdded(root.ctx.state, row.type, id, delta))
            }
        }
    }
}
