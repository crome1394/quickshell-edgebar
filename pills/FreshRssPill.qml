import QtQuick
import qs.components
import qs.services
import qs.theme

// FreshRSS: the feed icon and the unread count (99+ past 99, "RSS" when
// nothing is unread). A click opens or closes the reader. While this pill
// is on a bar, FreshRssService checks the count every few minutes.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool lit: mouse.containsMouse || FreshRssService.open
    readonly property int count: FreshRssService.unread
    readonly property string label: !FreshRssService.configured ? "Set up"
        : (root.count > 99 ? "99+" : (root.count > 0 ? String(root.count) : "RSS"))

    Component.onCompleted: FreshRssService.pillUsers++
    Component.onDestruction: FreshRssService.pillUsers = Math.max(0, FreshRssService.pillUsers - 1)

    implicitWidth: row.implicitWidth + Math.round(Theme.space * 2 * root.ui)
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

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(Theme.tabGap * root.ui)

        Text {
            rotation: WidgetService.iconTurn(root.edge)
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.freshRssGlyph
            color: root.lit || root.count > 0 ? root.theme.colAccent : root.theme.colFg
            font.family: root.theme.iconFont
            font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.theme.colFg
            font.family: root.theme.fontFamily
            font.pixelSize: Theme.barTextPx(root.ui, root.widthFactor)
            font.bold: root.count > 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            FreshRssService.toggle()
        }

        BarTip {
            edge: root.edge
            message: !FreshRssService.configured
                ? "FreshRSS: add the server in Settings → Applications → FreshRSS"
                : (FreshRssService.error.length ? "FreshRSS: " + FreshRssService.error
                    : "FreshRSS: " + root.count + " unread. Click to open the reader.")
            show: mouse.containsMouse
        }
    }
}
