pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

Item {
    id: root

    property string networkText: ""
    property string networkError: ""

    function refreshNetwork() {
        if (netProc.running)
            return
        root.networkError = ""
        netProc.running = true
    }

    Component.onCompleted: {
        Config.ensureNetEditor()
        root.refreshNetwork()
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector {
            id: netOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: netErr
            waitForEnd: true
        }
        onExited: (code) => {
            if (code !== 0) {
                const message = String(netErr.text || "").trim()
                root.networkError = message.length ? message.slice(0, 160) : "NetworkManager is not available"
                root.networkText = ""
                return
            }
            const lines = String(netOut.text || "").trim().split("\n")
            const out = []
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].length)
                    out.push(lines[i].split(":").join("  ·  "))
            }
            root.networkText = out.length ? out.join("\n") : "No active connection"
            root.networkError = ""
        }
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "On the bar"
                hint: "Address text drawn on the network pill. Apply saves these switches."
            }

            Item {
                width: parent.width
                height: optionCol.implicitHeight

                Column {
                    id: optionCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    CheckRow {
                        width: parent.width
                        title: "Full IP on bar"
                        detail: "Complete IPv4 address"
                        tip: "Show the complete IPv4 address on the network pill"
                        checked: Config.editorNetFull
                        onToggled: Config.editNetFull(!Config.editorNetFull)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Last octet on bar"
                        detail: "Last IPv4 octet when full IP is off"
                        tip: "Show the last IPv4 octet on the network pill when full IP is off"
                        checked: Config.editorNetOctet
                        onToggled: Config.editNetOctet(!Config.editorNetOctet)
                    }

                    CheckRow {
                        width: parent.width
                        title: "Device name on bar"
                        detail: "Adapter name beside the address"
                        tip: "Show the adapter name, such as enp10s0 or wlan0, beside the address"
                        checked: Config.editorNetDevice
                        onToggled: Config.editNetDevice(!Config.editorNetDevice)
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Network"
                hint: "Active NetworkManager connections. This reads once when the page opens."
            }

            Item {
                width: parent.width
                height: netCol.implicitHeight

                Column {
                    id: netCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.networkError.length ? root.networkError : (root.networkText.length ? root.networkText : "Reading…")
                        color: root.networkError.length ? Theme.danger : Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Rectangle {
                        width: refreshLabel.implicitWidth + Theme.space * 2
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: refreshMouse.containsMouse ? Theme.hover : Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        Text {
                            id: refreshLabel
                            anchors.centerIn: parent
                            text: "Refresh"
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                            font.bold: true
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshNetwork()

                            HoverTip {
                                message: "Read active connections again"
                                show: refreshMouse.containsMouse
                            }
                        }
                    }
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: Config.netEditorDirty
        undoEnabled: Config.canUndoNet()
        applyTip: "Save the address text shown on the network pill"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Turn full IP off, last octet on, and the device name off. Apply saves it."
        onApplyClicked: Config.applyNetEditor()
        onUndoClicked: Config.undoNetEditor()
        onResetClicked: Config.resetNetEditor()
    }
}
