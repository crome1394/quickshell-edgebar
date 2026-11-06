pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    property string query: ""
    property string formError: ""
    property int appTick: 0
    property int listLimit: Theme.launcherListMax
    property bool dragging: false
    property string dragKey: ""
    property real sceneX: 0
    property real sceneY: 0

    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property int cols: LauncherSettings.draftSlots() <= 1 ? 1 : 2
    readonly property int cellWidth: {
        const inner = Math.max(1, (scroll.width - root.scrollGutter) - Theme.sectionInset * 2)
        if (root.cols <= 1)
            return inner
        return Math.max(1, (inner - Theme.space) / root.cols)
    }
    readonly property var appPack: root.collectApps()
    readonly property string dragLabel: root.labelForDrag()

    function appValues() {
        // qmllint disable missing-property
        const values = DesktopEntries.applications ? DesktopEntries.applications.values : []
        // qmllint enable missing-property
        return values || []
    }

    function collectApps() {
        void root.appTick
        const query = root.query.trim().toLowerCase()
        const values = root.appValues()
        const matched = []
        for (let i = 0; i < values.length; i++) {
            const app = values[i]
            if (!app || app.noDisplay)
                continue
            const id = String(app.id || "")
            if (!Config.desktopIdOk(id))
                continue
            const name = String(app.name || "")
            const generic = String(app.genericName || "")
            if (!name.length)
                continue
            if (query.length) {
                const blob = (name + " " + id + " " + generic).toLowerCase()
                if (blob.indexOf(query) < 0)
                    continue
            }
            matched.push({ id: id, name: name, icon: String(app.icon || "") })
        }
        matched.sort(function(a, b) {
            const left = String(a.name || "").toLowerCase()
            const right = String(b.name || "").toLowerCase()
            if (left < right)
                return -1
            if (left > right)
                return 1
            return 0
        })
        const hidden = Math.max(0, matched.length - root.listLimit)
        const rows = hidden > 0 ? matched.slice(0, root.listLimit) : matched
        return { rows: rows, hidden: hidden }
    }

    function labelForDrag() {
        if (!root.dragKey.length)
            return ""
        const parts = root.dragKey.split(":")
        const launcher = Math.round(Number(parts[0]))
        const index = Math.round(Number(parts[1]))
        const boards = LauncherSettings.draftBoards()
        const row = boards[launcher - 1]
        if (!row || !row[index])
            return "Pin"
        return String(row[index].name || "Pin")
    }

    function noteDrag(pinKey, x, y) {
        root.dragKey = pinKey
        root.sceneX = x
        root.sceneY = y
        root.dragging = true
    }

    function noteDrop(commit) {
        const key = root.dragKey
        let launcher = 0
        let index = -1
        for (let i = 0; i < columns.count; i++) {
            const col = columns.itemAt(i) as LaunchColumn
            if (col && col.dropIndex >= 0) {
                launcher = col.launcher
                index = col.dropIndex
                break
            }
        }
        root.dragging = false
        root.dragKey = ""
        if (!commit || !key.length || launcher < 1)
            return
        const parts = key.split(":")
        const fromLauncher = Math.round(Number(parts[0]))
        const fromIndex = Math.round(Number(parts[1]))
        Qt.callLater(() => root.movePin(fromLauncher, fromIndex, launcher, index))
    }

    function movePin(fromLauncher, fromIndex, toLauncher, toIndex) {
        if (fromLauncher < 1 || toLauncher < 1 || toLauncher > Theme.launcherMax)
            return
        const boards = LauncherSettings.draftBoards()
        const src = boards[fromLauncher - 1]
        const dest = boards[toLauncher - 1]
        if (!src || !dest || fromIndex < 0 || fromIndex >= src.length)
            return
        if (fromLauncher === toLauncher && (toIndex === fromIndex || toIndex === fromIndex + 1))
            return
        const pin = src[fromIndex]
        if (fromLauncher !== toLauncher) {
            const key = LauncherSettings.pinKey(pin)
            for (let i = 0; i < dest.length; i++) {
                if (LauncherSettings.pinKey(dest[i]) === key) {
                    root.formError = "That pin is already on this launcher."
                    return
                }
            }
            if (dest.length >= Theme.launcherPinMax) {
                root.formError = "That launcher is full."
                return
            }
        }
        let at = toIndex
        if (fromLauncher === toLauncher && fromIndex < at)
            at -= 1
        src.splice(fromIndex, 1)
        if (at < 0)
            at = 0
        if (at > dest.length)
            at = dest.length
        dest.splice(at, 0, pin)
        root.formError = ""
        LauncherSettings.setBoards(boards)
    }

    function removePin(launcher, index) {
        const boards = LauncherSettings.draftBoards()
        const row = boards[launcher - 1]
        if (!row || index < 0 || index >= row.length)
            return
        row.splice(index, 1)
        root.formError = ""
        LauncherSettings.setBoards(boards)
    }

    function pinDesktop(app) {
        const id = String(app.id || "")
        const name = String(app.name || id).replace(/[\r\n]/g, " ").trim()
        const pin = LauncherSettings.cleanPin({ id: id, name: name, icon: String(app.icon || ""), command: [] })
        if (!pin) {
            root.formError = "This app cannot be pinned."
            return
        }
        const boards = LauncherSettings.draftBoards()
        const dest = boards[0]
        const key = LauncherSettings.pinKey(pin)
        for (let i = 0; i < dest.length; i++) {
            if (LauncherSettings.pinKey(dest[i]) === key) {
                root.formError = "That app is already on Launcher 1."
                return
            }
        }
        if (dest.length >= Theme.launcherPinMax) {
            root.formError = "Launcher 1 is full."
            return
        }
        dest.push(pin)
        root.formError = ""
        LauncherSettings.setBoards(boards)
    }

    function addCustom() {
        const name = nameField.text.trim()
        const raw = commandField.text.trim()
        const icon = iconField.text.trim()
        const parts = raw.length ? raw.split(/\s+/) : []
        const pin = LauncherSettings.cleanPin({ id: "", name: name, icon: icon, command: parts })
        if (!pin) {
            root.formError = "Need a name and a command, with no shell characters."
            return
        }
        const boards = LauncherSettings.draftBoards()
        const dest = boards[0]
        const key = LauncherSettings.pinKey(pin)
        for (let i = 0; i < dest.length; i++) {
            if (LauncherSettings.pinKey(dest[i]) === key) {
                root.formError = "That command is already on Launcher 1."
                return
            }
        }
        if (dest.length >= Theme.launcherPinMax) {
            root.formError = "Launcher 1 is full."
            return
        }
        dest.push(pin)
        LauncherSettings.setBoards(boards)
        nameField.text = ""
        commandField.text = ""
        iconField.text = ""
        root.formError = ""
    }

    function applyPage() {
        if (!LauncherSettings.editor.apply())
            return
        WidgetService.syncLaunchers()
    }

    function undoPage() {
        if (!LauncherSettings.editor.undo())
            return
        WidgetService.syncLaunchers()
    }


    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.appTick++
        }
    }

    Timer {
        interval: Theme.tooltipDelay
        running: true
        repeat: false
        onTriggered: root.appTick++
    }

    component LineField: TextField {
        id: field
        property string tip: ""
        height: Theme.fieldHeight
        verticalAlignment: Text.AlignVCenter
        selectByMouse: true
        leftPadding: Theme.space
        color: Theme.text
        placeholderTextColor: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        background: Rectangle {
            radius: Theme.radiusSm
            color: field.activeFocus ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: field.activeFocus ? Theme.accent : Theme.border
        }

        HoverHandler { id: fieldHover }
        HoverTip {
            message: field.tip
            show: fieldHover.hovered && field.tip.length > 0
        }
    }

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
            width: Math.max(0, scroll.width - root.scrollGutter)
            spacing: Theme.space

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Pins land on Launcher 1. Drag a row by || to move it onto another launcher. On a left or right bar, each icon turns 90° counter-clockwise so it stays upright."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            SectionHeader {
                width: parent.width
                title: "Launchers"
                hint: "Apply saves the count and the pins. Each launcher is its own bar widget. It stays off the bar until you enable it under Widgets and press Apply."
            }

            Item {
                width: parent.width
                implicitHeight: countCol.implicitHeight
                height: countCol.implicitHeight

                Column {
                    id: countCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    Text {
                        width: parent.width
                        text: "How many launchers"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    IntSlider {
                        width: parent.width
                        from: Theme.launcherMin
                        to: Theme.launcherMax
                        step: 1
                        value: LauncherSettings.draftSlots()
                        readout: String(LauncherSettings.draftSlots())
                        tip: "How many app launchers to keep. Four is the maximum."
                        onChanged: (value) => LauncherSettings.setCount(value)
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: boardGrid.implicitHeight
                height: boardGrid.implicitHeight

                Grid {
                    id: boardGrid
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    columns: root.cols
                    columnSpacing: Theme.space
                    rowSpacing: Theme.space

                    Repeater {
                        id: columns
                        model: LauncherSettings.draftSlots()
                        delegate: LaunchColumn {
                            id: column
                            required property int index
                            width: root.cellWidth
                            launcher: column.index + 1
                            dragging: root.dragging
                            dragKey: root.dragKey
                            sceneX: root.sceneX
                            sceneY: root.sceneY
                            onRowDragged: (pinKey, x, y) => root.noteDrag(pinKey, x, y)
                            onRowDropped: (commit) => root.noteDrop(commit)
                            onPinRemoved: (at) => root.removePin(column.launcher, at)
                        }
                    }
                }
            }

            Item {
                visible: root.formError.length > 0
                width: parent.width
                implicitHeight: errorText.implicitHeight
                height: errorText.implicitHeight

                Text {
                    id: errorText
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    wrapMode: Text.WordWrap
                    text: root.formError
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            SectionHeader {
                width: parent.width
                title: "Installed apps"
                hint: "Pin adds the app to Launcher 1. Search matches the name, the id, or the generic name."
            }

            Item {
                width: parent.width
                implicitHeight: appCol.implicitHeight
                height: appCol.implicitHeight

                Column {
                    id: appCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    LineField {
                        id: searchField
                        width: parent.width
                        placeholderText: "Search installed apps"
                        tip: "Filter by name, id, or generic name"
                        onTextChanged: {
                            root.query = searchField.text
                            root.listLimit = Theme.launcherListMax
                        }
                    }

                    Repeater {
                        model: root.appPack.rows
                        delegate: LaunchAppRow {
                            id: app
                            required property var modelData
                            required property int index
                            width: appCol.width
                            name: String(app.modelData.name || "")
                            iconName: String(app.modelData.icon || "")
                            onPinRequested: {
                                const pinned = {
                                    id: String(app.modelData.id || ""),
                                    name: String(app.modelData.name || ""),
                                    icon: String(app.modelData.icon || "")
                                }
                                Qt.callLater(() => root.pinDesktop(pinned))
                            }
                        }
                    }

                    Text {
                        visible: !root.appPack.rows.length
                        width: parent.width
                        text: "No matching apps."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Rectangle {
                        visible: root.appPack.hidden > 0
                        width: moreLabel.implicitWidth + Theme.space * 2
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: moreMouse.containsMouse ? Theme.hover : Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        Text {
                            id: moreLabel
                            anchors.centerIn: parent
                            text: "Show more (" + root.appPack.hidden + " left)"
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        MouseArea {
                            id: moreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.listLimit += Theme.launcherListMax
                        }
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Custom"
                hint: "A name and a command. The command is split on spaces and is not run through a shell. The icon is a theme name or an absolute path."
            }

            Item {
                width: parent.width
                implicitHeight: customCol.implicitHeight
                height: customCol.implicitHeight

                Column {
                    id: customCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    LineField {
                        id: nameField
                        width: parent.width
                        placeholderText: "Name"
                        tip: "Name shown on the launcher"
                    }

                    LineField {
                        id: commandField
                        width: parent.width
                        placeholderText: "Command, for example /usr/bin/firefox"
                        tip: "Program and arguments, separated by spaces. No shell characters."
                    }

                    LineField {
                        id: iconField
                        width: parent.width
                        placeholderText: "Icon name or path, optional"
                        tip: "Theme icon name, or an absolute path"
                    }

                    Rectangle {
                        width: addLabel.implicitWidth + Theme.space * 2
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: addMouse.containsMouse ? Theme.accentDim : Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: Theme.accent

                        Text {
                            id: addLabel
                            anchors.centerIn: parent
                            text: "Add"
                            color: Theme.wsActiveText
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                            font.bold: true
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addCustom()

                            HoverTip {
                                message: "Pin this command on Launcher 1"
                                show: addMouse.containsMouse
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        id: footer
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionInset
        anchors.bottom: parent.bottom
        spacing: Theme.tabGap

        Repeater {
            model: [
                { id: "apply", label: "Apply" },
                { id: "undo", label: "Undo" },
                { id: "reset", label: "Reset" }
            ]
            delegate: Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property string action: String(button.modelData.id || "")
                readonly property bool enabledAction: {
                    if (button.action === "apply")
                        return LauncherSettings.editor.dirty
                    if (button.action === "undo")
                        return LauncherSettings.editor.canUndo
                    return true
                }
                readonly property bool applyReady: button.action === "apply" && button.enabledAction

                implicitWidth: buttonLabel.implicitWidth + Theme.space * 2
                implicitHeight: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: button.enabledAction ? 1 : Theme.widgetOffOpacity
                color: button.applyReady && buttonMouse.containsMouse
                    ? Theme.accentDim
                    : (buttonMouse.containsMouse && button.enabledAction ? Theme.hover : Theme.pillBg)
                border.width: Theme.borderWidth
                border.color: button.applyReady ? Theme.accent : Theme.border

                Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    text: String(button.modelData.label || "")
                    color: button.applyReady ? Theme.wsActiveText : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: button.action === "apply"
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: button.enabledAction
                    cursorShape: button.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (button.action === "apply")
                            root.applyPage()
                        else if (button.action === "undo")
                            root.undoPage()
                        else
                            LauncherSettings.editor.reset()
                    }

                    HoverTip {
                        message: {
                            if (button.action === "apply")
                                return "Save the launchers and the pins"
                            if (button.action === "undo")
                                return "Drop an unsaved draft, or put back the last applied one"
                            return "Clear the pins and set the count to 1. Apply saves it."
                        }
                        show: buttonMouse.containsMouse
                    }
                }
            }
        }
    }

    Item {
        id: ghost
        anchors.fill: parent
        z: 10
        visible: root.dragging
        enabled: false

        Rectangle {
            x: ghost.mapFromItem(null, root.sceneX, root.sceneY).x + Theme.space
            y: ghost.mapFromItem(null, root.sceneX, root.sceneY).y + Theme.space
            width: ghostText.implicitWidth + Theme.space * 2
            height: Theme.chip
            radius: Theme.radiusSm
            color: Theme.pillBg
            border.width: Theme.borderWidth
            border.color: Theme.accent

            Text {
                id: ghostText
                anchors.centerIn: parent
                text: "||  " + root.dragLabel
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }
        }
    }
}
