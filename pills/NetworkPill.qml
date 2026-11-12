pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// Connection icon and optional address. Left click opens the menu.
// Right click toggles Wi-Fi. Loaded only while the network widget is on the bar.
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
    readonly property int textPx: Theme.barTextPx(root.ui, root.widthFactor)
    readonly property int pad: Math.max(1, Math.round(Theme.tabGap * root.ui))
    readonly property string addressText: {
        if (!NetworkService.primaryLabel().length && !NetworkService.primaryAddress().length)
            return ""
        const device = NetworkService.primaryAddress()
        if (!device.length && !Config.showNetworkDeviceName)
            return ""
        const ip = NetworkService.bareIp(device)
        let ipText = ""
        if (Config.showNetworkFullIp)
            ipText = ip
        else if (Config.showNetworkLastOctet) {
            const parts = ip.split(".")
            if (parts.length === 4)
                ipText = parts[3]
        }
        const nameText = Config.showNetworkDeviceName ? NetworkService.primaryIface() : ""
        if (!NetworkService.primaryLabel().length && !ip.length)
            return nameText
        if (!ipText.length && !nameText.length)
            return ""
        if (nameText.length && ipText.length)
            return nameText + " " + ipText
        if (nameText.length)
            return nameText
        return ipText
    }
    readonly property int faceWidth: Math.max(root.cell, faceRow.implicitWidth + root.pad * 2)

    function faceIcon() {
        const kind = NetworkService.linkKind()
        const signal = NetworkService.primarySignal()
        if (kind === "airplane")
            return "󰀝"
        if (kind === "portal")
            return "󰖟"
        if (kind === "vpn")
            return "󰖂"
        if (kind === "wired")
            return "󰈀"
        if (kind === "wifi") {
            if (signal >= 75)
                return "󰤨"
            if (signal >= 50)
                return "󰤥"
            if (signal >= 25)
                return "󰤢"
            return "󰤟"
        }
        if (kind === "wifioff")
            return "󰤭"
        return "󰤮"
    }

    // Side bars center the menu on the bar. Top and bottom keep it over this icon.
    function placeMenu(nudge) {
        WidgetService.placePopup(root, menuPopup.anchor, root.edge, nudge)
    }

    Component.onCompleted: NetworkService.retain()
    Component.onDestruction: NetworkService.release()
    onMenuOpenChanged: NetworkService.setPopup(root.menuOpen)

    implicitWidth: root.faceWidth
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: netMouse.containsMouse || root.menuOpen ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: netMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colBorder
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
        hovered: netMouse.containsMouse
    }

    Row {
        id: faceRow
        anchors.centerIn: parent
        spacing: root.pad

        Text {
            rotation: WidgetService.iconTurn(root.edge)
            width: root.icon
            height: root.cell
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.faceIcon()
            color: netMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colFg
            font.family: root.theme.iconFont
            font.pixelSize: root.icon
        }

        Text {
            visible: root.addressText.length > 0
            height: root.cell
            verticalAlignment: Text.AlignVCenter
            text: root.addressText
            color: root.theme.colFg
            font.family: root.theme.fontFamily
            font.pixelSize: root.textPx
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            dock.play()
            if (mouse.button === Qt.RightButton) {
                NetworkService.toggleWifi()
                return
            }
            root.menuOpen = !root.menuOpen
        }

        BarTip {
            edge: root.edge
            message: {
                const label = NetworkService.primaryLabel()
                return label.length ? label : "Network"
            }
            show: netMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.networkPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.networkPopupMaxHeight, menu.implicitHeight)
        // qmllint enable missing-property
        onVisibleChanged: if (visible) root.placeMenu(true)
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

            NetworkMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
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
            root.placeMenu(false)
        }
    }
}
