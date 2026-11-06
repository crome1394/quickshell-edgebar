pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.config
import qs.services
import qs.theme

// Settings → System → Transparency: one level for every application, and
// overrides for single applications. Apply saves; the bar then rewrites
// opacity.lua and reloads it in Hyprland.
Item {
    id: root

    property bool picking: false
    property string addError: ""

    readonly property var draft: OpacitySettings.editor.value
    readonly property var overrides: root.draft.overrides || []
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    function has(cls) {
        return root.overrides.some((r) => r.cls === cls)
    }

    function add(cls, label) {
        const clean = String(cls || "").trim()
        if (!OpacitySettings.classOk(clean)) {
            root.addError = "A window class is letters, digits, dots, dashes, underscores, or plus signs, like org.gnome.Nautilus."
            return
        }
        if (root.has(clean)) {
            root.addError = clean + " already has an override."
            return
        }
        if (!OpacitySettings.addOverride(clean, label)) {
            root.addError = "No room for more overrides (" + Theme.opacityOverrideMax + " at most)."
            return
        }
        root.addError = ""
        classField.text = ""
    }

    function togglePicker() {
        root.picking = !root.picking
        if (root.picking)
            OpacityService.listWindows()
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
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: pageScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: pageScroll.pressed || pageScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: Math.max(0, scroll.width - root.scrollGutter)
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "All applications"
                hint: "One opacity for every window. 100% is solid. Overrides below win over this level. Apply saves this page."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Opacity"

                    IntSlider {
                        width: parent.width
                        from: Theme.opacityMin
                        to: Theme.opacityMax
                        step: Theme.opacityStep
                        value: root.draft.all
                        readout: root.draft.all + "%"
                        tip: "Every window, " + Theme.opacityMin + " to " + Theme.opacityMax + "%"
                        onChanged: (value) => OpacitySettings.editor.set("all", value)
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Always solid: the Settings window and fullscreen windows."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            SectionHeader {
                width: parent.width
                title: "Overrides"
                hint: "Give one application its own opacity, with a separate level for when it is not focused. 100% keeps an app solid while the rest are see-through."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Text {
                    visible: root.overrides.length === 0
                    width: parent.width
                    text: "No overrides yet. Add an application below."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }

                Repeater {
                    model: root.overrides
                    delegate: OpacityOverrideCard {
                        required property var modelData
                        width: parent.width
                        row: modelData
                    }
                }

                // Add: pick an open window, or type a class.
                Row {
                    width: parent.width
                    spacing: Theme.tabGap

                    ChipButton {
                        id: pickButton
                        label: root.picking ? "Hide open windows" : "Add from open windows"
                        active: root.picking
                        tip: "Choose from the windows that are open now"
                        onClicked: root.togglePicker()
                    }

                    TextField {
                        id: classField
                        width: parent.width - pickButton.width - addButton.width - parent.spacing * 2
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true
                        placeholderText: "or type a window class, e.g. org.gnome.Nautilus"
                        leftPadding: Theme.space
                        color: Theme.text
                        placeholderTextColor: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: classField.activeFocus ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: root.addError.length ? Theme.danger : (classField.activeFocus ? Theme.accent : Theme.border)
                        }
                        onTextChanged: root.addError = ""
                        onAccepted: root.add(text, "")

                        HoverHandler {
                            id: classHover
                        }

                        HoverTip {
                            message: "The class Hyprland shows for the window (hyprctl clients). Matched exactly."
                            show: classHover.hovered
                        }
                    }

                    ChipButton {
                        id: addButton
                        label: "Add"
                        enabled: classField.text.trim().length > 0
                        tip: "Add an override for this class"
                        onClicked: root.add(classField.text, "")
                    }
                }

                Text {
                    visible: root.addError.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.addError
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                // Open windows, one per class.
                Rectangle {
                    visible: root.picking
                    width: parent.width
                    height: pickCol.implicitHeight + Theme.space * 2
                    radius: Theme.radius
                    color: Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: Theme.accent

                    Column {
                        id: pickCol
                        x: Theme.space
                        y: Theme.space
                        width: parent.width - Theme.space * 2
                        spacing: Theme.tabGap

                        Text {
                            visible: OpacityService.listing || OpacityService.windows.length === 0
                            text: OpacityService.listing ? "Reading open windows…" : "No open windows found."
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Repeater {
                            model: OpacityService.windows
                            delegate: Rectangle {
                                id: pick
                                required property var modelData
                                readonly property bool added: root.has(pick.modelData.cls)
                                readonly property var entry: DesktopEntries.heuristicLookup(pick.modelData.cls)
                                readonly property string name: pick.entry && pick.entry.name ? String(pick.entry.name) : pick.modelData.cls
                                readonly property string iconSource: pick.entry ? IconService.url(String(pick.entry.icon || "")) : ""
                                width: pickCol.width
                                height: Theme.fieldHeight + Theme.tabGap
                                radius: Theme.radiusSm
                                color: pickMouse.containsMouse && !pick.added ? Theme.hover : "transparent"
                                opacity: pick.added ? Theme.widgetOffOpacity : 1

                                Image {
                                    id: pickIcon
                                    x: Theme.tabGap
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.chip
                                    height: Theme.chip
                                    source: pick.iconSource
                                    sourceSize.width: width
                                    sourceSize.height: height
                                    asynchronous: true
                                }

                                Text {
                                    anchors.left: pickIcon.right
                                    anchors.leftMargin: Theme.space
                                    anchors.right: pickState.left
                                    anchors.rightMargin: Theme.space
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    text: pick.name + "   " + pick.modelData.cls + (pick.modelData.title.length ? "  ·  " + pick.modelData.title : "")
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                Text {
                                    id: pickState
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.space
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: pick.added ? "Added" : "+ Add"
                                    color: pick.added ? Theme.subtext : Theme.accent
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: !pick.added
                                }

                                MouseArea {
                                    id: pickMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !pick.added
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.add(pick.modelData.cls, pick.name)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            SectionHeader {
                width: parent.width
                title: "Hyprland"
                hint: "The bar writes these rules to opacity.lua and reloads them live. Your hyprland.lua loads that file last with require(\"opacity\")."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.tabGap

                Text {
                    width: parent.width
                    elide: Text.ElideMiddle
                    text: "Rules file: " + OpacityService.luaPath
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                Text {
                    visible: OpacityService.error.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: OpacityService.error
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: OpacitySettings.editor.dirty
        undoEnabled: OpacitySettings.editor.canUndo
        applyTip: "Save and apply the levels"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "All applications to the theme default and only the Satty override. Apply saves it."
        onApplyClicked: OpacitySettings.editor.apply()
        onUndoClicked: OpacitySettings.editor.undo()
        onResetClicked: OpacitySettings.editor.reset()
    }
}
