pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether the audio pill's menu is open. The pill's left-click and IPC
// both go through toggle():
//   qs ipc call audioMenu toggle | open | close
Singleton {
    id: root

    property bool open: false
    // The monitor whose bar opened it; "" opens on the main monitor.
    property string screen: ""

    // A click from the bar on `name` opens there, or closes it if it is
    // already open there.
    function toggle(name) {
        const where = String(name || "")
        if (root.open && root.screen === where) {
            root.open = false
            return
        }
        root.screen = where
        root.open = true
    }

    function show(name) {
        root.screen = String(name || "")
        root.open = true
    }

    function hide() {
        root.open = false
    }

    IpcHandler {
        target: "audioMenu"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
