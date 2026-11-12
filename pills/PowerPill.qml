pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.settings
import qs.theme

// Lock, logout, reboot, shutdown, and firmware setup.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1
    property bool menuOpen: false
    property string status: ""
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "󰌾", tip: "Lock the screen" },
        { id: "logout", label: "Logout", icon: "󰍃", tip: "End the Hyprland session" },
        { id: "reboot", label: "Reboot", icon: "󰑓", tip: "Reboot the machine" },
        { id: "shutdown", label: "Shutdown", icon: "󰐥", tip: "Power off the machine" },
        { id: "bios", label: "Enter BIOS", icon: "󰛳", tip: "Reboot into firmware setup" }
    ]

    function commandFor(action) {
        switch (String(action || "")) {
        case "lock":
            return ["hyprlock"]
        case "logout":
            return ["hyprctl", "dispatch", "exit"]
        case "reboot":
            return ["systemctl", "reboot"]
        case "shutdown":
            return ["systemctl", "poweroff"]
        case "bios":
            return ["systemctl", "reboot", "--firmware-setup"]
        }
        return []
    }

    function run(action) {
        const command = root.commandFor(action)
        if (!command.length || actionProc.running)
            return
        root.status = ""
        actionProc.command = command
        actionProc.running = true
        root.menuOpen = false
    }

    // Side bars center the menu on the bar. Top and bottom keep it over this icon.
    function placeMenu(nudge) {
        WidgetService.placePopup(root, menuPopup.anchor, root.edge, nudge)
    }

    implicitWidth: root.cell
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: powerMouse.containsMouse || root.menuOpen ? root.theme.colHover : root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: powerMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colBorder
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
        hovered: powerMouse.containsMouse
    }

    Text {
        anchors.centerIn: parent
        rotation: WidgetService.iconTurn(root.edge)
        text: "󰐥"
        color: powerMouse.containsMouse || root.menuOpen ? root.theme.colAccent : root.theme.colFg
        font.family: root.theme.iconFont
        font.pixelSize: root.icon
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dock.play()
            root.menuOpen = !root.menuOpen
        }

        BarTip {
            edge: root.edge
            message: "Power menu"
            show: powerMouse.containsMouse && !root.menuOpen
        }
    }

    Process {
        id: actionProc
        command: ["true"]
        stderr: StdioCollector {
            id: actionErr
            waitForEnd: true
        }
        onExited: (code) => {
            if (code === 0)
                return
            const message = String(actionErr.text || "").trim()
            root.status = message.length ? message.slice(0, 120) : "Command failed"
            root.menuOpen = true
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
        implicitHeight: menuCol.implicitHeight + Theme.space * 2
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

            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space
                spacing: Theme.tabGap

                Text {
                    width: parent.width
                    text: "Power"
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                }

                Repeater {
                    model: root.actions
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: rowMouse.containsMouse ? root.theme.colHover : root.theme.colSurface

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space
                            anchors.rightMargin: Theme.space
                            spacing: Theme.space

                            Text {
                                width: root.theme.iconPx
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: String(row.modelData.icon || "")
                                color: root.theme.colAccent
                                font.family: root.theme.iconFont
                                font.pixelSize: root.theme.iconPx
                            }

                            Text {
                                width: parent.width - root.theme.iconPx - Theme.space
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: String(row.modelData.label || "")
                                color: root.theme.colFg
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.fontPx
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(String(row.modelData.id || ""))

                            HoverTip {
                                message: String(row.modelData.tip || "")
                                show: rowMouse.containsMouse
                            }
                        }
                    }
                }

                Text {
                    visible: root.status.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.status
                    color: root.theme.colDanger
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }
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
