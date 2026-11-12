pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import qs.config
import qs.theme

Item {
    id: root

    property bool formReady: false
    property bool formatFromField: false
    property bool formatEcho: false

    readonly property var focused: {
        const top = Hyprland.activeToplevel
        if (!top)
            return { cls: "", title: "", pid: "" }
        const ipc = top.lastIpcObject || null
        function field(obj, key) {
            if (!obj)
                return ""
            const value = obj[key]
            if (value === undefined || value === null)
                return ""
            return String(value)
        }
        const wayland = top.wayland
        const appId = wayland ? String(wayland.appId || "") : ""
        const ipcClass = field(ipc, "class")
        const initialClass = field(ipc, "initialClass")
        let title = String(top.title || "")
        if (!title.length && wayland)
            title = String(wayland.title || "")
        if (!title.length)
            title = field(ipc, "initialTitle")
        let pid = field(ipc, "pid")
        if (pid === "0")
            pid = ""
        return { cls: appId || ipcClass || initialClass, title: title, pid: pid }
    }

    readonly property string focusedLine: {
        const cls = String(root.focused.cls || "")
        const title = String(root.focused.title || "")
        if (!cls.length && !title.length)
            return "Nothing is focused."
        let line = "Focused now: " + (cls.length ? cls : title)
        if (title.length && title.toLowerCase() !== cls.toLowerCase())
            line += "  ·  " + title
        return line
    }

    readonly property var previewValues: {
        const cls = String(root.focused.cls || "")
        const title = String(root.focused.title || "")
        const pid = String(root.focused.pid || "")
        const classText = cls.length ? cls : (title.length ? title : "app")
        let titleText = "Window title"
        if (title.length && title.toLowerCase() !== classText.toLowerCase())
            titleText = title
        return {
            icon: "◆",
            class: classText,
            title: titleText,
            pid: pid.length ? pid : "1000"
        }
    }

    readonly property string previewSource: {
        if (!root.formReady)
            return ActiveWindowSettings.formatText(ActiveWindowSettings.draftModel())
        return String(formatField.text || "")
    }
    readonly property bool patternCustom: root.previewSource.trim() !== "icon class title"
    readonly property string previewLine: {
        const parts = ActiveWindowSettings.formatPieces(root.previewSource)
        const line = ActiveWindowSettings.formatPlain(parts, root.previewValues)
        return line.length ? line : "Nothing to show"
    }

    readonly property var corners: [
        { id: "topLeft", label: "Top left" },
        { id: "topRight", label: "Top right" },
        { id: "bottomLeft", label: "Bottom left" },
        { id: "bottomRight", label: "Bottom right" }
    ]
    property string excludeKind: "class"
    readonly property int kindColumn: Theme.wsButtonWidth * 2

    function otherColumnWidth(total) {
        if (!(total > 0))
            return Theme.tabMinWidth * 3
        const gap = Theme.space
        const layoutMin = Theme.tabMinWidth * 2 + Theme.chip
        let other = Math.round((total - gap) * 0.62)
        if (total - gap - other < layoutMin)
            other = total - gap - layoutMin
        if (other < Theme.tabMinWidth * 2)
            other = Math.max(Theme.tabMinWidth, Math.round((total - gap) * 0.62))
        return other
    }

    function commit() {
        const which = root.excludeKind === "title" ? "title" : "class"
        const cleaned = ActiveWindowSettings.normalizeExcludes([{ text: excludeField.text, kind: which }])
        if (!cleaned.length)
            return
        const cur = ActiveWindowSettings.draftExcludes()
        if (cur.length >= ActiveWindowSettings.excludeMax)
            return
        const text = cleaned[0].text.toLowerCase()
        for (let i = 0; i < cur.length; i++) {
            if (cur[i].kind === which && String(cur[i].text || "").toLowerCase() === text)
                return
        }
        const next = cur.slice()
        next.push(cleaned[0])
        ActiveWindowSettings.editor.set("excludes", JSON.stringify(next))
        excludeField.text = ""
    }

    function commitFormat() {
        const text = String(formatField.text || "").replace(/[\r\n]/g, " ").trim().slice(0, ActiveWindowSettings.formatMax)
        const next = ActiveWindowSettings.formatApply(text, ActiveWindowSettings.draftModel())
        const canonical = ActiveWindowSettings.formatText(next)
        if (formatField.text !== canonical) {
            root.formatEcho = true
            formatField.text = canonical
            root.formatEcho = false
        }
        const json = ActiveWindowSettings.formatJson(next)
        if (json !== ActiveWindowSettings.editor.value.format)
            ActiveWindowSettings.editor.set("format", json)
    }

    function placePart(from, to) {
        if (from === to || from < 0 || to < 0)
            return
        const next = ActiveWindowSettings.formatMove(ActiveWindowSettings.draftModel(), from, to)
        ActiveWindowSettings.editor.set("format", ActiveWindowSettings.formatJson(next))
    }

    property bool dragging: false
    property int dragIndex: -1
    property int dropIndex: -1
    property real sceneX: 0
    property real sceneY: 0

    readonly property string dragLabel: {
        const order = ActiveWindowSettings.draftModel()
        if (root.dragIndex < 0 || root.dragIndex >= order.length)
            return ""
        return ActiveWindowSettings.layoutLabel(order[root.dragIndex].id)
    }

    function noteDrag(index, x, y) {
        root.dragIndex = index
        root.sceneX = x
        root.sceneY = y
        root.dragging = true
        const local = layoutCol.mapFromItem(null, x, y)
        const row = Theme.fieldHeight + Theme.tabGap
        let at = row > 0 ? Math.floor(local.y / row) : 0
        const last = ActiveWindowSettings.draftModel().length - 1
        if (at < 0)
            at = 0
        if (at > last)
            at = last
        root.dropIndex = at
    }

    function noteDrop(commit) {
        const from = root.dragIndex
        const to = root.dropIndex
        root.dragging = false
        root.dragIndex = -1
        root.dropIndex = -1
        if (commit)
            root.placePart(from, to)
    }

    Component.onCompleted: {
        formatField.text = ActiveWindowSettings.formatText(ActiveWindowSettings.draftModel())
        root.formReady = true
    }

    // Undo and Reset change the draft. Leave the field alone while it is being typed.
    Connections {
        target: ActiveWindowSettings.editor
        function onValueChanged() {
            if (!root.formReady || root.formatFromField)
                return
            const text = ActiveWindowSettings.formatText(ActiveWindowSettings.draftModel())
            if (formatField.text === text)
                return
            root.formatEcho = true
            formatField.text = text
            root.formatEcho = false
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

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            Row {
                id: pair
                width: parent.width
                spacing: Theme.space

                Column {
                    id: otherCol
                    width: root.otherColumnWidth(pair.width)
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "Other"
                        hint: "Corner, width, and the pattern for the popup. Apply saves these."
                    }

                    Item {
                        width: parent.width
                        height: otherCard.implicitHeight

                        Rectangle {
                            id: otherCard
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            implicitHeight: otherInner.implicitHeight + Theme.space * 2
                            radius: Theme.radius
                            color: Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Column {
                                id: otherInner
                                x: Theme.space
                                y: Theme.space
                                width: parent.width - Theme.space * 2
                                spacing: Theme.space

                                Rectangle {
                                    id: activeCard
                                    readonly property bool shown: ActiveWindowSettings.editor.value.show
                                    readonly property string corner: ActiveWindowSettings.editor.value.corner

                                    width: parent.width
                                    implicitHeight: activeInner.implicitHeight + Theme.space
                                    radius: Theme.radiusSm
                                    color: Theme.pillBg
                                    border.width: Theme.borderWidth
                                    border.color: Theme.border
                                    opacity: activeCard.shown ? 1 : Theme.widgetOffOpacity

                                    Column {
                                        id: activeInner
                                        x: Theme.space
                                        y: Theme.space / 2
                                        width: parent.width - Theme.space * 2
                                        spacing: Theme.tabGap

                                        Row {
                                            id: activeRow
                                            width: parent.width
                                            spacing: Theme.space

                                            Rectangle {
                                                width: Theme.toggleWidth
                                                height: Theme.chip
                                                radius: Theme.radiusSm
                                                color: activeToggle.containsMouse ? Theme.hover : "transparent"
                                                border.width: Theme.borderWidth
                                                border.color: activeCard.shown ? Theme.ok : Theme.danger

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: activeCard.shown ? "✓" : "✕"
                                                    color: activeCard.shown ? Theme.ok : Theme.danger
                                                    font.pixelSize: Theme.fontPx
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: activeToggle
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ActiveWindowSettings.editor.set("show", !ActiveWindowSettings.editor.value.show)

                                                    HoverTip {
                                                        message: "Show the focused window in the chosen corner"
                                                        show: activeToggle.containsMouse
                                                    }
                                                }
                                            }

                                            Text {
                                                width: Math.max(Theme.tabMinWidth, activeRow.width - Theme.toggleWidth - Theme.space)
                                                height: Theme.chip
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                text: "Active Window"
                                                color: Theme.text
                                                font.family: Theme.uiFont
                                                font.pixelSize: Theme.smallPx
                                            }
                                        }

                                        Flow {
                                            id: cornerRow
                                            width: parent.width
                                            spacing: Theme.tabGap

                                            Repeater {
                                                model: root.corners
                                                delegate: Rectangle {
                                                    id: cornerChip
                                                    required property var modelData
                                                    required property int index
                                                    readonly property bool cornerOn: activeCard.corner === String(cornerChip.modelData.id || "")

                                                    width: cornerLabel.implicitWidth + Theme.space * 2
                                                    height: Theme.chip
                                                    radius: Theme.radiusSm
                                                    color: cornerChip.cornerOn ? Theme.accentDim : Theme.pageBg
                                                    border.width: Theme.borderWidth
                                                    border.color: cornerChip.cornerOn ? Theme.accent : Theme.border

                                                    Text {
                                                        id: cornerLabel
                                                        anchors.centerIn: parent
                                                        text: String(cornerChip.modelData.label || "")
                                                        color: cornerChip.cornerOn ? Theme.wsActiveText : Theme.subtext
                                                        font.family: Theme.uiFont
                                                        font.pixelSize: Theme.smallPx
                                                        font.bold: cornerChip.cornerOn
                                                    }

                                                    MouseArea {
                                                        id: cornerMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ActiveWindowSettings.editor.set("corner", String(cornerChip.modelData.id || ""))

                                                        HoverTip {
                                                            message: "Place the popup at the " + String(cornerChip.modelData.label || "").toLowerCase()
                                                            show: cornerMouse.containsMouse
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    id: widthBlock
                                    width: parent.width
                                    spacing: Theme.tabGap

                                    HoverHandler {
                                        id: widthHover
                                    }

                                    HoverTip {
                                        message: "How wide the popup can grow. The class name stays whole. A longer title is cut off."
                                        show: widthHover.hovered && !widthSlider.hovered
                                    }

                                    Text {
                                        width: parent.width
                                        text: "Width"
                                        color: Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.fontPx
                                    }

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: "How wide the popup can grow. The class name stays whole. A longer title is cut off after that."
                                        color: Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                    }

                                    IntSlider {
                                        id: widthSlider
                                        width: parent.width
                                        from: Theme.activeWindowWidthMin
                                        to: Theme.activeWindowWidthMax
                                        step: Theme.activeWindowWidthStep
                                        value: ActiveWindowSettings.editor.value.width
                                        readout: ActiveWindowSettings.editor.value.width + " px"
                                        tip: "How wide the popup can grow. The class name stays whole. A longer title is cut off."
                                        onChanged: (value) => ActiveWindowSettings.editor.set("width", value)
                                    }
                                }

                                Column {
                                    id: patternBlock
                                    width: parent.width
                                    spacing: Theme.space

                                    Text {
                                        width: parent.width
                                        text: "Pattern"
                                        color: Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.fontPx
                                    }

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: "Words are icon, class, title, and pid. Marks around a word are drawn around that part, such as [class] or (pid)."
                                        color: Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: Theme.space

                                        TextField {
                                            id: formatField
                                            width: parent.width - setButton.width - Theme.space
                                            height: Theme.fieldHeight
                                            verticalAlignment: Text.AlignVCenter
                                            selectByMouse: true
                                            placeholderText: "icon [class] title (pid)"
                                            leftPadding: Theme.space
                                            rightPadding: Theme.space
                                            color: Theme.text
                                            placeholderTextColor: Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontPx
                                            background: Rectangle {
                                                radius: Theme.radiusSm
                                                color: formatField.activeFocus ? Theme.hover : Theme.pageBg
                                                border.width: Theme.borderWidth
                                                border.color: root.patternCustom ? Theme.accent : Theme.border
                                            }
                                            onTextChanged: {
                                                if (!root.formReady || root.formatEcho)
                                                    return
                                                const next = ActiveWindowSettings.formatApply(text, ActiveWindowSettings.draftModel())
                                                const json = ActiveWindowSettings.formatJson(next)
                                                if (json === ActiveWindowSettings.editor.value.format)
                                                    return
                                                root.formatFromField = true
                                                ActiveWindowSettings.editor.set("format", json)
                                                root.formatFromField = false
                                            }
                                            onAccepted: root.commitFormat()

                                            HoverHandler {
                                                id: formatHover
                                            }

                                            HoverTip {
                                                message: "Pattern for the corner popup. Set keeps it for Apply."
                                                show: formatHover.hovered
                                            }
                                        }

                                        Rectangle {
                                            id: setButton
                                            implicitWidth: setLabel.implicitWidth + Theme.space * 2
                                            implicitHeight: Theme.fieldHeight
                                            radius: Theme.radiusSm
                                            color: setMouse.containsMouse ? Theme.hover : Theme.pillBg
                                            border.width: Theme.borderWidth
                                            border.color: setMouse.containsMouse ? Theme.accent : Theme.border

                                            Text {
                                                id: setLabel
                                                anchors.centerIn: parent
                                                text: "Set"
                                                color: Theme.subtext
                                                font.family: Theme.uiFont
                                                font.pixelSize: Theme.smallPx
                                            }

                                            MouseArea {
                                                id: setMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.commitFormat()

                                                HoverTip {
                                                    message: "Keep this pattern for Apply"
                                                    show: setMouse.containsMouse
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        implicitHeight: previewCol.implicitHeight + Theme.space * 2
                                        radius: Theme.radiusSm
                                        color: Theme.pageBg
                                        border.width: Theme.borderWidth
                                        border.color: Theme.accent

                                        Column {
                                            id: previewCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: Theme.space
                                            spacing: Theme.tabGap

                                            Text {
                                                width: parent.width
                                                text: "Preview" + (root.patternCustom ? "  · custom" : "")
                                                color: Theme.subtext
                                                font.family: Theme.uiFont
                                                font.pixelSize: Theme.smallPx
                                            }

                                            Text {
                                                width: parent.width
                                                wrapMode: Text.WordWrap
                                                text: root.previewLine
                                                color: root.previewLine === "Nothing to show" ? Theme.subtext : Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontPx
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    id: layoutSide
                    width: Math.max(0, pair.width - otherCol.width - pair.spacing)
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: "Layout"
                        hint: "Order and on or off. The first row is the leftmost."
                    }

                    Item {
                        width: parent.width
                        height: layoutCol.implicitHeight

                        Column {
                            id: layoutCol
                            x: Theme.sectionInset
                            width: parent.width - Theme.sectionInset * 2
                            spacing: Theme.tabGap

                            Repeater {
                                model: ActiveWindowSettings.draftModel()
                                delegate: Rectangle {
                                    id: partRow
                                    required property var modelData
                                    required property int index
                                    readonly property string partId: String(partRow.modelData.id || "")
                                    readonly property bool partOn: !!partRow.modelData.on

                                    width: layoutCol.width
                                    height: Theme.fieldHeight
                                    radius: Theme.radiusSm
                                    color: Theme.pillBg
                                    border.width: Theme.borderWidth
                                    border.color: root.dragging && partRow.index === root.dropIndex ? Theme.accent : Theme.border
                                    opacity: root.dragging && partRow.index === root.dragIndex ? Theme.widgetOffOpacity : (partRow.partOn ? 1 : Theme.widgetOffOpacity)

                                    Rectangle {
                                        id: grip
                                        width: Theme.chip
                                        height: Theme.chip
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.space
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: Theme.radiusSm
                                        color: gripMouse.containsMouse ? Theme.hover : Theme.fieldBg
                                        border.width: Theme.borderWidth
                                        border.color: Theme.border

                                        Text {
                                            anchors.centerIn: parent
                                            text: "||"
                                            color: Theme.subtext
                                            font.family: Theme.uiFont
                                            font.pixelSize: Theme.smallPx
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: gripMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.SizeAllCursor
                                            property real pressX: 0
                                            property real pressY: 0
                                            property bool armed: false
                                            onPressed: (mouse) => {
                                                gripMouse.pressX = mouse.x
                                                gripMouse.pressY = mouse.y
                                                gripMouse.armed = false
                                            }
                                            onPositionChanged: (mouse) => {
                                                if (!gripMouse.pressed)
                                                    return
                                                const dx = mouse.x - gripMouse.pressX
                                                const dy = mouse.y - gripMouse.pressY
                                                const slop = Theme.space * Theme.space
                                                if (!gripMouse.armed && (dx * dx + dy * dy) < slop)
                                                    return
                                                gripMouse.armed = true
                                                const point = gripMouse.mapToItem(null, mouse.x, mouse.y)
                                                root.noteDrag(partRow.index, point.x, point.y)
                                            }
                                            onReleased: {
                                                if (gripMouse.armed)
                                                    root.noteDrop(true)
                                                gripMouse.armed = false
                                            }
                                            onCanceled: {
                                                if (gripMouse.armed)
                                                    root.noteDrop(false)
                                                gripMouse.armed = false
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.left: grip.right
                                        anchors.leftMargin: Theme.space
                                        anchors.right: partToggle.left
                                        anchors.rightMargin: Theme.space
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: (partRow.index + 1) + ". " + ActiveWindowSettings.layoutLabel(partRow.partId)
                                        color: partRow.partOn ? Theme.text : Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.fontPx
                                    }

                                    Rectangle {
                                        id: partToggle
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.tabGap
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Theme.checkBoxWidth
                                        height: Theme.checkBoxHeight
                                        radius: Theme.radiusSm
                                        color: partToggleMouse.containsMouse ? Theme.hover : "transparent"
                                        border.width: Theme.borderWidth
                                        border.color: partRow.partOn ? Theme.ok : Theme.danger

                                        Text {
                                            anchors.centerIn: parent
                                            text: partRow.partOn ? "✓" : "✕"
                                            color: partRow.partOn ? Theme.ok : Theme.danger
                                            font.pixelSize: Theme.checkGlyphPx
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: partToggleMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const next = ActiveWindowSettings.formatToggle(ActiveWindowSettings.draftModel(), partRow.partId)
                                                ActiveWindowSettings.editor.set("format", ActiveWindowSettings.formatJson(next))
                                            }

                                            HoverTip {
                                                message: partRow.partOn ? "Hide " + ActiveWindowSettings.layoutLabel(partRow.partId) : "Show " + ActiveWindowSettings.layoutLabel(partRow.partId)
                                                show: partToggleMouse.containsMouse
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Drag a row by ||. The switch shows or hides that part. A part with nothing to show, such as a title that matches the class, is skipped."
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.fieldHeight
            }

            SectionHeader {
                width: parent.width
                title: "Overrides"
                hint: "A class entry matches the app id or class. A title entry matches the window title. Wildcards are accepted."
            }

            Item {
                width: parent.width
                height: overrideCol.implicitHeight

                Column {
                    id: overrideCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.focusedLine
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.space

                        TextField {
                            id: excludeField
                            width: parent.width - kindPick.width - addButton.width - Theme.space * 2
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            placeholderText: "class or title"
                            leftPadding: Theme.space
                            color: Theme.text
                            placeholderTextColor: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: excludeField.activeFocus ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: excludeField.activeFocus ? Theme.accent : Theme.border
                            }
                            onAccepted: root.commit()

                            HoverHandler {
                                id: excludeHover
                            }

                            HoverTip {
                                message: "Class or title to exclude"
                                show: excludeHover.hovered
                            }
                        }

                        Row {
                            id: kindPick
                            spacing: Theme.tabGap

                            Repeater {
                                model: [
                                    { id: "class", label: "Class" },
                                    { id: "title", label: "Title" }
                                ]
                                delegate: Rectangle {
                                    id: kindChip
                                    required property var modelData
                                    required property int index
                                    readonly property string kindId: String(kindChip.modelData.id || "")
                                    readonly property bool picked: root.excludeKind === kindChip.kindId

                                    width: kindPickLabel.implicitWidth + Theme.space * 2
                                    height: Theme.fieldHeight
                                    radius: Theme.radiusSm
                                    color: kindChip.picked ? Theme.accentDim : Theme.pillBg
                                    border.width: Theme.borderWidth
                                    border.color: kindChip.picked ? Theme.accent : Theme.border

                                    Text {
                                        id: kindPickLabel
                                        anchors.centerIn: parent
                                        text: String(kindChip.modelData.label || "")
                                        color: kindChip.picked ? Theme.wsActiveText : Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                        font.bold: kindChip.picked
                                    }

                                    MouseArea {
                                        id: kindMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.excludeKind = kindChip.kindId

                                        HoverTip {
                                            message: kindChip.kindId === "title" ? "Match the window title" : "Match the app id or class"
                                            show: kindMouse.containsMouse
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: addButton
                            implicitWidth: addLabel.implicitWidth + Theme.space * 2
                            implicitHeight: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: addMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: addMouse.containsMouse ? Theme.accent : Theme.border

                            Text {
                                id: addLabel
                                anchors.centerIn: parent
                                text: "Add"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            MouseArea {
                                id: addMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.commit()

                                HoverTip {
                                    message: "Add this exclude"
                                    show: addMouse.containsMouse
                                }
                            }
                        }
                    }

                    Text {
                        visible: ActiveWindowSettings.draftExcludes().length === 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Nothing is excluded. Every focused window shows on the pill."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Item {
                        visible: ActiveWindowSettings.draftExcludes().length > 0
                        width: parent.width
                        height: Theme.badgeHeight

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space
                            anchors.rightMargin: Theme.space / 2
                            spacing: Theme.space

                            Text {
                                width: parent.width - root.kindColumn - Theme.chip - Theme.space * 2
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: "Pattern"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            Text {
                                width: root.kindColumn
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: "Kind"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            Item {
                                width: Theme.chip
                                height: 1
                            }
                        }
                    }

                    Repeater {
                        model: ActiveWindowSettings.draftExcludes()
                        delegate: Rectangle {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property string pattern: String(entry.modelData.text || "")
                            readonly property string kind: entry.modelData.kind === "title" ? "title" : "class"

                            width: overrideCol.width
                            implicitHeight: Theme.fieldHeight + Theme.space / 2
                            radius: Theme.radiusSm
                            color: Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            HoverHandler {
                                id: entryHover
                            }

                            HoverTip {
                                message: entry.kind === "title" ? "Title exclude" : "Class exclude"
                                show: entryHover.hovered && !removeMouse.containsMouse
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space / 2
                                spacing: Theme.space

                                Text {
                                    width: parent.width - root.kindColumn - removeButton.width - Theme.space * 2
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: entry.pattern
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }

                                Text {
                                    width: root.kindColumn
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    text: entry.kind === "title" ? "Title" : "Class"
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }

                                Rectangle {
                                    id: removeButton
                                    width: Theme.chip
                                    height: Theme.chip
                                    radius: Theme.radiusSm
                                    color: removeMouse.containsMouse ? Theme.hover : "transparent"
                                    border.width: Theme.borderWidth
                                    border.color: removeMouse.containsMouse ? Theme.danger : Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: removeMouse.containsMouse ? Theme.danger : Theme.subtext
                                        font.pixelSize: Theme.smallPx
                                    }

                                    MouseArea {
                                        id: removeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const cur = ActiveWindowSettings.draftExcludes()
                                            const next = []
                                            for (let i = 0; i < cur.length; i++) {
                                                if (cur[i].kind === entry.kind && String(cur[i].text || "") === entry.pattern)
                                                    continue
                                                next.push(cur[i])
                                            }
                                            ActiveWindowSettings.editor.set("excludes", JSON.stringify(next))
                                        }

                                        HoverTip {
                                            message: "Remove this exclude"
                                            show: removeMouse.containsMouse
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: ActiveWindowSettings.editor.dirty
        undoEnabled: ActiveWindowSettings.editor.canUndo
        applyTip: "Save the show switch, the corner, the width, the pattern, and the excludes"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the show switch, top left, the default width, icon then class then title, PID off, and the screensaver exclude. Apply saves it."
        onApplyClicked: {
            root.commitFormat()
            ActiveWindowSettings.editor.apply()
        }
        onUndoClicked: ActiveWindowSettings.editor.undo()
        onResetClicked: ActiveWindowSettings.editor.reset()
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
