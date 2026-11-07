import QtQuick

// The reader's keyboard map. One table drives both the key handler in
// FreshRssPanel and the "?" shortcut sheet, so the two always agree.
//
// Each entry: the action FreshRssPanel.run() performs, the keys that run
// it, the key caps the sheet shows, and what it does. Shift is matched
// exactly, so r and Shift+R are different keys. Keys marked `typing`
// also work while the search box has focus.
QtObject {
    id: root

    // One key: Qt key code plus "", "shift", "ctrl", or "any" (Shift or not).
    function k(code, mods) {
        return { code: code, mods: mods || "" }
    }

    readonly property var groups: [
        {
            title: "Move",
            keys: [
                { action: "down", keys: [root.k(Qt.Key_Down)], caps: ["↓"], text: "Next row" },
                { action: "up", keys: [root.k(Qt.Key_Up)], caps: ["↑"], text: "Previous row" },
                { action: "pageDown", keys: [root.k(Qt.Key_PageDown)], caps: ["PgDn"], text: "Down ten rows" },
                { action: "pageUp", keys: [root.k(Qt.Key_PageUp)], caps: ["PgUp"], text: "Up ten rows" },
                { action: "first", keys: [root.k(Qt.Key_Home)], caps: ["Home"], text: "First row" },
                { action: "last", keys: [root.k(Qt.Key_End)], caps: ["End"], text: "Last row" },
                { action: "nextArticle", keys: [root.k(Qt.Key_J)], caps: ["j"], text: "Next article" },
                { action: "prevArticle", keys: [root.k(Qt.Key_K)], caps: ["k"], text: "Previous article" },
                { action: "open", keys: [root.k(Qt.Key_Return), root.k(Qt.Key_Enter), root.k(Qt.Key_Right)], caps: ["Enter", "→"], text: "Open a feed or day" },
                { action: "close", keys: [root.k(Qt.Key_Left)], caps: ["←"], text: "Close a feed or day" }
            ]
        },
        {
            title: "Read and star",
            keys: [
                { action: "read", keys: [root.k(Qt.Key_R)], caps: ["r"], text: "Mark the article read" },
                { action: "unread", keys: [root.k(Qt.Key_U)], caps: ["u"], text: "Mark the article unread" },
                { action: "space", keys: [root.k(Qt.Key_Space)], caps: ["Space"], text: "Article: read ↔ unread. Feed or day: all read ↔ all unread" },
                { action: "feedRead", keys: [root.k(Qt.Key_R, "shift")], caps: ["Shift", "r"], text: "Mark the whole feed read" },
                { action: "feedUnread", keys: [root.k(Qt.Key_U, "shift")], caps: ["Shift", "u"], text: "Mark the whole feed unread" },
                { action: "star", keys: [root.k(Qt.Key_S)], caps: ["s"], text: "Star or unstar the article" }
            ]
        },
        {
            title: "Article",
            keys: [
                { action: "browser", keys: [root.k(Qt.Key_B)], caps: ["b"], text: "Open in the browser" },
                { action: "copy", keys: [root.k(Qt.Key_C)], caps: ["c"], text: "Copy the link" },
                { action: "mpv", keys: [root.k(Qt.Key_V)], caps: ["v"], text: "Play the video in mpv" },
                { action: "full", keys: [root.k(Qt.Key_F)], caps: ["f"], text: "Web page ↔ feed text" }
            ]
        },
        {
            title: "Search and window",
            keys: [
                { action: "find", keys: [root.k(Qt.Key_F, "ctrl"), root.k(Qt.Key_Slash)], caps: ["Ctrl", "f"], text: "Find (also /)", typing: true },
                { action: "reload", keys: [root.k(Qt.Key_R, "ctrl")], caps: ["Ctrl", "r"], text: "Reload from the server", typing: true },
                { action: "help", keys: [root.k(Qt.Key_Question, "any")], caps: ["?"], text: "Show or hide this list" },
                { action: "escape", keys: [root.k(Qt.Key_Escape)], caps: ["Esc"], text: "Leave search, clear it, then close", typing: true }
            ]
        }
    ]

    // The short list along the bottom of the window.
    readonly property var footer: [
        { caps: ["↑", "↓"], text: "move" },
        { caps: ["Enter"], text: "open" },
        { caps: ["Space"], text: "read / unread" },
        { caps: ["s"], text: "star" },
        { caps: ["Ctrl", "f"], text: "find" },
        { caps: ["?"], text: "all shortcuts" }
    ]

    // The action for a key press, or "" when it is not one of ours.
    // `typing` is true while the search box has focus.
    function actionFor(event, typing) {
        const mods = event.modifiers
        if ((mods & Qt.AltModifier) || (mods & Qt.MetaModifier))
            return ""
        const shift = (mods & Qt.ShiftModifier) !== 0
        const ctrl = (mods & Qt.ControlModifier) !== 0
        for (let g = 0; g < root.groups.length; g++) {
            const entries = root.groups[g].keys
            for (let e = 0; e < entries.length; e++) {
                const entry = entries[e]
                if (typing && !entry.typing)
                    continue
                for (let i = 0; i < entry.keys.length; i++) {
                    const key = entry.keys[i]
                    if (key.code !== event.key)
                        continue
                    if ((key.mods === "ctrl") !== ctrl)
                        continue
                    if (key.mods === "any" || shift === (key.mods === "shift"))
                        return entry.action
                }
            }
        }
        return ""
    }
}
