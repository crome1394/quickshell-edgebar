import QtQuick

// The App Library's keys, in one table for the key handler in
// LibraryPanel and the hints along its bottom. The search box keeps
// focus, so letters type; arrows move through the grid.
QtObject {
    id: root

    // code: Qt key; mods: "", "ctrl", or "shift" (matched exactly).
    readonly property var keys: [
        { action: "left", code: Qt.Key_Left, mods: "" },
        { action: "right", code: Qt.Key_Right, mods: "" },
        { action: "up", code: Qt.Key_Up, mods: "" },
        { action: "down", code: Qt.Key_Down, mods: "" },
        { action: "pageUp", code: Qt.Key_PageUp, mods: "" },
        { action: "pageDown", code: Qt.Key_PageDown, mods: "" },
        { action: "first", code: Qt.Key_Home, mods: "ctrl" },
        { action: "last", code: Qt.Key_End, mods: "ctrl" },
        { action: "open", code: Qt.Key_Return, mods: "" },
        { action: "open", code: Qt.Key_Enter, mods: "" },
        { action: "nextFolder", code: Qt.Key_Tab, mods: "" },
        { action: "prevFolder", code: Qt.Key_Backtab, mods: "shift" },
        { action: "prevFolder", code: Qt.Key_Tab, mods: "shift" },
        { action: "newFolder", code: Qt.Key_N, mods: "ctrl" },
        { action: "menu", code: Qt.Key_Menu, mods: "" },
        { action: "escape", code: Qt.Key_Escape, mods: "" }
    ]

    readonly property var hints: [
        { caps: ["←", "→", "↑", "↓"], text: "move" },
        { caps: ["Enter"], text: "open" },
        { caps: ["Tab"], text: "next folder" },
        { caps: ["Ctrl", "N"], text: "new folder" },
        { caps: ["Drag"], text: "onto a folder to add" },
        { caps: ["Right-click"], text: "more" },
        { caps: ["Esc"], text: "clear, close" }
    ]

    function actionFor(event) {
        const m = event.modifiers
        if (m & (Qt.MetaModifier | Qt.AltModifier))
            return ""
        const ctrl = (m & Qt.ControlModifier) !== 0
        const shift = (m & Qt.ShiftModifier) !== 0
        const mods = ctrl ? (shift ? "x" : "ctrl") : (shift ? "shift" : "")
        for (let i = 0; i < root.keys.length; i++) {
            if (root.keys[i].code === event.key && root.keys[i].mods === mods)
                return root.keys[i].action
        }
        return ""
    }
}
