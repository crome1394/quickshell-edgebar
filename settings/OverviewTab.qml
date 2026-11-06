pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// Settings → Bar → Overview. The overlay reads saved options until Apply.
Item {
    id: root

    readonly property bool twoCol: width >= Theme.settingsTwoColMin
    readonly property real sliderPitch: labelProbe.implicitHeight + Theme.borderWidth + Theme.fieldHeight + Theme.space
    readonly property real flagPitch: flagProbe.implicitHeight + Theme.space

    function colCount(wide) {
        return wide ? 2 : 1
    }

    function cellWidth(span, wide) {
        if (!wide)
            return span
        return (span - Theme.space) / 2
    }

    function cellX(index, span, wide) {
        if (!wide)
            return 0
        return (index % 2) * (root.cellWidth(span, true) + Theme.space)
    }

    function cellY(index, pitch, wide) {
        return Math.floor(index / root.colCount(wide)) * pitch
    }

    function gridHeight(count, pitch, wide) {
        if (count <= 0)
            return 0
        const rows = Math.ceil(count / root.colCount(wide))
        return rows * pitch - Theme.space
    }

    function sliderReadout(entry) {
        const scale = Number(entry.scale) || 1
        const n = OverviewSettings.draftInt(String(entry.key || ""), scale)
        const suffix = String(entry.suffix || "")
        if (scale === 100)
            return (n / 100).toFixed(2) + suffix
        return String(n) + suffix
    }

    Text {
        id: labelProbe
        visible: false
        text: "Ag"
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    CheckRow {
        id: flagProbe
        visible: false
        width: Theme.fieldHeight
        title: "Probe"
        detail: "Probe"
        checked: false
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
                title: "Overview"
                hint: "Apply saves this page. The overlay keeps the last saved options until then."
            }

            Item {
                width: parent.width
                height: introCol.implicitHeight

                Column {
                    id: introCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Super+Tab opens the workspace overview. Super+Shift+Tab opens desktop layout, with windows in place and close buttons. Super+Ctrl+Tab opens every workspace. Inside: Tab and Shift+Tab move between cards, arrows select a window, Enter focuses it, D closes the selected window, A toggles all workspaces, a bare Shift flips desktop layout, 1–9 and 0 pick a strip card, the wheel steps cards, and Esc or a click on empty space closes without switching. Press Super+Tab again to go to the workspace you are viewing (except All). Drag a window onto a card to move it. In grid layout, drop one preview on another to swap them."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "IPC: qs ipc call overview toggle | open | desktop | all | next | prev | close. toggle goes to the viewed workspace; close stays put."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Layout"
                hint: "Rows packs previews at their real aspect. Grid uses equal cells. Natural keeps each window where it sits on the desktop."
            }

            Item {
                width: parent.width
                height: layoutCol.implicitHeight

                Column {
                    id: layoutCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Item {
                        id: layoutChoices
                        width: parent.width
                        height: Theme.fieldHeight

                        Repeater {
                            model: [
                                { id: "rows", label: "Rows", tip: "Pack previews at their real aspect" },
                                { id: "grid", label: "Grid", tip: "Equal cells" },
                                { id: "natural", label: "Natural", tip: "Keep each window where it sits on the desktop" }
                            ]
                            delegate: Rectangle {
                                id: layoutChip
                                required property var modelData
                                required property int index
                                readonly property string chipId: String(layoutChip.modelData.id || "")
                                readonly property bool chosen: OverviewSettings.editor.value.ovLayout === layoutChip.chipId
                                readonly property int count: 3

                                x: layoutChip.index * (layoutChip.width + Theme.tabGap)
                                width: (layoutChoices.width - Theme.tabGap * (layoutChip.count - 1)) / layoutChip.count
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: layoutChip.chosen ? Theme.accentDim : (layoutMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: layoutChip.chosen ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String(layoutChip.modelData.label || "")
                                    color: layoutChip.chosen ? Theme.wsActiveText : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: layoutChip.chosen
                                }

                                MouseArea {
                                    id: layoutMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: OverviewSettings.editor.set("ovLayout", layoutChip.chipId)

                                    HoverTip {
                                        message: String(layoutChip.modelData.tip || "")
                                        show: layoutMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Workspace strip"
                hint: "Height is the strip on the top or bottom. Width is the strip on the left or right. Card length is how wide each card is on a top or bottom strip, and how tall it is on a left or right strip."
            }

            Item {
                width: parent.width
                height: stripCol.implicitHeight

                Column {
                    id: stripCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Item {
                        id: anchorChoices
                        width: parent.width
                        height: Theme.fieldHeight

                        Repeater {
                            model: [
                                { id: "top", label: "Top", tip: "Pin the strip to the top edge" },
                                { id: "bottom", label: "Bottom", tip: "Pin the strip to the bottom edge" },
                                { id: "left", label: "Left", tip: "Pin the strip to the left edge" },
                                { id: "right", label: "Right", tip: "Pin the strip to the right edge" }
                            ]
                            delegate: Rectangle {
                                id: anchorChip
                                required property var modelData
                                required property int index
                                readonly property string chipId: String(anchorChip.modelData.id || "")
                                readonly property bool chosen: OverviewSettings.editor.value.ovAnchor === anchorChip.chipId
                                readonly property int count: 4

                                x: anchorChip.index * (anchorChip.width + Theme.tabGap)
                                width: (anchorChoices.width - Theme.tabGap * (anchorChip.count - 1)) / anchorChip.count
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: anchorChip.chosen ? Theme.accentDim : (anchorMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: anchorChip.chosen ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String(anchorChip.modelData.label || "")
                                    color: anchorChip.chosen ? Theme.wsActiveText : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: anchorChip.chosen
                                }

                                MouseArea {
                                    id: anchorMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: OverviewSettings.editor.set("ovAnchor", anchorChip.chipId)

                                    HoverTip {
                                        message: String(anchorChip.modelData.tip || "")
                                        show: anchorMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: stripGrid
                        width: parent.width
                        height: root.gridHeight(stripRepeater.count, root.sliderPitch, root.twoCol)

                        Repeater {
                            id: stripRepeater
                            model: [
                                { key: "ovStripHeight", label: "Strip height (top or bottom)", from: 72, to: 640, step: 1, suffix: " px", tip: "How thick the strip is when it sits on the top or bottom" },
                                { key: "ovStripWidth", label: "Strip width (left or right)", from: 72, to: 640, step: 1, suffix: " px", tip: "How thick the strip is when it sits on the left or right" },
                                { key: "ovStripCardMax", label: "Card length", from: 160, to: 960, step: 1, suffix: " px", tip: "How long each workspace card can grow along the strip" },
                                { key: "ovStripGap", label: "Card spacing", from: 0, to: 64, step: 1, suffix: " px", tip: "Space between workspace cards" },
                                { key: "ovStripMargin", label: "Strip padding", from: 0, to: 64, step: 1, suffix: " px", tip: "Padding inside the strip around the cards" },
                                { key: "ovStripOffset", label: "Inset from the screen edge", from: 0, to: 120, step: 1, suffix: " px", tip: "How far the strip sits in from the screen edge" },
                                { key: "ovStripCardRound", label: "Card corner radius", from: 0, to: 28, step: 1, suffix: " px", tip: "Corner radius of each workspace card" }
                            ]
                            delegate: Column {
                                id: stripCell
                                required property var modelData
                                required property int index
                                x: root.cellX(stripCell.index, stripGrid.width, root.twoCol)
                                y: root.cellY(stripCell.index, root.sliderPitch, root.twoCol)
                                width: root.cellWidth(stripGrid.width, root.twoCol)
                                spacing: Theme.borderWidth

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: String(stripCell.modelData.label || "")
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }

                                IntSlider {
                                    width: parent.width
                                    from: stripCell.modelData.from
                                    to: stripCell.modelData.to
                                    step: stripCell.modelData.step
                                    value: OverviewSettings.draftInt(String(stripCell.modelData.key || ""), 1)
                                    readout: root.sliderReadout(stripCell.modelData)
                                    tip: String(stripCell.modelData.tip || "")
                                    onChanged: (value) => OverviewSettings.setScaled(String(stripCell.modelData.key || ""), value, 1)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Previews"
                hint: "Size, dim, and what is drawn on each window preview."
            }

            Item {
                width: parent.width
                height: previewCol.implicitHeight

                Column {
                    id: previewCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Item {
                        id: previewGrid
                        width: parent.width
                        height: root.gridHeight(previewRepeater.count, root.sliderPitch, root.twoCol)

                        Repeater {
                            id: previewRepeater
                            model: [
                                { key: "ovGap", label: "Gap between windows", from: 0, to: 120, step: 1, scale: 1, suffix: " px", tip: "Space between window previews" },
                                { key: "ovPadding", label: "Side margin", from: 0, to: 200, step: 1, scale: 1, suffix: " px", tip: "Margin on the sides that do not hold the strip" },
                                { key: "ovPaddingTop", label: "Gap beside the strip", from: 0, to: 160, step: 1, scale: 1, suffix: " px", tip: "Margin between the previews and the workspace strip" },
                                { key: "ovPaddingBottom", label: "Outer margin opposite the strip", from: 0, to: 160, step: 1, scale: 1, suffix: " px", tip: "Margin on the screen edge opposite the strip" },
                                { key: "ovMaxScale", label: "Max scale vs real size", from: 20, to: 150, step: 5, scale: 100, suffix: "×", tip: "Largest a preview can grow compared with the real window" },
                                { key: "ovPreviewRound", label: "Preview corner radius", from: 0, to: 32, step: 1, scale: 1, suffix: " px", tip: "Corner radius of each window preview" },
                                { key: "ovBlur", label: "Backdrop dim", from: 0, to: 100, step: 5, scale: 100, suffix: "", tip: "How dark the desktop is behind the overview" },
                                { key: "ovHoverBorder", label: "Hover border", from: 0, to: 8, step: 1, scale: 1, suffix: " px", tip: "Border drawn while the pointer is over a preview" },
                                { key: "ovSelectBorder", label: "Keyboard selection border", from: 0, to: 8, step: 1, scale: 1, suffix: " px", tip: "Border drawn on the preview selected from the keyboard" }
                            ]
                            delegate: Column {
                                id: previewCell
                                required property var modelData
                                required property int index
                                readonly property int sliderScale: Number(previewCell.modelData.scale) || 1
                                x: root.cellX(previewCell.index, previewGrid.width, root.twoCol)
                                y: root.cellY(previewCell.index, root.sliderPitch, root.twoCol)
                                width: root.cellWidth(previewGrid.width, root.twoCol)
                                spacing: Theme.borderWidth

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: String(previewCell.modelData.label || "")
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }

                                IntSlider {
                                    width: parent.width
                                    from: previewCell.modelData.from
                                    to: previewCell.modelData.to
                                    step: previewCell.modelData.step
                                    value: OverviewSettings.draftInt(String(previewCell.modelData.key || ""), previewCell.sliderScale)
                                    readout: root.sliderReadout(previewCell.modelData)
                                    tip: String(previewCell.modelData.tip || "")
                                    onChanged: (value) => OverviewSettings.setScaled(String(previewCell.modelData.key || ""), value, previewCell.sliderScale)
                                }
                            }
                        }
                    }

                    Item {
                        id: previewFlags
                        width: parent.width
                        height: root.gridHeight(previewFlagRepeater.count, root.flagPitch, root.twoCol)

                        Repeater {
                            id: previewFlagRepeater
                            model: [
                                { key: "ovBackdropBlur", title: "Blur the desktop", detail: "Blur what is behind the overview while it is open. The dim slider still darkens it.", tip: "Blur the desktop behind the overview while it is open" },
                                { key: "ovLivePreviews", title: "Live window previews", detail: "Off grabs a still frame. On follows the window while the overview is open.", tip: "Follow the window while the overview is open, or grab one frame" },
                                { key: "ovStripPreviews", title: "Strip previews", detail: "Window thumbnails inside the workspace cards. Off leaves the cards empty.", tip: "Draw window thumbnails inside the workspace cards" },
                                { key: "ovShowWindowLabels", title: "Window titles", detail: "Show the title under the hovered or selected preview.", tip: "Show the title under the hovered or selected preview" },
                                { key: "ovShowWsLabels", title: "Workspace labels", detail: "Names above the strip cards. Off gives the cards that space.", tip: "Show names above the strip cards" },
                                { key: "ovNumberLabels", title: "Use workspace numbers", detail: "Replace the emoji and name from the workspace widget with the workspace number.", tip: "Show the workspace number instead of the emoji and name" }
                            ]
                            delegate: CheckRow {
                                id: previewFlag
                                required property var modelData
                                required property int index
                                readonly property string flagKey: String(previewFlag.modelData.key || "")
                                x: root.cellX(previewFlag.index, previewFlags.width, root.twoCol)
                                y: root.cellY(previewFlag.index, root.flagPitch, root.twoCol)
                                width: root.cellWidth(previewFlags.width, root.twoCol)
                                title: String(previewFlag.modelData.title || "")
                                detail: String(previewFlag.modelData.detail || "")
                                tip: String(previewFlag.modelData.tip || "")
                                checked: !!OverviewSettings.editor.value[previewFlag.flagKey]
                                onToggled: OverviewSettings.editor.set(previewFlag.flagKey, !previewFlag.checked)
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Motion"
                hint: "How the overview opens, how cards slide, and how a dropped window flies to its card."
            }

            Item {
                width: parent.width
                height: motionCol.implicitHeight

                Column {
                    id: motionCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "Open and close"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 800
                        step: 1
                        value: OverviewSettings.draftInt("ovDuration", 1)
                        readout: OverviewSettings.draftInt("ovDuration", 1) + " ms"
                        tip: "How long the overview takes to open and close"
                        onChanged: (value) => OverviewSettings.setScaled("ovDuration", value, 1)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Slide between workspaces"
                        detail: "The preview area slides when Tab, the wheel, or a card changes the workspace."
                        tip: "Slide the preview area when the workspace card changes"
                        checked: !!OverviewSettings.editor.value.ovSwitchAnimation
                        onToggled: OverviewSettings.editor.set("ovSwitchAnimation", !OverviewSettings.editor.value.ovSwitchAnimation)
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "Slide length"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 800
                        step: 1
                        value: OverviewSettings.draftInt("ovSwitchDuration", 1)
                        readout: OverviewSettings.draftInt("ovSwitchDuration", 1) + " ms"
                        tip: "How long the slide between workspaces takes"
                        onChanged: (value) => OverviewSettings.setScaled("ovSwitchDuration", value, 1)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Fly a dropped window into its card"
                        detail: "The preview shrinks toward the workspace card after a drag."
                        tip: "Animate a dropped window toward the workspace card"
                        checked: !!OverviewSettings.editor.value.ovMoveAnimation
                        onToggled: OverviewSettings.editor.set("ovMoveAnimation", !OverviewSettings.editor.value.ovMoveAnimation)
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "Flight length"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 800
                        step: 1
                        value: OverviewSettings.draftInt("ovMoveDuration", 1)
                        readout: OverviewSettings.draftInt("ovMoveDuration", 1) + " ms"
                        tip: "How long the flight into a workspace card takes"
                        onChanged: (value) => OverviewSettings.setScaled("ovMoveDuration", value, 1)
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Workspaces"
                hint: "Show only active workspace, in the workspace options, hides empty cards here and keeps the next blank one."
            }

            Item {
                width: parent.width
                height: wsFlags.implicitHeight

                Item {
                    id: wsFlags
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    height: root.gridHeight(wsFlagRepeater.count, root.flagPitch, root.twoCol)

                    Repeater {
                        id: wsFlagRepeater
                        model: [
                            { key: "ovDynamic", title: "Dynamic workspaces", detail: "List populated workspaces and one empty card at the end. A window has to land there before another empty card appears.", tip: "List populated workspaces and one empty card at the end" },
                            { key: "ovAutodelete", title: "Hide emptied workspaces", detail: "With dynamic workspaces, drop emptied ones from the strip. Persistent slot cards stay.", tip: "Drop emptied workspaces that are not persistent slots" },
                            { key: "ovShowEmpty", title: "Show empty workspaces", detail: "When dynamic workspaces is off, keep empty ones as cards.", tip: "Keep empty workspaces as cards when dynamic workspaces is off" },
                            { key: "ovShowSpecial", title: "Show the special workspace", detail: "Add the configured special workspace as a strip card.", tip: "Add the configured special workspace as a strip card" },
                            { key: "ovStripAllCard", title: "All-workspaces card", detail: "Leading strip card that shows every window on this monitor.", tip: "Add a leading card that shows every window on this monitor" },
                            { key: "ovShowAll", title: "Open into all workspaces", detail: "Super+Tab starts in the all-workspaces view.", tip: "Super+Tab starts in the all-workspaces view" },
                            { key: "ovSwitchOnNew", title: "Follow a new workspace", detail: "Clicking the empty card creates it and moves the overview there.", tip: "Clicking the empty card creates it and moves the overview there" },
                            { key: "ovSwitchOnDrop", title: "Follow a dropped window", detail: "Dropping a window on a card also switches to that workspace.", tip: "Switch the overview to a card when a window is dropped on it" },
                            { key: "ovDragToSwap", title: "Drag to swap in grid layout", detail: "Dropping a preview onto another swaps the two windows.", tip: "In grid layout, drop one preview on another to swap them" }
                        ]
                        delegate: CheckRow {
                            id: wsFlag
                            required property var modelData
                            required property int index
                            readonly property string flagKey: String(wsFlag.modelData.key || "")
                            x: root.cellX(wsFlag.index, wsFlags.width, root.twoCol)
                            y: root.cellY(wsFlag.index, root.flagPitch, root.twoCol)
                            width: root.cellWidth(wsFlags.width, root.twoCol)
                            title: String(wsFlag.modelData.title || "")
                            detail: String(wsFlag.modelData.detail || "")
                            tip: String(wsFlag.modelData.tip || "")
                            checked: !!OverviewSettings.editor.value[wsFlag.flagKey]
                            onToggled: OverviewSettings.editor.set(wsFlag.flagKey, !wsFlag.checked)
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Input"
                hint: "Pointer, wheel, and what dismisses the overview."
            }

            Item {
                width: parent.width
                height: inputFlags.implicitHeight

                Item {
                    id: inputFlags
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    height: root.gridHeight(inputFlagRepeater.count, root.flagPitch, root.twoCol)

                    Repeater {
                        id: inputFlagRepeater
                        model: [
                            { key: "ovFocusFollowsMouse", title: "Selection follows the pointer", detail: "Hovering a preview selects it for Enter and D.", tip: "Hovering a preview selects it for Enter and D" },
                            { key: "ovScrollSwitches", title: "Wheel switches workspace", detail: "The wheel over the overview steps to the previous or next card.", tip: "The wheel steps to the previous or next card" },
                            { key: "ovExitOnClick", title: "Click empty space to close", detail: "A click that misses windows and cards dismisses the overview.", tip: "A click on empty space dismisses the overview" },
                            { key: "ovExitOnSwitch", title: "Close if the workspace changes", detail: "Dismiss when Hyprland switches workspace underneath the overview.", tip: "Dismiss when Hyprland switches workspace while the overview is open" }
                        ]
                        delegate: CheckRow {
                            id: inputFlag
                            required property var modelData
                            required property int index
                            readonly property string flagKey: String(inputFlag.modelData.key || "")
                            x: root.cellX(inputFlag.index, inputFlags.width, root.twoCol)
                            y: root.cellY(inputFlag.index, root.flagPitch, root.twoCol)
                            width: root.cellWidth(inputFlags.width, root.twoCol)
                            title: String(inputFlag.modelData.title || "")
                            detail: String(inputFlag.modelData.detail || "")
                            tip: String(inputFlag.modelData.tip || "")
                            checked: !!OverviewSettings.editor.value[inputFlag.flagKey]
                            onToggled: OverviewSettings.editor.set(inputFlag.flagKey, !inputFlag.checked)
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
        applyEnabled: OverviewSettings.editor.dirty
        undoEnabled: OverviewSettings.editor.canUndo
        applyTip: "Save the overview layout, strip, previews, motion, workspaces, and input"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the overview options to their defaults. Apply saves them."
        onApplyClicked: OverviewSettings.editor.apply()
        onUndoClicked: OverviewSettings.editor.undo()
        onResetClicked: OverviewSettings.editor.reset()
    }
}
