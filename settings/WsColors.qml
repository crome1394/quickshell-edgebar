pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import qs.config
import qs.theme

// Bar → Workspaces → Colors. Theme: workspace pills use the theme's
// colors, and each face's own label color is ignored. My colors: the
// label colors you set per workspace apply, plus optional colors for the
// active pill and the idle and hover text. An empty swatch uses the
// theme. Changes save at once.
Column {
    id: root

    readonly property bool custom: WorkspaceSettings.colorMode() === "custom"
    property string paintKey: ""

    readonly property var swatches: [
        { key: "wsActiveBg", label: "Active pill", tip: "Background of the focused workspace" },
        { key: "wsActiveFg", label: "Active text", tip: "Text of the focused workspace" },
        { key: "wsIdleFg", label: "Idle text", tip: "Text of the other workspaces" },
        { key: "wsHoverFg", label: "Hover text", tip: "Text under the pointer" }
    ]

    spacing: Theme.space

    Row {
        spacing: Theme.tabGap

        ChipButton {
            label: "Theme"
            active: !root.custom
            tip: "Use the theme's colors everywhere. Your label colors are kept but not shown."
            onClicked: WorkspaceSettings.setColorMode("theme")
        }

        ChipButton {
            label: "My colors"
            active: root.custom
            tip: "Use your own colors: the label color of each workspace, and the colors below"
            onClicked: WorkspaceSettings.setColorMode("custom")
        }
    }

    Flow {
        visible: root.custom
        width: parent.width
        spacing: Theme.space

        Repeater {
            model: root.swatches
            delegate: Row {
                id: swatchRow
                required property var modelData
                readonly property string value: Config.colorNorm(Config[modelData.key])
                spacing: Theme.tabGap

                Text {
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: swatchRow.modelData.label
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                ColorChip {
                    value: swatchRow.value.length ? swatchRow.value : "transparent"
                    emptyText: "Theme"
                    tip: swatchRow.modelData.tip + (swatchRow.value.length ? "" : " (theme color)")
                    onClicked: {
                        root.paintKey = swatchRow.modelData.key
                        picker.selectedColor = swatchRow.value.length ? swatchRow.value : Theme.accent
                        picker.open()
                    }
                }

                ChipButton {
                    visible: swatchRow.value.length > 0
                    label: "✕"
                    tip: "Use the theme color"
                    onClicked: WorkspaceSettings.setCustomColor(swatchRow.modelData.key, "")
                }
            }
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.custom
            ? "Label colors are set per workspace below. On a light theme, check that your colors still read."
            : "Pills follow the theme, so they read on light and dark themes alike."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    ColorDialog {
        id: picker
        title: "Workspace color"
        onAccepted: WorkspaceSettings.setCustomColor(root.paintKey, selectedColor)
    }
}
