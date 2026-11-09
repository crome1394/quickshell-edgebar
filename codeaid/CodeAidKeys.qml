import QtQuick

// Code Aid's keys, in one table for the key handler in CodeAidPanel and
// the hints along its bottom. The search box keeps focus, so letters type.
QtObject {
    id: root

    // code: Qt key; mods: "", "ctrl", or "shift" (matched exactly).
    readonly property var keys: [
        { action: "down", code: Qt.Key_Down, mods: "" },
        { action: "up", code: Qt.Key_Up, mods: "" },
        { action: "down", code: Qt.Key_N, mods: "ctrl" },
        { action: "up", code: Qt.Key_P, mods: "ctrl" },
        { action: "down", code: Qt.Key_J, mods: "ctrl" },
        { action: "up", code: Qt.Key_K, mods: "ctrl" },
        { action: "pageDown", code: Qt.Key_PageDown, mods: "" },
        { action: "pageUp", code: Qt.Key_PageUp, mods: "" },
        { action: "pick", code: Qt.Key_Return, mods: "" },
        { action: "pick", code: Qt.Key_Enter, mods: "" },
        { action: "copyNow", code: Qt.Key_Return, mods: "ctrl" },
        { action: "copyNow", code: Qt.Key_Enter, mods: "ctrl" },
        { action: "fields", code: Qt.Key_Tab, mods: "" },
        { action: "edit", code: Qt.Key_E, mods: "ctrl" },
        { action: "new", code: Qt.Key_T, mods: "ctrl" },
        { action: "delete", code: Qt.Key_Delete, mods: "shift" },
        { action: "escape", code: Qt.Key_Escape, mods: "" }
    ]

    readonly property var hints: [
        { caps: ["↑", "↓"], text: "move" },
        { caps: ["Enter"], text: "copy (fill blanks first)" },
        { caps: ["Ctrl", "Enter"], text: "copy as is" },
        { caps: ["Tab"], text: "blanks" },
        { caps: ["Ctrl", "E"], text: "edit" },
        { caps: ["Ctrl", "T"], text: "new" },
        { caps: ["Shift", "Del"], text: "delete" },
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
