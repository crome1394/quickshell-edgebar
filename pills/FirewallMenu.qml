pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.settings
import qs.theme

// The firewall menu: on or off with a switch, the default policies, the
// rules, and a row to add one. Changes ask for your password (pkexec).
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()

    readonly property var fw: FirewallService
    property string action: "allow"
    property string proto: "tcp"

    function add() {
        if (root.fw.addRule({ action: root.action, port: portField.text, proto: root.proto, from: fromField.text })) {
            portField.text = ""
            fromField.text = ""
        }
    }

    implicitHeight: col.implicitHeight + Theme.space * 2

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.theme.colBg
        border.width: Theme.borderWidth
        border.color: root.theme.colBorder
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.closeRequested()
    }

    Column {
        id: col
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        spacing: Theme.space

        Row {
            width: parent.width
            spacing: Theme.space

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.fw.enabled ? Theme.firewallOnGlyph : Theme.firewallOffGlyph
                color: root.fw.enabled ? root.theme.colOk : root.theme.colDanger
                font.family: root.theme.iconFont
                font.pixelSize: root.theme.iconPx + 6
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - switchChip.width - Theme.space * 2 - root.theme.iconPx - 6

                Text {
                    text: "Firewall " + (root.fw.enabled ? "on" : "off")
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx + 1
                    font.bold: true
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: "UFW · incoming " + (root.fw.policy.input || "?") + " · outgoing " + (root.fw.policy.output || "?")
                        + " · routed " + (root.fw.policy.forward || "?") + (root.fw.logging.length ? " · logging " + root.fw.logging : "")
                    color: root.theme.colFgMuted
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                }
            }

            ChipButton {
                id: switchChip
                anchors.verticalCenter: parent.verticalCenter
                label: root.fw.busy ? "…" : (root.fw.enabled ? "Turn off" : "Turn on")
                active: !root.fw.enabled
                enabled: !root.fw.busy && root.fw.available
                tip: "Asks for your password"
                onClicked: root.fw.toggle()
            }
        }

        Text {
            visible: !root.fw.enabled && root.fw.available
            width: parent.width
            wrapMode: Text.WordWrap
            text: "With the firewall off, every port open on this computer can be reached from the network."
            color: root.theme.colDanger
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: root.theme.colBorder
        }

        Text {
            text: "Rules (" + root.fw.rules.length + ")"
            color: root.theme.colFg
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
            font.bold: true
        }

        Text {
            visible: root.fw.rules.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: "No rules: incoming connections follow the default (" + (root.fw.policy.input || "deny") + ")."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Flickable {
            visible: root.fw.rules.length > 0
            width: parent.width
            height: Math.min(ruleCol.implicitHeight, Theme.fieldHeight * 8)
            contentHeight: ruleCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: ruleCol
                width: parent.width
                spacing: Theme.borderWidth

                Repeater {
                    model: root.fw.rules
                    delegate: FirewallRuleRow {
                        required property var modelData
                        width: ruleCol.width
                        theme: root.theme
                        rule: modelData
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: root.theme.colBorder
        }

        Text {
            text: "Add a rule"
            color: root.theme.colFg
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.fontPx
            font.bold: true
        }

        Row {
            spacing: Theme.tabGap

            Repeater {
                model: ["allow", "deny", "limit"]
                delegate: ChipButton {
                    required property string modelData
                    label: modelData.charAt(0).toUpperCase() + modelData.substring(1)
                    active: root.action === modelData
                    tip: modelData === "limit" ? "Allow, but block an address that connects 6 times in 30 seconds (for SSH)" : ""
                    onClicked: root.action = modelData
                }
            }

            Item {
                width: Theme.space
                height: 1
            }

            Repeater {
                model: [{ id: "tcp", label: "TCP" }, { id: "udp", label: "UDP" }, { id: "any", label: "Both" }]
                delegate: ChipButton {
                    required property var modelData
                    label: modelData.label
                    active: root.proto === modelData.id
                    onClicked: root.proto = modelData.id
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.tabGap

            TextBox {
                id: portField
                width: Theme.fieldHeight * 4
                placeholderText: "Port, e.g. 22"
                validator: RegularExpressionValidator { regularExpression: /\d{0,5}(:\d{0,5})?/ }
                onAccepted: root.add()
            }

            TextBox {
                id: fromField
                width: parent.width - portField.width - addChip.width - parent.spacing * 2
                placeholderText: "From (anywhere, or 192.168.1.0/24)"
                onAccepted: root.add()
            }

            ChipButton {
                id: addChip
                label: "Add"
                bold: true
                enabled: !root.fw.busy && (portField.text.length > 0 || fromField.text.length > 0)
                tip: "Add this rule (asks for your password)"
                onClicked: root.add()
            }
        }

        Text {
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.fw.error.length ? root.fw.error : root.fw.notice
            color: root.fw.error.length ? root.theme.colDanger : root.theme.colOk
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Changes ask for your password. Rules apply to incoming connections."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }
    }
}
