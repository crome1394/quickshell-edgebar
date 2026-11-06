pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether the Inspector window is open. The window only exists while it is
// (shell.qml loads it from `open`), so a closed Inspector costs nothing.
//   qs ipc call inspector toggle | open | close
//   qs ipc call inspector openTab bindings|system
Singleton {
    id: root

    property bool open: false
    property string tab: "bindings"
    readonly property var tabs: ["bindings", "system"]

    function toggle() {
        root.open = !root.open
    }

    function show() {
        root.open = true
    }

    function hide() {
        root.open = false
    }

    function showTab(id) {
        if (root.tabs.indexOf(id) < 0)
            return false
        root.tab = id
        root.open = true
        return true
    }

    IpcHandler {
        target: "inspector"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
        function openTab(tab: string): string {
            return root.showTab(String(tab || "").trim()) ? "ok" : "unknown tab: " + tab
        }
    }
}
