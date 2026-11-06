pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.theme

Item {
    id: root

    // qmllint disable unresolved-type
    readonly property var adapter: Bluetooth.defaultAdapter
    // qmllint enable unresolved-type

    // The device rows track .paired on their own. This only refreshes the empty line.
    property int pairPulse: 0

    function pairedCount() {
        void root.pairPulse
        if (!root.adapter)
            return 0
        // qmllint disable missing-property
        const values = root.adapter.devices ? root.adapter.devices.values : []
        // qmllint enable missing-property
        const list = values || []
        let count = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].paired)
                count++
        }
        return count
    }

    Component.onCompleted: Config.ensureBtEditor()

    Timer {
        interval: Theme.bluetoothPulseMs
        running: true
        repeat: true
        onTriggered: root.pairPulse++
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
                title: "Scan"
                hint: "How long a scan from the Bluetooth pill runs. Apply saves the length. Power, discovery, and devices change immediately."
            }

            Item {
                width: parent.width
                height: scanCol.implicitHeight

                Column {
                    id: scanCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.tabGap

                    HoverHandler {
                        id: scanHover
                    }

                    HoverTip {
                        message: "Stop discovery after this many seconds"
                        show: scanHover.hovered && !scanSlider.hovered
                    }

                    Text {
                        width: parent.width
                        text: "Scan length"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    IntSlider {
                        id: scanSlider
                        width: parent.width
                        from: Theme.bluetoothScanMin
                        to: Theme.bluetoothScanMax
                        step: Theme.bluetoothScanStep
                        value: Config.editorBtScan
                        readout: Config.editorBtScan + " s"
                        tip: "Stop discovery after this many seconds"
                        onChanged: (value) => Config.editBtScan(value)
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Bluetooth"
                hint: "Adapter power, discovery, and devices that are not paired."
            }

            Item {
                width: parent.width
                height: btCol.implicitHeight

                Column {
                    id: btCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        visible: !root.adapter
                        width: parent.width
                        text: "No Bluetooth adapter."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    CheckRow {
                        visible: !!root.adapter
                        width: parent.width
                        title: "Adapter power"
                        detail: root.adapter ? String(root.adapter.name || "") : ""
                        tip: "Turn the Bluetooth adapter on or off"
                        checked: !!(root.adapter && root.adapter.enabled)
                        onToggled: {
                            if (root.adapter)
                                root.adapter.enabled = !root.adapter.enabled
                        }
                    }

                    CheckRow {
                        visible: !!root.adapter
                        width: parent.width
                        title: "Discover devices"
                        detail: root.adapter && root.adapter.discovering ? "Scanning" : "Idle"
                        tip: "Scan for nearby devices"
                        checked: !!(root.adapter && root.adapter.discovering)
                        onToggled: {
                            if (root.adapter)
                                root.adapter.discovering = !root.adapter.discovering
                        }
                    }

                    Repeater {
                        model: root.adapter ? root.adapter.devices : []
                        delegate: CheckRow {
                            id: device
                            required property var modelData
                            required property int index
                            visible: !device.modelData.paired
                            width: btCol.width
                            title: String(device.modelData.name || device.modelData.deviceName || device.modelData.address || "Device")
                            detail: device.modelData.connected ? "Connected" : "Available"
                            tip: device.modelData.connected ? "Disconnect this device" : "Connect this device"
                            checked: !!device.modelData.connected
                            onToggled: device.modelData.connected = !device.modelData.connected
                        }
                    }
                }
            }

            SectionHeader {
                width: parent.width
                title: "Paired Devices"
                hint: "Devices this adapter has paired with."
            }

            Item {
                width: parent.width
                height: pairedCol.implicitHeight

                Column {
                    id: pairedCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Text {
                        visible: !!root.adapter && root.pairedCount() === 0
                        width: parent.width
                        text: "No paired devices."
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Repeater {
                        model: root.adapter ? root.adapter.devices : []
                        delegate: CheckRow {
                            id: pairedDevice
                            required property var modelData
                            required property int index
                            visible: !!pairedDevice.modelData.paired
                            width: pairedCol.width
                            title: String(pairedDevice.modelData.name || pairedDevice.modelData.deviceName || pairedDevice.modelData.address || "Device")
                            detail: pairedDevice.modelData.connected ? "Connected" : "Paired"
                            tip: pairedDevice.modelData.connected ? "Disconnect this device" : "Connect this device"
                            checked: !!pairedDevice.modelData.connected
                            onToggled: pairedDevice.modelData.connected = !pairedDevice.modelData.connected
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
        applyEnabled: Config.btEditorDirty
        undoEnabled: Config.canUndoBt()
        applyTip: "Save how long a Bluetooth scan runs"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Restore the scan length to the default. Apply saves it."
        onApplyClicked: Config.applyBtEditor()
        onUndoClicked: Config.undoBtEditor()
        onResetClicked: Config.resetBtEditor()
    }
}
