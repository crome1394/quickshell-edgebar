import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// Application Menu icon. Loaded only while that widget is on the bar.
// BarSlot rotates a side-bar pill 90° clockwise. The symbol turns 90° the
// other way so it stays upright.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property string tipText: ""
    property bool tipShow: false
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool side: root.edge === "left" || root.edge === "right"
    readonly property string symbol: Config.menuSymbolValue(Config.menuSymbol)
    readonly property int symbolPx: Math.max(1, Math.round(Config.menuPxValue() * root.ui * root.widthFactor))
    readonly property string fontName: Config.menuFont.length ? Config.menuFont : root.theme.iconFont
    readonly property color ink: Config.menuColor.length
        ? Config.menuColor
        : (menuMouse.containsMouse ? root.theme.colAccent : root.theme.colFg)

    function launch() {
        const command = Config.menuArgvFromLine(Config.menuCommandLine(Config.menuCommand))
        if (!command || !command.length)
            return
        Quickshell.execDetached(command)
    }

    implicitWidth: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.widthFactor * root.ui))
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: menuMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: menuMouse.containsMouse ? root.theme.colAccent : root.theme.colBorder
    clip: false
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
        hovered: menuMouse.containsMouse
    }

    Item {
        anchors.centerIn: parent
        width: glyph.implicitWidth
        height: glyph.implicitHeight
        rotation: root.side ? -90 : 0
        transformOrigin: Item.Center

        Text {
            id: glyph
            anchors.centerIn: parent
            text: root.symbol
            color: root.ink
            font.family: root.fontName
            font.pixelSize: root.symbolPx
            font.bold: Config.menuBold
            font.italic: Config.menuItalic
        }
    }

    MouseArea {
        id: menuMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            root.launch()
        }
        onEntered: {
            root.tipText = "Application Menu"
            root.tipShow = true
        }
        onExited: root.tipShow = false
    }

    BarTip {
        edge: root.edge
        message: root.tipText
        show: root.tipShow
    }
}
