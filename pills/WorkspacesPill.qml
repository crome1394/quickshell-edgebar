pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real hoverX: -1
    property bool dockHot: root.hoverX >= 0 && DockSettings.allIcons() && (DockSettings.magnify() || DockSettings.jumpOn())

    radius: Theme.radius
    color: root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
    property real widthFactor: 1

    readonly property real ui: WidgetService.uiScale

    implicitHeight: Math.max(1, Math.round((Theme.wsButtonHeight + Theme.wsPad) * root.ui))
    implicitWidth: Math.max(1, Math.round((row.implicitWidth + Math.round(Theme.wsPad * root.ui)) * widthFactor))

    HoverHandler {
        id: dockWatch
        enabled: DockSettings.allIcons() && (DockSettings.magnify() || DockSettings.jumpOn())
        onPointChanged: {
            if (!dockWatch.hovered) {
                root.hoverX = -1
                return
            }
            const local = row.mapFromItem(root, point.position.x, point.position.y)
            root.hoverX = local.x
        }
    }

    Timer {
        interval: Theme.dockPollMs
        repeat: true
        running: root.hoverX >= 0 && DockSettings.allIcons() && (DockSettings.magnify() || DockSettings.jumpOn())
        onTriggered: {
            if (!dockWatch.hovered)
                root.hoverX = -1
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            const delta = event.angleDelta.y > 0 ? 1 : -1
            WorkspaceService.switchRelative(delta)
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.max(0, Math.round(Theme.wsGap * root.ui))
        transform: Scale {
            origin.x: row.width / 2
            origin.y: row.height / 2
            xScale: root.widthFactor
        }

        Repeater {
            model: WorkspaceService.shown
            delegate: WorkspaceButton {
                id: button
                required property var modelData
                required property int index

                readonly property var face: {
                    void Config.revision
                    if (button.modelData.isSpecial)
                        return Config.specialFace()
                    return Config.faceForId(button.modelData.id)
                }

                active: button.modelData.isSpecial
                    ? WorkspaceService.specialActive
                    : (!WorkspaceService.specialActive && !!button.modelData.active)
                special: !!button.modelData.isSpecial
                workspaceId: button.modelData.id
                symbol: String(button.face.label || "")
                label: String(button.face.text || "")
                fontName: String(button.face.font || "")
                theme: root.theme
                symbolPx: button.face.fontPx >= 8 ? button.face.fontPx : root.theme.iconPx
                bold: button.face.bold !== false
                italic: !!button.face.italic
                labelColor: String(button.face.color || "")
                edge: root.edge
                dockNeighbor: DockSettings.neighbor(root.hoverX, button.x + button.width / 2)
                showNumber: {
                    if (button.modelData.isSpecial)
                        return false
                    if (Config.showNumbers)
                        return true
                    const glyph = String(button.face.label || "")
                    const word = String(button.face.text || "")
                    return !glyph.length && !word.length
                }
                onClicked: WorkspaceService.activate(button.modelData)
            }
        }
    }
}
