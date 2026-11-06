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

    readonly property int styleWidth: Theme.chip + Theme.borderWidth * 4
    readonly property var weekChoices: [
        { id: "0", label: "Sunday", tip: "Sunday is the first column" },
        { id: "1", label: "Monday", tip: "Monday is the first column" },
        { id: "2", label: "Tuesday", tip: "Tuesday is the first column" },
        { id: "3", label: "Wednesday", tip: "Wednesday is the first column" },
        { id: "4", label: "Thursday", tip: "Thursday is the first column" },
        { id: "5", label: "Friday", tip: "Friday is the first column" },
        { id: "6", label: "Saturday", tip: "Saturday is the first column" }
    ]
    readonly property var presetChoices: {
        const list = Config.clockPresets()
        const out = []
        for (let i = 0; i < list.length; i++) {
            const row = list[i]
            if (!row)
                continue
            out.push({
                id: String(row.format || ""),
                label: String(row.label || ""),
                tip: String(row.tip || row.format || "")
            })
        }
        return out
    }
    readonly property bool draftIsPreset: {
        const want = String(Config.editorClockFormat || "").trim()
        const presets = Config.clockPresets()
        for (let i = 0; i < presets.length; i++) {
            if (presets[i] && presets[i].format === want)
                return true
        }
        return false
    }
    readonly property string previewFormat: {
        const text = String(Config.editorClockFormat || "").trim()
        return text.length ? text : Config.clockFormatText()
    }
    readonly property color previewColor: Config.editorClockColor.length ? Config.editorClockColor : Theme.text

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

    function commitFormat() {
        const text = String(formatField.text || "").replace(/[\r\n]/g, " ").trim()
        formatField.text = text
        Config.setEditorClockFormat(text)
    }

    Component.onCompleted: {
        Config.ensureClockEditor()
        formatField.text = Config.editorClockFormat
        root.formReady = true
        fontList.running = true
    }

    Connections {
        target: Config
        function onEditorClockFormatChanged() {
            if (formatField.text !== Config.editorClockFormat)
                formatField.text = Config.editorClockFormat
        }
        function onRevisionChanged() {
            if (!root.formReady || Config.clockEditorDirty)
                return
            Config.seedClockEditor()
        }
    }

    SystemClock {
        id: previewClock
        precision: Config.clockFormatHasSeconds(root.previewFormat) ? SystemClock.Seconds : SystemClock.Minutes
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
        title: "Clock color"
        onAccepted: Config.setEditorClockColor(selectedColor)
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

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Date & Time"
                hint: "Font, color, size, and the pattern. Apply saves them on the clock."
            }

            Item {
                width: parent.width
                height: clockCol.implicitHeight

                Column {
                    id: clockCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Row {
                        id: faceRow
                        width: parent.width
                        height: Theme.fieldHeight
                        spacing: Theme.tabGap
                        readonly property int fixed: root.styleWidth * 3

                        Rectangle {
                            id: fontButton
                            width: Math.max(Theme.fieldHeight * 4, Math.round((faceRow.width - faceRow.fixed) * 0.46))
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
                                text: Config.editorClockFont.length ? Config.editorClockFont : "Bar font"
                                color: root.previewColor
                                font.family: Config.editorClockFont.length ? Config.editorClockFont : Theme.uiFont
                                font.pixelSize: Theme.fontPx
                                font.bold: Config.editorClockBold
                                font.italic: Config.editorClockItalic
                            }

                            MouseArea {
                                id: fontMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openFont()

                                HoverTip {
                                    message: "Font for the clock. Empty uses the bar font."
                                    show: fontMouse.containsMouse
                                }
                            }
                        }

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
                                        Config.setEditorClockColor("")
                                        return
                                    }
                                    if (Config.editorClockColor.length)
                                        colors.selectedColor = Config.editorClockColor
                                    colors.open()
                                }

                                HoverTip {
                                    message: "Clock color. Right-click clears it."
                                    show: colorMouse.containsMouse
                                }
                            }
                        }

                        Rectangle {
                            width: root.styleWidth
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: Config.editorClockBold ? Theme.accentDim : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: Config.editorClockBold ? Theme.accent : Theme.border

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
                                onClicked: Config.setEditorClockBold(!Config.editorClockBold)

                                HoverTip {
                                    message: "Bold the clock"
                                    show: boldMouse.containsMouse
                                }
                            }
                        }

                        Rectangle {
                            width: root.styleWidth
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: Config.editorClockItalic ? Theme.accentDim : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: Config.editorClockItalic ? Theme.accent : Theme.border

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
                                onClicked: Config.setEditorClockItalic(!Config.editorClockItalic)

                                HoverTip {
                                    message: "Italic the clock"
                                    show: italicMouse.containsMouse
                                }
                            }
                        }

                        IntSlider {
                            width: Math.max(Theme.fieldHeight * 4, faceRow.width - fontButton.width - root.styleWidth * 3 - Theme.tabGap * 4)
                            from: Theme.clockFontMin
                            to: Theme.clockFontMax
                            step: Theme.clockFontStep
                            value: Config.editorClockPercent
                            readout: Config.editorClockPercent + "%"
                            tip: "Clock text size, from " + Theme.clockFontMin + " to " + Theme.clockFontMax
                            onChanged: (value) => Config.setEditorClockPercent(value)
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Preset"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    SelectBox {
                        width: parent.width
                        choices: root.presetChoices
                        currentId: String(Config.editorClockFormat || "").trim()
                        emptyLabel: "Custom"
                        tip: "Common date and time patterns"
                        onPicked: (id) => Config.setEditorClockFormat(id)
                    }

                    Text {
                        width: parent.width
                        text: "First day of the week"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    SelectBox {
                        width: parent.width
                        choices: root.weekChoices
                        currentId: String(Config.editorClockWeekStart)
                        emptyLabel: "Sunday"
                        tip: "Which weekday is the first column of the calendar"
                        onPicked: (id) => Config.setEditorClockWeekStart(Number(id))
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.space

                        TextField {
                            id: formatField
                            width: parent.width - setButton.width - Theme.space
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            placeholderText: "e.g. ddd HH:mm"
                            leftPadding: Theme.space
                            color: Theme.text
                            placeholderTextColor: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontPx
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: formatField.activeFocus ? Theme.hover : Theme.fieldBg
                                border.width: Theme.borderWidth
                                border.color: root.draftIsPreset ? Theme.border : Theme.accent
                            }
                            onTextChanged: {
                                if (!root.formReady)
                                    return
                                if (text !== Config.editorClockFormat)
                                    Config.setEditorClockFormat(text)
                            }
                            onAccepted: root.commitFormat()

                            HoverHandler {
                                id: formatHover
                            }

                            HoverTip {
                                message: "Qt date and time pattern"
                                show: formatHover.hovered
                            }
                        }

                        Rectangle {
                            id: setButton
                            implicitWidth: setLabel.implicitWidth + Theme.space * 2
                            implicitHeight: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: setMouse.containsMouse ? Theme.hover : Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: setMouse.containsMouse ? Theme.accent : Theme.border

                            Text {
                                id: setLabel
                                anchors.centerIn: parent
                                text: "Set"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }

                            MouseArea {
                                id: setMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.commitFormat()

                                HoverTip {
                                    message: "Keep this pattern for Apply"
                                    show: setMouse.containsMouse
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        implicitHeight: previewCol.implicitHeight + Theme.space * 2
                        radius: Theme.radiusSm
                        color: Theme.fieldBg
                        border.width: Theme.borderWidth
                        border.color: Theme.accent

                        Column {
                            id: previewCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.space
                            spacing: Theme.tabGap

                            Text {
                                text: "Preview" + (root.draftIsPreset ? "" : "  · custom")
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                            }
                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: Qt.formatDateTime(previewClock.date, root.previewFormat)
                                color: root.previewColor
                                font.family: Config.editorClockFont.length ? Config.editorClockFont : Theme.fontFamily
                                font.pixelSize: Math.max(Theme.smallPx, Math.round(Theme.fontPx * Config.editorClockPercent / 100))
                                font.bold: Config.editorClockBold
                                font.italic: Config.editorClockItalic
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Misc"
                hint: "Which button opens the calendar. Apply saves it with the face."
            }

            Item {
                width: parent.width
                height: miscCol.implicitHeight

                Column {
                    id: miscCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        text: "Calendar click"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: [
                                { id: "left", label: "Left click", tip: "Open the calendar with the left button" },
                                { id: "right", label: "Right click", tip: "Open the calendar with the right button" }
                            ]
                            delegate: Rectangle {
                                id: clickChip
                                required property var modelData
                                required property int index
                                readonly property string clickId: String(clickChip.modelData.id || "")
                                readonly property bool chosen: Config.editorClockClick === clickChip.clickId

                                width: clickLabel.implicitWidth + Theme.space * 2
                                height: Theme.fieldHeight
                                radius: Theme.radiusSm
                                color: clickChip.chosen ? Theme.accentDim : (clickMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                border.width: Theme.borderWidth
                                border.color: clickChip.chosen ? Theme.accent : Theme.border

                                Text {
                                    id: clickLabel
                                    anchors.centerIn: parent
                                    text: String(clickChip.modelData.label || "")
                                    color: clickChip.chosen ? Theme.wsActiveText : Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: clickChip.chosen
                                }

                                MouseArea {
                                    id: clickMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.setEditorClockClick(clickChip.clickId)

                                    HoverTip {
                                        message: String(clickChip.modelData.tip || "")
                                        show: clickMouse.containsMouse
                                    }
                                }
                            }
                        }
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
                { id: "undo", label: "Undo" }
            ]
            delegate: Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property string action: String(button.modelData.id || "")
                readonly property bool enabledAction: button.action === "apply" ? Config.clockEditorDirty : Config.canUndoClock()
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
                    cursorShape: button.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!button.enabledAction)
                            return
                        if (button.action === "apply")
                            Config.applyClockEditor()
                        else
                            Config.undoClockEditor()
                    }

                    HoverTip {
                        message: button.action === "apply"
                            ? "Save the clock face, the week start, and the calendar click"
                            : "Drop an unsaved draft, or put back the last applied one"
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
                    Config.setEditorClockFont(family)
                    root.fontOpen = false
                }
                onDismiss: root.fontOpen = false
            }
        }
    }
}
