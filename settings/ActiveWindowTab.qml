pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import qs.config
import qs.theme

Item {
    id: root

    readonly property var focused: {
        const top = Hyprland.activeToplevel
        if (!top)
            return { cls: "", title: "" }
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
        return { cls: appId || ipcClass || initialClass, title: title }
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

    readonly property var corners: [
        { id: "topLeft", label: "Top left" },
        { id: "topRight", label: "Top right" },
        { id: "bottomLeft", label: "Bottom left" },
        { id: "bottomRight", label: "Bottom right" }
    ]
    property string excludeKind: "class"
    readonly property int kindColumn: Theme.wsButtonWidth * 2

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

    function movePart(index, delta) {
        const cur = ActiveWindowSettings.draftLayout().slice()
        const j = index + delta
        if (j < 0 || j >= cur.length)
            return
        const held = cur[index]
        cur[index] = cur[j]
        cur[j] = held
        ActiveWindowSettings.editor.set("layout", JSON.stringify(cur))
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

            Item {
                width: 1
                height: Theme.fieldHeight
            }

            SectionHeader {
                width: parent.width
                title: "Other"
                hint: "Show the focused window's icon, class, and title in a screen corner. Show PID adds the process id. Layout sets the order. Apply saves these."
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
                    spacing: Theme.tabGap

                    Rectangle {
                        id: activeCard
                        readonly property bool shown: ActiveWindowSettings.editor.value.show
                        readonly property string corner: ActiveWindowSettings.editor.value.corner

                        width: parent.width
                        implicitHeight: activeRow.implicitHeight + Theme.space
                        radius: Theme.radiusSm
                        color: Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        opacity: activeCard.shown ? 1 : Theme.widgetOffOpacity

                        Row {
                            id: activeRow
                            x: Theme.space
                            y: Theme.space / 2
                            width: parent.width - Theme.space * 2
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
                                width: Math.max(Theme.tabMinWidth, activeRow.width - Theme.toggleWidth - cornerRow.width - Theme.space * 2)
                                height: Theme.chip
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: "Active Window"
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            Row {
                                id: cornerRow
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

                    CheckRow {
                        width: parent.width
                        title: "Show PID"
                        detail: "The focused window's process id. Layout sets where it sits."
                        tip: "Show the process id on the Active Window popup"
                        checked: !!ActiveWindowSettings.editor.value.showPid
                        onToggled: ActiveWindowSettings.editor.set("showPid", !ActiveWindowSettings.editor.value.showPid)
                    }
                }
            }
            }

            SectionHeader {
                width: parent.width
                title: "Layout"
                hint: "The order of the icon, class, title, and PID on the popup. The first part is the leftmost."
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
                        model: ActiveWindowSettings.draftLayout()
                        delegate: Rectangle {
                            id: partRow
                            required property string modelData
                            required property int index
                            width: layoutCol.width
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.space
                                anchors.right: partButtons.left
                                anchors.rightMargin: Theme.space
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: (partRow.index + 1) + ". " + ActiveWindowSettings.layoutLabel(partRow.modelData)
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontPx
                            }

                            Row {
                                id: partButtons
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.tabGap
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.tabGap

                                ChipButton {
                                    enabled: partRow.index > 0
                                    label: "Move up"
                                    tip: "Move this part left on the popup"
                                    onClicked: root.movePart(partRow.index, -1)
                                }

                                ChipButton {
                                    enabled: partRow.index < ActiveWindowSettings.draftLayout().length - 1
                                    label: "Move down"
                                    tip: "Move this part right on the popup"
                                    onClicked: root.movePart(partRow.index, 1)
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Move up moves a part left. Move down moves it right. Show PID turns the process id on. A part with nothing to show, such as a title that matches the class, is skipped."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
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
        applyTip: "Save the show switch, the corner, the width, the PID switch, the layout, and the excludes"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the show switch, top left, the default width, PID off, icon then class then title then PID, and the screensaver exclude. Apply saves it."
        onApplyClicked: ActiveWindowSettings.editor.apply()
        onUndoClicked: ActiveWindowSettings.editor.undo()
        onResetClicked: ActiveWindowSettings.editor.reset()
    }
}
