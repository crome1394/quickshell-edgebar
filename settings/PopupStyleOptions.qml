pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import Quickshell
import qs.config
import qs.theme

// Settings → Notifications → Popups: how the built-in server's popups look.
// Part of the page's draft, so Apply saves it with the rest. "Send a test"
// shows a popup with the applied look.
Column {
    id: root

    readonly property var popup: NotificationSettings.editor.value.popup
    readonly property bool builtin: Config.notificationServer === "builtin"
    property int paintIndex: -1

    function set(key, value) {
        const next = Object.assign({}, root.popup)
        next[key] = value
        NotificationSettings.editor.set("popup", next)
    }

    function setColors(list) {
        root.set("appColors", list)
    }

    function addApp() {
        const name = appField.text.trim()
        if (!name.length)
            return
        const list = root.popup.appColors.slice()
        if (list.some((c) => c.app.toLowerCase() === name.toLowerCase()))
            return
        list.push({ app: name, color: ThemeBuilder.rgbText(PopupSettings.appColor(name, Object.assign({}, root.popup, { stripe: true }))) })
        root.setColors(list)
        appField.text = ""
    }

    spacing: Theme.space

    Text {
        visible: !root.builtin
        width: parent.width
        wrapMode: Text.WordWrap
        text: "These apply to the built-in server's popups. SwayNC draws its own."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    FormRow {
        width: parent.width
        label: "Style"

        Row {
            spacing: Theme.tabGap

            ChipButton {
                label: "Compact"
                active: root.popup.style === "compact"
                tip: "One line: app and summary"
                onClicked: root.set("style", "compact")
            }

            ChipButton {
                label: "Standard"
                active: root.popup.style === "standard"
                tip: "Icon, summary, body, and actions"
                onClicked: root.set("style", "standard")
            }

            ChipButton {
                label: "Large"
                active: root.popup.style === "large"
                tip: "Images shown big on top, and more body text"
                onClicked: root.set("style", "large")
            }
        }
    }

    FormRow {
        width: parent.width
        label: "Motion"

        Row {
            spacing: Theme.tabGap

            ChipButton {
                label: "Slide"
                active: root.popup.motion === "slide"
                tip: "Slide in from the screen edge and out again"
                onClicked: root.set("motion", "slide")
            }

            ChipButton {
                label: "Fade"
                active: root.popup.motion === "fade"
                tip: "Fade in and out"
                onClicked: root.set("motion", "fade")
            }

            ChipButton {
                label: "None"
                active: root.popup.motion === "none"
                tip: "Appear and disappear at once"
                onClicked: root.set("motion", "none")
            }
        }
    }

    FormRow {
        width: parent.width
        label: "Width"

        IntSlider {
            width: parent.width
            from: 280
            to: 560
            step: 20
            value: root.popup.width
            readout: root.popup.width + " px"
            tip: "Popup width"
            onChanged: (value) => root.set("width", value)
        }
    }

    FormRow {
        width: parent.width
        label: "Shown at once"

        IntSlider {
            width: parent.width
            from: 1
            to: 8
            value: root.popup.max
            readout: String(root.popup.max)
            tip: "How many popups stack before older ones wait"
            onChanged: (value) => root.set("max", value)
        }
    }

    FormRow {
        width: parent.width
        label: "Icon size"

        IntSlider {
            width: parent.width
            from: 32
            to: 128
            step: 8
            value: root.popup.image
            readout: root.popup.image + " px"
            tip: "The app icon or image beside the text"
            onChanged: (value) => root.set("image", value)
        }
    }

    FormRow {
        width: parent.width
        label: "Body lines"

        IntSlider {
            width: parent.width
            from: 0
            to: 10
            value: root.popup.lines
            readout: root.popup.lines === 0 ? "Off" : String(root.popup.lines)
            tip: "Lines of body text before it is cut off (Large shows twice as many). 0 hides the body."
            onChanged: (value) => root.set("lines", value)
        }
    }

    FormRow {
        width: parent.width
        label: "Edge gap"

        IntSlider {
            width: parent.width
            from: 0
            to: 64
            step: 4
            value: root.popup.margin
            readout: root.popup.margin + " px"
            tip: "Space between the popups and the screen edge"
            onChanged: (value) => root.set("margin", value)
        }
    }

    FormRow {
        width: parent.width
        label: "Glass"

        Row {
            width: parent.width
            spacing: Theme.tabGap

            ChipButton {
                id: menuGlass
                label: "Like menus"
                active: root.popup.glass === 0
                tip: "Use the theme's menu glass"
                onClicked: root.set("glass", 0)
            }

            IntSlider {
                width: parent.width - menuGlass.width - parent.spacing
                from: 40
                to: 100
                step: 2
                value: root.popup.glass === 0 ? ThemeStore.activeTheme.menu : root.popup.glass
                readout: root.popup.glass === 0 ? "Menus" : root.popup.glass + "%"
                tip: "How solid popups are, on their own"
                onChanged: (value) => root.set("glass", value)
            }
        }
    }

    CheckRow {
        width: parent.width
        title: "Progress bar"
        detail: "A thin bar showing the time left; it pauses while you hover"
        checked: root.popup.progress
        onToggled: root.set("progress", !root.popup.progress)
    }

    CheckRow {
        width: parent.width
        title: "Group by app"
        detail: "Several popups from one app share a card with a +N count; ✕ closes them all"
        checked: root.popup.group
        onToggled: root.set("group", !root.popup.group)
    }

    CheckRow {
        width: parent.width
        title: "Big image previews"
        detail: "Screenshots and album art show full width on top (Standard and Large)"
        checked: root.popup.bigImages
        onToggled: root.set("bigImages", !root.popup.bigImages)
    }

    CheckRow {
        width: parent.width
        title: "App color stripe"
        detail: "A colored edge per app, from the app's name, or your color below"
        checked: root.popup.stripe
        onToggled: root.set("stripe", !root.popup.stripe)
    }

    Text {
        width: parent.width
        text: "App colors"
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
        font.bold: true
    }

    Flow {
        width: parent.width
        spacing: Theme.space

        Repeater {
            model: root.popup.appColors
            delegate: Row {
                id: colorRow
                required property var modelData
                required property int index
                spacing: Theme.tabGap

                Text {
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: colorRow.modelData.app
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                ColorChip {
                    value: colorRow.modelData.color
                    tip: "Color for " + colorRow.modelData.app + " (always shown, even with the stripe off)"
                    onClicked: {
                        root.paintIndex = colorRow.index
                        picker.selectedColor = colorRow.modelData.color
                        picker.open()
                    }
                }

                ChipButton {
                    label: "✕"
                    tip: "Remove " + colorRow.modelData.app
                    onClicked: {
                        const list = root.popup.appColors.slice()
                        list.splice(colorRow.index, 1)
                        root.setColors(list)
                    }
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.tabGap

        TextBox {
            id: appField
            width: parent.width - addButton.width - testButton.width - parent.spacing * 2
            placeholderText: "App name as it appears on popups, e.g. Discord"
            onAccepted: root.addApp()
        }

        ChipButton {
            id: addButton
            label: "Add"
            enabled: appField.text.trim().length > 0 && root.popup.appColors.length < Theme.popupAppColorsMax
            tip: "Give this app its own color"
            onClicked: root.addApp()
        }

        ChipButton {
            id: testButton
            label: "Send a test"
            enabled: root.builtin
            tip: "Show a popup with the applied look (Apply first to see changes)"
            onClicked: Quickshell.execDetached(["notify-send", "-a", "Quickshell", "Test popup", "This is how popups look with the applied settings."])
        }
    }

    ColorDialog {
        id: picker
        title: "App color"
        onAccepted: {
            const list = root.popup.appColors.slice()
            if (root.paintIndex >= 0 && root.paintIndex < list.length) {
                list[root.paintIndex] = { app: list[root.paintIndex].app, color: ThemeBuilder.rgbText(selectedColor) }
                root.setColors(list)
            }
        }
    }
}
