pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// Transparency: left click opens the menu (glass, every application, and
// per-app overrides). Settings → System → Transparency edits the rest,
// including unfocused levels. Changes save at once.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property string screenName: ""
    readonly property bool menuOpen: OpacityMenuService.open && ScreenService.owns(OpacityMenuService.screen, root.screenName)
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))

    // Side bars center the menu on the bar. Top and bottom keep it over this icon.
    function placeMenu(nudge) {
        WidgetService.placePopup(root, menuPopup.anchor, root.edge, nudge)
    }

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colBorder
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
        hovered: opacityMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: Theme.opacityGlyph
        color: opacityMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: root.icon
    }

    MouseArea {
        id: opacityMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            OpacityMenuService.toggle(root.screenName)
        }

        BarTip {
            edge: root.edge
            message: "Window transparency"
            show: opacityMouse.containsMouse && !root.menuOpen
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.opacityPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.opacityPopupMaxHeight, menu.implicitHeight)
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property
        onVisibleChanged: if (visible) root.placeMenu(true)
        onClosed: OpacityMenuService.hide()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            OpacityMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
                open: root.menuOpen
                onCloseRequested: OpacityMenuService.hide()
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
