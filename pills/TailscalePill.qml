pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// Tailscale mark on the bar. Left click opens the menu, right click turns
// Tailscale on or off. Loaded only while the Tailscale widget is on the bar.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool menuOpen: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property bool hot: tsMouse.containsMouse || root.menuOpen

    function markInk() {
        if (TailscaleService.checked && !TailscaleService.available)
            return root.theme.colFgMuted
        if (TailscaleService.needsLogin || (TailscaleService.running && TailscaleService.health.length))
            return root.theme.colDanger
        if (root.hot)
            return root.theme.colAccent
        return TailscaleService.running ? root.theme.colFg : root.theme.colFgMuted
    }

    function tipText() {
        const t = TailscaleService
        if (t.checked && !t.available)
            return "Tailscale is not installed"
        if (t.needsLogin)
            return "Tailscale needs login"
        if (!t.running)
            return "Tailscale is off. Right-click to turn it on."
        const parts = ["Tailscale on", t.selfIp4]
        const exit = t.exitNodes.filter(n => n.exitActive)
        if (exit.length)
            parts.push("via " + (exit[0].place || exit[0].name))
        return parts.filter(s => s.length).join(" · ")
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

    Component.onCompleted: TailscaleService.retain()
    Component.onDestruction: {
        TailscaleService.setMenu(false)
        TailscaleService.release()
    }
    onMenuOpenChanged: TailscaleService.setMenu(root.menuOpen)

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.hot ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.hot ? root.theme.colAccent : root.theme.colBorder
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
        hovered: tsMouse.containsMouse
    }

    TailscaleMark {
        anchors.centerIn: parent
        size: root.icon
        ink: root.markInk()
        on: TailscaleService.running
    }

    MouseArea {
        id: tsMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton) {
                if (TailscaleService.available && !TailscaleService.needsLogin)
                    TailscaleService.toggle()
                return
            }
            root.menuOpen = !root.menuOpen
        }

        BarTip {
            edge: root.edge
            message: root.tipText()
            show: tsMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.tailscalePopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.tailscalePopupMaxHeight, menu.implicitHeight)
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

            TailscaleMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
                open: root.menuOpen
                onCloseRequested: root.menuOpen = false
                onSendRequested: (peer) => TailscaleService.pickAndSend(peer)
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
