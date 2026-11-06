import QtQuick
import QtQuick.Controls
import qs.theme

Rectangle {
    id: root

    required property bool special
    required property int slotIndex
    required property int slotId
    required property string hyprName
    required property string symbol
    required property string label
    required property string fontName
    required property int fontPx
    required property bool bold
    required property bool italic
    required property string labelColor
    required property bool canRemove

    signal idEdited(int index, int id)
    signal nameEdited(int index, string name)
    signal symbolEdited(int index, string text)
    signal labelEdited(int index, string text)
    signal fontRequested(int index)
    signal sizeEdited(int index, int px)
    signal boldEdited(int index, bool bold)
    signal italicEdited(int index, bool italic)
    signal colorRequested(int index)
    signal colorCleared(int index)
    signal removeRequested(int index)
    signal dragAt(int index, real x, real y)
    signal dragFinished(bool commit)

    property bool dropTarget: false
    property real pressX: 0
    property real pressY: 0
    property bool armed: false

    readonly property int displayPx: root.fontPx >= 8 ? root.fontPx : Theme.wsIconPx
    // Three glyphs plus the in-field clear button. The bar pill uses displayPx.
    readonly property int symbolWidth: Theme.iconPx * 3 + Theme.chip + Theme.space

    implicitHeight: Theme.space * 2 + Theme.fieldHeight * 2 + Theme.tabGap
    radius: Theme.radiusSm
    color: Theme.pillBg
    border.width: Theme.borderWidth
    border.color: root.dropTarget ? Theme.accent : Theme.border

    function fieldBg(focused) {
        return focused ? Theme.hover : Theme.fieldBg
    }

    onSlotIdChanged: {
        if (!idField.activeFocus)
            idField.text = String(root.slotId)
    }
    onHyprNameChanged: {
        if (!nameField.activeFocus)
            nameField.text = root.hyprName
    }
    onSymbolChanged: {
        if (!symbolField.activeFocus)
            symbolField.text = root.symbol
    }
    onLabelChanged: {
        if (!labelField.activeFocus)
            labelField.text = root.label
    }
    Component.onCompleted: {
        idField.text = String(root.slotId)
        nameField.text = root.hyprName
        symbolField.text = root.symbol
        labelField.text = root.label
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.space
        spacing: Theme.tabGap

        Row {
            id: topRow
            width: parent.width
            height: Theme.fieldHeight
            spacing: Theme.tabGap

            Rectangle {
                id: grip
                visible: !root.special
                width: Theme.chip
                height: Theme.fieldHeight
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
                    onPressed: (mouse) => {
                        root.pressX = mouse.x
                        root.pressY = mouse.y
                        root.armed = false
                    }
                    onPositionChanged: (mouse) => {
                        if (!gripMouse.pressed)
                            return
                        const dx = mouse.x - root.pressX
                        const dy = mouse.y - root.pressY
                        const slop = Theme.space * Theme.space
                        if (!root.armed && (dx * dx + dy * dy) < slop)
                            return
                        root.armed = true
                        const point = gripMouse.mapToItem(null, mouse.x, mouse.y)
                        root.dragAt(root.slotIndex, point.x, point.y)
                    }
                    onReleased: {
                        if (root.armed)
                            root.dragFinished(true)
                        root.armed = false
                    }
                    onCanceled: {
                        if (root.armed)
                            root.dragFinished(false)
                        root.armed = false
                    }

                    HoverTip {
                        message: "Drag to move this face onto another number"
                        show: gripMouse.containsMouse
                    }
                }
            }

            TextField {
                id: idField
                visible: !root.special
                width: Theme.fieldHeight + Theme.space * 2
                height: Theme.fieldHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                placeholderText: "#"
                color: Theme.text
                placeholderTextColor: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: root.fieldBg(idField.activeFocus)
                    border.width: Theme.borderWidth
                    border.color: idField.activeFocus ? Theme.accent : Theme.border
                }
                onEditingFinished: {
                    const n = Math.round(Number(text))
                    if (n >= 1 && n <= 10 && n !== root.slotId)
                        root.idEdited(root.slotIndex, n)
                    text = String(root.slotId)
                }

                HoverHandler {
                    id: idHover
                }

                HoverTip {
                    message: "Workspace number. A number another row owns swaps the two faces."
                    show: idHover.hovered
                }
            }

            TextField {
                id: nameField
                visible: root.special
                width: Theme.wsLabelMax + Theme.chip + Theme.wsGap
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                placeholderText: "magic"
                leftPadding: Theme.space
                color: Theme.text
                placeholderTextColor: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: root.fieldBg(nameField.activeFocus)
                    border.width: Theme.borderWidth
                    border.color: nameField.activeFocus ? Theme.accent : Theme.border
                }
                onEditingFinished: root.nameEdited(root.slotIndex, text)

                HoverHandler {
                    id: nameHover
                }

                HoverTip {
                    message: "Hyprland name of the special workspace"
                    show: nameHover.hovered
                }
            }

            TextField {
                id: symbolField
                width: root.symbolWidth
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                placeholderText: "sym"
                leftPadding: Theme.space
                rightPadding: symbolClear.visible ? Theme.chip : Theme.space
                color: Theme.text
                placeholderTextColor: Theme.subtext
                font.pixelSize: Theme.fontPx
                font.family: text.length && root.fontName.length ? root.fontName : Theme.uiFont
                font.bold: text.length ? root.bold : false
                font.italic: text.length ? root.italic : false
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: root.fieldBg(symbolField.activeFocus)
                    border.width: Theme.borderWidth
                    border.color: symbolField.activeFocus ? Theme.accent : Theme.border
                }
                onEditingFinished: {
                    if (text !== root.symbol)
                        root.symbolEdited(root.slotIndex, text)
                }

                HoverHandler {
                    id: symbolHover
                }

                HoverTip {
                    message: "Symbol on the pill, up to 3 characters"
                    show: symbolHover.hovered && !symbolClearMouse.containsMouse
                }

                Rectangle {
                    id: symbolClear
                    visible: symbolField.text.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.borderWidth * 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.iconPx
                    height: Theme.iconPx
                    radius: Theme.iconPx / 2
                    color: symbolClearMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: Theme.borderWidth
                    border.color: Theme.danger
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.danger
                        font.pixelSize: Theme.smallPx
                        font.bold: true
                    }
                    MouseArea {
                        id: symbolClearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.symbolEdited(root.slotIndex, "")

                        HoverTip {
                            message: "Clear the symbol"
                            show: symbolClearMouse.containsMouse
                        }
                    }
                }
            }

            Rectangle {
                id: fontButton
                width: {
                    let used = symbolField.width
                    let gaps = 2
                    if (root.special) {
                        used += nameField.width
                    } else {
                        used += grip.width + idField.width + removeBtn.width
                        gaps = 4
                    }
                    return Math.max(Theme.fieldHeight * 3, topRow.width - used - Theme.tabGap * gaps)
                }
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: fontMouse.containsMouse ? Theme.hover : Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: Theme.border
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space
                    anchors.rightMargin: Theme.space
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.fontName.length ? root.fontName : "Bar font"
                    color: Theme.text
                    font.family: root.fontName.length ? root.fontName : Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }
                MouseArea {
                    id: fontMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fontRequested(root.slotIndex)

                    HoverTip {
                        message: "Font for the symbol"
                        show: fontMouse.containsMouse
                    }
                }
            }

            Rectangle {
                id: removeBtn
                visible: !root.special
                width: Theme.chip
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: root.canRemove ? 1 : 0.35
                color: removeMouse.containsMouse ? Theme.hover : "transparent"
                border.width: Theme.borderWidth
                border.color: Theme.danger
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.danger
                    font.pixelSize: Theme.fontPx
                    font.bold: true
                }
                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.canRemove ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.canRemove)
                            root.removeRequested(root.slotIndex)
                    }

                    HoverTip {
                        message: root.canRemove ? "Remove this row and renumber the rows below" : "At least one numbered workspace stays"
                        show: removeMouse.containsMouse
                    }
                }
            }
        }

        Row {
            id: faceRow
            width: parent.width
            height: Theme.fieldHeight
            spacing: Theme.tabGap

            TextField {
                id: labelField
                width: Math.max(Theme.fieldHeight, faceRow.width - styleRow.width - faceRow.spacing)
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                placeholderText: "label"
                leftPadding: Theme.space
                rightPadding: labelClear.visible ? Theme.chip : Theme.space
                color: root.labelColor.length ? root.labelColor : Theme.text
                placeholderTextColor: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: root.bold
                font.italic: root.italic
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: root.fieldBg(labelField.activeFocus)
                    border.width: Theme.borderWidth
                    border.color: labelField.activeFocus ? Theme.accent : Theme.border
                }
                onEditingFinished: {
                    if (text !== root.label)
                        root.labelEdited(root.slotIndex, text)
                }

                HoverHandler {
                    id: labelHover
                }

                HoverTip {
                    message: "Label beside the symbol"
                    show: labelHover.hovered && !labelClearMouse.containsMouse
                }

                Rectangle {
                    id: labelClear
                    visible: labelField.text.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.borderWidth * 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.iconPx
                    height: Theme.iconPx
                    radius: Theme.iconPx / 2
                    color: labelClearMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: Theme.borderWidth
                    border.color: Theme.danger
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.danger
                        font.pixelSize: Theme.smallPx
                        font.bold: true
                    }
                    MouseArea {
                        id: labelClearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.labelEdited(root.slotIndex, "")

                        HoverTip {
                            message: "Clear the label"
                            show: labelClearMouse.containsMouse
                        }
                    }
                }
            }

            Row {
                id: styleRow
                height: Theme.fieldHeight
                spacing: Theme.wsGap

                Rectangle {
                    width: Theme.chip + Theme.borderWidth * 4
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: root.labelColor.length ? root.labelColor : Theme.text
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    MouseArea {
                        id: colorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton)
                                root.colorCleared(root.slotIndex)
                            else
                                root.colorRequested(root.slotIndex)
                        }

                        HoverTip {
                            message: "Label color. Right-click clears it."
                            show: colorMouse.containsMouse
                        }
                    }
                }
                Rectangle {
                    width: Theme.chip + Theme.borderWidth * 4
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: root.bold ? Theme.accentDim : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: root.bold ? Theme.accent : Theme.border
                    Text { anchors.centerIn: parent; text: "B"; color: Theme.text; font.bold: true; font.family: Theme.uiFont }
                    MouseArea {
                        id: boldMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.boldEdited(root.slotIndex, !root.bold)

                        HoverTip {
                            message: "Bold the symbol and the label"
                            show: boldMouse.containsMouse
                        }
                    }
                }
                Rectangle {
                    width: Theme.chip + Theme.borderWidth * 4
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: root.italic ? Theme.accentDim : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: root.italic ? Theme.accent : Theme.border
                    Text { anchors.centerIn: parent; text: "I"; color: Theme.text; font.italic: true; font.family: Theme.uiFont }
                    MouseArea {
                        id: italicMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.italicEdited(root.slotIndex, !root.italic)

                        HoverTip {
                            message: "Italic the symbol and the label"
                            show: italicMouse.containsMouse
                        }
                    }
                }
                Rectangle {
                    width: Theme.chip
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: sizeDownMouse.containsMouse ? Theme.hover : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    Text { anchors.centerIn: parent; text: "−"; color: Theme.text }
                    MouseArea {
                        id: sizeDownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sizeEdited(root.slotIndex, Math.max(8, root.displayPx - 1))

                        HoverTip {
                            message: "Smaller symbol"
                            show: sizeDownMouse.containsMouse
                        }
                    }
                }
                Text {
                    width: Theme.chip
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: String(root.displayPx)
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx

                    HoverHandler {
                        id: sizeHover
                    }

                    HoverTip {
                        message: "Symbol size"
                        show: sizeHover.hovered
                    }
                }
                Rectangle {
                    width: Theme.chip
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: sizeUpMouse.containsMouse ? Theme.hover : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                    Text { anchors.centerIn: parent; text: "+"; color: Theme.text }
                    MouseArea {
                        id: sizeUpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sizeEdited(root.slotIndex, Math.min(32, root.displayPx + 1))

                        HoverTip {
                            message: "Larger symbol"
                            show: sizeUpMouse.containsMouse
                        }
                    }
                }
            }
        }
    }
}
