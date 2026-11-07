pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// Applications → Application Menu: the pill icon (a symbol or an image),
// its size and color, and the command a click runs.
Item {
    id: root

    property bool formReady: false
    property bool fontOpen: false
    property bool fontWaiting: false

    // The shared font list arrived while a picker was waiting for it.
    onFontReadyChanged: {
        if (root.fontReady && root.fontWaiting) {
            root.fontWaiting = false
            root.fontOpen = true
        }
    }
    readonly property var fontNames: FontService.families
    readonly property bool fontReady: FontService.ready
    property string formError: ""
    property string imageError: ""

    readonly property var draft: MenuSettings.editor.value
    readonly property bool imageMode: root.draft.mode === "image"
    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property int displayPx: root.draft.px >= Theme.menuFontMin ? root.draft.px : Theme.iconPx
    readonly property color previewColor: root.draft.color.length ? root.draft.color : Theme.text
    readonly property string symbolFont: root.draft.font.length ? root.draft.font : Theme.iconFont
    readonly property string fontLabel: root.draft.font.length ? root.draft.font : "Icon font (default)"
    readonly property string previewUrl: root.imageMode ? MenuSettings.imageUrl(root.draft.image) : ""
    readonly property bool previewImage: (previewLoader.item as MenuIconImage)?.ready ?? false
    readonly property bool previewFailed: (previewLoader.item as MenuIconImage)?.failed ?? false

    function openFont() {
        if (root.fontReady) {
            root.fontOpen = true
            return
        }
        root.fontWaiting = true
        FontService.load()
    }

    function openImage() {
        const path = root.draft.image
        const folder = path.length ? path.substring(0, path.lastIndexOf("/")) : Quickshell.env("HOME")
        if (folder && folder.length)
            imageDialog.currentFolder = "file://" + folder
        imageDialog.open()
    }

    function openColor() {
        if (root.draft.color.length)
            colors.selectedColor = root.draft.color
        colors.open()
    }

    function applyPage() {
        if (MenuSettings.apply())
            root.formError = ""
        else
            root.formError = "The command needs a program and arguments, with no shell characters."
    }

    Component.onCompleted: {
        symbolField.text = root.draft.symbol
        commandField.text = root.draft.command
        root.formReady = true
        FontService.load()
    }

    // Undo, Reset, and Apply change the draft; keep the text fields in step.
    Connections {
        target: MenuSettings.editor
        function onValueChanged() {
            if (!root.formReady)
                return
            if (symbolField.text !== root.draft.symbol)
                symbolField.text = root.draft.symbol
            if (commandField.text !== root.draft.command)
                commandField.text = root.draft.command
        }
    }

    ColorDialog {
        id: colors
        title: "Application Menu color"
        onAccepted: MenuSettings.editor.set("color", String(selectedColor))
    }

    FileDialog {
        id: imageDialog
        title: "Application Menu image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Icons (*.svg *.svgz *.png)", "SVG (*.svg *.svgz)", "PNG (*.png)"]
        onAccepted: root.imageError = MenuSettings.setImage(String(selectedFile)) ? "" : "Pick an .svg, .svgz, or .png file."
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
                text: "The icon sits on the bar. A click runs the command. Apply saves this page. Turn the widget on under Widgets."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            SectionHeader {
                width: parent.width
                title: "Icon"
                hint: "Show a symbol from a font, or an SVG or PNG image. If the image cannot be loaded, the bar shows the symbol."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                // Preview and the symbol/image switch.
                Row {
                    width: parent.width
                    spacing: Theme.space * 2

                    Rectangle {
                        id: preview
                        width: Theme.menuPreviewSize
                        height: Theme.menuPreviewSize
                        radius: Theme.radius
                        color: Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        Loader {
                            id: previewLoader
                            anchors.centerIn: parent
                            active: root.previewUrl.length > 0
                            sourceComponent: Component {
                                MenuIconImage {
                                    source: root.previewUrl
                                    px: root.displayPx
                                    ink: root.previewColor
                                    tint: root.draft.tint
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !root.previewImage
                            text: MenuSettings.symbolValue(root.draft.symbol)
                            color: root.previewColor
                            font.family: root.symbolFont
                            font.pixelSize: root.displayPx
                            font.bold: root.draft.bold
                            font.italic: root.draft.italic
                        }

                        HoverHandler {
                            id: previewHover
                        }

                        HoverTip {
                            message: "How the icon looks on the bar"
                            show: previewHover.hovered
                        }
                    }

                    Column {
                        width: parent.width - preview.width - parent.spacing
                        spacing: Theme.tabGap

                        Text {
                            text: "Show"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        Row {
                            spacing: Theme.tabGap

                            ChipButton {
                                label: "Symbol"
                                minWidth: Theme.fieldHeight * 3
                                active: !root.imageMode
                                tip: "Use a character from a font"
                                onClicked: MenuSettings.editor.set("mode", "symbol")
                            }

                            ChipButton {
                                label: "Image"
                                minWidth: Theme.fieldHeight * 3
                                active: root.imageMode
                                tip: "Use an SVG or PNG file"
                                onClicked: {
                                    if (root.draft.image.length)
                                        MenuSettings.editor.set("mode", "image")
                                    else
                                        root.openImage()
                                }
                            }
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Size"

                    IntSlider {
                        width: parent.width
                        from: Theme.menuFontMin
                        to: Theme.menuFontMax
                        value: root.displayPx
                        readout: root.displayPx + " px"
                        tip: "Icon size, from " + Theme.menuFontMin + " to " + Theme.menuFontMax + " px"
                        onChanged: (value) => MenuSettings.setFontPx(value)
                    }
                }

                // Symbol mode.
                FormRow {
                    visible: !root.imageMode
                    width: parent.width
                    label: "Symbol"

                    Row {
                        width: parent.width
                        spacing: Theme.space

                        TextField {
                            id: symbolField
                            width: Theme.fieldHeight * 3
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            selectByMouse: true
                            placeholderText: Theme.menuSymbolDefault
                            color: root.previewColor
                            placeholderTextColor: Theme.subtext
                            font.family: root.symbolFont
                            font.pixelSize: Theme.fontPx
                            font.bold: root.draft.bold
                            font.italic: root.draft.italic
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
                                if (next !== root.draft.symbol)
                                    MenuSettings.editor.set("symbol", next)
                            }

                            HoverHandler {
                                id: symbolHover
                            }

                            HoverTip {
                                message: "Up to 3 characters. Empty uses the nine-square icon."
                                show: symbolHover.hovered
                            }
                        }

                        Text {
                            width: parent.width - symbolField.width - parent.spacing
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: "Up to 3 characters"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }
                }

                FormRow {
                    visible: !root.imageMode
                    width: parent.width
                    label: "Font"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        Rectangle {
                            width: parent.width - fontDefault.width - parent.spacing
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
                                    message: "Choose the font for the symbol"
                                    show: fontMouse.containsMouse
                                }
                            }
                        }

                        ChipButton {
                            id: fontDefault
                            label: "Default"
                            enabled: root.draft.font.length > 0
                            tip: "Use the icon font"
                            onClicked: MenuSettings.editor.set("font", "")
                        }
                    }
                }

                FormRow {
                    visible: !root.imageMode
                    width: parent.width
                    label: "Style"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "B"
                            bold: true
                            active: root.draft.bold
                            tip: "Bold the symbol"
                            onClicked: MenuSettings.editor.set("bold", !root.draft.bold)
                        }

                        ChipButton {
                            label: "I"
                            italic: true
                            active: root.draft.italic
                            tip: "Italic the symbol"
                            onClicked: MenuSettings.editor.set("italic", !root.draft.italic)
                        }
                    }
                }

                // Image mode.
                FormRow {
                    visible: root.imageMode
                    width: parent.width
                    label: "File"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        Rectangle {
                            width: parent.width - chooseButton.width - parent.spacing
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: fileMouse.containsMouse ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: root.previewFailed ? Theme.danger : Theme.border

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: root.draft.image.length ? root.draft.image : "No image chosen"
                                color: root.draft.image.length ? Theme.text : Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontPx
                            }

                            MouseArea {
                                id: fileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openImage()

                                HoverTip {
                                    message: root.draft.image.length ? root.draft.image : "Choose an SVG or PNG file"
                                    show: fileMouse.containsMouse
                                }
                            }
                        }

                        ChipButton {
                            id: chooseButton
                            label: "Choose…"
                            tip: "Choose an SVG or PNG file"
                            onClicked: root.openImage()
                        }
                    }
                }

                Text {
                    visible: root.imageMode && (root.imageError.length > 0 || root.previewFailed)
                    x: Theme.formLabelWidth + Theme.space
                    width: parent.width - x
                    wrapMode: Text.WordWrap
                    text: root.imageError.length ? root.imageError : "This image could not be loaded. The bar shows the symbol instead."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                FormRow {
                    visible: root.imageMode
                    width: parent.width
                    label: "Tint"

                    CheckRow {
                        width: parent.width
                        title: "Fill with the color"
                        detail: "For one-color SVGs. Off keeps the image's own colors."
                        tip: "Paint the image's shape with the color below"
                        checked: root.draft.tint
                        onToggled: MenuSettings.editor.set("tint", !root.draft.tint)
                    }
                }

                // Shared by both modes; in image mode it only shows with Tint on.
                FormRow {
                    visible: !root.imageMode || root.draft.tint
                    width: parent.width
                    label: "Color"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        Rectangle {
                            width: Theme.fieldHeight * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: root.previewColor
                            border.width: Theme.borderWidth
                            border.color: swatchMouse.containsMouse ? Theme.accent : Theme.border

                            MouseArea {
                                id: swatchMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton)
                                        MenuSettings.editor.set("color", "")
                                    else
                                        root.openColor()
                                }

                                HoverTip {
                                    message: "Choose the icon color. Right-click clears it."
                                    show: swatchMouse.containsMouse
                                }
                            }
                        }

                        ChipButton {
                            id: colorDefault
                            label: "Default"
                            enabled: root.draft.color.length > 0
                            tip: "Follow the theme: text color, accent on hover"
                            onClicked: MenuSettings.editor.set("color", "")
                        }

                        Text {
                            width: Math.max(0, parent.width - Theme.fieldHeight * 2 - colorDefault.width - parent.spacing * 2)
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: root.draft.color.length ? root.draft.color : "Theme color"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
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
                title: "Command"
                hint: "Program and arguments, separated by spaces. A shell is not used, and shell characters are rejected. Empty does nothing on click."
            }

            Column {
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
                        if (text !== root.draft.command)
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

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: MenuSettings.editor.dirty
        undoEnabled: MenuSettings.editor.canUndo
        applyTip: "Save the icon and the command"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the nine-square symbol and clear the command. Apply saves it."
        onApplyClicked: root.applyPage()
        onUndoClicked: {
            MenuSettings.editor.undo()
            root.formError = ""
            root.imageError = ""
        }
        onResetClicked: {
            MenuSettings.editor.reset()
            root.formError = ""
            root.imageError = ""
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
