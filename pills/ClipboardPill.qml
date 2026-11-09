import QtQuick
import qs.components
import qs.config
import qs.services
import qs.theme

// Clipboard: the clipboard icon. A click opens or closes the viewer. Dim
// while history is not being kept (off, or cliphist missing).
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool lit: mouse.containsMouse || ClipboardService.open

    implicitWidth: glyph.implicitWidth + Math.round(Theme.space * 2 * root.ui)
    implicitHeight: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    radius: Theme.radiusSm
    color: root.lit ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.lit ? root.theme.colAccent : root.theme.colBorder
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
        hovered: mouse.containsMouse
    }

    Text {
        id: glyph
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: Theme.clipboardGlyph
        color: root.lit ? root.theme.colAccent : root.theme.colFg
        opacity: ClipboardService.recording ? 1 : Theme.widgetOffOpacity
        font.family: root.theme.iconFont
        font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            ClipboardService.toggle()
        }

        BarTip {
            edge: root.edge
            message: !ClipboardService.available ? "Clipboard: install cliphist to keep a history"
                : (!ClipboardSettings.enabled() ? "Clipboard: history is off (Settings → Tools → Clipboard)"
                    : "Clipboard history. Click to open (Super+V).")
            show: mouse.containsMouse
        }
    }
}
