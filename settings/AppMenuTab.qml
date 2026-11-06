pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

Item {
    id: root

    property bool formReady: false
    property bool fontOpen: false
    property bool fontWaiting: false
    property var fontNames: []
    property bool fontReady: false
    property string formError: ""

    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property int styleWidth: Theme.chip + Theme.borderWidth * 4
    readonly property int displayPx: MenuSettings.editor.value.px >= Theme.menuFontMin
        ? MenuSettings.editor.value.px
        : Theme.iconPx
    readonly property color previewColor: MenuSettings.editor.value.color.length ? MenuSettings.editor.value.color : Theme.text
    readonly property string fontLabel: MenuSettings.editor.value.font.length ? MenuSettings.editor.value.font : "Icon font"

    function takeFonts(text) {
        const lines = String(text || "").split("\n")
        const seen = {}
        const out = []
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const bar = line.lastIndexOf("|")
            if (bar <= 0)
                continue
            if (line.substring(bar + 1).trim() !== "True")
                continue
            const families = line.substring(0, bar).split(",")
            for (let j = 0; j < families.length; j++) {
                const name = families[j].trim()
                if (!name.length || seen[name])
                    continue
                seen[name] = true
                out.push(name)
            }
        }
        out.sort((a, b) => String(a).localeCompare(String(b)))
        return out
    }

    function fallbackFonts() {
        const all = Qt.fontFamilies()
        const out = []
        for (let i = 0; i < all.length; i++) {
            const name = String(all[i] || "")
            if (!name.length || /\.(pcf|bdf|psf|otb|fon)$/i.test(name))
                continue
            out.push(name)
        }
        return out
    }

    function openFont() {
        if (root.fontReady) {
            root.fontOpen = true
            return
        }
        root.fontWaiting = true
        if (!fontList.running)
            fontList.running = true
    }

    function fontsArrived(text) {
        if (root.fontReady)
            return
        const parsed = root.takeFonts(text)
        root.fontNames = parsed.length ? parsed : root.fallbackFonts()
        root.fontReady = true
        if (!root.fontWaiting)
            return
        root.fontWaiting = false
        root.fontOpen = true
    }

    function applyPage() {
        if (MenuSettings.apply())
            root.formError = ""
        else
            root.formError = "The command needs a program and arguments, with no shell characters."
    }

    Component.onCompleted: {
        symbolField.text = MenuSettings.editor.value.symbol
        commandField.text = MenuSettings.editor.value.command
        root.formReady = true
        fontList.running = true
    }

    // Undo, Reset, and Apply change the draft; keep the text fields in step.
    Connections {
        target: MenuSettings.editor
        function onValueChanged() {
            if (!root.formReady)
                return
            if (symbolField.text !== MenuSettings.editor.value.symbol)
                symbolField.text = MenuSettings.editor.value.symbol
            if (commandField.text !== MenuSettings.editor.value.command)
                commandField.text = MenuSettings.editor.value.command
        }
    }

    Process {
        id: fontList
        command: ["fc-list", "-f", "%{family}|%{scalable}\n"]
        stdout: StdioCollector {
            id: fontOut
            waitForEnd: true
        }
        onExited: (code) => root.fontsArrived(code === 0 ? fontOut.text : "")
    }

    ColorDialog {
        id: colors
        title: "Application Menu color"
        onAccepted: MenuSettings.editor.set("color", String(selectedColor))
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

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "The icon sits on the bar. A click runs the command. Apply saves this page. The widget stays off the bar until you enable Application Menu under Widgets and press Apply."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            SectionHeader {
                width: parent.width
                title: "Icon"
                hint: "The symbol is at most 3 characters. Empty uses the nine-square icon. Empty font uses the icon font. Right-click the color to clear it."
            }

            Item {
                width: parent.width
                implicitHeight: iconCol.implicitHeight
                height: iconCol.implicitHeight

                Column {
                    id: iconCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    Row {
                        width: parent.width
                        height: Theme.fieldHeight
                        spacing: Theme.tabGap

                        TextField {
                            id: symbolField
                            width: Theme.iconPx * 3 + Theme.chip + Theme.space
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            selectByMouse: true
                            placeholderText: Theme.menuSymbolDefault
                            leftPadding: Theme.space
                            color: root.previewColor
                            placeholderTextColor: Theme.subtext
                            font.family: MenuSettings.editor.value.font.length ? MenuSettings.editor.value.font : Theme.iconFont
                            font.pixelSize: Theme.fontPx
                            font.bold: MenuSettings.editor.value.bold
                            font.italic: MenuSettings.editor.value.italic
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: symbolField.activeFocus ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: symbolField.activeFocus ? Theme.accent : Theme.border
                            }
                            onTextChanged: {
                                if (!root.formReady)
                                    return
                                const next = Config.symbolClamp(text)
                                if (text !== next)
                                    text = next
                                if (next !== MenuSettings.editor.value.symbol)
                                    MenuSettings.editor.set("symbol", next)
                            }

                            HoverHandler {
                                id: symbolHover
                            }

                            HoverTip {
                                message: "Symbol on the icon, up to 3 characters"
                                show: symbolHover.hovered
                            }
                        }

                        Rectangle {
                            id: fontButton
                            width: Math.max(Theme.fieldHeight * 4, parent.width - symbolField.width - styleRow.implicitWidth - Theme.tabGap * 2)
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: fontMouse.containsMouse ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: root.fontLabel
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontPx
                            }

                            MouseArea {
                                id: fontMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openFont()

                                HoverTip {
                                    message: "Font for the symbol. Empty uses the icon font."
                                    show: fontMouse.containsMouse
                                }
                            }
                        }

                        Row {
                            id: styleRow
                            height: Theme.fieldHeight
                            spacing: Theme.wsGap

                            Rectangle {
                                width: root.styleWidth
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: root.previewColor
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                MouseArea {
                                    id: colorMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            MenuSettings.editor.set("color", "")
                                            return
                                        }
                                        if (MenuSettings.editor.value.color.length)
                                            colors.selectedColor = MenuSettings.editor.value.color
                                        colors.open()
                                    }

                                    HoverTip {
                                        message: "Symbol color. Right-click clears it."
                                        show: colorMouse.containsMouse
                                    }
                                }
                            }

                            Rectangle {
                                width: root.styleWidth
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: MenuSettings.editor.value.bold ? Theme.accentDim : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: MenuSettings.editor.value.bold ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "B"
                                    color: Theme.text
                                    font.bold: true
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: boldMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MenuSettings.editor.set("bold", !MenuSettings.editor.value.bold)

                                    HoverTip {
                                        message: "Bold the symbol"
                                        show: boldMouse.containsMouse
                                    }
                                }
                            }

                            Rectangle {
                                width: root.styleWidth
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: MenuSettings.editor.value.italic ? Theme.accentDim : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: MenuSettings.editor.value.italic ? Theme.accent : Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "I"
                                    color: Theme.text
                                    font.italic: true
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: italicMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MenuSettings.editor.set("italic", !MenuSettings.editor.value.italic)

                                    HoverTip {
                                        message: "Italic the symbol"
                                        show: italicMouse.containsMouse
                                    }
                                }
                            }

                            Rectangle {
                                width: Theme.chip
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: sizeDownMouse.containsMouse ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "−"
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: sizeDownMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MenuSettings.setFontPx(root.displayPx - 1)

                                    HoverTip {
                                        message: "Smaller symbol"
                                        show: sizeDownMouse.containsMouse
                                    }
                                }
                            }

                            Text {
                                width: Theme.chip
                                height: Theme.fieldHeight
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: String(root.displayPx)
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx

                                HoverHandler {
                                    id: sizeHover
                                }

                                HoverTip {
                                    message: "Symbol size, from " + Theme.menuFontMin + " to " + Theme.menuFontMax
                                    show: sizeHover.hovered
                                }
                            }

                            Rectangle {
                                width: Theme.chip
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: sizeUpMouse.containsMouse ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: Theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontPx
                                }

                                MouseArea {
                                    id: sizeUpMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MenuSettings.setFontPx(root.displayPx + 1)

                                    HoverTip {
                                        message: "Larger symbol"
                                        show: sizeUpMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Command"
                hint: "Program and arguments, separated by spaces. A shell is not used, and shell characters are rejected. Empty does nothing on click."
            }

            Item {
                width: parent.width
                implicitHeight: commandCol.implicitHeight
                height: commandCol.implicitHeight

                Column {
                    id: commandCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    TextField {
                        id: commandField
                        width: parent.width
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true
                        placeholderText: "rofi -show drun"
                        leftPadding: Theme.space
                        color: Theme.text
                        placeholderTextColor: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: commandField.activeFocus ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: root.formError.length ? Theme.danger : (commandField.activeFocus ? Theme.accent : Theme.border)
                        }
                        onTextChanged: {
                            if (!root.formReady)
                                return
                            if (text !== MenuSettings.editor.value.command)
                                MenuSettings.editor.set("command", text)
                            if (root.formError.length)
                                root.formError = ""
                        }

                        HoverHandler {
                            id: commandHover
                        }

                        HoverTip {
                            message: "Program and arguments. For example rofi -show drun"
                            show: commandHover.hovered
                        }
                    }

                    Text {
                        visible: root.formError.length > 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.formError
                        color: Theme.danger
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }
        }
    }

    Row {
        id: footer
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionInset
        anchors.bottom: parent.bottom
        spacing: Theme.tabGap

        Repeater {
            model: [
                { id: "apply", label: "Apply" },
                { id: "undo", label: "Undo" },
                { id: "reset", label: "Reset" }
            ]
            delegate: Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property string action: String(button.modelData.id || "")
                readonly property bool enabledAction: {
                    if (button.action === "apply")
                        return MenuSettings.editor.dirty
                    if (button.action === "undo")
                        return MenuSettings.editor.canUndo
                    return true
                }
                readonly property bool applyReady: button.action === "apply" && button.enabledAction

                implicitWidth: buttonLabel.implicitWidth + Theme.space * 2
                implicitHeight: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: button.enabledAction ? 1 : Theme.widgetOffOpacity
                color: button.applyReady && buttonMouse.containsMouse
                    ? Theme.accentDim
                    : (buttonMouse.containsMouse && button.enabledAction ? Theme.hover : Theme.pillBg)
                border.width: Theme.borderWidth
                border.color: button.applyReady ? Theme.accent : Theme.border

                Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    text: String(button.modelData.label || "")
                    color: button.applyReady ? Theme.wsActiveText : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: button.action === "apply"
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: button.enabledAction
                    cursorShape: button.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (button.action === "apply")
                            root.applyPage()
                        else if (button.action === "undo") {
                            MenuSettings.editor.undo()
                            root.formError = ""
                        } else {
                            MenuSettings.editor.reset()
                            root.formError = ""
                        }
                    }

                    HoverTip {
                        message: {
                            if (button.action === "apply")
                                return "Save the icon and the command"
                            if (button.action === "undo")
                                return "Drop an unsaved draft, or put back the last applied one"
                            return "Restore the nine-square icon and clear the command. Apply saves it."
                        }
                        show: buttonMouse.containsMouse
                    }
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.fontOpen
        sourceComponent: Component {
            FontPicker {
                width: parent.width
                height: parent.height
                families: root.fontNames
                onChosen: (family) => {
                    MenuSettings.editor.set("font", family)
                    root.fontOpen = false
                }
                onDismiss: root.fontOpen = false
            }
        }
    }
}
