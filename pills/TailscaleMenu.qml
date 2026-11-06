pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.services
import qs.settings
import qs.theme

// Left-click menu for the Tailscale pill: on/off, this device, login,
// accounts, exit node, options, and the machines on the tailnet.
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()
    signal sendRequested(var peer)

    property string copied: ""
    property bool showOffline: false
    property string exitFilter: ""

    readonly property var ts: TailscaleService
    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property var shownPeers: root.ts.peers.filter(p => root.showOffline || p.online)
    readonly property int offlineCount: root.ts.peers.filter(p => !p.online).length
    readonly property var activeExit: root.ts.exitNodes.filter(n => n.exitActive)[0] || null
    readonly property var shownExits: {
        const q = root.exitFilter.trim().toLowerCase()
        if (!q.length)
            return root.ts.exitNodes
        return root.ts.exitNodes.filter(n => (n.name + " " + n.place).toLowerCase().indexOf(q) >= 0)
    }

    function stateLine() {
        const t = root.ts
        if (t.checked && !t.available)
            return "Not installed"
        if (!t.checked)
            return "Checking…"
        if (t.needsLogin)
            return "Needs login"
        if (t.starting)
            return "Connecting…"
        if (t.running)
            return root.activeExit ? "Connected via " + (root.activeExit.place || root.activeExit.name) : "Connected"
        return "Off"
    }

    function copyValue(text) {
        const value = String(text || "")
        if (!value.length)
            return
        Quickshell.clipboardText = value
        root.copied = value
        copyTimer.restart()
    }

    function accountLabel(a) {
        return String(a.tailnet || a.nickname || a.account || a.id || "Account")
    }

    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 2 + Theme.tabGap

    onOpenChanged: {
        if (root.open)
            root.forceActiveFocus()
        else
            root.exitFilter = ""
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = true
        root.closeRequested()
    }

    Timer {
        id: copyTimer
        interval: Theme.copiedFlashMs
        onTriggered: root.copied = ""
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 0
        color: root.theme.colAccent
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.fontPx
        font.bold: true
    }

    component Note: Text {
        width: parent ? parent.width : 0
        wrapMode: Text.WordWrap
        color: root.theme.colFgMuted
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    // A label, a value, and a copy button, for this device's addresses.
    component CopyLine: Item {
        id: line
        required property string label
        required property string value
        width: parent ? parent.width : 0
        height: Theme.chip
        visible: line.value.length > 0

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.wsButtonWidth * 2
            text: line.label
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.wsButtonWidth * 2
            anchors.right: copyChip.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideMiddle
            text: line.value
            color: root.theme.colFg
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.smallPx
        }

        MenuChip {
            id: copyChip
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            theme: root.theme
            label: "Copy"
            tip: "Copy " + line.value
            onClicked: root.copyValue(line.value)
        }
    }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerRow.top
        anchors.margins: Theme.space
        anchors.bottomMargin: Theme.tabGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: column.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: scrollBar.pressed || scrollBar.hovered ? root.theme.colAccent : root.theme.colFgMuted
            }
        }

        Column {
            id: column
            width: Math.max(0, flick.width - root.scrollGutter)
            spacing: Theme.space

            // Header: mark, state, the on/off switch, and close.
            Row {
                width: parent.width
                spacing: Theme.space

                TailscaleMark {
                    anchors.verticalCenter: parent.verticalCenter
                    size: root.theme.iconPx
                    ink: root.ts.running ? root.theme.colAccent : root.theme.colFgMuted
                    on: root.ts.running
                }

                TailscaleSwitch {
                    width: parent.width - root.theme.iconPx - closeBox.width - Theme.space * 2
                    theme: root.theme
                    label: "Tailscale · " + root.stateLine()
                    bold: true
                    on: root.ts.running || root.ts.starting
                    tip: root.ts.running ? "Turn Tailscale off (tailscale down)" : "Turn Tailscale on (tailscale up)"
                    visible: root.ts.available
                    onToggled: root.ts.toggle()
                }

                Text {
                    visible: !root.ts.available
                    width: parent.width - root.theme.iconPx - closeBox.width - Theme.space * 2
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: "Tailscale · " + root.stateLine()
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                }

                Rectangle {
                    id: closeBox
                    width: Theme.fieldHeight
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: closeMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: root.theme.colBorder

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Note {
                visible: root.ts.busy || root.ts.lastError.length > 0 || root.ts.notice.length > 0 || root.copied.length > 0
                text: root.ts.lastError.length ? root.ts.lastError
                    : (root.ts.busy ? "Working…" : (root.copied.length ? "Copied " + root.copied : root.ts.notice))
                color: root.ts.lastError.length ? root.theme.colDanger : root.theme.colOk
            }

            Note {
                visible: root.ts.checked && !root.ts.available
                text: "The tailscale command was not found. Install the tailscale package and enable tailscaled."
            }

            // Login.
            Rectangle {
                visible: root.ts.needsLogin
                width: parent.width
                implicitHeight: loginCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colDanger

                Column {
                    id: loginCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    Note {
                        text: "This device is not logged in to a tailnet."
                        color: root.theme.colFg
                    }

                    MenuChip {
                        theme: root.theme
                        label: root.ts.authUrl.length ? "Open login page" : "Log in"
                        tip: "Log in through your browser"
                        accent: true
                        onClicked: root.ts.login()
                    }
                }
            }

            // This device.
            Rectangle {
                visible: root.ts.available && root.ts.selfName.length > 0
                width: parent.width
                implicitHeight: selfCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: selfCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.ts.selfName
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    CopyLine {
                        label: "IPv4"
                        value: root.ts.selfIp4
                    }

                    CopyLine {
                        label: "IPv6"
                        value: root.ts.selfIp6
                    }

                    CopyLine {
                        label: "DNS"
                        value: root.ts.selfDns
                    }

                    Note {
                        text: [root.ts.tailnet.length ? "Tailnet " + root.ts.tailnet : "", root.ts.version.length ? "Tailscale " + root.ts.version : ""].filter(s => s.length).join("  ·  ")
                    }

                    // Warnings only matter while connected.
                    Repeater {
                        model: root.ts.running ? root.ts.health : []
                        delegate: Note {
                            required property var modelData
                            text: "⚠ " + String(modelData)
                            color: root.theme.colDanger
                        }
                    }
                }
            }

            // Accounts, when there is more than one.
            Column {
                visible: root.ts.accounts.length > 1
                width: parent.width
                spacing: Theme.tabGap

                SectionTitle {
                    text: "Account"
                }

                Repeater {
                    model: root.ts.accounts
                    delegate: TailscaleExitRow {
                        required property var modelData
                        width: parent.width
                        theme: root.theme
                        label: root.accountLabel(modelData)
                        detail: String(modelData.account || "")
                        chosen: modelData.selected === true
                        onPicked: {
                            if (!chosen)
                                root.ts.switchAccount(String(modelData.id || ""))
                        }
                    }
                }
            }

            // Exit node.
            Column {
                visible: root.ts.running
                width: parent.width
                spacing: Theme.tabGap

                SectionTitle {
                    text: "Exit node"
                }

                Note {
                    visible: root.ts.exitNodes.length === 0
                    text: "No exit nodes on this tailnet. A machine offers one with “Offer as exit node” or --advertise-exit-node."
                }

                TextField {
                    id: exitSearch
                    visible: root.ts.exitNodes.length > Theme.tailscaleSearchMin
                    width: parent.width
                    height: Theme.fieldHeight
                    placeholderText: "Search exit nodes"
                    text: root.exitFilter
                    onTextChanged: root.exitFilter = exitSearch.text
                    color: root.theme.colFg
                    placeholderTextColor: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    leftPadding: Theme.space
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: root.theme.colSurface
                        border.width: Theme.borderWidth
                        border.color: exitSearch.activeFocus ? root.theme.colAccent : root.theme.colBorder
                    }
                    Keys.onEscapePressed: (event) => {
                        event.accepted = true
                        if (exitSearch.text.length)
                            exitSearch.text = ""
                        else
                            root.closeRequested()
                    }
                }

                TailscaleExitRow {
                    visible: root.ts.exitNodes.length > 0
                    width: parent.width
                    theme: root.theme
                    label: "None"
                    detail: "direct to the internet"
                    chosen: !root.activeExit
                    onPicked: {
                        if (root.activeExit)
                            root.ts.setExitNode("")
                    }
                }

                Repeater {
                    model: root.shownExits
                    delegate: TailscaleExitRow {
                        required property var modelData
                        width: parent.width
                        theme: root.theme
                        label: modelData.place.length ? modelData.place : modelData.name
                        detail: modelData.mullvad ? "Mullvad" : modelData.ip4
                        chosen: modelData.exitActive
                        online: modelData.online
                        onPicked: {
                            if (!chosen)
                                root.ts.setExitNode(modelData.ip4)
                        }
                    }
                }
            }

            // Options: each is a `tailscale set` flag.
            Column {
                visible: root.ts.available && Object.keys(root.ts.prefs).length > 0
                width: parent.width
                spacing: 0

                SectionTitle {
                    text: "Options"
                }

                Repeater {
                    model: root.ts.options
                    delegate: TailscaleSwitch {
                        required property var modelData
                        width: parent.width
                        theme: root.theme
                        label: String(modelData.label)
                        tip: String(modelData.tip)
                        on: root.ts.optionOn(String(modelData.key))
                        onToggled: (next) => root.ts.setOption(String(modelData.key), next)
                    }
                }
            }

            // Machines.
            Column {
                visible: root.ts.available && root.ts.peers.length > 0
                width: parent.width
                spacing: Theme.tabGap

                Item {
                    width: parent.width
                    height: Theme.chip

                    SectionTitle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - offlineChip.width
                        text: "Machines · " + root.ts.peers.filter(p => p.online).length + " online"
                    }

                    MenuChip {
                        id: offlineChip
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.offlineCount > 0
                        theme: root.theme
                        label: root.showOffline ? "Hide offline" : "Show " + root.offlineCount + " offline"
                        onClicked: root.showOffline = !root.showOffline
                    }
                }

                Note {
                    visible: root.shownPeers.length === 0
                    text: "No machines online."
                }

                Repeater {
                    model: root.shownPeers
                    delegate: TailscalePeerRow {
                        required property var modelData
                        width: parent.width
                        theme: root.theme
                        peer: modelData
                        canSend: root.ts.running && root.ts.fileSharing && modelData.taildrop
                        onCopyRequested: (text) => root.copyValue(text)
                        onSendRequested: root.sendRequested(modelData)
                    }
                }
            }

            Note {
                text: "Right-click the pill to turn Tailscale on or off. Escape or ✕ closes this menu."
            }
        }
    }

    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        spacing: Theme.tabGap
        height: Theme.chip

        MenuChip {
            theme: root.theme
            label: "Admin console"
            tip: "Open login.tailscale.com in your browser"
            onClicked: root.ts.adminConsole()
        }

        MenuChip {
            theme: root.theme
            label: "Refresh"
            tip: "Check Tailscale again now"
            onClicked: {
                root.ts.refresh()
                root.ts.readPrefs()
                root.ts.readAccounts()
            }
        }
    }
}
