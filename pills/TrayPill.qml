pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.theme

// Status icons. A click opens a themed menu when the item has one.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1

    property bool menuOpen: false
    property var menuItem: null
    property var menuHandle: null
    property var menuStack: []
    property real hoverX: -1
    property bool dockHot: root.hoverX >= 0 && DockSettings.allIcons() && (DockSettings.magnify() || DockSettings.jumpOn())

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property int count: {
        const items = SystemTray.items
        if (!items)
            return 0
        // qmllint disable missing-property
        const rows = items.values
        // qmllint enable missing-property
        return rows ? rows.length : 0
    }
    readonly property string menuTitle: {
        const item = root.menuItem
        if (!item)
            return "Tray"
        return String(item.title || item.id || "Tray")
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

    function openMenu(item) {
        root.menuItem = item
        root.menuHandle = item.menu
        root.menuStack = []
        root.menuOpen = true
    }

    function closeMenu() {
        root.menuOpen = false
        root.menuStack = []
        root.menuHandle = null
        root.menuItem = null
    }

    function pushMenu(entry) {
        const stack = root.menuStack.slice()
        stack.push(root.menuHandle)
        root.menuStack = stack
        root.menuHandle = entry
    }

    function popMenu() {
        if (!root.menuStack.length) {
            root.closeMenu()
            return
        }
        const stack = root.menuStack.slice()
        root.menuHandle = stack.pop()
        root.menuStack = stack
    }

    function activateEntry(entry) {
        if (!entry || entry.isSeparator)
            return
        if (entry.hasChildren) {
            root.pushMenu(entry)
            return
        }
        entry.triggered()
        root.closeMenu()
    }

    implicitWidth: root.count > 0 ? iconRow.implicitWidth + Theme.wsPad : 0
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.theme.colSurface
    border.width: root.count > 0 ? Theme.borderWidth : 0
    border.color: root.theme.colBorder
    visible: root.count > 0

    HoverHandler {
        id: dockWatch
        enabled: DockSettings.allIcons() && (DockSettings.magnify() || DockSettings.jumpOn())
        onPointChanged: {
            if (!dockWatch.hovered) {
                root.hoverX = -1
                return
            }
            const local = iconRow.mapFromItem(root, point.position.x, point.position.y)
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

    Row {
        id: iconRow
        anchors.centerIn: parent
        spacing: Theme.wsGap

        Repeater {
            model: {
                const items = SystemTray.items
                if (!items)
                    return []
                // qmllint disable missing-property
                return items.values || []
                // qmllint enable missing-property
            }
            delegate: Rectangle {
                id: iconCell
                required property var modelData
                required property int index
                width: root.cell
                height: root.cell
                z: Math.round((dock.mag - 1) * 24)
                radius: Theme.radiusSm
                color: iconMouse.containsMouse ? root.theme.colHover : "transparent"
                border.width: iconMouse.containsMouse ? Theme.borderWidth : 0
                border.color: root.theme.colAccent
                transform: [
                    Scale {
                        xScale: dock.mag
                        yScale: dock.mag
                        origin.x: iconCell.width / 2
                        origin.y: dock.growIn ? iconCell.height : 0
                    },
                    Translate { y: dock.jumpY }
                ]

                DockFace {
                    id: dock
                    edge: root.edge
                    neighbors: true
                    hovered: iconMouse.containsMouse
                    neighbor: DockSettings.neighbor(root.hoverX, iconCell.x + iconCell.width / 2)
                }

                IconImage {
                    anchors.centerIn: parent
                    width: root.icon
                    height: root.icon
                    source: iconCell.modelData && iconCell.modelData.icon ? iconCell.modelData.icon : ""
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        dock.play()
                        const item = iconCell.modelData
                        if (!item)
                            return
                        if (item.hasMenu)
                            root.openMenu(item)
                        else
                            item.activate()
                    }
                    onWheel: (wheel) => {
                        const item = iconCell.modelData
                        if (item)
                            item.scroll(wheel.angleDelta.y, false)
                    }

                    BarTip {
                        edge: root.edge
                        message: {
                            const item = iconCell.modelData
                            if (!item)
                                return ""
                            const title = String(item.tooltipTitle || item.title || item.id || "Tray icon")
                            const detail = String(item.tooltipDescription || "")
                            return detail.length ? title + "\n" + detail : title
                        }
                        show: iconMouse.containsMouse && !root.menuOpen
                    }
                }
            }
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.popupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.wallpaperTile * 3, Math.max(Theme.fieldHeight * 3, menuCol.implicitHeight + Theme.space * 2))
        // qmllint enable missing-property
        onClosed: root.closeMenu()
        // qmllint disable missing-property
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        QsMenuOpener {
            id: opener
            menu: root.menuHandle
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space
                spacing: Theme.tabGap

                Row {
                    width: parent.width
                    height: Theme.fieldHeight
                    spacing: Theme.tabGap

                    Text {
                        width: parent.width - (root.menuStack.length ? backButton.width + closeButton.width + Theme.tabGap * 2 : closeButton.width + Theme.tabGap)
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.menuTitle
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    Rectangle {
                        id: backButton
                        visible: root.menuStack.length > 0
                        width: Theme.chip
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: backMouse.containsMouse ? root.theme.colHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: root.theme.colAccent
                            font.pixelSize: root.theme.fontPx
                            font.bold: true
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.popMenu()
                        }
                    }

                    Rectangle {
                        id: closeButton
                        width: Theme.chip
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: closeMouse.containsMouse ? root.theme.colHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: root.theme.colFgMuted
                            font.pixelSize: root.theme.smallPx
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeMenu()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Theme.borderWidth
                    color: root.theme.colBorder
                }

                Repeater {
                    model: opener.children
                    delegate: Rectangle {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool separator: !!(entry.modelData && entry.modelData.isSeparator)
                        width: menuCol.width
                        height: entry.separator ? Theme.space : Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: entry.separator ? "transparent" : (entryMouse.containsMouse ? root.theme.colHover : "transparent")
                        visible: !entry.modelData || entry.modelData.enabled !== false

                        Rectangle {
                            visible: entry.separator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Theme.space
                            anchors.rightMargin: Theme.space
                            height: Theme.borderWidth
                            color: root.theme.colBorder
                        }

                        Row {
                            visible: !entry.separator
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space
                            anchors.rightMargin: Theme.space
                            spacing: Theme.space

                            Text {
                                width: Theme.iconPx
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: {
                                    const row = entry.modelData
                                    if (!row)
                                        return ""
                                    if (row.buttonType === QsMenuButtonType.RadioButton)
                                        return row.checkState === Qt.Checked ? "●" : "○"
                                    if (row.checkState === Qt.Checked)
                                        return "✓"
                                    if (row.checkState === Qt.PartiallyChecked)
                                        return "◐"
                                    return ""
                                }
                                color: root.theme.colAccent
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.smallPx
                                font.bold: true
                            }

                            Text {
                                width: parent.width - Theme.iconPx - Theme.space * 2 - mark.width
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: entry.modelData ? String(entry.modelData.text || "") : ""
                                color: root.theme.colFg
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.fontPx
                            }

                            Text {
                                id: mark
                                width: Theme.iconPx
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                                visible: !!(entry.modelData && entry.modelData.hasChildren)
                                text: "▸"
                                color: root.theme.colAccent
                                font.pixelSize: root.theme.fontPx
                            }
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !entry.separator
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activateEntry(entry.modelData)
                        }
                    }
                }

                Text {
                    visible: {
                        const kids = opener.children
                        if (!kids)
                            return true
                        // qmllint disable missing-property
                        return kids.count === 0
                        // qmllint enable missing-property
                    }
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "No menu"
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    font.italic: true
                }
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
