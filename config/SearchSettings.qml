pragma Singleton
import QtQuick
import Quickshell
import qs.search
import qs.theme

// Applications → Launcher: the Pop Launcher style search (SearchService).
// Built in, or a command of your own run instead; which search modes are
// on; how many results; where it sits; the terminal for "t:" commands;
// launch history; and the web search shortcuts. Commands are split on
// spaces and never run through a shell.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    // The search modes, in the order the settings page lists them.
    readonly property var plugins: [
        { id: "windows", label: "Open windows", detail: "Listed when the box is empty, and matched by title" },
        { id: "apps", label: "Applications", detail: "Installed apps, by name, keywords, and description" },
        { id: "calc", label: "Calculator", detail: "= 2+2, or text that starts with a number (needs qalc)" },
        { id: "files", label: "Files", detail: "~/ or / browses folders; Tab completes" },
        { id: "find", label: "Find files", detail: "find <name> searches your home folder (fd, or find)" },
        { id: "recent", label: "Recent files", detail: "recent <name> searches recently opened files" },
        { id: "terminal", label: "Commands", detail: "t: or : runs in a terminal; run runs in the background" },
        { id: "web", label: "Web search", detail: "A shortcut and words, like ddg pop launcher" },
        { id: "scripts", label: "Scripts", detail: "Pop Launcher scripts in ~/.local/share/pop-launcher/scripts" },
        { id: "help", label: "Help", detail: "? lists the prefixes" }
    ]

    function pluginsNorm(src) {
        const out = {}
        const s = src && typeof src === "object" ? src : {}
        for (let i = 0; i < root.plugins.length; i++) {
            const id = root.plugins[i].id
            out[id] = s[id] !== false
        }
        return out
    }

    function pluginsFrom(text) {
        let parsed = null
        try {
            parsed = JSON.parse(String(text || "{}"))
        } catch (e) {
            parsed = null
        }
        return root.pluginsNorm(parsed)
    }

    function maxNorm(value) {
        const n = Math.round(Number(value))
        return Theme.searchMaxChoices.indexOf(n) >= 0 ? n : Theme.searchMaxDefault
    }

    function placeNorm(value) {
        return String(value || "") === "center" ? "center" : "top"
    }

    function lineNorm(value) {
        let text = String(value || "").replace(/[\r\n]/g, " ")
        if (text.length > Theme.searchCommandMax)
            text = text.substring(0, Theme.searchCommandMax)
        return text
    }

    // argv for a command line, [] when empty, null when it is not allowed.
    function argvFromLine(line) {
        return Config.commandArgv(line, Theme.searchCommandMax)
    }

    // Saved argv (JSON) back to a line for a text field.
    function lineFrom(stored) {
        let parsed = []
        try {
            parsed = JSON.parse(String(stored || "[]"))
        } catch (e) {
            parsed = []
        }
        if (!Array.isArray(parsed))
            return ""
        return parsed.map((t) => String(t || "")).filter((t) => t.length > 0).join(" ")
    }

    // Saved values, for the launcher.
    function builtIn() {
        return Config.searchBuiltIn !== false
    }

    function commandArgv() {
        return root.argvFromLine(root.lineFrom(Config.searchCommand)) || []
    }

    function pluginsValue() {
        return root.pluginsFrom(Config.searchPluginsJson)
    }

    function maxValue() {
        return root.maxNorm(Config.searchMaxResults)
    }

    // The terminal for "t:" commands and apps that need one.
    function terminalArgv() {
        const argv = root.argvFromLine(root.lineFrom(Config.searchTerminal))
        return argv && argv.length ? argv : [Theme.searchDefaultTerminal]
    }

    function webRulesValue() {
        return SearchLogic.webRulesFrom(Config.searchWebRulesJson)
    }

    // Text fields keep what was typed; signature() compares what would save.
    function normalize(src) {
        const s = src || {}
        const rules = []
        const list = Array.isArray(s.webRules) ? s.webRules : SearchLogic.defaultWebRules
        for (let i = 0; i < list.length && rules.length < SearchLogic.webRulesMax; i++) {
            const r = list[i] || {}
            // Rows being typed are kept as typed; only saving drops bad ones.
            rules.push({
                prefixes: Array.isArray(r.prefixes) ? r.prefixes.join(" ") : String(r.prefixes || "").substring(0, 100),
                name: String(r.name || "").substring(0, 40),
                url: String(r.url || "").substring(0, 300),
                raw: r.raw === true
            })
        }
        return {
            builtIn: s.builtIn !== false,
            command: root.lineNorm(s.command),
            plugins: root.pluginsNorm(s.plugins),
            maxResults: root.maxNorm(s.maxResults),
            place: root.placeNorm(s.place),
            dim: !!s.dim,
            terminal: root.lineNorm(s.terminal),
            history: s.history !== false,
            webRules: rules
        }
    }

    function cleanRules(rows) {
        const out = []
        for (let i = 0; i < rows.length; i++) {
            const r = SearchLogic.webRuleNorm(rows[i])
            if (r)
                out.push(r)
        }
        return out
    }

    function signature(src) {
        const v = root.normalize(src)
        v.command = v.command.trim()
        v.terminal = v.terminal.trim()
        v.webRules = root.cleanRules(v.webRules)
        return JSON.stringify(v)
    }

    function snapshot() {
        return root.normalize({
            builtIn: Config.searchBuiltIn,
            command: root.lineFrom(Config.searchCommand),
            plugins: root.pluginsValue(),
            maxResults: Config.searchMaxResults,
            place: Config.searchPlace,
            dim: Config.searchDim,
            terminal: root.lineFrom(Config.searchTerminal),
            history: Config.searchHistory,
            webRules: root.webRulesValue()
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function sameRules(a, b) {
        return JSON.stringify(a) === JSON.stringify(b)
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        const rules = root.cleanRules(clean.webRules)
        Config.saveFields(() => {
            Config.searchBuiltIn = clean.builtIn
            Config.searchCommand = JSON.stringify(root.argvFromLine(clean.command) || [])
            Config.searchPluginsJson = JSON.stringify(clean.plugins)
            Config.searchMaxResults = clean.maxResults
            Config.searchPlace = clean.place
            Config.searchDim = clean.dim
            Config.searchTerminal = JSON.stringify(root.argvFromLine(clean.terminal) || [])
            Config.searchHistory = clean.history
            // The defaults save as "", so later changes to them still apply.
            Config.searchWebRulesJson = root.sameRules(rules, root.cleanRules(SearchLogic.defaultWebRules)) ? "" : JSON.stringify(rules)
        })
    }

    // Why Apply is refused, or "" when it can save.
    function problem(src) {
        const v = root.normalize(src)
        if (root.argvFromLine(v.command) === null)
            return "The command has a character that is not allowed."
        if (root.argvFromLine(v.terminal) === null)
            return "The terminal command has a character that is not allowed."
        if (!v.builtIn && !(root.argvFromLine(v.command) || []).length)
            return "With the built-in launcher off, give a command to run instead."
        for (let i = 0; i < v.webRules.length; i++) {
            if (!SearchLogic.webRuleNorm(v.webRules[i]))
                return "Web shortcut " + (i + 1) + " needs a short lowercase shortcut, a name, and an address."
        }
        return ""
    }

    // False, with nothing saved, while problem() has a reason.
    function apply() {
        if (!root.editor.dirty)
            return true
        if (root.problem(root.editor.draft).length)
            return false
        root.editor.apply()
        return true
    }

    // Web rule rows on the settings page.
    function setRule(index, key, value) {
        const rows = root.editor.value.webRules.slice()
        if (index < 0 || index >= rows.length)
            return
        const row = Object.assign({}, rows[index])
        row[key] = value
        rows[index] = row
        root.editor.set("webRules", rows)
    }

    function addRule() {
        const rows = root.editor.value.webRules.slice()
        if (rows.length >= SearchLogic.webRulesMax)
            return
        rows.push({ prefixes: "", name: "", url: "", raw: false })
        root.editor.set("webRules", rows)
    }

    function removeRule(index) {
        const rows = root.editor.value.webRules.slice()
        if (index < 0 || index >= rows.length)
            return
        rows.splice(index, 1)
        root.editor.set("webRules", rows)
    }

    function setPlugin(id, on) {
        const next = Object.assign({}, root.editor.value.plugins)
        next[id] = !!on
        root.editor.set("plugins", next)
    }
}
