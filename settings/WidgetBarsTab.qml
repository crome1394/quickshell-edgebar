pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    readonly property int cellWidth: Math.max(1, (width - Theme.sectionInset * 2 - Theme.space) / 2)
    property bool dragging: false
    property string dragId: ""
    property real sceneX: 0
    property real sceneY: 0
    readonly property string dragLabel: {
        if (root.dragId.length === 0)
            return ""
        if (WidgetService.isDivider(root.dragId))
            return "|  Divider " + root.dragId.substring(7)
        return WidgetService.labelFor(root.dragId)
    }
    function noteDrag(widgetId, x, y) {
        root.dragId = widgetId
        root.sceneX = x
        root.sceneY = y
        root.dragging = true
    }

    function noteDrop(commit) {
        const id = root.dragId
        let zone = ""
        let index = -1
        if (topZone.dropIndex >= 0) {
            zone = topZone.zone
            index = topZone.dropIndex
        } else if (leftZone.dropIndex >= 0) {
            zone = leftZone.zone
            index = leftZone.dropIndex
        } else if (bottomZone.dropIndex >= 0) {
            zone = bottomZone.zone
            index = bottomZone.dropIndex
        } else if (rightZone.dropIndex >= 0) {
            zone = rightZone.zone
            index = rightZone.dropIndex
        }
        root.dragging = false
        root.dragId = ""
        if (commit && id.length && zone.length)
            Qt.callLater(() => WidgetService.place(id, zone, index))
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

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Drag a row by || to reorder it or move it onto another bar. Apply saves the layout, sizes, and bar settings. Undo drops an unsaved draft, or puts back the last applied one. Workspaces and the settings icon are drawn on the bar. The other rows keep their place until those widgets are added."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            SectionHeader {
                width: parent.width
                title: "Bar/Widget Positions"
                hint: "L, C, and R align the cluster. On a side bar, L is the top of the screen and R is the bottom. S spans the monitor. H auto-hides the bar. Apply saves these with the rest of this page."
            }

            Item {
                width: 1
                height: Math.max(0, Theme.fieldHeight / 2 - Theme.space)
            }

            Item {
                width: parent.width
                height: zones.implicitHeight

                Grid {
                    id: zones
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    columns: 2
                    columnSpacing: Theme.space
                    rowSpacing: Theme.space

                WidgetZone {
                    id: topZone
                    width: root.cellWidth
                    zone: "top"
                    title: "Top Bar"
                    hint: "Upper strip, left to right"
                    dragging: root.dragging
                    dragId: root.dragId
                    sceneX: root.sceneX
                    sceneY: root.sceneY
                    onRowDragged: (widgetId, x, y) => root.noteDrag(widgetId, x, y)
                    onRowDropped: (commit) => root.noteDrop(commit)
                }
                WidgetZone {
                    id: leftZone
                    width: root.cellWidth
                    zone: "left"
                    title: "Left Bar"
                    hint: "Left edge, top to bottom"
                    dragging: root.dragging
                    dragId: root.dragId
                    sceneX: root.sceneX
                    sceneY: root.sceneY
                    onRowDragged: (widgetId, x, y) => root.noteDrag(widgetId, x, y)
                    onRowDropped: (commit) => root.noteDrop(commit)
                }
                WidgetZone {
                    id: bottomZone
                    width: root.cellWidth
                    zone: "bottom"
                    title: "Bottom Bar"
                    hint: "Lower strip, left to right"
                    dragging: root.dragging
                    dragId: root.dragId
                    sceneX: root.sceneX
                    sceneY: root.sceneY
                    onRowDragged: (widgetId, x, y) => root.noteDrag(widgetId, x, y)
                    onRowDropped: (commit) => root.noteDrop(commit)
                }
                WidgetZone {
                    id: rightZone
                    width: root.cellWidth
                    zone: "right"
                    title: "Right Bar"
                    hint: "Right edge, top to bottom"
                    dragging: root.dragging
                    dragId: root.dragId
                    sceneX: root.sceneX
                    sceneY: root.sceneY
                    onRowDragged: (widgetId, x, y) => root.noteDrag(widgetId, x, y)
                    onRowDropped: (commit) => root.noteDrop(commit)
                }
                }
            }

            Item {
                width: 1
                height: Theme.fieldHeight
            }

            SectionHeader {
                width: parent.width
                title: "Misc"
                hint: "UI Scale Auto follows the monitor width. Uncheck it to set a manual scale. Flush pulls tiled windows up to the bar. Apply saves these with the rest of this page."
            }

            Item {
                width: parent.width
                height: miscGrid.implicitHeight

                Grid {
                    id: miscGrid
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    columns: 2
                    columnSpacing: Theme.space
                    rowSpacing: Theme.space

                Column {
                    width: root.cellWidth
                    spacing: Theme.space

                    CheckRow {
                        width: parent.width
                        title: "UI Scale Auto"
                        detail: "Scale with monitor width (recommended)"
                        checked: WidgetService.uiScaleAuto
                        onToggled: WidgetService.setUiScaleAuto(!WidgetService.uiScaleAuto)
                    }

                    Column {
                        visible: !WidgetService.uiScaleAuto
                        width: parent.width
                        spacing: Theme.tabGap

                        Text {
                            width: parent.width
                            text: "Manual scale"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Row {
                            width: parent.width
                            height: Theme.fieldHeight
                            spacing: Theme.tabGap

                            Text {
                                id: scalePercent
                                width: Math.max(implicitWidth, Theme.chip)
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: WidgetService.uiScalePercent + "%"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            IntSlider {
                                width: parent.width - scalePercent.width - Theme.tabGap
                                from: Math.round(Theme.uiScaleMin * 100)
                                to: Math.round(Theme.uiScaleMax * 100)
                                step: 5
                                value: WidgetService.uiScalePercent
                                onChanged: (value) => WidgetService.setUiScalePercent(value)
                            }
                        }
                    }
                }

                CheckRow {
                    width: root.cellWidth
                    title: "Flush windows to bar"
                    detail: "Close the gap between tiled windows and the bar"
                    checked: WidgetService.flushWindows
                    onToggled: WidgetService.setFlushWindows(!WidgetService.flushWindows)
                }

                CheckRow {
                    width: root.cellWidth
                    title: "Settings menu icon toggle"
                    detail: "Gear pill opens Settings. Hiding it removes that control."
                    checked: WidgetService.editorVisible("controlBar")
                    onToggled: WidgetService.toggle("controlBar")
                }
                }
            }

            Item {
                width: 1
                height: Theme.fieldHeight
            }

            SectionHeader {
                width: parent.width
                title: "Auto-hide"
                hint: "Turn it on per bar with the H chip in that bar's header above. A hidden bar slides off its edge and gives the space back to windows. Touch the edge to bring it back; it stays out while you hover it or one of its menus is open."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Hide after"

                    IntSlider {
                        width: parent.width
                        from: Theme.barHideDelayMin
                        to: Theme.barHideDelayMax
                        step: Theme.barDelayStep
                        value: WidgetService.hideDelay()
                        readout: (WidgetService.hideDelay() / 1000).toFixed(2) + " s"
                        tip: "How long the bar waits after the pointer leaves before it slides away"
                        onChanged: (value) => WidgetService.setHideDelay(value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Show after"

                    IntSlider {
                        width: parent.width
                        from: Theme.barRevealDelayMin
                        to: Theme.barRevealDelayMax
                        step: Theme.barDelayStep
                        value: WidgetService.revealDelay()
                        readout: (WidgetService.revealDelay() / 1000).toFixed(2) + " s"
                        tip: "How long the pointer rests on the edge before the bar comes back. A short wait stops it popping out when you pass the edge."
                        onChanged: (value) => WidgetService.setRevealDelay(value)
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: {
                        const names = { top: "Top", bottom: "Bottom", left: "Left", right: "Right" }
                        const on = BarSettings.edges.filter((e) => WidgetService.barEnabled(e) && WidgetService.barAutoHides(e))
                        return on.length ? "Auto-hiding: " + on.map((e) => names[e]).join(", ") : "No bar auto-hides yet."
                    }
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
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
                { id: "add", label: "Add |" },
                { id: "layout", label: "Reset layout" },
                { id: "sizes", label: "Reset sizes" }
            ]
            delegate: Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property string action: String(button.modelData.id || "")
                readonly property bool enabledAction: {
                    if (button.action === "apply")
                        return WidgetService.editorDirty
                    if (button.action === "undo")
                        return WidgetService.canUndo()
                    if (button.action === "add")
                        return WidgetService.canAddDivider()
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (button.action === "apply")
                            WidgetService.applyEditor()
                        else if (button.action === "undo")
                            WidgetService.undoEditor()
                        else if (button.action === "add")
                            WidgetService.addDivider()
                        else if (button.action === "layout")
                            WidgetService.resetLayout()
                        else
                            WidgetService.resetScales()
                    }
                }
            }
        }
    }
}
