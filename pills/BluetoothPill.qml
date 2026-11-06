pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.services
import qs.theme

// Bluetooth icon. Left click opens the menu. Right click toggles adapter power.
// Loaded only while the Bluetooth widget is on the bar.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool menuOpen: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    // qmllint disable unresolved-type
    readonly property var adapter: Bluetooth.defaultAdapter
    // qmllint enable unresolved-type
    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))

    function faceIcon() {
        const adapter = root.adapter
        if (!adapter || !adapter.enabled)
            return "󰂲"
        if (adapter.discovering)
            return "󰂰"
        if (root.connectedCount() > 0)
            return "󰂱"
        return "󰂯"
    }

    function deviceValues() {
        const adapter = root.adapter
        if (!adapter)
            return []
        // qmllint disable missing-property
        const rows = adapter.devices ? adapter.devices.values : null
        // qmllint enable missing-property
        return rows || []
    }

    function connectedCount() {
        const rows = root.deviceValues()
        let count = 0
        for (let i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].connected)
                count += 1
        }
        return count
    }

    function tipText() {
        const adapter = root.adapter
        if (!adapter)
            return "No Bluetooth adapter"
        if (!adapter.enabled)
            return "Bluetooth is off"
        if (adapter.discovering)
            return "Scanning"
        const count = root.connectedCount()
        if (count > 0)
            return count === 1 ? "1 connected" : (count + " connected")
        return "Bluetooth"
    }

    function togglePower() {
        if (!root.adapter)
            return
        root.adapter.enabled = !root.adapter.enabled
    }

    function placeMenu() {
        const content = root.Window.contentItem
        if (!content)
            return
        const bounds = root.mapToItem(content, 0, 0, root.width, root.height)
        const cx = Math.round(bounds.x + bounds.width / 2)
        const cy = Math.round(bounds.y + bounds.height / 2)
        let x = cx
        let y = Math.round(content.height)
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (root.edge === "bottom") {
            y = 0
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width)
            y = cy
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (root.edge === "right") {
            x = 0
            y = cy
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const anchor = menuPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = grow
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: btMouse.containsMouse || root.menuOpen ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: btMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colBorder
    transform: [
        Scale {
            xScale: dock.mag
            yScale: dock.mag
            origin.x: root.width / 2
            origin.y: dock.growIn ? root.height : 0
        },
        Translate { y: dock.jumpY }
    ]

    DockFace {
        id: dock
        edge: root.edge
        hovered: btMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        text: root.faceIcon()
        color: btMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: root.icon
    }

    MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton) {
                root.togglePower()
                return
            }
            root.menuOpen = !root.menuOpen
        }

        BarTip {
            edge: root.edge
            message: root.tipText()
            show: btMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.bluetoothPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.bluetoothPopupMaxHeight, menu.implicitHeight)
        // qmllint enable missing-property
        onClosed: root.menuOpen = false
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            BluetoothMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
                adapter: root.adapter
                open: root.menuOpen
                onCloseRequested: root.menuOpen = false
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: menuPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeMenu()
        }
    }
}
