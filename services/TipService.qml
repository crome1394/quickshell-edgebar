pragma Singleton
import QtQuick
import Quickshell

// The one bar tooltip on screen. A BarTip asks for it with request() after
// its hover delay and gives it back with release(). BarTipHost (in
// shell.qml) draws it next to the item that asked, so the whole shell has
// a single tooltip window instead of one per pill.
Singleton {
    id: root

    property Item target: null
    property string message: ""
    property string edge: "top"

    function request(item, text, side) {
        if (!item || !String(text || "").length)
            return
        root.message = String(text)
        root.edge = String(side || "top")
        root.target = item
    }

    // Only the item showing the tip can hide it, so a late release from
    // one pill does not close another pill's tip.
    function release(item) {
        if (root.target === item) {
            root.target = null
            root.message = ""
        }
    }
}
