pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.theme

// Widgets → Bars → Monitors. Bars on: the main monitor, every monitor, or
// the monitors you pick. Main monitor: where single-screen things go (the
// Active Window popup, menus opened from a keybind). Saves at once.
Column {
    id: root

    spacing: Theme.space

    function describe(screen) {
        return String(screen.name) + "  " + screen.width + "×" + screen.height
    }

    FormRow {
        width: parent.width
        label: "Bars on"

        Row {
            spacing: Theme.tabGap

            ChipButton {
                label: "Main monitor"
                active: ScreenService.mode === "main"
                tip: "One set of bars, on the main monitor"
                onClicked: ScreenService.setMode("main")
            }

            ChipButton {
                label: "Every monitor"
                active: ScreenService.mode === "all"
                tip: "The same bars on every monitor"
                onClicked: ScreenService.setMode("all")
            }

            ChipButton {
                label: "Pick"
                active: ScreenService.mode === "pick"
                tip: "Bars on the monitors you choose below"
                onClicked: ScreenService.setMode("pick")
            }
        }
    }

    FormRow {
        visible: ScreenService.mode === "pick"
        width: parent.width
        label: "Monitors"

        Flow {
            width: parent.width
            spacing: Theme.tabGap

            Repeater {
                model: ScreenService.screens
                delegate: ChipButton {
                    required property var modelData
                    label: root.describe(modelData)
                    active: ScreenService.picked.indexOf(String(modelData.name)) >= 0
                    tip: "Show bars on " + modelData.name
                    onClicked: ScreenService.togglePicked(String(modelData.name))
                }
            }
        }
    }

    FormRow {
        width: parent.width
        label: "Main monitor"

        Flow {
            width: parent.width
            spacing: Theme.tabGap

            Repeater {
                model: ScreenService.screens
                delegate: ChipButton {
                    required property var modelData
                    label: root.describe(modelData)
                    active: ScreenService.mainName === String(modelData.name)
                    tip: "Main monitor: bars in Main monitor mode, the Active Window popup, and menus opened from a keybind"
                    onClicked: ScreenService.setMain(String(modelData.name))
                }
            }
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: ScreenService.screens.length > 1
            ? "Each bar has the same widgets. A menu opens on the monitor whose bar you clicked."
            : "One monitor connected. These options matter once you add another."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }
}
