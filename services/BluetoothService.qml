pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.config

// Shared Bluetooth actions for the pill, its menu, and the settings tab.
// - Scans always stop on their own after the saved scan length.
// - Pairing stops the scan and makes the adapter pairable first, then trusts
//   and connects the device once it is paired, so headsets and speakers
//   reconnect on their own later.
// Nothing runs while idle: one stopped timer and one idle Connections.
Singleton {
    id: root

    // qmllint disable unresolved-type
    readonly property var adapter: Bluetooth.defaultAdapter
    // qmllint enable unresolved-type

    // The device we asked to pair, until pairing finishes.
    property var pairTarget: null

    function deviceValues() {
        const adapter = root.adapter
        if (!adapter)
            return []
        // qmllint disable missing-property
        const rows = adapter.devices ? adapter.devices.values : null
        // qmllint enable missing-property
        return rows || []
    }

    // Battery as 0..100, or -1 when the device does not report one.
    function batteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1
        const value = Number(device.battery)
        if (isNaN(value) || value < 0)
            return -1
        if (value <= 1.01)
            return Math.round(value * 100)
        return Math.max(0, Math.min(100, Math.round(value)))
    }

    function deviceName(device) {
        if (!device)
            return "Device"
        return String(device.name || device.deviceName || device.address || "Device")
    }

    // Connected devices that report a battery, lowest charge first.
    function batteryDevices() {
        const rows = root.deviceValues()
        const out = []
        for (let i = 0; i < rows.length; i++) {
            const device = rows[i]
            if (!device || !device.connected)
                continue
            const percent = root.batteryPercent(device)
            if (percent >= 0)
                out.push({ name: root.deviceName(device), percent: percent })
        }
        out.sort((a, b) => a.percent - b.percent)
        return out
    }

    function startScan() {
        if (!root.adapter || !root.adapter.enabled)
            return
        root.adapter.discovering = true
        scanTimer.restart()
    }

    function stopScan() {
        scanTimer.stop()
        if (root.adapter && root.adapter.discovering)
            root.adapter.discovering = false
    }

    function toggleScan() {
        if (root.adapter && root.adapter.discovering)
            root.stopScan()
        else
            root.startScan()
    }

    // Scanning while pairing or connecting makes many adapters fail or stall.
    // BlueZ boots with the adapter not pairable. Pairing still "works" then,
    // but the link key is not saved (bonded stays false), so the device drops
    // back to unpaired on its next disconnect. Make the adapter pairable first.
    function pair(device) {
        if (!device || device.pairing)
            return
        root.stopScan()
        if (root.adapter && !root.adapter.pairable)
            root.adapter.pairable = true
        root.pairTarget = device
        device.pair()
    }

    function cancelPair(device) {
        if (!device)
            return
        if (root.pairTarget === device)
            root.pairTarget = null
        device.cancelPair()
    }

    function connect(device) {
        if (!device)
            return
        root.stopScan()
        if (!device.paired) {
            root.pair(device)
            return
        }
        device.connect()
    }

    function finishPair() {
        const device = root.pairTarget
        if (!device || device.pairing)
            return
        root.pairTarget = null
        if (!device.paired)
            return
        if (!device.trusted)
            device.trusted = true
        if (!device.connected)
            device.connect()
    }

    Timer {
        id: scanTimer
        interval: Math.max(1, Config.bluetoothScanSeconds) * 1000
        repeat: false
        onTriggered: root.stopScan()
    }

    Connections {
        target: root.pairTarget
        ignoreUnknownSignals: true
        function onPairedChanged() {
            root.finishPair()
        }
        function onPairingChanged() {
            root.finishPair()
        }
    }
}
