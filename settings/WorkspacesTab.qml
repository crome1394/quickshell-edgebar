import QtQuick
import QtQuick.Dialogs
import Quickshell.Io
import qs.config
import qs.theme

Item {
    id: root

    property var draft: []
    property var special: ({})
    property int draftTick: 0
    property var undoSlots: []
    property var undoSpecial: ({})
    property bool undoReady: false
    property int fontTarget: -1
    property int colorTarget: -1
    property var fontNames: []
    property bool fontReady: false
    property bool fontWaiting: false
    property int fontPending: -1

    readonly property bool twoCol: width >= Theme.settingsTwoColMin
    property bool dragging: false
    property int dragIndex: -1
    property int dropIndex: -1
    property real sceneX: 0
    property real sceneY: 0
    readonly property string dragLabel: {
        const rows = root.draft || []
        if (root.dragIndex < 0 || root.dragIndex >= rows.length)
            return ""
        const slot = rows[root.dragIndex]
        const symbol = String(slot.label || "")
        const name = String(slot.text || "")
        if (symbol.length && name.length)
            return symbol + "  " + name
        if (symbol.length)
            return symbol
        if (name.length)
            return name
        return String(slot.id || "")
    }
    readonly property bool canApply: {
        void root.draftTick
        void Config.revision
        return root.slotsDirty() || root.specialDirty()
    }
    readonly property bool canUndo: root.canApply || root.undoReady

    function seed() {
        root.draft = WorkspaceSettings.effectiveSlots()
        root.special = WorkspaceSettings.specialObject()
        root.draftTick++
    }

    function slotsDirty() {
        return WorkspaceSettings.slotsSignature(root.draft) !== WorkspaceSettings.slotsSignature(WorkspaceSettings.effectiveSlots())
    }

    function specialDirty() {
        return WorkspaceSettings.specialSignature(root.special) !== WorkspaceSettings.specialSignature(WorkspaceSettings.specialObject())
    }

    function mutate(fn) {
        const cur = WorkspaceSettings.sanitizeSlots(root.draft)
        fn(cur)
        root.draft = cur
        root.draftTick++
    }

    function mutateSpecial(fn) {
        const cur = WorkspaceSettings.copySpecial(root.special)
        fn(cur)
        root.special = cur
        root.draftTick++
    }

    function wrap(list, offset) {
        const out = []
        const total = root.draft.length
        for (let i = 0; i < list.length; i++)
            out.push({ index: offset + i, slot: list[i], count: total })
        return out
    }

    function leftRows() {
        void root.draftTick
        void root.twoCol
        const rows = root.draft || []
        if (!root.twoCol)
            return root.wrap(rows, 0)
        const take = Math.max(0, Math.ceil((1 + rows.length) / 2) - 1)
        return root.wrap(rows.slice(0, take), 0)
    }

    function rightRows() {
        void root.draftTick
        void root.twoCol
        if (!root.twoCol)
            return []
        const rows = root.draft || []
        const take = Math.max(0, Math.ceil((1 + rows.length) / 2) - 1)
        return root.wrap(rows.slice(take), take)
    }

    function setDraftCount(count) {
        const n = WorkspaceSettings.clampCount(count)
        root.mutate(function(cur) {
            while (cur.length > n)
                cur.pop()
            while (cur.length < n) {
                const id = WorkspaceSettings.nextFreeId(cur)
                if (id < 0)
                    break
                cur.push(WorkspaceSettings.blankSlot(id, WorkspaceSettings.iconForId(id)))
            }
        })
    }

    function swapFace(cur, i, j) {
        const keys = ["label", "text", "font", "fontPx", "bold", "italic", "color"]
        for (let k = 0; k < keys.length; k++) {
            const key = keys[k]
            const tmp = cur[i][key]
            cur[i][key] = cur[j][key]
            cur[j][key] = tmp
        }
    }

    function setDraftId(index, id) {
        root.mutate(function(cur) {
            const i = Math.round(Number(index))
            const n = Math.round(Number(id))
            if (i < 0 || i >= cur.length || n < 1 || n > 10 || cur[i].id === n)
                return
            for (let j = 0; j < cur.length; j++) {
                if (j !== i && cur[j].id === n) {
                    root.swapFace(cur, i, j)
                    return
                }
            }
            cur[i].id = n
        })
    }

    function setSymbol(index, text) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].label = Config.symbolClamp(text)
        })
    }

    function setLabel(index, text) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].text = Config.textClamp(text)
        })
    }

    function setFont(index, family) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].font = Config.fontClamp(family)
        })
    }

    function setSize(index, px) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].fontPx = Config.fontPxClamp(px)
        })
    }

    function setBold(index, bold) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].bold = !!bold
        })
    }

    function setItalic(index, italic) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].italic = !!italic
        })
    }

    function setColor(index, color) {
        root.mutate(function(cur) {
            if (index >= 0 && index < cur.length)
                cur[index].color = Config.colorNorm(color)
        })
    }

    function moveFace(from, to) {
        root.mutate(function(cur) {
            const i = Math.round(Number(from))
            const j = Math.round(Number(to))
            if (i < 0 || j < 0 || i >= cur.length || j >= cur.length || i === j)
                return
            const keys = ["label", "text", "font", "fontPx", "bold", "italic", "color"]
            const face = {}
            for (let k = 0; k < keys.length; k++)
                face[keys[k]] = cur[i][keys[k]]
            if (i < j) {
                for (let n = i; n < j; n++) {
                    for (let k = 0; k < keys.length; k++)
                        cur[n][keys[k]] = cur[n + 1][keys[k]]
                }
            } else {
                for (let n = i; n > j; n--) {
                    for (let k = 0; k < keys.length; k++)
                        cur[n][keys[k]] = cur[n - 1][keys[k]]
                }
            }
            for (let k = 0; k < keys.length; k++)
                cur[j][keys[k]] = face[keys[k]]
        })
    }

    function indexAt(sceneX, sceneY) {
        const columns = [leftCol, rightCol]
        for (let c = 0; c < columns.length; c++) {
            const kids = columns[c].children
            for (let i = 0; i < kids.length; i++) {
                const item = kids[i]
                if (!item || item.special !== false || item.slotIndex === undefined)
                    continue
                if (item.width <= 0 || item.height <= 0)
                    continue
                const local = item.mapFromItem(null, sceneX, sceneY)
                if (local.x >= 0 && local.y >= 0 && local.x <= item.width && local.y <= item.height)
                    return item.slotIndex
            }
        }
        return -1
    }

    function noteDrag(index, x, y) {
        root.dragIndex = index
        root.sceneX = x
        root.sceneY = y
        root.dropIndex = root.indexAt(x, y)
        root.dragging = true
    }

    function noteDrop(commit) {
        const from = root.dragIndex
        const to = root.dropIndex
        root.dragging = false
        root.dragIndex = -1
        root.dropIndex = -1
        if (commit && from >= 0 && to >= 0 && from !== to)
            Qt.callLater(() => root.moveFace(from, to))
    }

    function removeDraft(index) {
        root.fontTarget = -1
        root.colorTarget = -1
        root.mutate(function(cur) {
            const i = Math.round(Number(index))
            if (cur.length <= 1 || i < 0 || i >= cur.length)
                return
            cur.splice(i, 1)
            for (let k = 0; k < cur.length; k++)
                cur[k].id = k + 1
        })
    }

    function addDraft() {
        root.mutate(function(cur) {
            if (cur.length >= 10)
                return
            const id = WorkspaceSettings.nextFreeId(cur)
            if (id < 0)
                return
            cur.push(WorkspaceSettings.blankSlot(id, WorkspaceSettings.iconForId(id)))
        })
    }

    function setSpecialName(name) {
        root.mutateSpecial(function(cur) { cur.name = WorkspaceSettings.nameNorm(name) })
    }
    function setSpecialSymbol(text) {
        root.mutateSpecial(function(cur) { cur.label = Config.symbolClamp(text) })
    }
    function setSpecialLabel(text) {
        root.mutateSpecial(function(cur) { cur.text = Config.textClamp(text) })
    }
    function setSpecialFont(family) {
        root.mutateSpecial(function(cur) { cur.font = Config.fontClamp(family) })
    }
    function setSpecialSize(px) {
        root.mutateSpecial(function(cur) { cur.fontPx = Config.fontPxClamp(px) })
    }
    function setSpecialBold(bold) {
        root.mutateSpecial(function(cur) { cur.bold = !!bold })
    }
    function setSpecialItalic(italic) {
        root.mutateSpecial(function(cur) { cur.italic = !!italic })
    }
    function setSpecialColor(color) {
        root.mutateSpecial(function(cur) { cur.color = Config.colorNorm(color) })
    }

    function openFont(index) {
        root.fontPending = index
        root.fontWaiting = true
        if (root.fontReady)
            root.showPendingFont()
        else if (!fontList.running)
            fontList.running = true
    }

    function showPendingFont() {
        if (!root.fontWaiting)
            return
        root.fontTarget = root.fontPending
        root.fontWaiting = false
    }

    function takeFonts(text) {
        const seen = {}
        const out = []
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            const bar = line.lastIndexOf("|")
            if (bar <= 0)
                continue
            if (line.substring(bar + 1).trim() !== "True")
                continue
            const families = line.substring(0, bar).split(",")
            for (let j = 0; j < families.length; j++) {
                const name = families[j].trim()
                if (!name.length || seen[name])
                    continue
                seen[name] = true
                out.push(name)
            }
        }
        out.sort((a, b) => String(a).localeCompare(String(b)))
        return out
    }

    function fallbackFonts() {
        const all = Qt.fontFamilies()
        const out = []
        for (let i = 0; i < all.length; i++) {
            const name = String(all[i] || "")
            if (!name.length || /\.(pcf|bdf|psf|otb|fon)$/i.test(name))
                continue
            out.push(name)
        }
        return out
    }

    function fontsArrived(text) {
        if (root.fontReady)
            return
        const parsed = root.takeFonts(text)
        root.fontNames = parsed.length ? parsed : root.fallbackFonts()
        root.fontReady = true
        root.showPendingFont()
    }

    function applyFont(family) {
        if (root.fontTarget === -2)
            root.setSpecialFont(family)
        else if (root.fontTarget >= 0)
            root.setFont(root.fontTarget, family)
        root.fontTarget = -1
    }

    function openColor(index) {
        root.colorTarget = index
        const current = index === -2 ? String(root.special.color || "") : colorAt(index)
        colors.selectedColor = current.length ? current : Theme.text
        colors.open()
    }

    function colorAt(index) {
        const rows = root.draft || []
        if (index < 0 || index >= rows.length)
            return ""
        return String(rows[index].color || "")
    }

    function applyColor(color) {
        const hex = Config.colorNorm(color)
        if (root.colorTarget === -2)
            root.setSpecialColor(hex)
        else if (root.colorTarget >= 0)
            root.setColor(root.colorTarget, hex)
        root.colorTarget = -1
    }

    function applyDraft() {
        if (!root.canApply)
            return
        root.undoSlots = WorkspaceSettings.effectiveSlots()
        root.undoSpecial = WorkspaceSettings.specialObject()
        root.undoReady = true
        WorkspaceSettings.commit(root.draft, root.special)
        root.seed()
    }

    function undoDraft() {
        if (root.canApply) {
            root.seed()
            return
        }
        if (!root.undoReady)
            return
        WorkspaceSettings.commit(root.undoSlots, root.undoSpecial)
        root.undoReady = false
        root.seed()
    }

    function editId(index, id) { root.setDraftId(index, id) }
    function editSymbol(index, text) {
        if (index < 0)
            root.setSpecialSymbol(text)
        else
            root.setSymbol(index, text)
    }
    function editLabel(index, text) {
        if (index < 0)
            root.setSpecialLabel(text)
        else
            root.setLabel(index, text)
    }
    function editSize(index, px) {
        if (index < 0)
            root.setSpecialSize(px)
        else
            root.setSize(index, px)
    }
    function editBold(index, bold) {
        if (index < 0)
            root.setSpecialBold(bold)
        else
            root.setBold(index, bold)
    }
    function editItalic(index, italic) {
        if (index < 0)
            root.setSpecialItalic(italic)
        else
            root.setItalic(index, italic)
    }
    function editRemove(index) { root.removeDraft(index) }

    Component.onCompleted: root.seed()

    // Bitmap faces (cursor.pcf, Arabic Newspaper, …) make Qt remeasure and
    // warn on every resize. Only scalable families are offered.
    Process {
        id: fontList
        command: ["fc-list", "-f", "%{family}|%{scalable}\n"]
        stdout: StdioCollector {
            id: fontOut
            waitForEnd: true
        }
        onExited: (code) => {
            root.fontsArrived(code === 0 ? fontOut.text : "")
        }
    }

    ColorDialog {
        id: colors
        title: "Label color"
        onAccepted: root.applyColor(selectedColor)
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        spacing: Theme.space

        Flickable {
            id: scroll
            width: parent.width
            height: parent.height
            contentWidth: width
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: body
                width: scroll.width
                spacing: Theme.space

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Each number is a Hyprland workspace. Drag a row by || to move its symbol, label, font, and size onto another number. Removing a row renumbers the rows below it. Show only active hides an empty numbered pill until that workspace is focused or has a window. Occupied workspaces outside the list still appear after them, in number order. Toggles and startup apply immediately. Apply saves the faces and leaves Hyprland's workspace order alone."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                SectionHeader {
                    width: parent.width
                    title: "Workspace options"
                }

                Item {
                    width: parent.width
                    height: wsOptions.implicitHeight

                    WsOptions {
                        id: wsOptions
                        x: Theme.sectionInset
                        width: parent.width - Theme.sectionInset * 2
                        draftCount: Math.max(1, root.draft.length)
                        onCountEdited: (value) => root.setDraftCount(value)
                    }
                }

                SectionHeader {
                    width: parent.width
                    title: "Colors"
                    hint: "Follow the theme, or use your own colors. Saves at once."
                }

                WsColors {
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                }

                SectionHeader {
                    width: parent.width
                    title: "Workspaces"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "The number is the Hyprland workspace. Typing a number another row owns swaps the two faces, so the symbol on 5 can move onto 1. Hyprland is not reordered. Symbol is at most 3 characters; ✕ clears it, and an empty symbol draws no glyph. Label sits beside the symbol. B and I style both. Font opens a search. − and + set the symbol size from 8 to 32. The swatch colors the label; right-click clears it. The special row takes a Hyprland name instead of a number."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                Item {
                    width: parent.width
                    height: board.implicitHeight

                    Row {
                        id: board
                        x: Theme.sectionInset
                        width: parent.width - Theme.sectionInset * 2
                        spacing: Theme.space

                    Column {
                        id: leftCol
                        width: root.twoCol ? (parent.width - Theme.space) / 2 : parent.width
                        spacing: Theme.space

                        WsSlotCard {
                            width: parent.width
                            special: true
                            slotIndex: -1
                            slotId: 0
                            hyprName: String(root.special.name || "")
                            symbol: String(root.special.label || "")
                            label: String(root.special.text || "")
                            fontName: String(root.special.font || "")
                            fontPx: Config.fontPxClamp(root.special.fontPx)
                            bold: root.special.bold !== false
                            italic: !!root.special.italic
                            labelColor: String(root.special.color || "")
                            canRemove: false
                            onNameEdited: (index, name) => root.setSpecialName(name)
                            onSymbolEdited: (index, text) => root.editSymbol(index, text)
                            onLabelEdited: (index, text) => root.editLabel(index, text)
                            onFontRequested: (index) => root.openFont(-2)
                            onSizeEdited: (index, px) => root.editSize(index, px)
                            onBoldEdited: (index, bold) => root.editBold(index, bold)
                            onItalicEdited: (index, italic) => root.editItalic(index, italic)
                            onColorRequested: (index) => root.openColor(-2)
                            onColorCleared: (index) => root.setSpecialColor("")
                        }

                        Repeater {
                            model: root.leftRows()
                            delegate: WsSlotCard {
                                required property var modelData
                                required property int index
                                width: parent.width
                                special: false
                                slotIndex: modelData.index
                                slotId: modelData.slot.id
                                hyprName: ""
                                symbol: String(modelData.slot.label || "")
                                label: String(modelData.slot.text || "")
                                fontName: String(modelData.slot.font || "")
                                fontPx: Config.fontPxClamp(modelData.slot.fontPx)
                                bold: modelData.slot.bold !== false
                                italic: !!modelData.slot.italic
                                labelColor: String(modelData.slot.color || "")
                                canRemove: modelData.count > 1
                                dropTarget: root.dragging && root.dropIndex === modelData.index
                                onIdEdited: (index, id) => root.editId(index, id)
                                onSymbolEdited: (index, text) => root.editSymbol(index, text)
                                onLabelEdited: (index, text) => root.editLabel(index, text)
                                onFontRequested: (index) => root.openFont(index)
                                onSizeEdited: (index, px) => root.editSize(index, px)
                                onBoldEdited: (index, bold) => root.editBold(index, bold)
                                onItalicEdited: (index, italic) => root.editItalic(index, italic)
                                onColorRequested: (index) => root.openColor(index)
                                onColorCleared: (index) => root.setColor(index, "")
                                onRemoveRequested: (index) => root.editRemove(index)
                                onDragAt: (index, x, y) => root.noteDrag(index, x, y)
                                onDragFinished: (commit) => root.noteDrop(commit)
                            }
                        }
                    }

                    Column {
                        id: rightCol
                        width: root.twoCol ? (parent.width - Theme.space) / 2 : 0
                        visible: root.twoCol
                        spacing: Theme.space

                        Repeater {
                            model: root.rightRows()
                            delegate: WsSlotCard {
                                required property var modelData
                                required property int index
                                width: parent.width
                                special: false
                                slotIndex: modelData.index
                                slotId: modelData.slot.id
                                hyprName: ""
                                symbol: String(modelData.slot.label || "")
                                label: String(modelData.slot.text || "")
                                fontName: String(modelData.slot.font || "")
                                fontPx: Config.fontPxClamp(modelData.slot.fontPx)
                                bold: modelData.slot.bold !== false
                                italic: !!modelData.slot.italic
                                labelColor: String(modelData.slot.color || "")
                                canRemove: modelData.count > 1
                                dropTarget: root.dragging && root.dropIndex === modelData.index
                                onIdEdited: (index, id) => root.editId(index, id)
                                onSymbolEdited: (index, text) => root.editSymbol(index, text)
                                onLabelEdited: (index, text) => root.editLabel(index, text)
                                onFontRequested: (index) => root.openFont(index)
                                onSizeEdited: (index, px) => root.editSize(index, px)
                                onBoldEdited: (index, bold) => root.editBold(index, bold)
                                onItalicEdited: (index, italic) => root.editItalic(index, italic)
                                onColorRequested: (index) => root.openColor(index)
                                onColorCleared: (index) => root.setColor(index, "")
                                onRemoveRequested: (index) => root.editRemove(index)
                                onDragAt: (index, x, y) => root.noteDrag(index, x, y)
                                onDragFinished: (commit) => root.noteDrop(commit)
                            }
                        }
                    }
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

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.sectionInset
        anchors.rightMargin: Theme.sectionInset
        height: Theme.footerHeight

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.buttonHeight
            width: addLabel.implicitWidth + Theme.buttonPadX
            radius: Theme.radiusSm
            opacity: root.draft.length >= 10 ? 0.4 : 1
            color: addMouse.containsMouse ? Theme.hover : Theme.pillBg
            border.width: Theme.borderWidth
            border.color: Theme.border
            Text {
                id: addLabel
                anchors.centerIn: parent
                text: "Add workspace"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.draft.length < 10 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.draft.length < 10)
                        root.addDraft()
                }

                HoverTip {
                    message: "Add a numbered workspace"
                    show: addMouse.containsMouse
                }
            }
        }

        Rectangle {
            id: applyButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.buttonHeight
            width: applyLabel.implicitWidth + Theme.buttonPadX
            radius: Theme.radiusSm
            opacity: root.canApply ? 1 : 0.4
            color: applyMouse.containsMouse && root.canApply ? Theme.accentDim : Theme.pillBg
            border.width: Theme.borderWidth
            border.color: root.canApply ? Theme.accent : Theme.border
            Text {
                id: applyLabel
                anchors.centerIn: parent
                text: "Apply"
                color: root.canApply ? Theme.wsActiveText : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }
            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.canApply)
                        root.applyDraft()
                }

                HoverTip {
                    message: "Save the faces. Hyprland's workspace order stays as it is."
                    show: applyMouse.containsMouse
                }
            }
        }

        Rectangle {
            anchors.right: applyButton.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.buttonHeight
            width: undoLabel.implicitWidth + Theme.buttonPadX
            radius: Theme.radiusSm
            opacity: root.canUndo ? 1 : 0.4
            color: undoMouse.containsMouse && root.canUndo ? Theme.hover : Theme.pillBg
            border.width: Theme.borderWidth
            border.color: Theme.border
            Text {
                id: undoLabel
                anchors.centerIn: parent
                text: "Undo"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }
            MouseArea {
                id: undoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canUndo ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.canUndo)
                        root.undoDraft()
                }

                HoverTip {
                    message: "Restore the last saved faces"
                    show: undoMouse.containsMouse
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.fontTarget !== -1
        sourceComponent: Component {
            FontPicker {
                width: parent.width
                height: parent.height
                families: root.fontNames
                onChosen: (family) => root.applyFont(family)
                onDismiss: root.fontTarget = -1
            }
        }
    }
}
