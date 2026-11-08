pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether the audio pill's menu is open. The pill's left-click and IPC
// both go through toggle():
//   qs ipc call audioMenu toggle | open | close
// With Speaker and Microphone as separate widgets, `owner` says which one
// opened it ("out" or "in"), so only that pill shows the menu. IPC leaves
// it "", which the combined pill or the Speaker widget takes.
Singleton {
    id: root

    property bool open: false
    // The monitor whose bar opened it; "" opens on the main monitor.
    property string screen: ""
    property string owner: ""

    // True when the pill drawing `part` ("both", "out", "in") on `name`
    // should show the menu.
    function shownBy(name, part) {
        if (!root.open || !ScreenService.owns(root.screen, name))
            return false
        if (root.owner === part)
            return true
        return root.owner === "" ? part !== "in" : part === "both"
    }

    // A click from the bar on `name` opens there, or closes it if it is
    // already open there.
    function toggle(name, part) {
        const where = String(name || "")
        const who = part === "out" || part === "in" ? part : ""
        if (root.open && root.screen === where && root.owner === who) {
            root.open = false
            return
        }
        root.screen = where
        root.owner = who
        root.open = true
    }

    function show(name) {
        root.screen = String(name || "")
        root.owner = ""
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
