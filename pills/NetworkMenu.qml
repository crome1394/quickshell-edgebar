pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.settings
import qs.theme

// Left-click menu for the network pill. Headers, toggles, and lists.
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()

    property bool showDetails: false
    property string expandedName: ""
    property string copied: ""
    property int focusCount: 0

    readonly property bool wifiJoined: {
        void NetworkService.tick
        const rows = NetworkService.wifiRows || []
        for (let i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].connected)
                return true
        }
        return false
    }

    function focusIn() {
        root.focusCount += 1
    }

    function focusOut() {
        root.focusCount = Math.max(0, root.focusCount - 1)
    }

    function modeChips() {
        return [
            { id: "wired", label: "Wired", on: NetworkService.wiredOn, tip: "Show ethernet devices. Off disconnects them." },
            { id: "wifi", label: "Wi-Fi", on: NetworkService.wifiOn, tip: "Turn the Wi-Fi radio on or off" },
            { id: "airplane", label: "Airplane", on: NetworkService.airplaneOn, tip: "Turn Wi-Fi and cellular radios off. Ethernet stays up." },
            { id: "vpn", label: "VPN", on: NetworkService.vpnOn, tip: "Show saved VPN profiles. Off disconnects them." }
        ]
    }

    function toggleMode(id) {
        if (id === "wired")
            NetworkService.setWired(!NetworkService.wiredOn)
        else if (id === "wifi")
            NetworkService.setWifi(!NetworkService.wifiOn)
        else if (id === "airplane")
            NetworkService.setAirplane(!NetworkService.airplaneOn)
        else if (id === "vpn")
            NetworkService.setVpn(!NetworkService.vpnOn)
    }

    function footerActions() {
        return [
            { id: "editor", label: "Connection editor", tip: "Open the connection editor" },
            { id: "dns", label: "Flush DNS", tip: "Flush the system DNS cache" },
            { id: "ip", label: "Refresh IP", tip: "Reapply the active connection" },
            { id: "close", label: "Close", tip: "Close this menu" }
        ]
    }

    function runFooter(id) {
        if (id === "editor")
            NetworkService.openEditor()
        else if (id === "dns")
            NetworkService.flushDns()
        else if (id === "ip")
            NetworkService.refreshIp()
        else if (id === "close")
            root.closeRequested()
    }

    function headerIcon() {
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

    function headerMeta() {
        const fact = NetworkService.factFor(NetworkService.primaryIface()) || {}
        const parts = []
        if (fact.state)
            parts.push(String(fact.state))
        if (fact.speed)
            parts.push(String(fact.speed))
        const signal = NetworkService.primarySignal()
        if (signal >= 0)
            parts.push(signal + "%")
        return parts.join("  ·  ")
    }

    function copyValue(text) {
        const value = String(text || "")
        if (!value.length)
            return
        Quickshell.clipboardText = value
        root.copied = value
        copyTimer.restart()
    }

    function wifiActions(net) {
        const out = []
        if (!net)
            return out
        if (net.connected)
            out.push({ id: "disconnect", label: "Disconnect" })
        else if (!root.wifiJoined) {
            out.push({ id: "connect", label: "Connect" })
        }
        if (net.known && !net.connected)
            out.push({ id: "forget", label: "Forget" })
        return out
    }

    function runWifi(net, id, password) {
        if (!net)
            return
        if (id === "disconnect")
            net.disconnect()
        else if (id === "forget")
            net.forget()
        else if (id === "connect") {
            if (!net.known && !NetworkService.networkOpen(net))
                net.connectWithPsk(String(password || ""))
            else
                net.connect()
        }
        NetworkService.noteChange()
    }

    function connectHidden() {
        const name = hiddenName.text.trim()
        if (!name.length)
            return
        NetworkService.connectHidden(name, hiddenSecret.text)
        hiddenSecret.text = ""
    }

    readonly property int scrollGutter: Theme.space + Theme.tabGap
    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 2 + Theme.tabGap

    onOpenChanged: {
        if (root.open)
            root.forceActiveFocus()
        else
            root.focusCount = 0
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = true
        root.closeRequested()
    }

    Binding {
        target: NetworkService
        property: "fieldFocused"
        value: root.focusCount > 0
        when: root.open || root.focusCount === 0
    }

    Timer {
        id: copyTimer
        interval: Theme.copiedFlashMs
        repeat: false
        onTriggered: root.copied = ""
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
            id: netScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: netScroll.pressed || netScroll.hovered ? root.theme.colAccent : root.theme.colFgMuted
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
                text: "Network"
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: card.implicitHeight + Theme.space * 2
            radius: Theme.radiusSm
            color: root.theme.colSurface
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            Column {
                id: card
                x: Theme.space
                y: Theme.space
                width: parent.width - Theme.space * 2
                spacing: Theme.tabGap

                Row {
                    width: parent.width
                    spacing: Theme.space

                    Text {
                        width: root.theme.iconPx + Theme.space
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        text: root.headerIcon()
                        color: root.theme.colAccent
                        font.family: root.theme.iconFont
                        font.pixelSize: root.theme.iconPx
                    }

                    Column {
                        width: parent.width - root.theme.iconPx - Theme.space * 2
                        spacing: 1

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: {
                                const label = NetworkService.primaryLabel()
                                return label.length ? label : "Not connected"
                            }
                            color: root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: NetworkService.bareIp(NetworkService.primaryAddress())
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.headerMeta()
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width
                            text: "↓ " + NetworkService.formatRate(NetworkService.rxRate) + "    ↑ " + NetworkService.formatRate(NetworkService.txRate)
                            color: root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.fieldHeight

                    Text {
                        id: detailsLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.showDetails ? "Details  ▴" : "Details  ▾"
                        color: detailsMouse.containsMouse ? root.theme.colAccent : root.theme.colFgMuted
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: true

                        MouseArea {
                            id: detailsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showDetails = !root.showDetails

                            HoverTip {
                                message: "IPv4, gateway, DNS, and the rest of this connection"
                                show: detailsMouse.containsMouse
                            }
                        }
                    }
                }

                Column {
                    visible: root.showDetails
                    width: parent.width
                    spacing: Theme.tabGap

                    Repeater {
                        model: NetworkService.linesFor(NetworkService.primaryIface(), "", NetworkService.primarySignal())
                        delegate: Rectangle {
                            id: line
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: lineMouse.containsMouse ? root.theme.colHover : root.theme.colBg

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space
                                spacing: Theme.space

                                Text {
                                    width: Theme.chip * 4
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    text: String(line.modelData.label || "")
                                    color: root.theme.colFgMuted
                                    font.family: root.theme.uiFont
                                    font.pixelSize: root.theme.smallPx
                                }

                                Text {
                                    width: parent.width - Theme.chip * 4 - Theme.space
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: String(line.modelData.value || "")
                                    color: root.theme.colFg
                                    font.family: root.theme.uiFont
                                    font.pixelSize: root.theme.smallPx
                                }
                            }

                            MouseArea {
                                id: lineMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.copyValue(line.modelData.value)

                                HoverTip {
                                    message: "Copy"
                                    show: lineMouse.containsMouse
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.copied.length > 0
            width: parent.width
            text: "Copied"
            color: root.theme.colOk
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Text {
            visible: NetworkService.lastError.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: NetworkService.lastError
            color: root.theme.colDanger
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Text {
            visible: NetworkService.notice.length > 0 && !NetworkService.lastError.length
            width: parent.width
            wrapMode: Text.WordWrap
            text: NetworkService.notice
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Row {
            width: parent.width
            spacing: Theme.tabGap

            Repeater {
                model: root.modeChips()
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    width: (parent.width - Theme.tabGap * 3) / 4
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: chipMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: chip.modelData.on ? (chip.modelData.id === "airplane" ? root.theme.colDanger : root.theme.colOk) : root.theme.colBorder

                    Text {
                        anchors.centerIn: parent
                        text: String(chip.modelData.label || "")
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: !!chip.modelData.on
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMode(String(chip.modelData.id || ""))

                        HoverTip {
                            message: String(chip.modelData.tip || "")
                            show: chipMouse.containsMouse
                        }
                    }
                }
            }
        }

        Column {
            visible: NetworkService.wiredOn
            width: parent.width
            spacing: Theme.tabGap

            Text {
                width: parent.width
                text: "Wired"
                color: root.theme.colAccent
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                visible: !(NetworkService.wiredRows && NetworkService.wiredRows.length)
                width: parent.width
                text: "No ethernet device."
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            Repeater {
                model: NetworkService.wiredRows
                delegate: Rectangle {
                    id: wired
                    required property var modelData
                    required property int index
                    width: parent.width
                    implicitHeight: wiredCol.implicitHeight + Theme.space
                    radius: Theme.radiusSm
                    color: root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: wired.modelData.connected ? root.theme.colOk : root.theme.colBorder

                    Column {
                        id: wiredCol
                        x: Theme.space
                        y: Theme.tabGap
                        width: parent.width - Theme.space * 2
                        spacing: Theme.tabGap

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: String(wired.modelData.name || "Ethernet")
                            color: root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: {
                                const fact = NetworkService.factFor(wired.modelData.name) || {}
                                if (fact.connection)
                                    return String(fact.state || "Connected") + "  ·  " + String(fact.connection)
                                if (fact.state)
                                    return String(fact.state)
                                return wired.modelData.connected ? "Connected" : "Down"
                            }
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.smallPx
                        }

                        Rectangle {
                            width: wiredLabel.implicitWidth + Theme.space * 2
                            height: Theme.fieldHeight
                            radius: Theme.radiusSm
                            color: wiredMouse.containsMouse ? root.theme.colHover : root.theme.colBg
                            border.width: Theme.borderWidth
                            border.color: root.theme.colBorder

                            Text {
                                id: wiredLabel
                                anchors.centerIn: parent
                                text: wired.modelData.connected ? "Disconnect" : "Connect"
                                color: root.theme.colFg
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: wiredMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (wired.modelData.connected)
                                        wired.modelData.disconnect()
                                    else
                                        NetworkService.connectIface(String(wired.modelData.name || ""))
                                    NetworkService.noteChange()
                                }

                                HoverTip {
                                    message: wired.modelData.connected ? "Disconnect this port" : "Connect this port"
                                    show: wiredMouse.containsMouse
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            visible: NetworkService.wifiOn
            width: parent.width
            spacing: Theme.tabGap

            Text {
                width: parent.width
                text: "Wi-Fi"
                color: root.theme.colAccent
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                visible: !(NetworkService.wifiRows && NetworkService.wifiRows.length)
                width: parent.width
                text: "No networks found."
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            Repeater {
                model: NetworkService.wifiRows
                delegate: Rectangle {
                    id: wifi
                    required property var modelData
                    required property int index
                    readonly property bool needsPassword: !wifi.modelData.connected && !wifi.modelData.known && !NetworkService.networkOpen(wifi.modelData) && !root.wifiJoined
                    readonly property string netName: String(wifi.modelData.name || "")
                    width: parent.width
                    implicitHeight: wifiCol.implicitHeight + Theme.space
                    radius: Theme.radiusSm
                    color: root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: wifi.modelData.connected ? root.theme.colOk : root.theme.colBorder

                    Column {
                        id: wifiCol
                        x: Theme.space
                        y: Theme.tabGap
                        width: parent.width - Theme.space * 2
                        spacing: Theme.tabGap

                        Row {
                            width: parent.width
                            spacing: Theme.space

                            Text {
                                width: parent.width - signalText.width - (lockText.visible ? lockText.width + Theme.space : 0) - Theme.space
                                height: Theme.fieldHeight
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: wifi.netName
                                color: root.theme.colFg
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.fontPx
                                font.bold: true
                            }

                            Text {
                                id: lockText
                                visible: !NetworkService.networkOpen(wifi.modelData)
                                height: Theme.fieldHeight
                                verticalAlignment: Text.AlignVCenter
                                text: "󰌾"
                                color: root.theme.colFgMuted
                                font.family: root.theme.iconFont
                                font.pixelSize: root.theme.smallPx
                            }

                            Text {
                                id: signalText
                                height: Theme.fieldHeight
                                verticalAlignment: Text.AlignVCenter
                                text: NetworkService.percent(wifi.modelData.signalStrength) + "%"
                                color: root.theme.colFgMuted
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.smallPx
                            }
                        }

                        Item {
                            visible: root.wifiActions(wifi.modelData).length > 0 || wifi.modelData.connected
                            width: parent.width
                            height: Math.max(Theme.fieldHeight, actionFlow.implicitHeight)

                            Flow {
                                id: actionFlow
                                width: parent.width - (wifiExpand.visible ? wifiExpand.implicitWidth + Theme.space : 0)
                                spacing: Theme.tabGap

                                Repeater {
                                    model: root.wifiActions(wifi.modelData)
                                    delegate: Rectangle {
                                        id: action
                                        required property var modelData
                                        required property int index
                                        width: actionLabel.implicitWidth + Theme.space * 2
                                        height: Theme.fieldHeight
                                        radius: Theme.radiusSm
                                        color: actionMouse.containsMouse ? root.theme.colHover : root.theme.colBg
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
                                            onClicked: root.runWifi(wifi.modelData, String(action.modelData.id || ""), pskField.text)

                                            HoverTip {
                                                message: String(action.modelData.label || "")
                                                show: actionMouse.containsMouse
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                id: wifiExpand
                                visible: wifi.modelData.connected
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.expandedName === wifi.netName ? "Details  ▴" : "Details  ▾"
                                color: wifiExpandMouse.containsMouse ? root.theme.colAccent : root.theme.colFgMuted
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.smallPx
                                font.bold: true

                                MouseArea {
                                    id: wifiExpandMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const name = wifi.netName
                                        root.expandedName = root.expandedName === name ? "" : name
                                    }

                                    HoverTip {
                                        message: "IPv4, gateway, DNS, and the rest of this network"
                                        show: wifiExpandMouse.containsMouse
                                    }
                                }
                            }
                        }

                        TextField {
                            id: pskField
                            visible: wifi.needsPassword
                            width: parent.width
                            height: Theme.fieldHeight
                            echoMode: TextInput.Password
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            placeholderText: "Password"
                            leftPadding: Theme.space
                            color: root.theme.colFg
                            placeholderTextColor: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                            background: Rectangle {
                                radius: Theme.radiusSm
                                color: pskField.activeFocus ? root.theme.colHover : root.theme.colBg
                                border.width: Theme.borderWidth
                                border.color: pskField.activeFocus ? root.theme.colAccent : root.theme.colBorder
                            }
                            onActiveFocusChanged: activeFocus ? root.focusIn() : root.focusOut()
                            onAccepted: root.runWifi(wifi.modelData, "connect", text)
                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                root.closeRequested()
                            }
                        }

                        Column {
                            visible: wifi.modelData.connected && root.expandedName === wifi.netName
                            width: parent.width
                            spacing: Theme.tabGap

                            Repeater {
                                model: NetworkService.linesFor(wifi.modelData.device ? String(wifi.modelData.device.name || "") : "", NetworkService.securityLabel(wifi.modelData), NetworkService.percent(wifi.modelData.signalStrength))
                                delegate: Rectangle {
                                    id: extra
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    height: Theme.fieldHeight
                                    radius: Theme.radiusSm
                                    color: extraMouse.containsMouse ? root.theme.colHover : root.theme.colBg

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.space
                                        anchors.rightMargin: Theme.space
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        text: String(extra.modelData.label || "") + "  " + String(extra.modelData.value || "")
                                        color: root.theme.colFg
                                        font.family: root.theme.uiFont
                                        font.pixelSize: root.theme.smallPx
                                    }

                                    MouseArea {
                                        id: extraMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyValue(extra.modelData.value)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.space * 2
            }

            Row {
                width: parent.width
                spacing: Theme.tabGap

                TextField {
                    id: hiddenName
                    width: (parent.width - hiddenButton.width - Theme.tabGap * 2) / 2
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    placeholderText: "Hidden network"
                    leftPadding: Theme.space
                    color: root.theme.colFg
                    placeholderTextColor: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: hiddenName.activeFocus ? root.theme.colHover : root.theme.colBg
                        border.width: Theme.borderWidth
                        border.color: hiddenName.activeFocus ? root.theme.colAccent : root.theme.colBorder
                    }
                    onActiveFocusChanged: activeFocus ? root.focusIn() : root.focusOut()
                    onAccepted: root.connectHidden()
                    Keys.onEscapePressed: (event) => {
                        event.accepted = true
                        root.closeRequested()
                    }
                }

                TextField {
                    id: hiddenSecret
                    width: hiddenName.width
                    height: Theme.fieldHeight
                    echoMode: TextInput.Password
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    placeholderText: "Password"
                    leftPadding: Theme.space
                    color: root.theme.colFg
                    placeholderTextColor: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: hiddenSecret.activeFocus ? root.theme.colHover : root.theme.colBg
                        border.width: Theme.borderWidth
                        border.color: hiddenSecret.activeFocus ? root.theme.colAccent : root.theme.colBorder
                    }
                    onActiveFocusChanged: activeFocus ? root.focusIn() : root.focusOut()
                    onAccepted: root.connectHidden()
                    Keys.onEscapePressed: (event) => {
                        event.accepted = true
                        root.closeRequested()
                    }
                }

                Rectangle {
                    id: hiddenButton
                    width: hiddenLabel.implicitWidth + Theme.space * 2
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: hiddenMouse.containsMouse ? root.theme.colHover : root.theme.colBg
                    border.width: Theme.borderWidth
                    border.color: root.theme.colBorder

                    Text {
                        id: hiddenLabel
                        anchors.centerIn: parent
                        text: "Connect"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: true
                    }

                    MouseArea {
                        id: hiddenMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectHidden()

                        HoverTip {
                            message: "Connect to a network that is not broadcasting"
                            show: hiddenMouse.containsMouse
                        }
                    }
                }
            }
        }

        Column {
            visible: NetworkService.vpnOn
            width: parent.width
            spacing: Theme.tabGap

            Text {
                width: parent.width
                text: "VPN"
                color: root.theme.colAccent
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                visible: !(NetworkService.vpnRows && NetworkService.vpnRows.length)
                width: parent.width
                text: "No saved VPN profiles."
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }

            Repeater {
                model: NetworkService.vpnRows
                delegate: Rectangle {
                    id: vpn
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: Theme.fieldHeight + Theme.space
                    radius: Theme.radiusSm
                    color: root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: vpn.modelData.active ? root.theme.colOk : root.theme.colBorder

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space
                        anchors.rightMargin: Theme.tabGap
                        spacing: Theme.space

                        Text {
                            width: parent.width - vpnButton.width - Theme.space
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: String(vpn.modelData.name || "VPN")
                            color: root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                        }

                        Rectangle {
                            id: vpnButton
                            width: vpnLabel.implicitWidth + Theme.space * 2
                            height: parent.height
                            radius: Theme.radiusSm
                            color: vpnMouse.containsMouse ? root.theme.colHover : root.theme.colBg

                            Text {
                                id: vpnLabel
                                anchors.centerIn: parent
                                text: vpn.modelData.active ? "Disconnect" : "Connect"
                                color: root.theme.colFg
                                font.family: root.theme.uiFont
                                font.pixelSize: root.theme.smallPx
                                font.bold: true
                            }

                            MouseArea {
                                id: vpnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkService.toggleVpn(String(vpn.modelData.uuid || ""), !!vpn.modelData.active)

                                HoverTip {
                                    message: vpn.modelData.active ? "Disconnect this VPN" : "Connect this VPN"
                                    show: vpnMouse.containsMouse
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Right-click the pill to toggle Wi-Fi. Escape or Close closes this menu."
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

        Repeater {
            model: root.footerActions()
            delegate: Rectangle {
                id: foot
                required property var modelData
                required property int index
                readonly property int count: root.footerActions().length
                width: Math.max(1, Math.floor((footerRow.width - Theme.tabGap * (foot.count - 1)) / foot.count))
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: footMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Theme.space
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: String(foot.modelData.label || "")
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    font.bold: true
                }

                MouseArea {
                    id: footMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runFooter(String(foot.modelData.id || ""))

                    HoverTip {
                        message: String(foot.modelData.tip || "")
                        show: footMouse.containsMouse
                    }
                }
            }
        }
    }
}
