pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → Tools → Night Light: how warm, and an optional schedule.
// Apply saves. The widget and qs ipc call nightLight toggle turn it on.
Item {
    id: root

    readonly property var draft: NightLightSettings.editor.value

    Component.onCompleted: NightLightService.recheck()

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "Night Light"
            hint: "Warms the screen in the evening to cut blue light, with hyprsunset. Turn on the Night Light widget under Widgets, or use qs ipc call nightLight toggle."
        }

        Column {
            x: Theme.sectionInset
            width: parent.width - Theme.sectionInset * 2
            spacing: Theme.space

            Text {
                visible: NightLightService.checked && !NightLightService.available
                width: parent.width
                wrapMode: Text.WordWrap
                text: "hyprsunset is not installed, so the night light cannot change the screen. Install it with: sudo pacman -S hyprsunset"
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Text {
                visible: NightLightService.error.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: NightLightService.error
                color: Theme.danger
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            FormRow {
                width: parent.width
                label: "Now"

                Row {
                    spacing: Theme.tabGap

                    ChipButton {
                        label: NightLightService.on ? "On" : "Off"
                        active: NightLightService.on
                        enabled: NightLightService.available
                        tip: "Turn the night light on or off now"
                        onClicked: NightLightService.toggle()
                    }
                }
            }

            FormRow {
                width: parent.width
                label: "Warmth"

                IntSlider {
                    width: parent.width
                    from: Theme.nightTempMin
                    to: Theme.nightTempMax
                    step: Theme.nightTempStep
                    value: root.draft.temp
                    readout: root.draft.temp + " K"
                    tip: "Lower is warmer and cuts more blue light. 6500 K is neutral; 4000 K is a common evening setting."
                    onChanged: (value) => NightLightSettings.editor.set("temp", value)
                }
            }

            CheckRow {
                width: parent.width
                title: "On a schedule"
                detail: "Turn on and off at set times; a click on the widget holds until the next switch"
                checked: root.draft.schedule
                onToggled: NightLightSettings.editor.set("schedule", !root.draft.schedule)
            }

            FormRow {
                visible: root.draft.schedule
                width: parent.width
                label: "From – to"

                Row {
                    spacing: Theme.space

                    TextBox {
                        id: startField
                        width: Theme.fieldHeight * 3
                        text: root.draft.start
                        placeholderText: "20:00"
                        inputMask: "99:99"
                        onEditingFinished: NightLightSettings.editor.set("start", text)
                    }

                    Text {
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        text: "to"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    TextBox {
                        id: endField
                        width: Theme.fieldHeight * 3
                        text: root.draft.end
                        placeholderText: "07:00"
                        inputMask: "99:99"
                        onEditingFinished: NightLightSettings.editor.set("end", text)
                    }
                }
            }
        }
    }

    DraftFooter {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: NightLightSettings.editor.dirty
        undoEnabled: NightLightSettings.editor.canUndo
        applyTip: "Save the warmth and the schedule"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: Theme.nightTempDefault + " K and no schedule. Apply saves it."
        onApplyClicked: NightLightSettings.editor.apply()
        onUndoClicked: NightLightSettings.editor.undo()
        onResetClicked: NightLightSettings.editor.reset()
    }
}
