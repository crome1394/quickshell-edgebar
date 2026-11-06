pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// One machine in the Tailscale menu: OS glyph, name, how it is reached,
// and buttons to copy its address or send it files.
Rectangle {
    id: root

    required property var theme
    required property var peer
    required property bool canSend

    signal copyRequested(string text)
    signal sendRequested()

    function osGlyph(os) {
        const v = String(os || "").toLowerCase()
        if (v === "linux")
            return "󰌽"
        if (v === "macos" || v === "ios")
            return "󰀵"
        if (v === "windows")
            return "󰍲"
        if (v === "android")
            return "󰀲"
        return "󰟀"
    }

    function ago(stamp) {
        const t = Date.parse(String(stamp || ""))
        if (!(t > 0) || new Date(t).getFullYear() < 2000)
            return "offline"
        const mins = Math.max(0, Math.round((Date.now() - t) / 60000))
        if (mins < 60)
            return "seen " + mins + "m ago"
        if (mins < 60 * 48)
            return "seen " + Math.round(mins / 60) + "h ago"
        return "seen " + Math.round(mins / 1440) + "d ago"
    }

    function detail() {
        const p = root.peer
        const parts = [p.ip4]
        if (!p.online)
            parts.push(root.ago(p.lastSeen))
        else if (p.active)
            parts.push(p.direct ? "direct" : (p.relay.length ? "relay " + p.relay : "relay"))
        if (p.exitActive)
            parts.push("your exit node")
        else if (p.exitOption)
            parts.push("exit node")
        return parts.filter(s => s.length).join(" · ")
    }

    implicitHeight: Theme.fieldHeight + Theme.space
    radius: Theme.radiusSm
    color: peerMouse.containsMouse ? root.theme.colHover : "transparent"
    opacity: root.peer.online ? 1 : Theme.widgetOffOpacity

    MouseArea {
        id: peerMouse
        anchors.fill: parent
        hoverEnabled: true
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.tabGap
        spacing: Theme.space

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.theme.iconPx
            text: root.osGlyph(root.peer.os)
            color: root.peer.online ? root.theme.colOk : root.theme.colFgMuted
            font.family: root.theme.iconFont
            font.pixelSize: root.theme.iconPx
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.theme.iconPx - buttons.width - Theme.space * 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: String(root.peer.name || "")
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.detail()
                color: root.theme.colFgMuted
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.smallPx
            }
        }

        Row {
            id: buttons
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.tabGap

            MenuChip {
                theme: root.theme
                label: "IP"
                tip: "Copy " + root.peer.ip4
                visible: root.peer.ip4.length > 0
                onClicked: root.copyRequested(root.peer.ip4)
            }

            MenuChip {
                theme: root.theme
                label: "DNS"
                tip: "Copy " + root.peer.dns
                visible: root.peer.dns.length > 0
                onClicked: root.copyRequested(root.peer.dns)
            }

            MenuChip {
                theme: root.theme
                label: "Send"
                tip: "Send files with Taildrop"
                visible: root.canSend
                onClicked: root.sendRequested()
            }
        }
    }
}
