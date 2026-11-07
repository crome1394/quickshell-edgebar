pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.settings
import qs.theme

// Transparency menu: one level for every application, a quick slider for
// each override, and Add override to pick an open window. Settings → System
// → Transparency edits the rest. Changes save at once; OpacityService
// applies them.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    readonly property bool menuOpen: OpacityMenuService.open
    property bool picking: false
    property string addError: ""
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))

    function placeMenu() {
        const content = root.Window.contentItem
        if (!content)
            return
        const bounds = root.mapToItem(content, 0, 0, root.width, root.height)
        const cx = Math.round(bounds.x + bounds.width / 2)
        const cy = Math.round(bounds.y + bounds.height / 2)
        let x = cx
        let y = Math.round(content.height)
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (root.edge === "bottom") {
            y = 0
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width)
            y = cy
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (root.edge === "right") {
            x = 0
            y = cy
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const anchor = menuPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = grow
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    readonly property var overrides: OpacitySettings.savedOverrides().filter((r) => r.on)
    // Every saved override's class, switched off ones too, for "Added".
    readonly property var overrideClasses: OpacitySettings.savedOverrides().map((r) => r.cls)

    onMenuOpenChanged: {
        if (!root.menuOpen) {
            root.picking = false
            root.addError = ""
        }
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

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colBorder
    transform: [
        Scale {
            xScale: dock.mag
            yScale: dock.mag
            origin.x: root.width / 2
            origin.y: dock.growIn ? root.height : 0
        },
        Translate { y: dock.jumpY }
    ]

    DockFace {
        id: dock
        edge: root.edge
        hovered: opacityMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        text: "󱡓"
        color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: root.icon
    }

    MouseArea {
        id: opacityMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            OpacityMenuService.toggle()
        }

        BarTip {
            edge: root.edge
            message: "Window transparency"
            show: opacityMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.popupWidth + Theme.space * 8
        // qmllint disable missing-property
        implicitHeight: menuCol.implicitHeight + Theme.space * 2
        // qmllint enable missing-property
        onClosed: OpacityMenuService.hide()
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space
                spacing: Theme.space

                Text {
                    width: parent.width
                    text: "Transparency"
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: "All applications"
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
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

                Text {
                    visible: root.overrides.length > 0
                    width: parent.width
                    text: "Overrides"
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                }

                Repeater {
                    model: root.overrides
                    delegate: Column {
                        id: overrideRow
                        required property var modelData
                        width: menuCol.width
                        spacing: Theme.borderWidth

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: overrideRow.modelData.label
                                + (overrideRow.modelData.active !== overrideRow.modelData.inactive
                                    ? "  ·  unfocused " + overrideRow.modelData.inactive + "%" : "")
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                        }

                        Item {
                            width: parent.width
                            height: overrideSlider.implicitHeight

                            Rectangle {
                                id: removeButton
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
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

                            IntSlider {
                                id: overrideSlider
                                anchors.left: removeButton.right
                                anchors.leftMargin: Theme.space
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
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
                }

                MenuChip {
                    theme: root.theme
                    label: root.picking ? "Hide open windows" : "Add override"
                    accent: root.picking
                    tip: "Add an override for one of the windows open now"
                    onClicked: root.togglePicker()
                }

                Text {
                    visible: root.picking && (OpacityService.listing || OpacityService.windows.length === 0)
                    width: parent.width
                    text: OpacityService.listing ? "Reading open windows…" : "No open windows found."
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                Flickable {
                    visible: root.picking && OpacityService.windows.length > 0
                    width: parent.width
                    height: Math.min(pickCol.implicitHeight, Theme.opacityPickMaxHeight)
                    contentHeight: pickCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: pickCol
                        width: parent.width
                        spacing: Theme.borderWidth

                        Repeater {
                            model: root.picking ? OpacityService.windows : []
                            delegate: OpacityAddRow {
                                required property var modelData
                                width: pickCol.width
                                theme: root.theme
                                cls: modelData.cls
                                added: root.overrideClasses.indexOf(modelData.cls) >= 0
                                onPicked: (cls, label) => root.addPicked(cls, label)
                            }
                        }
                    }
                }

                Text {
                    visible: root.addError.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.addError
                    color: root.theme.colDanger
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Settings and fullscreen windows stay solid. Edit unfocused levels in Settings → System → Transparency."
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                Text {
                    visible: OpacityService.error.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: OpacityService.error
                    color: root.theme.colDanger
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }

                Rectangle {
                    width: themeButtonLabel.implicitWidth + Theme.space * 2
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: themeMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: root.theme.colBorder

                    Text {
                        id: themeButtonLabel
                        anchors.centerIn: parent
                        text: "Use theme"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: true
                    }

                    MouseArea {
                        id: themeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: OpacitySettings.useTheme()

                        HoverTip {
                            message: "Set All applications back to the theme default (" + DefaultTheme.opacityQuickshell + "%)"
                            show: themeMouse.containsMouse
                        }
                    }
                }
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: menuPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeMenu()
        }
    }
}
