import QtQuick
import qs.components
import qs.services
import qs.theme

// Screen recorder. Idle: a record button. Left click records (the focused
// monitor or a region, per Settings), right click records a region, middle
// click opens the recordings folder. Recording: a red mark and the time;
// a click stops and saves.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property bool recording: RecorderService.recording
    readonly property bool lit: mouse.containsMouse || root.recording || RecorderService.picking
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))

    implicitWidth: root.recording ? row.implicitWidth + Math.round(Theme.space * 2 * root.ui) : Math.max(1, Math.round(root.cell * root.widthFactor))
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: mouse.containsMouse ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.recording ? root.theme.colDanger : (root.lit ? root.theme.colAccent : root.theme.colBorder)
    opacity: RecorderService.checked && !RecorderService.available ? Theme.widgetOffOpacity : 1
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
            anchors.verticalCenter: parent.verticalCenter
            text: root.recording ? Theme.recordingGlyph : Theme.recordGlyph
            color: root.recording ? root.theme.colDanger : (root.lit ? root.theme.colAccent : root.theme.colFg)
            font.family: root.theme.iconFont
            font.pixelSize: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
        }

        Text {
            visible: root.recording
            anchors.verticalCenter: parent.verticalCenter
            text: RecorderService.elapsed
            color: root.theme.colDanger
            font.family: root.theme.fontFamily
            font.pixelSize: Theme.barTextPx(root.ui, root.widthFactor)
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (event) => {
            dock.play()
            if (event.button === Qt.MiddleButton)
                RecorderService.openFolder()
            else if (root.recording)
                RecorderService.stop()
            else
                RecorderService.start(event.button === Qt.RightButton ? "region" : "")
        }

        BarTip {
            edge: root.edge
            message: {
                if (!RecorderService.available)
                    return "Screen recording needs gpu-screen-recorder."
                if (RecorderService.recording)
                    return "Recording " + RecorderService.elapsed + ". Click to stop and save."
                if (RecorderService.picking)
                    return "Drag a region to record (Escape cancels)."
                return (RecorderService.error.length ? RecorderService.error + " " : "")
                    + "Click to record, right-click for a region, middle-click opens the folder."
            }
            show: mouse.containsMouse
        }
    }
}
