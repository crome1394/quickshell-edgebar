pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// Widgets → System Stats → Text Style. Pick a widget (All or one metric)
// and a part (Label, Percent, Value), then set its font, bold, italic,
// size, and color. A metric follows All for every field it does not set.
// Font and color pickers belong to the page, so this only asks for them.
Column {
    id: root

    property string target: "all"
    property string part: "label"

    signal fontRequested()
    signal colorRequested()

    readonly property var current: StatsSettings.draftStyle(root.target, root.part)
    readonly property var own: StatsSettings.draftOverrides(root.target, root.part)
    readonly property bool isAll: root.target === "all"
    readonly property int styleWidth: Theme.chip + Theme.borderWidth * 4

    readonly property var targetChoices: [
        { id: "all", label: "All widgets", tip: "The base every widget follows" },
        { id: "cpu", label: "CPU", tip: "Override for CPU" },
        { id: "mem", label: "Memory", tip: "Override for Memory" },
        { id: "gpu", label: "GPU", tip: "Override for GPU" },
        { id: "vram", label: "VRAM", tip: "Override for VRAM" }
    ]
    readonly property var partChoices: [
        { id: "label", label: "Label", tip: "The name: CPU, Memory, GPU, VRAM" },
        { id: "percent", label: "Percent", tip: "The percent; its color comes from Thresholds" },
        { id: "value", label: "Value", tip: "Temperature for CPU and GPU, used memory for Memory and VRAM" }
    ]

    spacing: Theme.space

    Row {
        width: root.width
        spacing: Theme.tabGap

        SelectBox {
            width: Math.round((root.width - Theme.tabGap) / 2)
            choices: root.targetChoices
            currentId: root.target
            emptyLabel: "All widgets"
            tip: "Which widget to style"
            onPicked: (id) => root.target = id
        }

        SelectBox {
            width: root.width - Math.round((root.width - Theme.tabGap) / 2) - Theme.tabGap
            choices: root.partChoices
            currentId: root.part
            emptyLabel: "Label"
            tip: "Which text to style"
            onPicked: (id) => root.part = id
        }
    }

    // Font, bold, italic, and size.
    Row {
        id: faceRow
        width: root.width
        height: Theme.fieldHeight
        spacing: Theme.tabGap

        Rectangle {
            id: fontButton
            width: Math.max(Theme.fieldHeight * 4, Math.round((faceRow.width - root.styleWidth * 2 - Theme.tabGap * 3) * 0.46))
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
                text: root.current.font.length ? root.current.font : "Bar font"
                color: Theme.text
                font.family: root.current.font.length ? root.current.font : Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: root.current.bold
                font.italic: root.current.italic
            }

            MouseArea {
                id: fontMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.fontRequested()

                HoverTip {
                    message: "Font for this text. Bar font follows the theme."
                    show: fontMouse.containsMouse
                }
            }
        }

        ChipButton {
            width: root.styleWidth
            label: "B"
            bold: true
            active: root.current.bold
            tip: "Bold"
            onClicked: StatsSettings.setStyle(root.target, root.part, "bold", !root.current.bold)
        }

        ChipButton {
            width: root.styleWidth
            label: "I"
            italic: true
            active: root.current.italic
            tip: "Italic"
            onClicked: StatsSettings.setStyle(root.target, root.part, "italic", !root.current.italic)
        }

        IntSlider {
            width: Math.max(Theme.fieldHeight * 4, faceRow.width - fontButton.width - root.styleWidth * 2 - Theme.tabGap * 3)
            from: Theme.clockFontMin
            to: Theme.clockFontMax
            step: Theme.clockFontStep
            value: root.current.size
            readout: root.current.size + "%"
            tip: "Text size, from " + Theme.clockFontMin + " to " + Theme.clockFontMax + "%. The bar's height caps it."
            onChanged: (value) => StatsSettings.setStyle(root.target, root.part, "size", value)
        }
    }

    // Color: Auto follows the theme; a chip picks a fixed color.
    Row {
        visible: root.part !== "percent"
        width: root.width
        height: Theme.fieldHeight
        spacing: Theme.tabGap

        Text {
            width: Math.max(implicitWidth, Theme.fieldHeight * 2)
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: "Color"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ChipButton {
            label: "Auto"
            active: root.current.color === "auto"
            tip: root.part === "value"
                ? "Theme colors: temperature steps for CPU and GPU, text color for memory. Changes with the theme."
                : "The theme's text color. Changes with the theme."
            onClicked: StatsSettings.setStyle(root.target, root.part, "color", "auto")
        }

        Rectangle {
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            color: root.current.color === "auto" ? "transparent" : root.current.color
            border.width: Theme.borderWidth
            border.color: root.current.color === "auto" ? Theme.border : Theme.accent

            Text {
                visible: root.current.color === "auto"
                anchors.centerIn: parent
                text: "+"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            MouseArea {
                id: colorMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.colorRequested()

                HoverTip {
                    message: "Pick a fixed color. It stays the same when you switch themes."
                    show: colorMouse.containsMouse
                }
            }
        }
    }

    Text {
        visible: root.part === "percent"
        width: root.width
        wrapMode: Text.WordWrap
        text: "Percent color comes from Thresholds."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    // A metric shows what it overrides, and can drop it.
    Row {
        visible: !root.isAll
        width: root.width
        height: Theme.fieldHeight
        spacing: Theme.tabGap

        Text {
            width: parent.width - useAll.width - Theme.tabGap
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.own.length ? "Own " + root.own.join(", ") + "; the rest follows All widgets" : "Follows All widgets"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ChipButton {
            id: useAll
            label: "Use All"
            enabled: root.own.length > 0
            opacity: enabled ? 1 : 0.5
            tip: "Drop this part's own settings so it follows All widgets"
            onClicked: StatsSettings.clearStyle(root.target, root.part)
        }
    }
}
