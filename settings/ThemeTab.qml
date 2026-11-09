pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.theme

// Settings → Theme: pick a preset or one of your saved themes, adjust it
// (tone, accent, alert, tint, temperature steps), save it under a
// name, and import or export theme files. Apply makes the draft live.
Item {
    id: root

    property int revealSerial: 0
    property string revealSection: ""

    readonly property var draft: ThemeSettings.editor.value
    readonly property var theme: root.draft.theme
    readonly property var saved: ThemeSettings.library()
    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property string home: Quickshell.env("HOME") || "/"

    property string paintKey: ""
    // Which font the picker is choosing: "ui", "bar", or "" (closed).
    property string fontKey: ""
    property string status: ""
    property bool statusBad: false

    function say(message, bad) {
        root.status = message
        root.statusBad = !!bad
    }

    function same(a, b) {
        return JSON.stringify(ThemeBuilder.normalize(a)) === JSON.stringify(ThemeBuilder.normalize(b))
    }

    function paint(key) {
        root.paintKey = key
        picker.selectedColor = root.theme[key]
        picker.open()
    }

    // A file URL from a dialog as a local path, or "".
    function localPath(url) {
        const text = String(url || "")
        if (!text.startsWith("file://"))
            return ""
        const path = decodeURIComponent(text.substring(7))
        return path.startsWith("/") && path.indexOf("\n") < 0 ? path : ""
    }

    function saveAs() {
        const name = nameField.text.trim()
        if (!name.length) {
            root.say("Give the theme a name first.", true)
            return
        }
        const replacing = ThemeSettings.hasSaved(name)
        if (!ThemeSettings.saveCurrent(name)) {
            root.say("No room for more saved themes (" + Theme.themeLibraryMax + " at most).", true)
            return
        }
        ThemeSettings.setField("name", name)
        root.say((replacing ? "Updated " : "Saved ") + name + ", with your stat and audio thresholds.", false)
    }

    function exportTo(url) {
        const path = root.localPath(url)
        if (!path.length) {
            root.say("Pick a local file to export to.", true)
            return
        }
        exportFile.path = path
        exportFile.setText(ThemeSettings.exportText())
    }

    function importFrom(url) {
        const path = root.localPath(url)
        if (!path.length) {
            root.say("Pick a local theme file.", true)
            return
        }
        if (importFile.path === path)
            importFile.reload()
        else
            importFile.path = path
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
                title: "Current theme"
                hint: "Choose a theme below, adjust it here, then Apply. Presets change colors only; your fonts and stat and audio thresholds stay."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                ThemeCard {
                    width: Math.min(parent.width, Theme.themeCardMinWidth * 2)
                    theme: root.theme
                    active: ThemeSettings.editor.dirty
                    note: ThemeSettings.editor.dirty ? "Not applied yet" : "Applied"
                }

                FormRow {
                    width: parent.width
                    label: "Tone"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "Dark"
                            active: root.theme.tone === "dark"
                            tip: "Light text on dark glass"
                            onClicked: ThemeSettings.setField("tone", "dark")
                        }

                        ChipButton {
                            label: "Light"
                            active: root.theme.tone === "light"
                            tip: "Dark text on paper. Best with solid glass (System → Transparency)."
                            onClicked: ThemeSettings.setField("tone", "light")
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Colors"

                    Row {
                        spacing: Theme.space

                        ColorChip {
                            value: root.theme.accent
                            tip: "Accent: hovers, borders, the active workspace, and highlights"
                            onClicked: root.paint("accent")
                        }

                        ColorChip {
                            value: root.theme.alert
                            tip: "Alert: errors, hot temperatures, and calendar weekdays"
                            onClicked: root.paint("alert")
                        }

                        ColorChip {
                            value: root.theme.tint
                            tip: "Tint: the color of the bar, pill, and menu glass"
                            onClicked: root.paint("tint")
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Glass"

                    Text {
                        width: parent.width
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        text: "Bar and menu glass are set in System → Transparency, the same for every theme."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }

                FormRow {
                    width: parent.width
                    label: "CPU warm at"

                    IntSlider {
                        width: parent.width
                        from: Theme.themeTempMin
                        to: Theme.themeTempMax - Theme.themeTempStep
                        step: Theme.themeTempStep
                        value: root.theme.temp.warmAt
                        readout: root.theme.temp.warmAt + "°"
                        tip: "System Stats shows the CPU temperature in the warm color above this"
                        onChanged: (value) => ThemeSettings.setTemp("warmAt", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "CPU hot at"

                    IntSlider {
                        width: parent.width
                        from: Theme.themeTempMin + Theme.themeTempStep
                        to: Theme.themeTempMax
                        step: Theme.themeTempStep
                        value: root.theme.temp.hotAt
                        readout: root.theme.temp.hotAt + "°"
                        tip: "System Stats shows the CPU temperature in the alert color above this"
                        onChanged: (value) => ThemeSettings.setTemp("hotAt", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "UI font"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: root.theme.fonts.ui.length ? root.theme.fonts.ui : "Default (" + DefaultTheme.uiFont + ")"
                            tip: "Font for menus, Settings, and labels"
                            onClicked: {
                                root.fontKey = "ui"
                                FontService.load()
                            }
                        }

                        ChipButton {
                            visible: root.theme.fonts.ui.length > 0
                            label: "Default"
                            tip: "Use " + DefaultTheme.uiFont
                            onClicked: ThemeSettings.setFont("ui", "")
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Bar font"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: root.theme.fonts.bar.length ? root.theme.fonts.bar : "Default (" + DefaultTheme.fontFamily + ")"
                            tip: "Font for text on the bar (clock, stats, workspace names) unless a widget sets its own"
                            onClicked: {
                                root.fontKey = "bar"
                                FontService.load()
                            }
                        }

                        ChipButton {
                            visible: root.theme.fonts.bar.length > 0
                            label: "Default"
                            tip: "Use " + DefaultTheme.fontFamily
                            onClicked: ThemeSettings.setFont("bar", "")
                        }
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Text size"

                    IntSlider {
                        width: parent.width
                        from: 80
                        to: 130
                        step: 5
                        value: root.theme.fonts.size
                        readout: root.theme.fonts.size + "%"
                        tip: "Scales text and icons on the bar, in menus, and in Settings"
                        onChanged: (value) => ThemeSettings.setFont("size", value)
                    }
                }

                Row {
                    visible: Object.keys(root.theme.colors).length > 0
                    width: parent.width
                    spacing: Theme.space

                    Text {
                        width: parent.width - clearButton.width - Theme.space
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: "This theme sets " + Object.keys(root.theme.colors).length + " colors of its own (text, workspaces, and so on)."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    ChipButton {
                        id: clearButton
                        label: "Use derived colors"
                        tip: "Drop those colors and derive every color from the accent, alert, and tint"
                        onClicked: ThemeSettings.clearDetails()
                    }
                }

                Text {
                    visible: root.draft.stats !== null || root.draft.audio !== null
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "This theme also brings its own stat and audio thresholds and colors. Apply replaces yours."
                    color: Theme.accent
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
                title: "Settings window"
                hint: "How the tabs along the bottom of Settings look. Saves at once."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Tab style"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "Index dividers"
                            active: Config.settingsTabStyle !== "flat"
                            tip: "Colored tabs hanging from the page, like a binder's dividers"
                            onClicked: Config.saveFields(() => { Config.settingsTabStyle = "" })
                        }

                        ChipButton {
                            label: "Flat"
                            active: Config.settingsTabStyle === "flat"
                            tip: "Plain chips in the theme's colors"
                            onClicked: Config.saveFields(() => { Config.settingsTabStyle = "flat" })
                        }
                    }
                }

                FormRow {
                    visible: Config.settingsTabStyle !== "flat"
                    width: parent.width
                    label: "Tab colors"

                    Row {
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "Rainbow"
                            active: Config.settingsTabColors !== "accent"
                            tip: "A fixed color per section, so you can find tabs by color"
                            onClicked: Config.saveFields(() => { Config.settingsTabColors = "" })
                        }

                        ChipButton {
                            label: "From accent"
                            active: Config.settingsTabColors === "accent"
                            tip: "Hues spread around the theme's accent, so they change with the theme"
                            onClicked: Config.saveFields(() => { Config.settingsTabColors = "accent" })
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
                title: "My themes"
                hint: "Save the look above under a name. A saved theme keeps your stat and audio thresholds and colors too. Export writes a theme file; Import reads one from this bar or the old bar."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                Row {
                    width: parent.width
                    spacing: Theme.tabGap

                    TextField {
                        id: nameField
                        width: parent.width - saveButton.width - importButton.width - exportButton.width - parent.spacing * 3
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true
                        maximumLength: 48
                        text: root.theme.name
                        placeholderText: "Theme name"
                        leftPadding: Theme.space
                        color: Theme.text
                        placeholderTextColor: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: nameField.activeFocus ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: nameField.activeFocus ? Theme.accent : Theme.border
                        }
                        onAccepted: root.saveAs()
                    }

                    ChipButton {
                        id: saveButton
                        label: ThemeSettings.hasSaved(nameField.text) ? "Update" : "Save"
                        bold: true
                        tip: "Save the look above, with your thresholds, under this name"
                        onClicked: root.saveAs()
                    }

                    ChipButton {
                        id: importButton
                        label: "Import…"
                        tip: "Add a theme file (from this bar or the old bar) to My themes"
                        onClicked: importDialog.open()
                    }

                    ChipButton {
                        id: exportButton
                        label: "Export…"
                        tip: "Write the look above, with your thresholds, to a theme file"
                        onClicked: exportDialog.open()
                    }
                }

                Text {
                    visible: root.status.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.status
                    color: root.statusBad ? Theme.danger : Theme.ok
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                Text {
                    visible: root.saved.length === 0
                    width: parent.width
                    text: "No saved themes yet."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }

                Flow {
                    id: savedFlow
                    width: parent.width
                    spacing: Theme.space
                    readonly property int cols: Math.max(1, Math.floor((width + spacing) / (Theme.themeCardMinWidth + spacing)))
                    readonly property real cardWidth: (width - spacing * (cols - 1)) / cols

                    Repeater {
                        model: root.saved
                        delegate: ThemeCard {
                            required property var modelData
                            width: savedFlow.cardWidth
                            theme: modelData
                            removable: true
                            note: modelData.stats || modelData.audio ? "With thresholds" : ""
                            active: root.theme.name === modelData.name && root.same(root.theme, modelData)
                            onChosen: ThemeSettings.choose(modelData)
                            onRemoveRequested: {
                                ThemeSettings.removeSaved(modelData.name)
                                root.say("Deleted " + modelData.name + ".", false)
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            Repeater {
                model: ThemePresets.groups
                delegate: Column {
                    id: group
                    required property string modelData
                    width: body.width
                    spacing: Theme.space

                    SectionHeader {
                        width: parent.width
                        title: group.modelData === "New" ? "New presets" : group.modelData + " presets"
                        hint: group.modelData === "Light"
                            ? "Paper themes with dark text. They stay solid so text holds up over any wallpaper."
                            : (group.modelData === "New" ? "Added with this bar." : "From the old bar, adapted to this one.")
                    }

                    Flow {
                        id: presetFlow
                        x: Theme.sectionInset
                        width: parent.width - Theme.sectionInset * 2
                        spacing: Theme.space
                        readonly property int cols: Math.max(1, Math.floor((width + spacing) / (Theme.themeCardMinWidth + spacing)))
                        readonly property real cardWidth: (width - spacing * (cols - 1)) / cols

                        Repeater {
                            model: ThemePresets.list.filter((t) => t.group === group.modelData)
                            delegate: ThemeCard {
                                required property var modelData
                                width: presetFlow.cardWidth
                                theme: modelData
                                active: root.theme.name === modelData.name && root.same(root.theme, modelData)
                                onChosen: ThemeSettings.choose(modelData)
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.tabGap
                    }
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: ThemeSettings.editor.dirty
        undoEnabled: ThemeSettings.editor.canUndo
        applyTip: "Make this theme live on the bar, menus, and Settings"
        undoTip: "Drop an unsaved draft, or put back the last applied theme"
        resetTip: "Draft Liquid amber, the bar's default. Your thresholds stay. Apply saves it."
        onApplyClicked: ThemeSettings.editor.apply()
        onUndoClicked: ThemeSettings.editor.undo()
        onResetClicked: ThemeSettings.editor.reset()
    }

    // Font list over the page while choosing a font.
    Loader {
        anchors.fill: parent
        z: 3
        active: root.fontKey.length > 0 && FontService.ready
        sourceComponent: Component {
            FontPicker {
                families: FontService.families
                onChosen: (family) => {
                    ThemeSettings.setFont(root.fontKey, family)
                    root.fontKey = ""
                }
                onDismiss: root.fontKey = ""
            }
        }
    }

    ColorDialog {
        id: picker
        title: "Theme color"
        onAccepted: ThemeSettings.setField(root.paintKey, selectedColor)
    }

    FileDialog {
        id: exportDialog
        title: "Export theme"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: ["Theme files (*.json)"]
        currentFolder: "file://" + root.home
        selectedFile: "file://" + root.home + "/" + root.theme.name.replace(/[^A-Za-z0-9._ -]/g, "").trim().replace(/ +/g, "-") + ".json"
        onAccepted: root.exportTo(selectedFile)
    }

    FileDialog {
        id: importDialog
        title: "Import theme"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Theme files (*.json)", "All files (*)"]
        currentFolder: "file://" + root.home
        onAccepted: root.importFrom(selectedFile)
    }

    // Writes an export. Created with the page, idle until a path is set.
    FileView {
        id: exportFile
        atomicWrites: true
        printErrors: false
        onSaved: root.say("Exported to " + exportFile.path + ".", false)
        onSaveFailed: root.say("Could not write " + exportFile.path + ".", true)
    }

    // Reads an import when a path is chosen.
    FileView {
        id: importFile
        printErrors: false
        onLoaded: {
            const error = ThemeSettings.importText(importFile.text())
            if (error.length)
                root.say(error, true)
            else
                root.say("Imported " + root.theme.name + " into My themes. Apply to use it.", false)
        }
        onLoadFailed: root.say("Could not read " + importFile.path + ".", true)
    }
}
