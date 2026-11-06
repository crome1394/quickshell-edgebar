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
                hint: "Font for the pill, and which button opens the terminal. The other button does nothing."
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
                        width: parent.width
                        text: "Terminal click"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Row {
                        spacing: Theme.tabGap

                        Repeater {
                            model: [
                                { id: "left", label: "Left click", tip: "Open btop or nvtop with the left button" },
                                { id: "right", label: "Right click", tip: "Open btop or nvtop with the right button" }
                            ]
                            delegate: Rectangle {
                                id: clickChip
                                required property var modelData
                                required property int index
                                readonly property string clickId: String(clickChip.modelData.id || "")
                                readonly property bool chosen: StatsSettings.editor.value.click === clickChip.clickId

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
                                    onClicked: StatsSettings.editor.set("click", clickChip.clickId)

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

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Thresholds"
                hint: "Each step has a color to the left of the buttons. Above high is the color past the last step. Apply stores the steps and colors in the theme."
            }

            Item {
                width: parent.width
                height: root.wide
                       ? Math.max(cpuBands.implicitHeight, memBands.implicitHeight) + Theme.space + Math.max(gpuBands.implicitHeight, vramBands.implicitHeight)
                       : cpuBands.implicitHeight + memBands.implicitHeight + gpuBands.implicitHeight + vramBands.implicitHeight + Theme.space * 3

                StatBandGroup {
                    id: cpuBands
                    x: Theme.sectionInset
                    width: root.wide ? (parent.width - Theme.sectionInset * 2 - Theme.space) / 2 : parent.width - Theme.sectionInset * 2
                    metric: "cpu"
                    title: "CPU"
                    onColorRequested: (slot) => root.pickStatColor("cpu", slot)
                }

                StatBandGroup {
                    id: memBands
                    x: root.wide ? cpuBands.x + cpuBands.width + Theme.space : Theme.sectionInset
                    y: root.wide ? 0 : cpuBands.height + Theme.space
                    width: cpuBands.width
                    metric: "mem"
                    title: "Memory"
                    onColorRequested: (slot) => root.pickStatColor("mem", slot)
                }

                StatBandGroup {
                    id: gpuBands
                    x: Theme.sectionInset
                    y: root.wide ? Math.max(cpuBands.height, memBands.height) + Theme.space : memBands.y + memBands.height + Theme.space
                    width: cpuBands.width
                    metric: "gpu"
                    title: "GPU"
                    onColorRequested: (slot) => root.pickStatColor("gpu", slot)
                }

                StatBandGroup {
                    id: vramBands
                    x: root.wide ? cpuBands.x + cpuBands.width + Theme.space : Theme.sectionInset
                    y: root.wide ? gpuBands.y : gpuBands.y + gpuBands.height + Theme.space
                    width: cpuBands.width
                    metric: "vram"
                    title: "VRAM"
                    onColorRequested: (slot) => root.pickStatColor("vram", slot)
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            SectionHeader {
                width: parent.width
                title: "Terminal"
                hint: "CPU and Memory open btop. GPU and VRAM open nvtop. The window class and title are the program name."
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
        applyTip: "Save the sections, the font, the threshold steps and colors, the terminal, and the click"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the theme steps and colors, the bar font, all four sections, the bars, kitty, and left click. Apply saves it."
        onApplyClicked: StatsSettings.editor.apply()
        onUndoClicked: StatsSettings.editor.undo()
        onResetClicked: StatsSettings.editor.reset()
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
