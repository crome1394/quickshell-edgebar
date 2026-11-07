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

    function toggle() {
        root.open = !root.open
    }

    function show() {
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
