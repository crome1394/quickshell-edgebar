pragma Singleton
import QtQuick
import Quickshell

// Connectivity → Network: what the network pill shows.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function normalize(src) {
        return {
            full: !!src.full,
            octet: !!src.octet,
            device: !!src.device
        }
    }

    function snapshot() {
        return root.normalize({
            full: Config.showNetworkFullIp,
            octet: Config.showNetworkLastOctet,
            device: Config.showNetworkDeviceName
        })
    }

    function defaults() {
        return { full: false, octet: true, device: false }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.showNetworkFullIp = clean.full
            Config.showNetworkLastOctet = clean.octet
            Config.showNetworkDeviceName = clean.device
        })
    }
}
