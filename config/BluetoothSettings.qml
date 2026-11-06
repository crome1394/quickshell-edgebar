pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Connectivity → Bluetooth: how long a scan runs.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function scanNorm(seconds) {
        const step = Math.max(1, Theme.bluetoothScanStep)
        let next = Math.round(Number(seconds) / step) * step
        if (!(next >= Theme.bluetoothScanMin))
            next = Theme.bluetoothScanMin
        if (next > Theme.bluetoothScanMax)
            next = Theme.bluetoothScanMax
        return next
    }

    function normalize(src) {
        return { scan: root.scanNorm(src.scan) }
    }

    function snapshot() {
        return root.normalize({ scan: Config.bluetoothScanSeconds })
    }

    function defaults() {
        return { scan: Theme.bluetoothScanDefault }
    }

    function commit(snap) {
        Config.saveFields(() => {
            Config.bluetoothScanSeconds = root.scanNorm(snap.scan)
        })
    }
}
