pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// On-Screen Display → Symbols: pick a slot, then type the text it shows
// (a Nerd Font glyph, an emoji, or a short word). Empty uses the default.
Column {
    id: root

    property string slot: "volHigh"

    readonly property var draft: OsdSettings.editor.value
    readonly property string own: String(root.draft.icons[root.slot] || "")

    spacing: Theme.space

    // Grows while the list is open, so the list pushes the page down.
    Row {
        width: root.width
        height: picker.implicitHeight
        spacing: Theme.tabGap

        SelectBox {
            id: picker
            width: Math.round(root.width * 0.45)
            choices: OsdSettings.iconSlots.map(s => ({ id: s.id, label: s.label, tip: "The symbol for " + s.label.toLowerCase() }))
            currentId: root.slot
            emptyLabel: "Volume high"
            tip: "Which symbol to change"
            onPicked: (id) => root.slot = id
        }

        Rectangle {
            width: Theme.fieldHeight * 1.5
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: OsdSettings.glyph(root.slot, root.draft)
                color: Theme.text
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconPx
            }
        }

        PathField {
            width: root.width - picker.width - Theme.fieldHeight * 1.5 - defaultChip.width - Theme.tabGap * 3
            value: root.own
            placeholderText: "Default"
            tip: "Any short text: paste a Nerd Font glyph or an emoji. Up to " + Theme.osdGlyphMax + " characters."
            onEdited: (text) => OsdSettings.setIcon(root.slot, text)
        }

        ChipButton {
            id: defaultChip
            label: "Default"
            enabled: root.own.length > 0
            opacity: enabled ? 1 : 0.5
            tip: "Use the built-in symbol again"
            onClicked: OsdSettings.setIcon(root.slot, "")
        }
    }
}
