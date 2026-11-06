pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

Item {
    id: root

    property var terminals: []
    property string actionError: ""
    property bool fontOpen: false
    property string paintMetric: "cpu"
    property int paintSlot: 0
    property bool fontWaiting: false
    property bool fontReady: false
    property var fontNames: []

    readonly property int styleWidth: Theme.chip + Theme.borderWidth * 4
    readonly property bool wide: width >= Theme.settingsTwoColMin

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

    function addTerminal(line) {
        const name = String(line || "").trim()
        if (!/^[A-Za-z0-9._+-]{1,64}$/.test(name))
            return
        const have = root.terminals
        for (let i = 0; i < have.length; i++) {
            if (have[i] === name)
                return
        }
        root.terminals = have.concat([name])
    }

    Component.onCompleted: {
        termProc.running = true
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

    Process {
        id: termProc
        command: ["bash", Quickshell.shellDir + "/scripts/list-terminals.sh"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => root.addTerminal(line)
        }
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
                title: "System Stats Toggles"
                hint: "Which parts of the pill are drawn. Apply saves this page. Turn the widget on under Bars."
            }

            Item {
                width: parent.width
                height: toggleCol.implicitHeight

                Column {
                    id: toggleCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    CheckRow {
                        width: parent.width
                        title: "Show CPU"
                        detail: "CPU percent, temperature, and bar"
                        tip: "Show the CPU section on the System Stats pill"
                        checked: StatsSettings.editor.value.cpu
                        onToggled: StatsSettings.editor.set("cpu", !StatsSettings.editor.value.cpu)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Show Memory"
                        detail: "Memory percent, used memory, and bar"
                        tip: "Show the Memory section on the System Stats pill"
                        checked: StatsSettings.editor.value.mem
                        onToggled: StatsSettings.editor.set("mem", !StatsSettings.editor.value.mem)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Show GPU"
                        detail: "GPU percent, temperature, and bar"
                        tip: "Show the GPU section on the System Stats pill"
                        checked: StatsSettings.editor.value.gpu
                        onToggled: StatsSettings.editor.set("gpu", !StatsSettings.editor.value.gpu)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Show VRAM"
                        detail: "VRAM percent, used memory, and bar"
                        tip: "Show the VRAM section on the System Stats pill"
                        checked: StatsSettings.editor.value.vram
                        onToggled: StatsSettings.editor.set("vram", !StatsSettings.editor.value.vram)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Show Bar Graphs"
                        detail: "Utilization bars on the pill"
                        tip: "Show or hide the bars on the System Stats pill"
                        checked: StatsSettings.editor.value.gauges
                        onToggled: StatsSettings.editor.set("gauges", !StatsSettings.editor.value.gauges)
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
                hint: "Font for the pill, and what a left or right click on each group runs. Leave a field empty to do nothing."
            }

            Item {
                width: parent.width
                height: miscCol.implicitHeight

                Column {
                    id: miscCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Row {
                        id: faceRow
                        width: parent.width
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
                                text: StatsSettings.editor.value.font.length ? StatsSettings.editor.value.font : "Bar font"
                                color: Theme.text
                                font.family: StatsSettings.editor.value.font.length ? StatsSettings.editor.value.font : Theme.uiFont
                                font.pixelSize: Theme.fontPx
                                font.bold: StatsSettings.editor.value.bold
                                font.italic: StatsSettings.editor.value.italic
                            }

                            MouseArea {
                                id: fontMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openFont()

                                HoverTip {
                                    message: "Font for the stats pill. Empty uses the bar font."
                                    show: fontMouse.containsMouse
                                }
                            }
                        }

                        Rectangle {
                            width: root.styleWidth
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: StatsSettings.editor.value.bold ? Theme.accentDim : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: StatsSettings.editor.value.bold ? Theme.accent : Theme.border

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
                                onClicked: StatsSettings.editor.set("bold", !StatsSettings.editor.value.bold)

                                HoverTip {
                                    message: "Bold the stats text"
                                    show: boldMouse.containsMouse
                                }
                            }
                        }

                        Rectangle {
                            width: root.styleWidth
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: StatsSettings.editor.value.italic ? Theme.accentDim : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: StatsSettings.editor.value.italic ? Theme.accent : Theme.border

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
                                onClicked: StatsSettings.editor.set("italic", !StatsSettings.editor.value.italic)

                                HoverTip {
                                    message: "Italic the stats text"
                                    show: italicMouse.containsMouse
                                }
                            }
                        }

                        IntSlider {
                            width: Math.max(Theme.fieldHeight * 4, faceRow.width - fontButton.width - root.styleWidth * 2 - Theme.tabGap * 3)
                            from: Theme.clockFontMin
                            to: Theme.clockFontMax
                            step: Theme.clockFontStep
                            value: StatsSettings.editor.value.fontPercent
                            readout: StatsSettings.editor.value.fontPercent + "%"
                            tip: "Stats text size, from " + Theme.clockFontMin + " to " + Theme.clockFontMax
                            onChanged: (value) => StatsSettings.editor.set("fontPercent", value)
                        }
                    }

                    Text {
                        visible: root.actionError.length > 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.actionError
                        color: Theme.danger
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Repeater {
                        model: StatsSettings.actionSlots
                        delegate: CommandRow {
                            required property var modelData
                            width: parent.width
                            title: String(modelData.label)
                            command: StatsSettings.editor.value.actions[modelData.id].cmd
                            inTerminal: StatsSettings.editor.value.actions[modelData.id].term
                            onCommandEdited: (text) => StatsSettings.setAction(String(modelData.id), "cmd", text)
                            onTerminalToggled: (on) => StatsSettings.setAction(String(modelData.id), "term", on)
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
                title: "Terminal"
                hint: "Click commands marked Terminal open in this terminal. The window keeps the terminal's own class, so its window rules apply."
            }

            Item {
                width: parent.width
                height: termCol.implicitHeight

                Column {
                    id: termCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        text: "Default terminal"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Text {
                        visible: root.terminals.length === 0
                        width: parent.width
                        text: "No terminal found"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Item {
                        width: parent.width
                        height: termFlow.implicitHeight

                        Flow {
                            id: termFlow
                            width: parent.width
                            spacing: Theme.tabGap

                            Repeater {
                                model: root.terminals
                                delegate: Rectangle {
                                    id: termChip
                                    required property string modelData
                                    required property int index
                                    readonly property bool chosen: StatsSettings.editor.value.terminal === termChip.modelData

                                    width: termLabel.implicitWidth + Theme.space * 2
                                    height: Theme.fieldHeight
                                    radius: Theme.radiusSm
                                    color: termChip.chosen ? Theme.accentDim : (termMouse.containsMouse ? Theme.hover : Theme.pillBg)
                                    border.width: Theme.borderWidth
                                    border.color: termChip.chosen ? Theme.accent : Theme.border

                                    Text {
                                        id: termLabel
                                        anchors.centerIn: parent
                                        text: termChip.modelData
                                        color: termChip.chosen ? Theme.wsActiveText : Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                        font.bold: termChip.chosen
                                    }

                                    MouseArea {
                                        id: termMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: StatsSettings.setTerminal(termChip.modelData)

                                        HoverTip {
                                            message: "Open btop and nvtop in " + termChip.modelData
                                            show: termMouse.containsMouse
                                        }
                                    }
                                }
                            }
                        }
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
        applyEnabled: StatsSettings.editor.dirty
        undoEnabled: StatsSettings.editor.canUndo
        applyTip: "Save the sections, the font, the click commands, the threshold steps and colors, and the terminal"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the theme steps and colors, the bar font, all four sections, the bars, kitty, and btop and nvtop on left click. Apply saves it."
        onApplyClicked: {
            if (StatsSettings.apply())
                root.actionError = ""
            else
                root.actionError = "Check the command for " + StatsSettings.badAction(StatsSettings.editor.draft.actions) + ". Use a program and arguments, with no shell characters."
        }
        onUndoClicked: {
            StatsSettings.editor.undo()
            root.actionError = ""
        }
        onResetClicked: {
            StatsSettings.editor.reset()
            root.actionError = ""
        }
    }

    function pickStatColor(metric, slot) {
        root.paintMetric = metric
        root.paintSlot = slot
        bandColors.selectedColor = StatsSettings.colorAt(metric, slot)
        bandColors.open()
    }

    ColorDialog {
        id: bandColors
        title: "Threshold color"
        onAccepted: StatsSettings.setColor(root.paintMetric, root.paintSlot, selectedColor)
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
                    StatsSettings.editor.set("font", family)
                    root.fontOpen = false
                }
                onDismiss: root.fontOpen = false
            }
        }
    }
}
