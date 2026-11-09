pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// Firewall (UFW): a shield, green-checked while on and crossed out in red
// while off. Left click opens the menu (rules, policies, add a rule);
// right click turns the firewall on or off. Changes ask for your password.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool menuOpen: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property bool hot: fwMouse.containsMouse || root.menuOpen
    readonly property bool on: FirewallService.enabled

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
        if (root.edge === "bottom") {
            y = 0
            edgeFlags = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width)
            y = cy
            edgeFlags = Edges.Right
        } else if (root.edge === "right") {
            x = 0
            y = cy
            edgeFlags = Edges.Left
        }
        const anchor = menuPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = edgeFlags
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    implicitWidth: Math.max(1, Math.round(root.cell * root.widthFactor))
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.hot ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: !root.on && FirewallService.available ? root.theme.colDanger : (root.hot ? root.theme.colAccent : root.theme.colBorder)
    opacity: FirewallService.available ? 1 : Theme.widgetOffOpacity
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
        hovered: fwMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: root.on ? Theme.firewallOnGlyph : Theme.firewallOffGlyph
        color: !root.on ? root.theme.colDanger : (root.hot ? root.theme.colAccent : root.theme.colFg)
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: fwMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton)
                FirewallService.toggle()
            else
                root.menuOpen = !root.menuOpen
        }

        BarTip {
            edge: root.edge
            message: !FirewallService.available
                ? "UFW is not installed."
                : "Firewall " + (root.on ? "on" : "OFF") + " · " + FirewallService.rules.length
                    + (FirewallService.rules.length === 1 ? " rule" : " rules") + ". Right-click to turn it " + (root.on ? "off" : "on") + "."
            show: fwMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.firewallPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.firewallPopupMaxHeight, menu.implicitHeight)
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property
        onClosed: root.menuOpen = false

        FirewallMenu {
            id: menu
            anchors.fill: parent
            theme: root.theme
            open: root.menuOpen
            onCloseRequested: root.menuOpen = false
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
