pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.defaultapps
import qs.services
import qs.theme

// Settings → Applications → Default Apps: which app opens each kind of
// file and link, saved in ~/.config/mimeapps.list (read by xdg-open,
// browsers, and file managers). Common tasks shows problems found in that
// file, each with a fix, then the everyday choices; All file types lists
// every type by family; By app lists each app and what it opens. Fixes
// and picks change the draft; Apply writes the file.
Item {
    id: root

    readonly property var ctx: DefaultAppsService.ctx
    readonly property bool ready: DefaultAppsService.ready
    readonly property var problems: DefaultAppsService.problems
    readonly property int keptCount: DefaultAppsSettings.kept().length
    // Cards whose fix is safe to apply without asking: missing apps and
    // wildcard lines. Odd defaults may be on purpose.
    readonly property var safeCards: root.problems.filter((c) => !c.canKeep)
    // "common" (the everyday choices and problems), "all" (every type), or
    // "apps" (each app and what it opens).
    property string view: "common"
    property string openGroup: ""
    property var expanded: ({})

    function edit(next) {
        DefaultAppsSettings.editor.edit(next)
    }

    function cleanUp() {
        let next = DefaultAppsSettings.editor.value
        for (const card of root.safeCards)
            next = DefaultAppsLogic.applyEdits(next, card.edits)
        root.edit(next)
    }

    function pick(group, id) {
        root.edit(DefaultAppsLogic.setGroup(DefaultAppsSettings.editor.value, group, id, root.ctx))
        root.openGroup = ""
    }

    function toggleExpanded(id) {
        const next = Object.assign({}, root.expanded)
        next[id] = !next[id]
        root.expanded = next
    }

    Component.onCompleted: DefaultAppsService.retain()
    Component.onDestruction: DefaultAppsService.release()

    Column {
        id: head
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "Default Apps"
            hint: "Which app opens each kind of file and link. Saved in ~/.config/mimeapps.list, which xdg-open, browsers, and file managers read."
        }

        Column {
            visible: !root.ready || DefaultAppsService.error.length > 0 || DefaultAppsService.overrideActive
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.tabGap

            Text {
                visible: !root.ready
                width: parent.width
                text: "Reading your default apps…"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Text {
                visible: DefaultAppsService.error.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: DefaultAppsService.error
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Text {
                visible: DefaultAppsService.overrideActive
                width: parent.width
                wrapMode: Text.WordWrap
                text: "A desktop-specific file (~/.config/" + (DefaultAppsService.desktops[0] || "desktop") + "-mimeapps.list) also sets defaults, and its choices win over this page."
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        Row {
            x: Theme.sectionInset
            spacing: Theme.tabGap

            ChipButton {
                label: "Common tasks"
                active: root.view === "common"
                tip: "The everyday choices, and problems found in your file"
                onClicked: root.view = "common"
            }

            ChipButton {
                label: "All file types"
                active: root.view === "all"
                tip: "Every type with its app, grouped by family, searchable, and Test a file"
                onClicked: root.view = "all"
            }

            ChipButton {
                label: "By app"
                active: root.view === "apps"
                tip: "Each app, what it opens by default, and what else it can open"
                onClicked: root.view = "apps"
            }
        }
    }

    Loader {
        id: allPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: footer.top
        anchors.topMargin: Theme.space
        anchors.bottomMargin: Theme.space
        anchors.leftMargin: Theme.sectionInset
        active: root.view === "all"
        sourceComponent: DefaultAppsAllTypes {
            ctx: root.ctx
            ready: root.ready
        }
    }

    Loader {
        id: appsPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: footer.top
        anchors.topMargin: Theme.space
        anchors.bottomMargin: Theme.space
        anchors.leftMargin: Theme.sectionInset
        active: root.view === "apps"
        sourceComponent: DefaultAppsByApp {
            ctx: root.ctx
            ready: root.ready
        }
    }

    Flickable {
        id: scroll
        visible: root.view === "common"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.topMargin: Theme.space
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: pageScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: pageScroll.pressed || pageScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: scroll.width - Theme.scrollBarWidth
            spacing: Theme.space

            SectionHeader {
                visible: root.problems.length > 0
                width: parent.width
                title: "Problems found (" + root.problems.length + ")"
                hint: "Fixes change the draft. Apply saves them."
            }

            Row {
                visible: root.safeCards.length > 1
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                ChipButton {
                    id: cleanChip
                    label: "Clean up " + root.safeCards.length + " problems"
                    bold: true
                    tip: "Remove apps that are not installed (the suggested app takes over where needed) and wildcard lines. Apply saves it."
                    onClicked: root.cleanUp()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - cleanChip.width - Theme.space
                    wrapMode: Text.WordWrap
                    text: "Missing apps and ignored lines. Odd choices below stay for you to decide."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Column {
                visible: root.problems.length > 0
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                Repeater {
                    model: root.problems
                    delegate: DefaultAppsProblem {
                        required property var modelData
                        width: parent.width
                        problem: modelData
                        onFixClicked: root.edit(DefaultAppsLogic.applyEdits(DefaultAppsSettings.editor.value, modelData.edits))
                        onKeepClicked: DefaultAppsSettings.keep(modelData.keys)
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Common tasks"
                hint: "Picking an app sets every type in the row that the app says it can open. Details shows each type and why it opens where it does."
            }

            Column {
                visible: root.ready
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Repeater {
                    model: DefaultAppsLogic.groups
                    delegate: DefaultAppsRow {
                        id: row
                        required property var modelData
                        width: parent.width
                        group: row.modelData
                        info: root.ready ? DefaultAppsLogic.groupState(row.modelData, root.ctx) : null
                        open: root.openGroup === row.modelData.id
                        expanded: !!root.expanded[row.modelData.id]
                        choices: row.open ? DefaultAppsLogic.candidates(row.modelData, root.ctx) : []
                        onOpenToggled: root.openGroup = row.open ? "" : row.modelData.id
                        onExpandToggled: root.toggleExpanded(row.modelData.id)
                        onPicked: (id) => root.pick(row.modelData, id)
                    }
                }
            }

            Row {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (keptChip.visible ? keptChip.width + Theme.space : 0)
                    wrapMode: Text.WordWrap
                    text: "Each Apply first copies the file to ~/.config/mimeapps.list.bak."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                ChipButton {
                    id: keptChip
                    visible: root.keptCount > 0
                    label: "Show " + root.keptCount + " kept " + (root.keptCount === 1 ? "problem" : "problems")
                    tip: "Warn again about the problems you chose to keep"
                    onClicked: DefaultAppsSettings.clearKept()
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: DefaultAppsSettings.editor.dirty && root.ready && !DefaultAppsService.saving
        undoEnabled: DefaultAppsSettings.editor.canUndo
        resetEnabled: root.ready
        applyTip: "Save to ~/.config/mimeapps.list"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Clear your choices for the common tasks so the system decides. Link handlers and other types you set stay. Apply saves it."
        onApplyClicked: DefaultAppsSettings.editor.apply()
        onUndoClicked: DefaultAppsSettings.editor.undo()
        onResetClicked: DefaultAppsSettings.editor.reset()
    }
}
