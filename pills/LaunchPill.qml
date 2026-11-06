pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services
import qs.theme

// Pinned icons for one app launcher, in one pill. Loaded only while that
// launcher is on the bar and has at least one pin. An empty launcher draws
// nothing. BarSlot rotates a side-bar pill 90° clockwise. These icons turn
// 90° the other way so they stay upright.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property int launcher: 1
    property string tipText: ""
    property bool tipShow: false
    property int runTick: 0
    property real hoverX: -1
    property bool dockHot: root.hoverX >= 0 && (DockSettings.magnify() || DockSettings.jumpOn())

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int dot: Math.max(Theme.borderWidth * 2, Math.round(Theme.wsGap * root.ui))
    readonly property int icon: Math.max(1, Math.min(root.cell - root.dot, Math.round(root.theme.iconPx * root.ui * root.widthFactor)))
    readonly property int gap: Theme.wsGap
    readonly property bool side: root.edge === "left" || root.edge === "right"
    readonly property var pins: root.boardPins()
    readonly property int pinCount: root.pins.length !== undefined ? root.pins.length : 0
    readonly property var runMarks: root.buildMarks()

    function boardPins() {
        const boards = LauncherSettings.savedBoards()
        const row = boards[root.launcher - 1]
        if (!row || row.length === undefined)
            return []
        return row
    }

    function norm(text) {
        let value = String(text || "").trim().toLowerCase()
        if (value.slice(-8) === ".desktop")
            value = value.slice(0, -8)
        return value
    }

    function basename(path) {
        const text = String(path || "")
        const slash = text.lastIndexOf("/")
        return slash >= 0 ? text.slice(slash + 1) : text
    }

    function windowList() {
        const tops = Hyprland.toplevels
        // qmllint disable missing-property
        const values = tops ? tops.values : []
        // qmllint enable missing-property
        return values || []
    }

    function pinKeys(pin) {
        const keys = []
        const id = root.norm(pin.id)
        if (id.length)
            keys.push(id)
        if (id.length) {
            const entry = DesktopEntries.byId(String(pin.id || ""))
            if (entry) {
                const startup = root.norm(entry.startupClass)
                if (startup.length)
                    keys.push(startup)
            }
        }
        const command = pin.command || []
        if (command.length) {
            const base = root.norm(root.basename(command[0]))
            if (base.length)
                keys.push(base)
        }
        return keys
    }

    function buildMarks() {
        void root.runTick
        void Hyprland.activeToplevel
        const running = {}
        const focused = {}
        const list = root.windowList()
        for (let i = 0; i < list.length; i++) {
            const top = list[i]
            if (!top)
                continue
            const wayland = top.wayland
            const appId = wayland ? root.norm(wayland.appId) : ""
            const ipc = top.lastIpcObject || null
            const cls = ipc ? root.norm(ipc.class) : ""
            const initial = ipc ? root.norm(ipc.initialClass) : ""
            const keys = [appId, cls, initial]
            const on = !!top.activated
            for (let k = 0; k < keys.length; k++) {
                if (!keys[k].length)
                    continue
                running[keys[k]] = true
                if (on)
                    focused[keys[k]] = true
            }
        }
        const states = []
        const pins = root.pins
        for (let p = 0; p < pins.length; p++) {
            const keys = root.pinKeys(pins[p])
            let state = ""
            for (let k = 0; k < keys.length; k++) {
                if (focused[keys[k]]) {
                    state = "focus"
                    break
                }
                if (running[keys[k]])
                    state = "run"
            }
            states.push(state)
        }
        return states
    }

    function launch(pin) {
        if (!pin)
            return
        const id = String(pin.id || "")
        if (id.length && Config.desktopIdOk(id)) {
            const entry = DesktopEntries.byId(id)
            if (entry) {
                entry.execute()
                return
            }
            Quickshell.execDetached(["gtk-launch", id])
            return
        }
        const raw = pin.command || []
        if (!raw.length)
            return
        const program = String(raw[0] || "")
        if (!Config.programOk(program))
            return
        const command = [program]
        for (let i = 1; i < raw.length; i++) {
            const token = String(raw[i] || "")
            if (Config.argOk(token))
                command.push(token)
        }
        Quickshell.execDetached(command)
    }

    implicitWidth: root.pinCount > 0
        ? root.pinCount * root.cell + Math.max(0, root.pinCount - 1) * root.gap
        : 0
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
    clip: false

    HoverHandler {
        id: dockWatch
        enabled: DockSettings.magnify() || DockSettings.jumpOn()
        onPointChanged: {
            if (!dockWatch.hovered) {
                root.hoverX = -1
                return
            }
            root.hoverX = point.position.x
        }
    }

    Timer {
        interval: Theme.dockPollMs
        repeat: true
        running: root.hoverX >= 0 && (DockSettings.magnify() || DockSettings.jumpOn())
        onTriggered: {
            if (!dockWatch.hovered)
                root.hoverX = -1
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = event ? String(event.name || "") : ""
            if (name === "openwindow" || name === "closewindow" || name === "activewindow"
                    || name === "windowtitle" || name === "windowtitlev2")
                root.runTick++
        }
    }

    Repeater {
        model: root.pins
        delegate: Item {
            id: cell
            required property var modelData
            required property int index

            readonly property string iconSource: IconService.url(String(cell.modelData.icon || ""))
            readonly property string runState: {
                const marks = root.runMarks
                if (!marks || cell.index >= marks.length)
                    return ""
                return String(marks[cell.index] || "")
            }
            readonly property string letter: {
                const label = String(cell.modelData.name || "").trim()
                return label.length ? label.charAt(0).toUpperCase() : "•"
            }

            x: cell.index * (root.cell + root.gap)
            y: 0
            z: Math.round((dock.mag - 1) * 24)
            implicitWidth: root.cell
            implicitHeight: root.cell
            width: root.cell
            height: root.cell

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: iconMouse.containsMouse ? root.theme.colHover : "transparent"
                border.width: 0
                transform: [
                    Scale {
                        xScale: dock.mag
                        yScale: dock.mag
                        origin.x: cell.width / 2
                        origin.y: dock.growIn ? cell.height : 0
                    },
                    Translate { y: dock.jumpY }
                ]

                DockFace {
                    id: dock
                    edge: root.edge
                    always: true
                    neighbors: true
                    hovered: iconMouse.containsMouse
                    neighbor: DockSettings.neighbor(root.hoverX, cell.x + cell.width / 2)
                }

                Item {
                    id: glyph
                    anchors.centerIn: parent
                    width: root.icon
                    height: root.icon
                    rotation: root.side ? -90 : 0
                    transformOrigin: Item.Center

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: cell.iconSource
                        visible: cell.iconSource.length > 0 && iconImage.status !== Image.Error
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !iconImage.visible
                        text: cell.letter
                        color: iconMouse.containsMouse ? root.theme.colAccent : root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: true
                    }
                }

                Rectangle {
                    visible: cell.runState.length > 0
                    width: root.dot
                    height: root.dot
                    radius: width / 2
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Theme.borderWidth
                    color: {
                        const ink = DockSettings.dotColor()
                        if (cell.runState === "focus")
                            return ink
                        return Qt.rgba(ink.r, ink.g, ink.b, 0.72)
                    }
                }
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                z: 1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    dock.play()
                    root.launch(cell.modelData)
                }
                onEntered: {
                    root.tipText = String(cell.modelData.name || "")
                    root.tipShow = root.tipText.length > 0
                }
                onExited: root.tipShow = false
            }
        }
    }

    BarTip {
        edge: root.edge
        message: root.tipText
        show: root.tipShow
    }
}
