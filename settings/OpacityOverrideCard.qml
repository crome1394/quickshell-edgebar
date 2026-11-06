import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme

// One application override on System → Transparency: the app, an on/off
// chip, a remove button, and focused / unfocused levels. "Same" ties the
// unfocused level to the focused one.
Rectangle {
    id: root

    required property var row

    readonly property bool linked: root.row.active === root.row.inactive
    readonly property var entry: DesktopEntries.heuristicLookup(root.row.cls)
    readonly property string iconSource: root.entry ? IconService.url(String(root.entry.icon || "")) : ""

    function set(field, value) {
        OpacitySettings.setOverride(root.row.cls, field, value)
    }

    implicitHeight: body.implicitHeight + Theme.space * 2
    radius: Theme.radius
    color: Theme.pillBg
    border.width: Theme.borderWidth
    border.color: Theme.border
    opacity: root.row.on ? 1 : Theme.widgetOffOpacity

    Column {
        id: body
        x: Theme.space * 1.5
        y: Theme.space
        width: parent.width - Theme.space * 3
        spacing: Theme.tabGap

        // App, class, on/off, remove.
        Item {
            width: parent.width
            height: Theme.fieldHeight

            Rectangle {
                id: iconBox
                width: Theme.fieldHeight
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: Theme.fieldBg

                Image {
                    anchors.centerIn: parent
                    visible: root.iconSource.length > 0
                    width: parent.width - Theme.tabGap
                    height: width
                    source: root.iconSource
                    sourceSize.width: width
                    sourceSize.height: height
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource.length === 0
                    text: root.row.label.charAt(0).toUpperCase()
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                    font.bold: true
                }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: Theme.space
                anchors.right: actions.left
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.row.label
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                    font.bold: true
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.row.cls
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallPx
                }
            }

            Row {
                id: actions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.tabGap

                ChipButton {
                    label: root.row.on ? "On" : "Off"
                    active: root.row.on
                    minWidth: Theme.fieldHeight * 1.6
                    tip: root.row.on ? "Turn this override off without removing it" : "Turn this override on"
                    onClicked: root.set("on", !root.row.on)
                }

                ChipButton {
                    label: "✕"
                    tip: "Remove this override"
                    onClicked: OpacitySettings.removeOverride(root.row.cls)
                }
            }
        }

        FormRow {
            width: parent.width
            label: "Focused"

            IntSlider {
                width: parent.width
                from: Theme.opacityMin
                to: Theme.opacityMax
                step: Theme.opacityStep
                value: root.row.active
                readout: root.row.active + "%"
                tip: "Opacity while this app has focus. 100 is solid."
                onChanged: (value) => {
                    if (root.linked)
                        OpacitySettings.editor.set("overrides", OpacitySettings.editor.value.overrides.map(
                            (r) => r.cls === root.row.cls ? Object.assign({}, r, { active: value, inactive: value }) : r))
                    else
                        root.set("active", value)
                }
            }
        }

        FormRow {
            width: parent.width
            label: "Unfocused"

            Row {
                width: parent.width
                spacing: Theme.tabGap

                ChipButton {
                    id: sameChip
                    label: "Same"
                    active: root.linked
                    minWidth: Theme.fieldHeight * 2
                    tip: root.linked
                        ? "Unfocused follows Focused. Click to set it on its own."
                        : "Make Unfocused the same as Focused"
                    onClicked: {
                        if (root.linked)
                            root.set("inactive", OpacitySettings.clamp(Math.max(Theme.opacityMin, root.row.active - Theme.opacityStep * 3)))
                        else
                            root.set("inactive", root.row.active)
                    }
                }

                IntSlider {
                    visible: !root.linked
                    width: parent.width - sameChip.width - parent.spacing
                    from: Theme.opacityMin
                    to: Theme.opacityMax
                    step: Theme.opacityStep
                    value: root.row.inactive
                    readout: root.row.inactive + "%"
                    tip: "Opacity while another window has focus"
                    onChanged: (value) => root.set("inactive", value)
                }

                Text {
                    visible: root.linked
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: root.row.inactive + "%, same as focused"
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }
    }
}
