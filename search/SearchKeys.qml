import QtQuick

// The launcher's keys, in one table for the key handler in SearchPanel
// and the hints along its bottom. The search box keeps focus, so plain
// letters type; every key here is one that does not type or has a
// modifier held. Alt+1…9 run that row, as in the clipboard viewer.
QtObject {
    id: root

    // code: Qt key; mods: "", "alt", "ctrl", or "shift" (matched exactly).
    readonly property var keys: [
        { action: "down", code: Qt.Key_Down, mods: "" },
        { action: "up", code: Qt.Key_Up, mods: "" },
        { action: "down", code: Qt.Key_N, mods: "ctrl" },
        { action: "up", code: Qt.Key_P, mods: "ctrl" },
        { action: "down", code: Qt.Key_J, mods: "ctrl" },
        { action: "up", code: Qt.Key_K, mods: "ctrl" },
        { action: "pageDown", code: Qt.Key_PageDown, mods: "" },
        { action: "pageUp", code: Qt.Key_PageUp, mods: "" },
        { action: "open", code: Qt.Key_Return, mods: "" },
        { action: "open", code: Qt.Key_Enter, mods: "" },
        { action: "context", code: Qt.Key_Return, mods: "shift" },
        { action: "context", code: Qt.Key_Enter, mods: "shift" },
        { action: "complete", code: Qt.Key_Tab, mods: "" },
        { action: "escape", code: Qt.Key_Escape, mods: "" }
    ]

    readonly property var hints: [
        { caps: ["↑", "↓"], text: "move" },
        { caps: ["Enter"], text: "open" },
        { caps: ["Shift", "Enter"], text: "app actions" },
        { caps: ["Tab"], text: "complete" },
        { caps: ["?"], text: "prefixes" },
        { caps: ["Esc"], text: "clear, close" }
    ]

    // The action for a key press, or "". Alt+1…9 give "pick1" … "pick9".
    function actionFor(event) {
        const m = event.modifiers
        if (m & Qt.MetaModifier)
            return ""
        const alt = (m & Qt.AltModifier) !== 0
        const ctrl = (m & Qt.ControlModifier) !== 0
        const shift = (m & Qt.ShiftModifier) !== 0
        if (alt && !ctrl && !shift && event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
            return "pick" + (event.key - Qt.Key_0)
        const mods = alt ? (ctrl || shift ? "x" : "alt") : (ctrl ? (shift ? "x" : "ctrl") : (shift ? "shift" : ""))
        for (let i = 0; i < root.keys.length; i++) {
            if (root.keys[i].code === event.key && root.keys[i].mods === mods)
                return root.keys[i].action
        }
        return ""
    }
}
