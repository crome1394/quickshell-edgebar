pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import qs.config
import qs.theme

// Settings → Bar → Dock. The bar reads saved options until Apply.
Item {
    id: root

    readonly property var draft: DockSettings.editor.value

    function choose(key, value) {
        DockSettings.editor.set(key, value)
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
                title: "Dock"
                hint: "Mac-style hover. Apply saves this page. The bar keeps the last saved options until then."
            }

            Item {
                width: parent.width
                height: dockCol.implicitHeight

                Column {
                    id: dockCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "All icons covers the app launchers, the application menu, the tray, workspaces, network, Bluetooth, the bell, transparency, settings, and power."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Text {
                        width: parent.width
                        text: "Running-dot color"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Row {
                        width: parent.width
                        height: Theme.fieldHeight
                        spacing: Theme.tabGap

                        Rectangle {
                            id: dotChip
                            width: Theme.chip
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: root.draft.dot
                            border.width: Theme.borderWidth
                            border.color: dotMouse.containsMouse ? Theme.accent : Theme.border

                            MouseArea {
                                id: dotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dotDialog.selectedColor = root.draft.dot
                                    dotDialog.open()
                                }

                                HoverTip {
                                    message: "Color of the running-app dot"
                                    show: dotMouse.containsMouse
                                }
                            }
                        }

                        Text {
                            width: parent.width - dotChip.width - Theme.tabGap
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: String(root.draft.dot || "")
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Apply to"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Item {
                        id: scopeChoices
                        width: parent.width
                        height: Theme.fieldHeight

                        Repeater {
                            model: [
                                { id: "quicklaunch", label: "Application Launcher", tip: "Only the pinned app icons" },
                                { id: "icons", label: "All icons", tip: "Every icon widget except stats and volume" }
                            ]
                            delegate: Rectangle {
                                id: scopeChip
                                required property var modelData
                                required property int index
                                readonly property string chipId: String(scopeChip.modelData.id || "")
                                readonly property bool chosen: root.draft.scope === scopeChip.chipId
                                readonly property int count: 2

                                x: scopeChip.index * (scopeChip.width + Theme.tabGap)
                                width: (scopeChoices.width - Theme.tabGap * (scopeChip.count - 1)) / scopeChip.count
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: scopeChip.chosen ? Theme.accentDim : (scopeMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: scopeChip.chosen ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String(scopeChip.modelData.label || "")
                                    color: scopeChip.chosen ? Theme.wsActiveText : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: scopeChip.chosen
                                }

                                MouseArea {
                                    id: scopeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.choose("scope", scopeChip.chipId)

                                    HoverTip {
                                        message: String(scopeChip.modelData.tip || "")
                                        show: scopeMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Effect"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Item {
                        id: effectChoices
                        width: parent.width
                        height: Theme.fieldHeight

                        Repeater {
                            model: [
                                { id: "off", label: "Off", tip: "Icons stay still" },
                                { id: "magnify", label: "Magnify", tip: "Hover grows the icon" },
                                { id: "jump", label: "Jump", tip: "A click bounces the icon" },
                                { id: "both", label: "Both", tip: "Hover grows it and a click bounces it" }
                            ]
                            delegate: Rectangle {
                                id: effectChip
                                required property var modelData
                                required property int index
                                readonly property string chipId: String(effectChip.modelData.id || "")
                                readonly property bool chosen: root.draft.effect === effectChip.chipId
                                readonly property int count: 4

                                x: effectChip.index * (effectChip.width + Theme.tabGap)
                                width: (effectChoices.width - Theme.tabGap * (effectChip.count - 1)) / effectChip.count
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: effectChip.chosen ? Theme.accentDim : (effectMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: effectChip.chosen ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: String(effectChip.modelData.label || "")
                                    color: effectChip.chosen ? Theme.wsActiveText : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: effectChip.chosen
                                }

                                MouseArea {
                                    id: effectMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.choose("effect", effectChip.chipId)

                                    HoverTip {
                                        message: String(effectChip.modelData.tip || "")
                                        show: effectMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: magnifyCol.implicitHeight
                        opacity: root.draft.effect === "magnify" || root.draft.effect === "both" ? 1 : 0.45

                        Column {
                            id: magnifyCol
                            width: parent.width
                            spacing: Theme.space

                            Text {
                                width: parent.width
                                text: "Magnify amount"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            IntSlider {
                                width: parent.width
                                from: Theme.dockScaleMin
                                to: Theme.dockScaleMax
                                step: Theme.dockScaleStep
                                value: root.draft.percent
                                readout: root.draft.percent + "%"
                                tip: "Size of the icon under the pointer"
                                onChanged: (value) => root.choose("percent", value)
                            }

                            Text {
                                width: parent.width
                                text: "Neighbor spread"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            IntSlider {
                                width: parent.width
                                from: Theme.dockRadiusMin
                                to: Theme.dockRadiusMax
                                step: Theme.dockRadiusStep
                                value: root.draft.radius
                                readout: root.draft.radius + "px"
                                tip: "How far the growth reaches along a row of icons"
                                onChanged: (value) => root.choose("radius", value)
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: jumpCol.implicitHeight
                        opacity: root.draft.effect === "jump" || root.draft.effect === "both" ? 1 : 0.45

                        Column {
                            id: jumpCol
                            width: parent.width
                            spacing: Theme.space

                            Text {
                                width: parent.width
                                text: "Jump height"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            IntSlider {
                                width: parent.width
                                from: Theme.dockJumpMin
                                to: Theme.dockJumpMax
                                step: Theme.dockJumpStep
                                value: root.draft.jump
                                readout: root.draft.jump + "px"
                                tip: "How far a click bounces the icon"
                                onChanged: (value) => root.choose("jump", value)
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
        applyEnabled: DockSettings.editor.dirty
        undoEnabled: DockSettings.editor.canUndo
        applyTip: "Save the dock effect, the spread, and the running-dot color"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore Both, all icons, 128%, 72px spread, an 8px jump, and the cyan dot. Apply saves it."
        onApplyClicked: DockSettings.editor.apply()
        onUndoClicked: DockSettings.editor.undo()
        onResetClicked: DockSettings.editor.reset()
    }

    ColorDialog {
        id: dotDialog
        title: "Running-dot color"
        onAccepted: DockSettings.editor.set("dot", String(selectedColor))
    }
}
