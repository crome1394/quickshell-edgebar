pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether the Transparency pill's menu is open. The pill's click and IPC
// both go through toggle(), show(), and hide(). Loaded only while the
// pill is on the bar, so the IPC target exists only then:
//   qs ipc call opacityMenu toggle | open | close
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
        target: "opacityMenu"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
