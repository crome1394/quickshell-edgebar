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
        target: "audioMenu"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
