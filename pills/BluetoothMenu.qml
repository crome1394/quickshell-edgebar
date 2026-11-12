pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.settings
import qs.theme

// Left-click menu: scan, discoverable, and the device list.
Item {
    id: root

    required property var theme
    property var adapter: null
    property bool open: false

    signal closeRequested()

    property var connected: []
    property var paired: []
    property var available: []
    property string rowKey: ""
    property string forgetAddress: ""
    property string renameAddress: ""
    property string renameText: ""
    property int focusCount: 0
    property bool wasOpen: false

    function deviceValues() {
        const adapter = root.adapter
        if (!adapter)
            return []
        // qmllint disable missing-property
        const list = adapter.devices ? adapter.devices.values : null
        // qmllint enable missing-property
        return list || []
    }

    function subtitle(device) {
        if (!device)
            return ""
        const parts = []
        if (device.pairing)
            parts.push("Pairing…")
        const battery = BluetoothService.batteryPercent(device)
        if (battery >= 0)
            parts.push(battery + "%")
        if (device.blocked)
            parts.push("Blocked")
        const address = String(device.address || "")
        if (address.length)
            parts.push(address)
        return parts.join("  ·  ")
    }

    function actionsFor(device) {
        const out = []
        if (!device)
            return out
        if (device.connected)
            out.push({ id: "disconnect", label: "Disconnect", device: device })
        else if (device.paired)
            out.push({ id: "connect", label: "Connect", device: device })
        else if (device.pairing)
            out.push({ id: "cancel", label: "Cancel", device: device })
        else
            out.push({ id: "pair", label: "Pair", device: device })
        if (device.paired) {
            out.push({ id: "trust", label: device.trusted ? "Trusted" : "Trust", device: device })
            out.push({ id: "block", label: device.blocked ? "Blocked" : "Block", device: device })
            out.push({ id: "rename", label: "Rename", device: device })
            const address = String(device.address || "")
            out.push({
                id: "forget",
                label: root.forgetAddress === address ? "Confirm" : "Forget",
                device: device
            })
        }
        return out
    }

    function runAction(device, action) {
        if (!device)
            return
        const id = String(action || "")
        if (id === "connect")
            BluetoothService.connect(device)
        else if (id === "disconnect")
            device.disconnect()
        else if (id === "pair")
            BluetoothService.pair(device)
        else if (id === "cancel")
            BluetoothService.cancelPair(device)
        else if (id === "trust")
            device.trusted = !device.trusted
        else if (id === "block")
            device.blocked = !device.blocked
        else if (id === "rename") {
            root.renameAddress = String(device.address || "")
            root.renameText = String(device.name || device.deviceName || "")
        } else if (id === "forget") {
            const address = String(device.address || "")
            if (root.forgetAddress === address) {
                root.forgetAddress = ""
                device.forget()
            } else {
                root.forgetAddress = address
            }
        }
    }

    function saveRename(device, typed) {
        const name = String(typed || "").replace(/[\r\n]/g, " ").trim()
        if (!device || name.length < 1 || name.length > 80)
            return
        device.name = name
        root.renameAddress = ""
    }

    function rebuild() {
        if (root.focusCount > 0)
            return
        const list = root.deviceValues()
        const connected = []
        const paired = []
        const available = []
        for (let i = 0; i < list.length; i++) {
            const device = list[i]
            if (!device)
                continue
            if (device.connected)
                connected.push(device)
            else if (device.paired)
                paired.push(device)
            else
                available.push(device)
        }
        function byName(a, b) {
            const left = String(a.name || a.deviceName || a.address || "")
            const right = String(b.name || b.deviceName || b.address || "")
            return left.localeCompare(right)
        }
        connected.sort(byName)
        paired.sort(byName)
        available.sort(byName)
        let key = "c:"
        for (let i = 0; i < connected.length; i++)
            key += String(connected[i].address || i) + "\n"
        key += "p:"
        for (let i = 0; i < paired.length; i++)
            key += String(paired[i].address || i) + "\n"
        key += "a:"
        for (let i = 0; i < available.length; i++)
            key += String(available[i].address || i) + "\n"
        if (key === root.rowKey)
            return
        root.rowKey = key
        root.connected = connected
        root.paired = paired
        root.available = available
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 0
        color: root.theme.colAccent
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.fontPx
        font.bold: true
    }

    // One device on a section bubble. colBg reads against the colSurface bubble.
    component DeviceCard: Rectangle {
        id: card
        required property var device
        width: parent ? parent.width : 0
        implicitHeight: deviceCol.implicitHeight + Theme.space
        radius: Theme.radiusSm
        color: root.theme.colBg
        border.width: Theme.borderWidth
        border.color: card.device && card.device.connected ? root.theme.colOk : root.theme.colBorder

        Column {
            id: deviceCol
            x: Theme.space
            y: Theme.tabGap
            width: parent.width - Theme.space * 2
            spacing: Theme.tabGap

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: BluetoothService.deviceName(card.device)
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                visible: text.length > 0
                width: parent.width
                elide: Text.ElideRight
                text: root.subtitle(card.device)
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            TextField {
                id: renameField
                visible: !!card.device && root.renameAddress === String(card.device.address || "")
                width: parent.width
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                leftPadding: Theme.space
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: renameField.activeFocus ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: renameField.activeFocus ? root.theme.colAccent : root.theme.colBorder
                }
                onVisibleChanged: {
                    if (visible) {
                        text = root.renameText
                        forceActiveFocus()
                    }
                }
                onActiveFocusChanged: activeFocus ? root.focusCount += 1 : (root.focusCount = Math.max(0, root.focusCount - 1))
                onAccepted: root.saveRename(card.device, text)
                Keys.onEscapePressed: (event) => {
                    event.accepted = true
                    root.renameAddress = ""
                }
            }

            Flow {
                width: parent.width
                spacing: Theme.tabGap

                Repeater {
                    model: root.actionsFor(card.device)
                    delegate: Rectangle {
                        id: action
                        required property var modelData
                        required property int index
                        width: actionLabel.implicitWidth + Theme.space * 2
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: actionMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                        border.width: Theme.borderWidth
                        border.color: root.theme.colBorder

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: String(action.modelData.label || "")
                            color: root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                            font.bold: true
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runAction(action.modelData.device, String(action.modelData.id || ""))

                            HoverTip {
                                message: String(action.modelData.label || "")
                                show: actionMouse.containsMouse
                            }
                        }
                    }
                }
            }
        }
    }

    readonly property int scrollGutter: Theme.space + Theme.tabGap
    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 2 + Theme.tabGap

    onOpenChanged: {
        if (root.open) {
            root.wasOpen = true
            root.rebuild()
            root.forceActiveFocus()
            BluetoothService.startScan()
            return
        }
        root.focusCount = 0
        if (root.wasOpen)
            BluetoothService.stopScan()
        root.wasOpen = false
        root.forgetAddress = ""
        root.renameAddress = ""
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = true
        root.closeRequested()
    }

    Timer {
        interval: Theme.bluetoothRefreshMs
        repeat: true
        running: root.open && root.focusCount === 0
        onTriggered: root.rebuild()
    }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerRow.top
        anchors.topMargin: Theme.space
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.space
        anchors.bottomMargin: Theme.tabGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: column.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: btScroll
            policy: flick.contentHeight > flick.height + 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: btScroll.pressed || btScroll.hovered ? root.theme.colAccent : root.theme.colFgMuted
            }
        }

        Column {
            id: column
            width: Math.max(0, flick.width - root.scrollGutter)
            spacing: Theme.space

        Row {
            width: parent.width
            spacing: Theme.tabGap

            Text {
                width: parent.width
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                text: "Bluetooth"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }
        }

        Text {
            visible: !root.adapter
            width: parent.width
            text: "No Bluetooth adapter."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
        }

        Text {
            visible: !!root.adapter && !root.adapter.enabled
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Bluetooth is off."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
        }

        Rectangle {
            id: connectedBubble
            visible: !!root.adapter && root.adapter.enabled && root.connected.length > 0
            width: parent.width
            implicitHeight: connectedCol.implicitHeight + Theme.space * 2
            radius: Theme.radiusSm
            color: root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            Column {
                id: connectedCol
                x: Theme.space
                y: Theme.space
                width: parent.width - Theme.space * 2
                spacing: Theme.tabGap

                SectionTitle {
                    text: "Connected"
                }

                Repeater {
                    model: root.connected
                    delegate: DeviceCard {
                        required property var modelData
                        width: connectedCol.width
                        device: modelData
                    }
                }
            }
        }

        Row {
            id: deviceRow
            visible: !!root.adapter && root.adapter.enabled
            width: parent.width
            spacing: Theme.space
            readonly property real bubbleHeight: Math.max(pairedCol.implicitHeight, availCol.implicitHeight) + Theme.space * 2
            height: deviceRow.visible ? deviceRow.bubbleHeight : 0

            Rectangle {
                id: pairedBubble
                width: (parent.width - Theme.space) / 2
                height: deviceRow.bubbleHeight
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: pairedCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "Paired"
                    }

                    Text {
                        visible: root.paired.length === 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "No paired devices."
                        color: root.theme.colFgMuted
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                    }

                    Repeater {
                        model: root.paired
                        delegate: DeviceCard {
                            required property var modelData
                            width: pairedCol.width
                            device: modelData
                        }
                    }
                }
            }

            Rectangle {
                id: availBubble
                width: (parent.width - Theme.space) / 2
                height: deviceRow.bubbleHeight
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: availCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "Available"
                    }

                    Text {
                        visible: root.available.length === 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "No devices nearby."
                        color: root.theme.colFgMuted
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                    }

                    Repeater {
                        model: root.available
                        delegate: DeviceCard {
                            required property var modelData
                            width: availCol.width
                            device: modelData
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Right-click the pill to turn Bluetooth on or off."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }
        }
    }

    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.space
        anchors.bottomMargin: Theme.space
        spacing: Theme.tabGap
        height: Theme.fieldHeight

        // Four equal buttons: Scan, Discoverable, Power, Close.
        readonly property real cell: Math.max(1, (footerRow.width - Theme.tabGap * 3) / 4)

        Rectangle {
            width: footerRow.cell
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: scanMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: BluetoothService.scanning ? root.theme.colOk : root.theme.colBorder
            opacity: root.adapter && root.adapter.enabled ? 1 : 0.55

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: BluetoothService.scanning ? "Scanning" : "Scan"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BluetoothService.toggleScan()

                HoverTip {
                    message: BluetoothService.scanning ? "Stop scanning" : "Scan for nearby devices. Stops after " + Config.bluetoothScanSeconds + " seconds."
                    show: scanMouse.containsMouse
                }
            }
        }

        Rectangle {
            width: footerRow.cell
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: discoverMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: root.adapter && root.adapter.discoverable ? root.theme.colOk : root.theme.colBorder
            opacity: root.adapter && root.adapter.enabled ? 1 : 0.55

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: "Discoverable"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
                font.bold: !!(root.adapter && root.adapter.discoverable)
            }

            MouseArea {
                id: discoverMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.adapter && root.adapter.enabled)
                        root.adapter.discoverable = !root.adapter.discoverable
                }

                HoverTip {
                    message: "Let other devices find this computer"
                    show: discoverMouse.containsMouse
                }
            }
        }

        Rectangle {
            width: footerRow.cell
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: powerMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: root.adapter && root.adapter.enabled ? root.theme.colOk : root.theme.colDanger
            opacity: root.adapter ? 1 : 0.55

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.adapter && root.adapter.enabled ? "Power off" : "Power on"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled
                }

                HoverTip {
                    message: "Turn the Bluetooth adapter on or off"
                    show: powerMouse.containsMouse
                }
            }
        }

        Rectangle {
            width: footerRow.cell
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            color: closeMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: "Close"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()

                HoverTip {
                    message: "Close this menu"
                    show: closeMouse.containsMouse
                }
            }
        }
    }
}
