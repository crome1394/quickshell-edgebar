import QtQuick

// The viewer's keys, in one table that drives both the key handler in
// ClipboardPanel and the hints along its bottom. The search box always
// has focus, so plain letters type; every key here is one that does not
// type (arrows, Enter, Esc, Tab) or has Alt, Ctrl, or Shift held.
// Zoom (Tab or Alt+Z) fills the card with the preview.
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
        { action: "first", code: Qt.Key_Home, mods: "ctrl" },
        { action: "last", code: Qt.Key_End, mods: "ctrl" },
        { action: "copy", code: Qt.Key_Return, mods: "" },
        { action: "copy", code: Qt.Key_Enter, mods: "" },
        { action: "delete", code: Qt.Key_Delete, mods: "shift" },
        { action: "zoom", code: Qt.Key_Z, mods: "alt" },
        { action: "zoom", code: Qt.Key_Tab, mods: "" },
        { action: "escape", code: Qt.Key_Escape, mods: "" }
    ]

    // Shown along the bottom of the window.
    readonly property var hints: [
        { caps: ["↑", "↓"], text: "move" },
        { caps: ["Enter"], text: "copy" },
        { caps: ["Alt", "1–9"], text: "copy that one" },
        { caps: ["Shift", "Del"], text: "delete" },
        { caps: ["Tab"], text: "zoom" },
        { caps: ["Esc"], text: "clear search, close" }
    ]

    // Shown instead while zoomed.
    readonly property var zoomHints: [
        { caps: ["↑", "↓"], text: "next / previous" },
        { caps: ["PgUp", "PgDn"], text: "scroll" },
        { caps: ["Enter"], text: "copy" },
        { caps: ["Click"], text: "picture: fit ↔ full size" },
        { caps: ["Tab"], text: "back to the list" }
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
