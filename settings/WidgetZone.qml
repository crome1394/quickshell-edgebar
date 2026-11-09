pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.theme

Column {
    id: root

    required property string zone
    required property string title
    required property string hint
    required property bool dragging
    required property string dragId
    required property real sceneX
    required property real sceneY

    signal rowDragged(string widgetId, real x, real y)
    signal rowDropped(bool commit)

    readonly property var entries: WidgetService.zoneEntries(root.zone)
    readonly property int contentWidth: Math.max(1, root.width - Theme.space * 2)
    readonly property int accentWidth: Theme.dividerThickness + Theme.borderWidth
    // M, then L C R.
    readonly property int alignChipsWidth: (4 * Theme.chip) + (3 * Theme.tabGap)
    readonly property string monitor: WidgetService.barMonitor(root.zone)
    readonly property var monitorChoices: [{ id: "", label: "Every bar monitor", detail: "The monitors picked under Monitors below" }]
        .concat(Quickshell.screens.map((s) => ({
            id: String(s.name),
            label: String(s.name),
            detail: s.width + "×" + s.height + (String(s.name) === ScreenService.mainName ? " · main" : "")
        })))
    readonly property bool alongHorizontal: root.zone === "top" || root.zone === "bottom"
    readonly property var alignChoices: root.alongHorizontal
        ? [
            { id: "left", label: "L", tip: "Align left" },
            { id: "center", label: "C", tip: "Align center" },
            { id: "right", label: "R", tip: "Align right" }
        ]
        : [
            { id: "left", label: "L", tip: "Top of the screen" },
            { id: "center", label: "C", tip: "Align center" },
            { id: "right", label: "R", tip: "Bottom of the screen" }
        ]
    readonly property string spanTip: root.alongHorizontal
        ? "Span the monitor width"
        : "Span the height of the screen"
    readonly property int dropIndex: {
        if (!root.dragging || root.dragId.length === 0)
            return -1
        return root.indexAt(root.sceneX, root.sceneY)
    }
    readonly property int markerY: {
        if (root.dropIndex < 0)
            return 0
        const count = root.entries.length
        const stop = Math.min(root.dropIndex, count)
        let cursor = 0
        for (let i = 0; i < stop; i++)
            cursor += Theme.dividerRowHeight + Theme.tabGap
        return Math.max(0, cursor - Math.floor(Theme.tabGap / 2))
    }

    function indexAt(sceneX, sceneY) {
        const local = root.mapFromItem(null, sceneX, sceneY)
        if (local.x < 0 || local.y < 0 || local.x > root.width || local.y > root.height)
            return -1
        const rows = listCol.mapFromItem(null, sceneX, sceneY)
        const count = root.entries.length
        if (count === 0 || rows.y <= 0)
            return 0
        let cursor = 0
        for (let i = 0; i < count; i++) {
            if (rows.y < cursor + Theme.dividerRowHeight / 2)
                return i
            cursor += Theme.dividerRowHeight + Theme.tabGap
        }
        return count
    }

    spacing: Theme.space

    Item {
        id: head
        width: parent.width
        readonly property int titleBand: Math.max(1, Math.floor((head.width - root.alignChipsWidth) / 2) - root.accentWidth - Theme.space * 2)
        implicitHeight: Math.max(Theme.fieldHeight, titleSide.implicitHeight)
        height: implicitHeight

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: Theme.sectionBg
        }

        Row {
            id: titleSide
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Theme.tabGap
            spacing: Theme.space

            Rectangle {
                width: root.accentWidth
                height: Theme.fieldHeight
                radius: Theme.borderWidth
                color: Theme.accent
            }

            Column {
                width: head.titleBand
                spacing: 1

                Row {
                    id: titleRow
                    spacing: Theme.tabGap
                    width: Math.min(head.titleBand, titleText.implicitWidth + countBadge.width + Theme.tabGap)

                    Text {
                        id: titleText
                        width: Math.max(1, titleRow.width - countBadge.width - Theme.tabGap)
                        height: Theme.badgeHeight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.title
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: true
                    }

                    Rectangle {
                        id: countBadge
                        width: Math.max(Theme.badgeHeight, countText.implicitWidth + Theme.space)
                        height: Theme.badgeHeight
                        radius: height / 2
                        color: Theme.accentDim
                        border.width: Theme.borderWidth
                        border.color: Theme.accent

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: String(root.entries.length)
                            color: Theme.accent
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                            font.bold: true
                        }
                    }
                }

                Text {
                    width: head.titleBand
                    wrapMode: Text.WordWrap
                    text: root.hint
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: (Theme.fieldHeight - Theme.chip) / 2
            spacing: Theme.tabGap

            // M: which monitor this bar is on.
            Rectangle {
                id: monitorChip
                readonly property bool selected: root.monitor.length > 0

                width: Theme.chip
                height: Theme.chip
                radius: Theme.radiusSm
                color: monitorChip.selected || monitorPopup.opened ? Theme.accentDim : Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: monitorChip.selected || monitorPopup.opened ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "M"
                    color: monitorChip.selected ? Theme.wsActiveText : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: monitorChip.selected
                }

                MouseArea {
                    id: monitorMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: monitorPopup.opened ? monitorPopup.close() : monitorPopup.open()
                }

                HoverTip {
                    message: "Monitor: " + (root.monitor.length ? root.monitor : "every bar monitor") + ". Apply saves it."
                    show: monitorMouse.containsMouse && !monitorPopup.opened
                }

                Popup {
                    id: monitorPopup
                    y: monitorChip.height + Theme.tabGap
                    x: Math.min(0, root.width / 2 - width / 2)
                    width: Theme.fieldHeight * 8
                    padding: Theme.tabGap
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: Theme.pageBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                    }

                    contentItem: Column {
                        spacing: Theme.tabGap

                        Text {
                            width: parent.width
                            text: root.title + " on"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Repeater {
                            model: root.monitorChoices
                            delegate: Rectangle {
                                id: option
                                required property var modelData
                                readonly property bool chosen: root.monitor === String(option.modelData.id)

                                width: parent.width
                                height: optionText.implicitHeight + Theme.space
                                radius: Theme.radiusSm
                                color: option.chosen ? Theme.accentDim : (optionMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: option.chosen ? Theme.accent : "transparent"

                                Column {
                                    id: optionText
                                    x: Theme.space
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Theme.space * 2

                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: (option.chosen ? "✓ " : "") + String(option.modelData.label)
                                        color: option.chosen ? Theme.wsActiveText : Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.fontPx
                                        font.bold: option.chosen
                                    }

                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: String(option.modelData.detail)
                                        color: Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                    }
                                }

                                MouseArea {
                                    id: optionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        WidgetService.setBarMonitor(root.zone, String(option.modelData.id))
                                        monitorPopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.alignChoices
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    readonly property string choice: String(chip.modelData.id || "")
                    readonly property bool selected: WidgetService.barAlign(root.zone) === chip.choice

                    width: Theme.chip
                    height: Theme.chip
                    radius: Theme.radiusSm
                    color: chip.selected ? Theme.accentDim : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: chip.selected ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: String(chip.modelData.label || "")
                        color: chip.selected ? Theme.wsActiveText : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                        font.bold: chip.selected
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetService.setBarAlign(root.zone, chip.choice)
                    }

                    HoverTip {
                        message: String(chip.modelData.tip || "")
                        show: chipMouse.containsMouse
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Theme.tabGap
            spacing: Theme.tabGap

            Item {
                width: Theme.chip
                height: Theme.fieldHeight

                Rectangle {
                    id: spanChip
                    readonly property bool selected: WidgetService.barSpans(root.zone)

                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.chip
                    height: Theme.chip
                    radius: Theme.radiusSm
                    color: spanChip.selected ? Theme.accentDim : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: spanChip.selected ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "S"
                        color: spanChip.selected ? Theme.wsActiveText : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                        font.bold: spanChip.selected
                    }

                    MouseArea {
                        id: spanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetService.setBarSpans(root.zone, !WidgetService.barSpans(root.zone))
                    }

                    HoverTip {
                        message: root.spanTip
                        show: spanMouse.containsMouse
                    }
                }
            }

            Item {
                width: Theme.chip
                height: Theme.fieldHeight

                Rectangle {
                    id: hideChip
                    readonly property bool selected: WidgetService.barAutoHides(root.zone)

                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.chip
                    height: Theme.chip
                    radius: Theme.radiusSm
                    color: hideChip.selected ? Theme.accentDim : Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: hideChip.selected ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "H"
                        color: hideChip.selected ? Theme.wsActiveText : Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                        font.bold: hideChip.selected
                    }

                    MouseArea {
                        id: hideMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetService.setBarAutoHides(root.zone, !WidgetService.barAutoHides(root.zone))
                    }

                    HoverTip {
                        message: hideChip.selected
                            ? "Auto-hide is on: the bar slides away and comes back when the pointer touches this edge"
                            : "Auto-hide: slide this bar away until the pointer touches its edge"
                        show: hideMouse.containsMouse
                    }
                }
            }

            Item {
                width: Theme.toggleWidth
                height: Theme.fieldHeight

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.toggleWidth
                    height: Theme.chip
                    radius: Theme.radiusSm
                    color: enableMouse.containsMouse ? Theme.hover : "transparent"
                    border.width: Theme.borderWidth
                    border.color: WidgetService.barEnabled(root.zone) ? Theme.ok : Theme.danger

                    Text {
                        anchors.centerIn: parent
                        text: WidgetService.barEnabled(root.zone) ? "✓" : "✕"
                        color: WidgetService.barEnabled(root.zone) ? Theme.ok : Theme.danger
                        font.pixelSize: Theme.fontPx
                        font.bold: true
                    }

                    MouseArea {
                        id: enableMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetService.setBarEnabled(root.zone, !WidgetService.barEnabled(root.zone))
                    }

                    HoverTip {
                        message: "Enable bar"
                        show: enableMouse.containsMouse
                    }
                }
            }
        }
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: inner.implicitHeight + Theme.space * 2
        radius: Theme.radius
        color: Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: root.dropIndex >= 0 ? Theme.accent : Theme.border

        Column {
            id: inner
            x: Theme.space
            y: Theme.space
            width: root.contentWidth
            spacing: Theme.tabGap

            Item {
                id: listWrap
                width: parent.width
                implicitHeight: listCol.implicitHeight
                height: listCol.implicitHeight

                Column {
                    id: listCol
                    width: parent.width
                    spacing: Theme.tabGap

                    Repeater {
                        model: root.entries
                        delegate: WidgetRow {
                            id: row
                            required property var modelData
                            required property int index

                            width: root.contentWidth
                            widgetId: String(row.modelData.id || "")
                            label: String(row.modelData.label || "")
                            shown: WidgetService.editorVisible(row.widgetId)
                            divider: !!row.modelData.divider
                            percent: WidgetService.scalePercent(row.widgetId)
                            onToggled: WidgetService.toggle(row.widgetId)
                            onScaleEdited: (value) => WidgetService.setScale(row.widgetId, value)
                            onDragAt: (widgetId, x, y) => root.rowDragged(widgetId, x, y)
                            onDragFinished: (commit) => root.rowDropped(commit)
                        }
                    }

                    Text {
                        visible: root.entries.length === 0
                        width: parent.width
                        height: Theme.fieldHeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        text: "Nothing here yet. Drag a row here by ||."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }

                Rectangle {
                    visible: root.dropIndex >= 0
                    y: root.markerY
                    width: parent.width
                    height: Theme.dividerThickness
                    radius: Theme.borderWidth
                    color: Theme.accent
                    z: 1
                }
            }
        }
    }
}
