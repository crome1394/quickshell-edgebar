import QtQuick
import qs.services
import qs.settings
import qs.theme

// One UFW rule in the firewall menu: the action as a colored badge, the
// port and protocol, where it applies from, IPv4/IPv6, and ✕ to delete
// (asks for your password).
Rectangle {
    id: root

    required property var theme
    required property var rule

    readonly property bool allowing: root.rule.action === "allow"

    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    color: rowMouse.containsMouse ? root.theme.colHover : "transparent"

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
    }

    Rectangle {
        id: badge
        x: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.fieldHeight * 2
        height: Theme.chip - Theme.tabGap
        radius: Theme.radiusSm
        color: root.allowing ? root.theme.colOk : (root.rule.action === "limit" ? root.theme.colAccentDim : root.theme.colDanger)

        Text {
            anchors.centerIn: parent
            text: root.rule.action.toUpperCase()
            color: Theme.indexTabDarkInk
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx - 1
            font.bold: true
        }
    }

    Text {
        anchors.left: badge.right
        anchors.leftMargin: Theme.space
        anchors.right: families.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: FirewallService.describePort(root.rule)
            + (root.rule.direction === "out" ? " · out" : "")
            + "  ·  from " + (FirewallService.anyAddr(root.rule.from) ? "anywhere" : root.rule.from)
        color: root.theme.colFg
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    Text {
        id: families
        anchors.right: deleteText.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        text: root.rule.families.join(" ")
        color: root.theme.colFgMuted
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.smallPx - 1
    }

    Text {
        id: deleteText
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        text: "✕"
        color: delMouse.containsMouse ? root.theme.colDanger : root.theme.colFgMuted
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
        font.bold: true

        MouseArea {
            id: delMouse
            anchors.fill: parent
            anchors.margins: -Theme.tabGap
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: !FirewallService.busy
            onClicked: FirewallService.deleteRule(root.rule)

            HoverTip {
                message: "Delete this rule (asks for your password)"
                show: delMouse.containsMouse
            }
        }
    }
}
