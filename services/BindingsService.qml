pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Key bindings for Inspector → Bindings, read from the Hyprland Lua config.
// Only hl.bind(...) lines with a "--#" description are listed:
//   hl.bind("SUPER + T", ...) --# Opens the terminal
//   hl.bind("SUPER + T", ...) --#Apps# Opens the terminal
// Commented-out binds are skipped. The file is read and watched only while
// the Inspector is open (retain/release).
Singleton {
    id: root

    property int watchers: 0
    readonly property bool active: root.watchers > 0

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string configHome: {
        const xdg = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        return xdg.length ? xdg : root.home + "/.config"
    }
    readonly property var candidates: [
        root.configHome + "/hypr/config/keybindings.lua",
        root.configHome + "/hypr/hyprland.lua"
    ]
    property int tryIndex: 0
    property string file: ""
    property var binds: []          // { key, keys, action, category, dispatch, runnable, line }
    property bool loaded: false

    function retain() {
        root.watchers += 1
        if (root.watchers === 1) {
            root.tryIndex = 0
            root.loaded = false
        }
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    // "SUPER + T" from the first argument: quotes dropped, mainMod .. read
    // as SUPER, spacing around + made even.
    readonly property var mouseNames: ({
        "mouse:272": "Left click", "mouse:273": "Right click", "mouse:274": "Middle click",
        "mouse:275": "Back button", "mouse:276": "Forward button",
        "mouse_up": "Wheel up", "mouse_down": "Wheel down"
    })

    function keyText(expr) {
        return String(expr)
            .replace(/mainMod\s*\.\.\s*/g, "SUPER + ")
            .replace(/["']/g, "")
            .replace(/\s*\.\.\s*/g, " ")
            .replace(/\s*\+\s*/g, " + ")
            .replace(/\s+/g, " ")
            .trim()
            .split(" + ")
            .map((part) => root.mouseNames[part] || part)
            .join(" + ")
    }

    // The arguments of a call, split at top-level commas, starting just
    // after its "(". Quotes are respected, so "a, b" stays one argument.
    // Stops at the call's closing ")".
    function callArgs(text) {
        const out = []
        let depth = 0
        let quote = ""
        let start = 0
        for (let i = 0; i < text.length; i++) {
            const ch = text[i]
            if (quote.length) {
                if (ch === "\\")
                    i++
                else if (ch === quote)
                    quote = ""
                continue
            }
            if (ch === "\"" || ch === "'") {
                quote = ch
            } else if (ch === "(" || ch === "{" || ch === "[") {
                depth++
            } else if (ch === ")" || ch === "}" || ch === "]") {
                if (depth === 0) {
                    out.push(text.substring(start, i).trim())
                    return out
                }
                depth--
            } else if (ch === "," && depth === 0) {
                out.push(text.substring(start, i).trim())
                start = i + 1
            }
        }
        return null
    }

    function parse(text) {
        const out = []
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const raw = lines[i]
            if (raw.trim().startsWith("--"))
                continue
            const at = raw.indexOf("hl.bind(")
            const note = raw.indexOf("--#")
            if (at < 0 || note < at)
                continue
            const args = root.callArgs(raw.substring(at + 8, note))
            if (!args || args.length < 2)
                continue
            const comment = raw.substring(note)
            const grouped = /^--#([^#\n]+)#\s*(.*)$/.exec(comment)
            const key = root.keyText(args[0])
            out.push({
                key: key,
                keys: key.split(" + "),
                action: grouped ? grouped[2].trim() : comment.substring(3).trim(),
                category: grouped ? grouped[1].trim() : "",
                dispatch: args[1],
                // Drag and resize binds need the mouse held; a click can't run them.
                runnable: !/\bmouse\s*=\s*true\b/.test(args.slice(2).join(",")),
                line: i + 1
            })
        }
        return out
    }

    // ── Collapsed groups (kept while the bar runs) ──────────────────────
    property var collapsed: ({})

    function isCollapsed(name) {
        return root.collapsed[name] === true
    }

    function toggleGroup(name) {
        const next = Object.assign({}, root.collapsed)
        next[name] = !root.isCollapsed(name)
        root.collapsed = next
    }

    function setAll(names, closed) {
        const next = {}
        for (let i = 0; i < names.length; i++)
            next[names[i]] = !!closed
        root.collapsed = next
    }

    // ── Run a binding ───────────────────────────────────────────────────
    // The Inspector closes first so the binding acts on the window you had
    // focused, then Hyprland runs the bind's own action (the Lua after the
    // key in hl.bind), the same code the key runs. The text comes from your
    // Hyprland config, which Hyprland already runs.
    property string pending: ""

    function run(bind) {
        if (!bind || !bind.runnable || !String(bind.dispatch || "").length)
            return false
        root.pending = String(bind.dispatch)
        InspectorService.hide()
        runTimer.restart()
        return true
    }

    Timer {
        id: runTimer
        interval: Theme.inspectorRunDelayMs
        onTriggered: {
            if (root.pending.length)
                Quickshell.execDetached(["hyprctl", "dispatch", root.pending])
            root.pending = ""
        }
    }

    // Binds whose key, action, or category contain `query`, grouped by
    // category in file order. Uncategorized binds go under "Other" when
    // others have a category, or form one untitled group when none do.
    function groups(query) {
        const q = String(query || "").trim().toLowerCase()
        const list = q.length
            ? root.binds.filter((b) => (b.key + "\n" + b.action + "\n" + b.category).toLowerCase().indexOf(q) >= 0)
            : root.binds
        const anyCategory = root.binds.some((b) => b.category.length > 0)
        const out = []
        const at = {}
        for (let i = 0; i < list.length; i++) {
            const name = list[i].category.length ? list[i].category : (anyCategory ? "Other" : "")
            if (at[name] === undefined) {
                at[name] = out.length
                out.push({ category: name, binds: [] })
            }
            out[at[name]].binds.push(list[i])
        }
        return out
    }

    FileView {
        id: view
        path: root.active && root.tryIndex < root.candidates.length ? root.candidates[root.tryIndex] : ""
        watchChanges: true
        printErrors: false
        onFileChanged: view.reload()
        onLoaded: {
            const found = root.parse(view.text())
            if (!found.length && root.tryIndex + 1 < root.candidates.length) {
                root.tryIndex += 1
                return
            }
            root.binds = found
            root.file = view.path
            root.loaded = true
        }
        onLoadFailed: {
            if (root.tryIndex + 1 < root.candidates.length) {
                root.tryIndex += 1
                return
            }
            root.binds = []
            root.file = ""
            root.loaded = true
        }
    }
}
