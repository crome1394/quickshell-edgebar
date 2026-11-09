pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.theme

// Settings → System → Display: resolution, refresh rate, and color depth.
// Only modes the monitor reports can be picked, and only rates that
// resolution has. 10-bit shows when the monitor supports it, and a mode
// Hyprland would not keep at 10-bit is marked and cannot be picked again.
// Apply asks to Keep, and goes back on its own if there is no answer.
Item {
    id: root

    property string selName: ""
    property string selKey: ""
    property string selMode: ""
    property int selDepth: 8
    // Select whatever the monitor runs on the next refresh: on open, and
    // after a change ends (kept, gone back, or timed out).
    property bool followLive: true

    // Arrangement: open with two or more monitors, folded with one. A click
    // on its title bar overrides that until the monitor count changes.
    readonly property int enabledCount: root.monitors.filter((m) => !m.disabled).length
    property int arrangeOverride: -1
    readonly property bool arrangeOpen: root.arrangeOverride < 0 ? root.enabledCount > 1 : root.arrangeOverride === 1
    onEnabledCountChanged: root.arrangeOverride = -1

    function toggleArrange() {
        root.arrangeOverride = root.arrangeOpen ? 0 : 1
    }
    // Bumped when the saved list of failed pairs changes.
    readonly property var rejected: DisplaySettings.rejectedList()

    readonly property var monitors: DisplayService.monitors
    readonly property var monitor: DisplayService.monitorNamed(root.selName)
    readonly property var groups: root.monitor ? root.monitor.groups : []
    readonly property var group: root.groupFor(root.selKey)
    readonly property string liveMode: root.monitor ? DisplayService.liveMode(root.monitor) : ""
    readonly property bool waiting: DisplayService.pending !== null
    readonly property bool changed: !!root.monitor && (root.selMode !== root.liveMode || root.selDepth !== root.monitor.depth)
    readonly property bool tenBitBlocked: root.rejectedPair(root.selMode, 10)

    function groupFor(key) {
        for (let i = 0; i < root.groups.length; i++) {
            if (root.groups[i].key === key)
                return root.groups[i]
        }
        return null
    }

    function rejectedPair(mode, depth) {
        return !!root.monitor && root.rejected.indexOf(DisplaySettings.rejectKey(root.monitor.name, mode, depth)) >= 0
    }

    function rateLabel(mode) {
        const p = DisplaySettings.parseMode(mode)
        if (!p || !root.monitor)
            return ""
        const g = root.groupFor(p.w + "x" + p.h)
        const r = g ? g.rates.find((x) => x.mode === mode) : null
        return r ? r.label : String(Math.round(p.hz))
    }

    function describe(mode, depth) {
        const p = DisplaySettings.parseMode(mode)
        if (!p)
            return "—"
        return p.w + " × " + p.h + "  ·  " + root.rateLabel(mode) + " Hz  ·  " + depth + "-bit"
    }

    // Start from what the monitor runs now.
    function syncToLive() {
        const m = root.monitor
        if (!m)
            return
        const live = DisplaySettings.parseMode(root.liveMode)
        root.selKey = live ? live.w + "x" + live.h : (root.groups.length ? root.groups[0].key : "")
        root.selMode = root.liveMode
        root.selDepth = m.depth
    }

    function pickMonitor(name) {
        root.selName = name
        root.syncToLive()
    }

    function pickResolution(key) {
        const g = root.groupFor(key)
        if (!g)
            return
        root.selKey = key
        // Keep the same rate when this size has it, else its fastest.
        const keep = g.rates.find((r) => Math.abs(r.hz - (DisplaySettings.parseMode(root.selMode) || { hz: 0 }).hz) < 0.6)
        root.pickRate((keep || g.rates[0]).mode)
    }

    function pickRate(mode) {
        root.selMode = mode
        if (root.selDepth === 10 && (root.rejectedPair(mode, 10) || !root.monitor.tenBit))
            root.selDepth = 8
    }

    function applySelection() {
        if (root.monitor && root.changed)
            DisplayService.apply(root.monitor.name, root.selMode, root.selDepth)
    }

    Component.onCompleted: DisplayService.retain()
    Component.onDestruction: DisplayService.release()

    Connections {
        target: DisplayService
        function onMonitorsChanged() {
            if (root.waiting)
                return
            if (!root.monitor && root.monitors.length) {
                const first = root.monitors.find((m) => !m.disabled) || root.monitors[0]
                root.pickMonitor(first.name)
            } else if (root.followLive || !root.changed || !root.groupFor(root.selKey)) {
                root.syncToLive()
            }
            // Stop following once the data is newer than the last apply.
            if (DisplayService.settled)
                root.followLive = false
        }
        function onPendingChanged() {
            if (!root.waiting)
                root.followLive = true
        }
    }

    Flickable {
        id: scroll
        anchors.fill: parent
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
            width: scroll.width - Theme.space - Theme.tabGap
            spacing: Theme.space

            // Two side-by-side sections with their titles on the left: the
            // monitor's modes, and the arrangement, which folds sideways to
            // its title bar (folded by default with a single monitor). Below
            // the two-column width an open Arrangement drops underneath.
            Item {
                id: sections
                width: parent.width
                readonly property bool stacked: width < Theme.settingsTwoColMin && root.arrangeOpen
                readonly property real arrangeWidth: root.arrangeOpen
                    ? Math.max(Theme.displayArrangeMin, Math.min(Theme.displayArrangeMax, width * 0.4))
                    : Theme.sideHeaderWidth
                height: sections.stacked
                    ? displaySection.height + Theme.space + arrangeSection.height
                    : Math.max(displaySection.height, arrangeSection.implicitHeight)

                SideSection {
                    id: displaySection
                    title: "Display"
                    hint: "Modes come from the monitor itself. Apply tries the mode, then asks you to keep it. With no answer, the old mode comes back."
                    width: sections.stacked ? sections.width : sections.width - sections.arrangeWidth - Theme.space
                    height: implicitHeight

                    Column {
                        width: parent.width

                        spacing: Theme.space

                        Text {
                            visible: DisplayService.loading && !root.monitors.length
                            text: "Reading monitors…"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        // Monitor card: name, model, and what it runs now.
                        Rectangle {
                            visible: !!root.monitor
                            width: parent.width
                            height: monitorCol.implicitHeight + Theme.space * 2
                            radius: Theme.radius
                            color: Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: Theme.border

                            Column {
                                id: monitorCol
                                x: Theme.space * 1.5
                                y: Theme.space
                                width: parent.width - Theme.space * 3
                                spacing: Theme.tabGap

                                Row {
                                    width: parent.width
                                    spacing: Theme.space

                                    Text {
                                        text: ""
                                        color: Theme.accent
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.fontPx * 1.6
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - Theme.fontPx * 2 - parent.spacing
                                        spacing: 0

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: root.monitor ? root.monitor.label : ""
                                            color: Theme.text
                                            font.family: Theme.uiFont
                                            font.pixelSize: Theme.fontPx
                                            font.bold: true
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: root.monitor ? root.monitor.name + "  ·  now " + root.describe(root.liveMode, root.monitor.depth) : ""
                                            color: Theme.subtext
                                            font.family: Theme.uiFont
                                            font.pixelSize: Theme.smallPx
                                        }
                                    }
                                }

                                // More than one monitor: pick which one to set.
                                Flow {
                                    visible: root.monitors.length > 1
                                    width: parent.width
                                    spacing: Theme.tabGap

                                    Repeater {
                                        model: root.monitors
                                        delegate: ChipButton {
                                            id: monChip
                                            required property var modelData
                                            label: monChip.modelData.name + (monChip.modelData.disabled ? " (off)" : "")
                                            active: monChip.modelData.name === root.selName
                                            enabled: !root.waiting
                                            tip: monChip.modelData.label + (monChip.modelData.disabled ? " (off)" : "")
                                            onClicked: root.pickMonitor(monChip.modelData.name)
                                        }
                                    }
                                }

                                // On / off, for a second screen used for other things.
                                Row {
                                    visible: root.monitors.length > 1 && !!root.monitor
                                    width: parent.width
                                    spacing: Theme.space

                                    ChipButton {
                                        id: powerChip
                                        readonly property bool isMain: !!root.monitor && root.monitor.name === ScreenService.mainName
                                        label: root.monitor && root.monitor.disabled ? "Turn on" : "Turn off"
                                        bold: true
                                        active: !!root.monitor && root.monitor.disabled
                                        enabled: !root.waiting && !DisplayService.busy && (!powerChip.isMain || (root.monitor && root.monitor.disabled))
                                        opacity: enabled ? 1 : 0.5
                                        tip: powerChip.isMain
                                            ? "The main monitor stays on. Make another one main first (Widgets → Bars → Monitors)."
                                            : (root.monitor && root.monitor.disabled
                                                ? "Use " + root.monitor.name + " again, with its mode, place, and workspaces as before"
                                                : "Stop using " + (root.monitor ? root.monitor.name : "it") + ", as if unplugged: its windows move over and the pointer cannot go there. Stays off after a restart.")
                                        onClicked: DisplayService.setPower(root.monitor.name, root.monitor.disabled)
                                    }

                                    Text {
                                        width: parent.width - powerChip.width - parent.spacing
                                        height: powerChip.height
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        text: "For a key: qs ipc call display toggle"
                                        color: Theme.subtext
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx

                                        HoverHandler {
                                            id: powerHint
                                        }

                                        HoverTip {
                                            message: "qs ipc call display toggle turns every monitor but the main one off or on; qs ipc call display toggleMonitor " + (root.monitor ? root.monitor.name : "HDMI-A-1") + " does just that one."
                                            show: powerHint.hovered
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: !!root.monitor && root.monitor.disabled
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: root.monitor ? root.monitor.name + " is off. Turn it on to change its mode or edges." : ""
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        Text {
                            visible: root.waiting
                            text: "Trying a change: answer in the window in the middle of the screen."
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        // Resolutions.
                        Text {
                            visible: root.groups.length > 0
                            text: "Resolution"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                        }

                        Flow {
                            id: tileFlow
                            visible: root.groups.length > 0
                            width: parent.width
                            spacing: Theme.space
                            // As many tiles as fit this column, stretched to fill each row.
                            readonly property int cols: Math.max(1, Math.floor((width + spacing) / (Theme.displayTileWidth + spacing)))
                            readonly property real tileWidth: (width - spacing * (cols - 1)) / cols
                            enabled: !root.waiting
                            opacity: root.waiting ? Theme.widgetOffOpacity : 1

                            Repeater {
                                model: root.groups
                                delegate: ResolutionTile {
                                    id: tile
                                    required property var modelData
                                    required property int index
                                    width: tileFlow.tileWidth
                                    modeWidth: tile.modelData.w
                                    modeHeight: tile.modelData.h
                                    topRate: tile.modelData.rates.length ? tile.modelData.rates[0].label : ""
                                    selected: tile.modelData.key === root.selKey
                                    current: !!root.monitor && tile.modelData.w === root.monitor.width && tile.modelData.h === root.monitor.height
                                    largest: tile.index === 0
                                    onClicked: root.pickResolution(tile.modelData.key)
                                }
                            }
                        }

                        FormRow {
                            visible: !!root.group
                            width: parent.width
                            label: "Refresh rate"

                            Flow {
                                width: parent.width
                                spacing: Theme.tabGap
                                enabled: !root.waiting

                                Repeater {
                                    model: root.group ? root.group.rates : []
                                    delegate: ChipButton {
                                        id: rateChip
                                        required property var modelData
                                        label: rateChip.modelData.label + " Hz"
                                        minWidth: Theme.fieldHeight * 2.5
                                        active: rateChip.modelData.mode === root.selMode
                                        tip: rateChip.modelData.hz.toFixed(2) + " Hz"
                                            + (root.rejectedPair(rateChip.modelData.mode, 10) ? ". 8-bit only on this monitor." : "")
                                        onClicked: root.pickRate(rateChip.modelData.mode)
                                    }
                                }
                            }
                        }

                        FormRow {
                            visible: !!root.group
                            width: parent.width
                            label: "Color depth"

                            Row {
                                width: parent.width
                                spacing: Theme.tabGap
                                enabled: !root.waiting

                                ChipButton {
                                    label: "8-bit"
                                    minWidth: Theme.fieldHeight * 2.5
                                    active: root.selDepth === 8
                                    tip: "8 bits per color. Works with every mode."
                                    onClicked: root.selDepth = 8
                                }

                                ChipButton {
                                    id: tenChip
                                    label: "10-bit"
                                    minWidth: Theme.fieldHeight * 2.5
                                    active: root.selDepth === 10
                                    enabled: !!root.monitor && root.monitor.tenBit && !root.tenBitBlocked
                                    tip: !root.monitor || !root.monitor.tenBit
                                        ? "This monitor does not report 10-bit color"
                                        : (root.tenBitBlocked ? "This monitor would not keep 10-bit at this mode" : "10 bits per color: smoother gradients")
                                    onClicked: root.selDepth = 10
                                }

                                Text {
                                    width: Math.max(0, parent.width - tenChip.width * 2 - parent.spacing * 2)
                                    height: Theme.fieldHeight
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: root.tenBitBlocked ? "10-bit is not kept at this mode" : (root.monitor && !root.monitor.tenBit ? "8-bit only" : "")
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }
                            }
                        }

                        // What will change, and Apply.
                        Rectangle {
                            visible: !!root.group
                            width: parent.width
                            height: Theme.fieldHeight + Theme.space * 2
                            radius: Theme.radius
                            color: Theme.pillBg
                            border.width: Theme.borderWidth
                            border.color: root.changed ? Theme.accent : Theme.border

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.space * 1.5
                                anchors.right: applyRow.left
                                anchors.rightMargin: Theme.space
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: root.changed
                                    ? root.describe(root.liveMode, root.monitor.depth) + "   →   " + root.describe(root.selMode, root.selDepth)
                                    : "This is the current mode."
                                color: root.changed ? Theme.text : Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontPx
                                font.bold: root.changed
                            }

                            Row {
                                id: applyRow
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.space
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.tabGap

                                ChipButton {
                                    label: "Current"
                                    enabled: root.changed && !root.waiting
                                    tip: "Put the choices back to the current mode"
                                    onClicked: root.syncToLive()
                                }

                                ChipButton {
                                    label: "Apply"
                                    active: root.changed && !root.waiting && !DisplayService.busy
                                    enabled: root.changed && !root.waiting && !DisplayService.busy
                                    minWidth: Theme.fieldHeight * 3
                                    tip: "Try this mode. You get " + Theme.displayConfirmSeconds + " seconds to keep it."
                                    onClicked: root.applySelection()
                                }
                            }
                        }

                        Text {
                            visible: DisplayService.error.length > 0
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: DisplayService.error
                            color: Theme.danger
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Text {
                            visible: DisplayService.notice.length > 0
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: DisplayService.notice
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        Item {
                            width: parent.width
                            height: Theme.space
                        }

                        DisplayInsetOptions {
                            visible: root.selName.length > 0 && !(root.monitor && root.monitor.disabled)
                            width: parent.width
                            monitor: root.selName
                        }

                        Item {
                            width: parent.width
                            height: Theme.space
                        }

                        // Where Keep saves, and housekeeping.
                        Row {
                            width: parent.width
                            spacing: Theme.tabGap

                            Text {
                                width: parent.width - detectChip.width - forgetChip.width - parent.spacing * 2
                                height: Theme.fieldHeight
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: DisplayService.managedFile.length
                                    ? "Keep saves to " + DisplayService.managedFile
                                    : "Changes last until Hyprland restarts (no monitors file marked \"" + DisplaySettings.fileMarker + "\")"
                                color: Theme.subtext
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx

                                HoverHandler {
                                    id: fileHover
                                }

                                HoverTip {
                                    message: DisplayService.managedFile.length
                                        ? DisplayService.managedFile
                                        : "To save modes, add a comment line \"-- " + DisplaySettings.fileMarker + "\" to a monitors file your Hyprland config loads, at " + DisplayService.fileCandidates.join(" or ")
                                    show: fileHover.hovered
                                }
                            }

                            ChipButton {
                                id: forgetChip
                                label: "Forget failed (" + root.rejected.length + ")"
                                enabled: root.rejected.length > 0 && !root.waiting
                                tip: "Let every mode and color depth be tried again"
                                onClicked: DisplaySettings.clearRejected()
                            }

                            ChipButton {
                                id: detectChip
                                label: "Detect"
                                enabled: !DisplayService.loading && !root.waiting
                                tip: "Read the monitors again"
                                onClicked: DisplayService.refresh()
                            }
                        }
                    }
                }

                SideSection {
                    id: arrangeSection
                    title: "Arrangement"
                    hint: "Drag a monitor next to another to place it left, right, above, or below; it snaps to the nearest side. Apply tries it, with Keep or Go back."
                    collapsible: true
                    expanded: root.arrangeOpen
                    onToggled: root.toggleArrange()
                    x: sections.stacked ? 0 : sections.width - width
                    y: sections.stacked ? displaySection.height + Theme.space : 0
                    width: sections.stacked ? sections.width : sections.arrangeWidth
                    height: sections.stacked ? implicitHeight : Math.max(implicitHeight, displaySection.height)

                    Behavior on width {
                        NumberAnimation { duration: Theme.popupMotionMs; easing.type: Easing.OutCubic }
                    }

                    MonitorLayout {
                        width: parent.width
                        monitors: root.monitors.filter((m) => !m.disabled)
                        selected: root.selName
                        onPicked: (name) => root.pickMonitor(name)
                    }
                }
            }
        }
    }
}
