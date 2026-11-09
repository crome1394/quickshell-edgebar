pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.library
import qs.services
import qs.theme

// The App Library, like Pop's: a search box over a grid of apps, with
// Library Home and your folders along the bottom. Type to search every
// app; Enter or a click opens one. Drag an app onto a folder to add it;
// right-click an app or a folder for more. shell.qml creates this only
// while LibraryService.open. Keys: library/LibraryKeys.qml.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: window

    screen: ScreenService.mainScreen
    color: Theme.freshRssScrim
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-library"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    LibraryModel {
        id: lib
    }

    LibraryKeys {
        id: keys
    }

    readonly property int columns: LibrarySettings.columns()
    readonly property int iconPx: LibrarySettings.iconPx()
    readonly property bool showNames: LibrarySettings.showNames()
    readonly property int tileWidth: window.iconPx + Theme.libraryTileExtra
    readonly property int tileHeight: window.iconPx + (window.showNames ? Theme.libraryTileExtra : Theme.space * 2)

    // The app being dragged, or null.
    property var dragApp: null
    property point lastPointer: Qt.point(-1, -1)

    function pointerMoved(at, index) {
        const first = window.lastPointer.x < 0
        if (at.x === window.lastPointer.x && at.y === window.lastPointer.y)
            return
        window.lastPointer = at
        if (!first)
            lib.moveTo(index)
    }

    function launch(app) {
        if (lib.launch(app))
            LibraryService.hide()
    }

    function focusSearch() {
        search.forceActiveFocus()
    }

    // Right-click menus.
    function appMenu(app, at) {
        if (!app)
            return
        const items = [{ label: "Open " + app.name, action: "open" }]
        const actions = app.entry.actions || []
        for (let i = 0; i < actions.length; i++)
            items.push({ label: String(actions[i].name || ""), action: "act:" + i })
        if (lib.folder >= 0 && !lib.searching)
            items.push({ label: "Remove from " + lib.folders[lib.folder].name, action: "remove:" + lib.folder })
        for (let i = 0; i < lib.folders.length; i++) {
            if (!lib.inFolder(app, i))
                items.push({ label: "Add to " + lib.folders[i].name, action: "add:" + i })
        }
        menu.target = app
        menu.openAt(card.mapFromGlobal(at.x, at.y), items)
    }

    function folderMenu(index, at) {
        const f = lib.folders[index]
        if (!f)
            return
        const items = [{ label: "Rename…", action: "rename:" + index }]
        if (index > 0)
            items.push({ label: "Move left", action: "left:" + index })
        if (index < lib.folders.length - 1)
            items.push({ label: "Move right", action: "right:" + index })
        items.push({ label: "Delete " + f.name + "…", action: "askDelete:" + index, danger: true })
        menu.target = null
        menu.openAt(card.mapFromGlobal(at.x, at.y), items)
    }

    function runMenu(action) {
        const cut = action.indexOf(":")
        const verb = cut >= 0 ? action.substring(0, cut) : action
        const n = cut >= 0 ? Number(action.substring(cut + 1)) : -1
        const app = menu.target
        switch (verb) {
        case "open":
            window.launch(app)
            break
        case "act": {
            const a = app && app.entry.actions ? app.entry.actions[n] : null
            if (a) {
                SearchService.launchAction(app.entry, a)
                LibraryService.hide()
            }
            break
        }
        case "add":
            lib.addTo(n, app)
            break
        case "remove":
            lib.removeFrom(n, app)
            break
        case "rename":
            window.renaming = n
            dialog.openWith("Rename folder", "Rename", lib.folders[n].name)
            break
        case "left":
            lib.moveFolder(n, n - 1)
            break
        case "right":
            lib.moveFolder(n, n + 1)
            break
        case "askDelete":
            // Asked again, so a stray click does not lose a folder.
            menu.openAt(menu.at, [
                { label: "Delete " + lib.folders[n].name + " (the apps stay installed)", action: "delete:" + n, danger: true },
                { label: "Keep it", action: "" }
            ])
            return
        case "delete":
            lib.deleteFolder(n)
            break
        }
        window.focusSearch()
    }

    // -1 for a new folder, else the folder being renamed.
    property int renaming: -1

    function newFolder() {
        window.renaming = -1
        dialog.openWith("New folder", "Create", LibraryLogic.freeName(lib.folders, "New Folder"))
    }

    function run(action) {
        switch (action) {
        case "left": lib.move(-1); break
        case "right": lib.move(1); break
        case "up": lib.move(-window.columns); break
        case "down": lib.move(window.columns); break
        case "pageUp": lib.move(-window.columns * Theme.libraryRowsShown); break
        case "pageDown": lib.move(window.columns * Theme.libraryRowsShown); break
        case "first": lib.moveTo(0); break
        case "last": lib.moveTo(lib.shown.length - 1); break
        case "open": window.launch(lib.current); break
        case "nextFolder": lib.cycleFolder(1); break
        case "prevFolder": lib.cycleFolder(-1); break
        case "newFolder": window.newFolder(); break
        case "menu": {
            const tile = grid.currentItem
            if (tile)
                window.appMenu(lib.current, tile.mapToGlobal(tile.width / 2, tile.height / 2))
            break
        }
        case "escape":
            if (menu.shown)
                menu.close()
            else if (search.text.length)
                search.text = ""
            else
                LibraryService.hide()
            break
        }
    }

    function handleKey(event) {
        const action = keys.actionFor(event)
        if (!action.length)
            return
        window.run(action)
        event.accepted = true
    }

    // Dragging an app: the icon follows the pointer over the card and
    // drops on a folder.
    function dragStart(app, at) {
        window.dragApp = app
        window.dragMove(at)
        ghost.Drag.active = true
    }

    function dragMove(at) {
        const p = card.mapFromGlobal(at.x, at.y)
        ghost.x = p.x - ghost.width / 2
        ghost.y = p.y - ghost.height / 2
    }

    function dragEnd() {
        ghost.Drag.drop()
        ghost.Drag.active = false
        window.dragApp = null
    }

    // A click outside the card closes.
    MouseArea {
        anchors.fill: parent
        onClicked: LibraryService.hide()
    }

    Rectangle {
        id: card
        readonly property int pad: Theme.space * 2
        anchors.centerIn: parent
        width: Math.min(window.width - Theme.space * 4, window.columns * window.tileWidth + card.pad * 2 + Theme.scrollBarWidth)
        height: Math.min(window.height - Theme.space * 4, column.implicitHeight + card.pad * 2)
        radius: Theme.radius
        color: Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: card.pad
            y: card.pad
            width: card.width - card.pad * 2
            spacing: Theme.space

            Item {
                width: parent.width
                height: Theme.searchFieldHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, search.x - Theme.space)
                    elide: Text.ElideRight
                    text: lib.title
                    textFormat: Text.PlainText
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx + 2
                    font.bold: true
                }

                TextField {
                    id: search
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width * 0.5, Theme.searchWidth)
                    height: parent.height
                    focus: true
                    verticalAlignment: Text.AlignVCenter
                    placeholderText: "Type to search apps"
                    leftPadding: Theme.space * 4
                    color: Theme.text
                    placeholderTextColor: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                    maximumLength: Theme.searchQueryMax
                    background: Rectangle {
                        radius: height / 2
                        color: Theme.fieldBg
                        border.width: Theme.borderWidth
                        border.color: search.activeFocus ? Theme.accent : Theme.border

                        Text {
                            x: Theme.space * 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            text: Theme.searchGlyph
                            color: Theme.subtext
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fontPx
                        }
                    }
                    onTextChanged: lib.query = text
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: (event) => window.handleKey(event)
                }
            }

            GridView {
                id: grid
                width: parent.width
                height: Theme.libraryRowsShown * window.tileHeight
                cellWidth: Math.floor((width - Theme.scrollBarWidth) / window.columns)
                cellHeight: window.tileHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                model: lib.shown
                currentIndex: lib.cursor
                onCurrentIndexChanged: grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: AppTile {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    app: modelData
                    iconUrl: lib.iconSource(modelData.icon)
                    current: index === lib.cursor
                    iconPx: window.iconPx
                    showName: window.showNames
                    onHovered: (at) => window.pointerMoved(at, index)
                    onClicked: window.launch(modelData)
                    onRightClicked: (at) => {
                        lib.moveTo(index)
                        window.appMenu(modelData, at)
                    }
                    onDragStarted: (at) => window.dragStart(modelData, at)
                    onDragMoved: (at) => window.dragMove(at)
                    onDragEnded: window.dragEnd()
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Theme.space * 4
                    visible: grid.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: lib.searching ? "No app matches." : (lib.folder >= 0 ? "This folder is empty.\nDrag an app onto it below, or right-click an app → Add to."
                        : "Every app is in a folder.")
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.borderWidth
                color: Theme.border
            }

            // Library Home, the folders, and New folder.
            Flickable {
                id: strip
                width: parent.width
                height: folderRow.implicitHeight
                contentWidth: folderRow.implicitWidth
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: folderRow
                    x: Math.max(0, (strip.width - folderRow.implicitWidth) / 2)
                    spacing: Theme.tabGap

                    FolderTab {
                        label: "Library Home"
                        glyph: Theme.libraryHomeGlyph
                        selected: lib.folder < 0 && !lib.searching
                        acceptsDrop: false
                        onClicked: {
                            lib.folder = -1
                            search.text = ""
                        }
                    }

                    Repeater {
                        model: lib.folders
                        delegate: FolderTab {
                            required property var modelData
                            required property int index
                            label: modelData.name
                            glyph: Theme.libraryFolderGlyph
                            selected: lib.folder === index && !lib.searching
                            onClicked: {
                                lib.folder = index
                                search.text = ""
                            }
                            onRightClicked: (at) => window.folderMenu(index, at)
                            onDropped: lib.addTo(index, window.dragApp)
                        }
                    }

                    FolderTab {
                        visible: lib.folders.length < Theme.libraryFoldersMax
                        label: "New folder"
                        glyph: Theme.libraryAddGlyph
                        selected: false
                        acceptsDrop: false
                        onClicked: window.newFolder()
                    }
                }
            }

            Flow {
                width: parent.width
                height: Theme.keyCapHeight
                clip: true
                spacing: Theme.space * 2

                Repeater {
                    model: keys.hints
                    delegate: Row {
                        id: hint
                        required property var modelData
                        spacing: Theme.tabGap

                        Repeater {
                            model: hint.modelData.caps
                            delegate: KeyCap {
                                required property string modelData
                                label: modelData
                            }
                        }

                        Text {
                            height: Theme.keyCapHeight
                            verticalAlignment: Text.AlignVCenter
                            text: hint.modelData.text
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }
                }
            }
        }

        // The icon under the pointer while an app is dragged.
        Item {
            id: ghost
            visible: window.dragApp !== null
            width: window.iconPx
            height: window.iconPx
            z: 5
            Drag.keys: ["library-app"]
            Drag.hotSpot.x: ghost.width / 2
            Drag.hotSpot.y: ghost.height / 2

            Image {
                anchors.fill: parent
                source: window.dragApp ? lib.iconSource(window.dragApp.icon) : ""
                sourceSize.width: window.iconPx
                sourceSize.height: window.iconPx
                fillMode: Image.PreserveAspectFit
                opacity: 0.85
            }
        }

        LibraryMenu {
            id: menu
            // The app a menu is for, or null for a folder menu.
            property var target: null
            onPicked: (action) => window.runMenu(action)
        }

        NameDialog {
            id: dialog
            check: (text) => {
                const name = LibraryLogic.nameNorm(text)
                if (!name.length)
                    return "Give the folder a name."
                if (lib.nameTaken(name, window.renaming))
                    return "There is already a folder called " + name + "."
                return ""
            }
            onAccepted: (name) => {
                if (window.renaming >= 0) {
                    lib.renameFolder(window.renaming, name)
                } else {
                    const index = lib.createFolder(name)
                    if (index >= 0)
                        lib.folder = index
                }
                window.focusSearch()
            }
            onCancelled: window.focusSearch()
        }
    }

    Component.onCompleted: search.forceActiveFocus()
}
