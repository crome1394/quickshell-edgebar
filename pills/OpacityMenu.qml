pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.settings
import qs.theme

// Left-click menu for the Transparency pill. Same choices the pill had:
// bar and menu glass, one level for every window, and a slider per
// override. Laid out like the Tailscale menu. Changes save at once.
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()

    property bool picking: false
    property string addError: ""

    readonly property var overrides: OpacitySettings.savedOverrides().filter((row) => row.on)
    readonly property var overrideClasses: OpacitySettings.savedOverrides().map((row) => row.cls)
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    function stateLine() {
        const n = root.overrides.length
        return "All apps " + OpacitySettings.allValue() + "%" + (n > 0 ? " · " + n + (n === 1 ? " override" : " overrides") : "")
    }

    function togglePicker() {
        root.picking = !root.picking
        root.addError = ""
        if (root.picking)
            OpacityService.listWindows()
    }

    function addPicked(cls, label) {
        if (OpacitySettings.addOverrideLive(cls, label))
            root.addError = ""
        else if (!OpacitySettings.hasOverride(cls))
            root.addError = "No room for more overrides (" + Theme.opacityOverrideMax + " at most)."
    }

    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 2 + Theme.tabGap

    focus: true

    onOpenChanged: {
        if (root.open)
            root.forceActiveFocus()
        else {
            root.picking = false
            root.addError = ""
        }
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = true
        root.closeRequested()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.closeRequested()
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 0
        color: root.theme.colAccent
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.fontPx
        font.bold: true
    }

    component Note: Text {
        width: parent ? parent.width : 0
        wrapMode: Text.WordWrap
        color: root.theme.colFgMuted
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerRow.top
        anchors.margins: Theme.space
        anchors.bottomMargin: Theme.tabGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: column.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: scrollBar.pressed || scrollBar.hovered ? root.theme.colAccent : root.theme.colFgMuted
            }
        }

        Column {
            id: column
            width: Math.max(0, flick.width - root.scrollGutter)
            spacing: Theme.space

            Row {
                width: parent.width
                spacing: Theme.space

                Item {
                    width: root.theme.iconPx
                    height: Theme.fieldHeight

                    Text {
                        anchors.centerIn: parent
                        text: Theme.opacityGlyph
                        color: root.theme.colAccent
                        font.family: root.theme.iconFont
                        font.pixelSize: root.theme.iconPx
                    }
                }

                Text {
                    width: parent.width - root.theme.iconPx - closeBox.width - Theme.space * 2
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: "Transparency · " + root.stateLine()
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeBox
                    width: Theme.fieldHeight
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: closeMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: root.theme.colBorder

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Note {
                visible: OpacityService.error.length > 0
                text: OpacityService.error
                color: root.theme.colDanger
            }

            Rectangle {
                width: parent.width
                implicitHeight: glassCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: glassCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "Glass"
                    }

                    Text {
                        width: parent.width
                        text: "Bar"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    IntSlider {
                        width: parent.width
                        from: 0
                        to: 100
                        step: Theme.themeGlassStep
                        value: ThemeStore.glass.bar
                        readout: ThemeStore.glass.bar + "%"
                        tip: "How solid the bar is (every bar without its own glass). 100 is solid."
                        onChanged: (value) => OpacitySettings.setGlassLive("bar", value)
                    }

                    Text {
                        width: parent.width
                        text: "Menus"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    IntSlider {
                        width: parent.width
                        from: Theme.themeMenuGlassMin
                        to: 100
                        step: Theme.themeGlassStep
                        value: ThemeStore.glass.menu
                        readout: ThemeStore.glass.menu + "%"
                        tip: "Menus, Settings, readers, and popups. 100 is solid."
                        onChanged: (value) => OpacitySettings.setGlassLive("menu", value)
                    }

                    Note {
                        text: "100 is solid."
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: appsCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: appsCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "All applications"
                    }

                    IntSlider {
                        width: parent.width
                        from: Theme.opacityMin
                        to: Theme.opacityMax
                        step: Theme.opacityStep
                        value: OpacitySettings.allValue()
                        readout: OpacitySettings.allValue() + "%"
                        tip: "Every window, " + Theme.opacityMin + " to " + Theme.opacityMax + "%. 100 is solid."
                        onChanged: (value) => OpacitySettings.setAllLive(value)
                    }

                    Note {
                        text: "Settings and fullscreen windows stay solid. An override's unfocused level is edited in Settings → System → Transparency."
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: overCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: overCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: root.overrides.length > 0 ? "Overrides · " + root.overrides.length : "Overrides"
                    }

                    Note {
                        visible: root.overrides.length === 0
                        text: "None yet. Add one for a window that should differ from every other app."
                    }

                    Repeater {
                        model: root.overrides
                        delegate: Column {
                            id: overrideRow
                            required property var modelData
                            width: overCol.width
                            spacing: Theme.borderWidth

                            Row {
                                width: parent.width
                                spacing: Theme.space

                                Text {
                                    width: parent.width - removeBox.width - Theme.space
                                    height: Theme.chip
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: overrideRow.modelData.label
                                        + (overrideRow.modelData.active !== overrideRow.modelData.inactive
                                            ? "  ·  unfocused " + overrideRow.modelData.inactive + "%" : "")
                                    color: root.theme.colFg
                                    font.family: root.theme.uiFont
                                    font.pixelSize: root.theme.smallPx
                                }

                                Rectangle {
                                    id: removeBox
                                    width: Theme.chip
                                    height: Theme.chip
                                    radius: Theme.radiusSm
                                    color: removeMouse.containsMouse ? root.theme.colHover : "transparent"
                                    border.width: Theme.borderWidth
                                    border.color: removeMouse.containsMouse ? root.theme.colDanger : root.theme.colBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: removeMouse.containsMouse ? root.theme.colDanger : root.theme.colFgMuted
                                        font.family: root.theme.uiFont
                                        font.pixelSize: root.theme.smallPx
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: removeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: OpacitySettings.removeOverrideLive(overrideRow.modelData.cls)

                                        HoverTip {
                                            message: "Remove the " + overrideRow.modelData.label + " override"
                                            show: removeMouse.containsMouse
                                        }
                                    }
                                }
                            }

                            IntSlider {
                                width: parent.width
                                from: Theme.opacityMin
                                to: Theme.opacityMax
                                step: Theme.opacityStep
                                value: overrideRow.modelData.active
                                readout: overrideRow.modelData.active + "%"
                                tip: overrideRow.modelData.label + " (" + overrideRow.modelData.cls + ") while focused"
                                onChanged: (value) => OpacitySettings.setOverrideLive(overrideRow.modelData.cls, value)
                            }
                        }
                    }

                    MenuChip {
                        theme: root.theme
                        label: root.picking ? "Hide open windows" : "Add override"
                        accent: root.picking
                        tip: "Add an override for one of the windows open now"
                        onClicked: root.togglePicker()
                    }

                    Note {
                        visible: root.picking && (OpacityService.listing || OpacityService.windows.length === 0)
                        text: OpacityService.listing ? "Reading open windows…" : "No open windows found."
                    }

                    Repeater {
                        model: root.picking ? OpacityService.windows : []
                        delegate: OpacityAddRow {
                            required property var modelData
                            width: overCol.width
                            theme: root.theme
                            cls: modelData.cls
                            added: root.overrideClasses.indexOf(modelData.cls) >= 0
                            onPicked: (cls, label) => root.addPicked(cls, label)
                        }
                    }

                    Note {
                        visible: root.addError.length > 0
                        text: root.addError
                        color: root.theme.colDanger
                    }
                }
            }

            Note {
                text: "Escape or ✕ closes this menu. The list scrolls when it is taller than the screen."
            }
        }
    }

    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        spacing: Theme.tabGap
        height: Theme.chip

        MenuChip {
            theme: root.theme
            label: "Use theme"
            tip: "Set All applications back to the theme default (" + DefaultTheme.opacityQuickshell + "%)"
            onClicked: OpacitySettings.useTheme()
        }
    }
}
