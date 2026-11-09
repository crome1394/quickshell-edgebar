pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.theme

// What the launcher shows for the text typed, Pop Launcher style. A
// prefix picks one mode (? help, = calculator, ~/ or / files, find,
// recent, t: or : terminal, run background); otherwise apps, open
// windows, scripts, web shortcuts, and arithmetic are searched together.
// An empty box lists the open windows, then the apps you use most.
// Each row: { key, kind, name, desc, icon, priority, score, complete, ... }.
Item {
    id: root

    property string query: ""
    property int cursor: 0
    // A row whose desktop actions are listed instead (Shift+Enter).
    property var contextRow: null

    readonly property var plugins: SearchSettings.pluginsValue()
    readonly property int maxRows: SearchSettings.maxValue()
    readonly property string home: SearchService.home
    readonly property var parsed: SearchLogic.parseQuery(root.query, root.plugins)
    readonly property var webRules: SearchSettings.webRulesValue()

    AppCatalog {
        id: catalog
    }

    readonly property var apps: catalog.apps

    Component.onCompleted: {
        try {
            Hyprland.refreshToplevels()
        } catch (e) {
        }
    }

    // Sources that run a program or read files, fed only in their mode.
    CalcSource {
        id: calc
        expr: {
            const p = root.parsed
            if (root.plugins.calc === false)
                return ""
            if (p.mode === "calc")
                return p.rest
            if (p.mode === "default" && SearchLogic.looksLikeMath(root.query))
                return root.query
            return ""
        }
    }

    FindSource {
        id: find
        home: root.home
        term: root.parsed.mode === "find" ? root.parsed.rest : ""
    }

    FilesSource {
        id: files
        readonly property var parts: root.parsed.mode === "files" ? SearchLogic.pathParts(root.query, root.home) : null
        dir: files.parts ? files.parts.dir : ""
        base: files.parts ? files.parts.base : ""
    }

    RecentSource {
        id: recent
        home: root.home
        active: root.parsed.mode === "recent"
    }

    ScriptsSource {
        id: scripts
        home: root.home
        active: root.plugins.scripts !== false
    }

    // The fallback symbol for a row with no icon.
    function glyphFor(row) {
        if (row.kind === "file" && row.isDir)
            return Theme.searchGlyphs.folder
        return Theme.searchGlyphs[row.kind] || Theme.searchGlyph
    }

    function iconPath(name) {
        return catalog.iconSource(name)
    }

    function appRow(app, score) {
        const category = root.categoryLabel(app.categories)
        const about = app.comment || app.genericName
        return {
            key: "app:" + app.id, kind: "app", app: app,
            name: app.name, desc: category.length && about.length ? category + " – " + about : (about || category),
            icon: root.iconPath(app.icon),
            priority: 0, score: score, complete: app.name
        }
    }

    // Freedesktop main categories as Pop names them.
    function categoryLabel(cats) {
        const names = { Network: "Internet", Development: "Development", Game: "Games", Graphics: "Graphics",
            AudioVideo: "Multimedia", Audio: "Multimedia", Video: "Multimedia", Office: "Office", Education: "Education",
            Science: "Science", Settings: "Settings", System: "System", Utility: "Utilities" }
        const list = cats || []
        for (let i = 0; i < list.length; i++) {
            if (names[list[i]])
                return names[list[i]]
        }
        return ""
    }

    function windowRows(text) {
        if (root.plugins.windows === false)
            return []
        const out = []
        const tops = Hyprland.toplevels ? Hyprland.toplevels.values : []
        for (let i = 0; i < tops.length; i++) {
            const t = tops[i]
            const ipc = t.lastIpcObject || {}
            const cls = String(ipc["class"] || "")
            const title = String(t.title || ipc.title || "")
            if (!title.length && !cls.length)
                continue
            const score = text.length ? SearchLogic.fieldsScore(text, [{ text: title, weight: 1 }, { text: cls, weight: 0.9, loose: true }]) : 50 - i * 0.01
            if (text.length && score <= 0)
                continue
            const entry = cls.length ? DesktopEntries.heuristicLookup(cls) : null
            const ws = t.workspace ? String(t.workspace.name || t.workspace.id || "") : ""
            out.push({
                key: "win:" + String(t.address), kind: "window", address: String(t.address),
                name: title || cls, desc: (entry ? String(entry.name) : cls) + (ws.length ? " – workspace " + ws : ""),
                icon: root.iconPath(entry ? entry.icon : cls),
                priority: 0, score: score + 5, complete: title
            })
        }
        return out
    }

    function scriptRows(text) {
        if (root.plugins.scripts === false || !text.length)
            return []
        const out = []
        const list = scripts.scripts
        for (let i = 0; i < list.length; i++) {
            const s = list[i]
            const score = SearchLogic.fieldsScore(text, [{ text: s.name, weight: 1 }, { text: (s.keywords || []).join(" "), weight: 0.8 },
                { text: s.description, weight: 0.4 }])
            if (score > 0)
                out.push({ key: "script:" + s.path, kind: "script", path: s.path, name: s.name, desc: s.description || "Script",
                    icon: root.iconPath(s.icon || "utilities-terminal"), priority: 0, score: score, complete: s.name })
        }
        return out
    }

    function calcRows() {
        if (calc.missing)
            return [{ key: "calc:missing", kind: "none", name: "The calculator needs qalc", desc: "Install it with: sudo pacman -S libqalculate",
                icon: root.iconPath("accessories-calculator"), priority: 3, score: 0, complete: "" }]
        if (!calc.current)
            return []
        return [{ key: "calc", kind: "calc", value: calc.result, name: calc.result, desc: calc.expr.trim() + "  ·  Enter copies the answer",
            icon: root.iconPath("accessories-calculator"), priority: 3, score: 100, complete: calc.result }]
    }

    function webRows(text) {
        if (root.plugins.web === false)
            return []
        return SearchLogic.webMatches(text, root.webRules).map((m) => ({
            key: "web:" + m.rule.name, kind: "web", url: m.url,
            name: m.rule.raw ? m.url : m.rule.name + ": " + m.terms, desc: m.url,
            icon: root.iconPath("web-browser"), priority: 2, score: 100, complete: ""
        }))
    }

    function fileRow(path, name, isDir, score) {
        return {
            key: "file:" + path, kind: "file", path: path, isDir: isDir,
            name: name + (isDir ? "/" : ""), desc: SearchLogic.tildePath(path, root.home),
            icon: root.iconPath(isDir ? "folder" : "text-x-generic"),
            priority: 0, score: score, complete: SearchLogic.tildePath(path, root.home) + (isDir ? "/" : "")
        }
    }

    function contextRows(row) {
        const out = []
        const app = row && row.app ? row.app : null
        if (!app)
            return out
        out.push({ key: "ctx:launch", kind: "app", app: app, name: "Open " + app.name, desc: "Start a new copy",
            icon: root.iconPath(app.icon), priority: 0, score: 0, complete: "" })
        const actions = app.entry.actions || []
        for (let i = 0; i < actions.length; i++) {
            const a = actions[i]
            out.push({ key: "ctx:" + i, kind: "action", app: app, action: a, name: String(a.name || ""), desc: app.name,
                icon: root.iconPath(a.icon || app.icon), priority: 0, score: 0, complete: "" })
        }
        return out
    }

    // The rows to show, best first.
    // Everything build() reads is tracked by this binding, so it reruns as
    // each source answers.
    readonly property var results: root.build(root.query, root.parsed, root.contextRow)

    function build(text, p, contextRow) {
        if (contextRow)
            return root.contextRows(contextRow)
        const rest = String(p.rest || "")
        switch (p.mode) {
        case "help":
            return SearchLogic.helpRows(root.plugins).map((h) => ({ key: "help:" + h.prefix, kind: "help", name: h.prefix.trim(), desc: h.text,
                icon: root.iconPath("help-about"), priority: 0, score: 0, complete: h.prefix }))
        case "calc":
            return root.calcRows()
        case "files":
            return files.entries.map((e, i) => root.fileRow(e.path, e.name, e.isDir, 100 - i))
        case "find":
            if (!rest.trim().length)
                return [{ key: "find:hint", kind: "none", name: "Type a file name", desc: "Searches your home folder", icon: root.iconPath("system-search"),
                    priority: 0, score: 0, complete: "" }]
            return find.paths.map((path, i) => root.fileRow(path, path.substring(path.lastIndexOf("/") + 1), false, 100 - i))
        case "recent": {
            const term = rest.trim()
            const list = recent.files.filter((f) => !term.length || SearchLogic.fieldsScore(term, [{ text: f.name, weight: 1 }]) > 0)
            return list.slice(0, Theme.searchFilesMax).map((f, i) => root.fileRow(f.path, f.name, false, 100 - i))
        }
        case "terminal":
        case "background": {
            const cmd = rest.trim()
            const inTerm = p.mode === "terminal"
            return [{ key: "run", kind: "run", command: cmd, terminal: inTerm,
                name: cmd.length ? cmd : (inTerm ? "Type a command to run in a terminal" : "Type a command to run in the background"),
                desc: inTerm ? "Runs in " + SearchSettings.terminalArgv()[0] : "Runs in the background",
                icon: root.iconPath("utilities-terminal"), priority: 0, score: 0, complete: "" }]
        }
        }
        const q = text.trim()
        const now = Date.now()
        const hist = SearchService.history
        let rows = []
        if (!q.length) {
            rows = root.windowRows("")
            // Then the apps you use most, so an empty box is still useful.
            if (root.plugins.apps !== false) {
                const used = root.apps.map((a) => ({ a: a, b: SearchLogic.historyBonus(hist["app:" + a.id], now) }))
                    .filter((x) => x.b > 0).sort((x, y) => y.b - x.b)
                for (let i = 0; i < used.length && rows.length < root.maxRows; i++)
                    rows.push(root.appRow(used[i].a, used[i].b))
            }
            return rows.slice(0, root.maxRows)
        }
        rows = rows.concat(root.calcRows(), root.webRows(text), root.windowRows(q), root.scriptRows(q))
        if (root.plugins.apps !== false) {
            for (let i = 0; i < root.apps.length; i++) {
                const a = root.apps[i]
                const s = SearchLogic.appScore(q, a)
                if (s > 0)
                    rows.push(root.appRow(a, s + SearchLogic.historyBonus(hist["app:" + a.id], now)))
            }
        }
        return SearchLogic.sortResults(rows).slice(0, root.maxRows)
    }

    // Results change as you type; keep the highlight on the first row.
    onResultsChanged: {
        if (root.cursor >= root.results.length)
            root.cursor = Math.max(0, root.results.length - 1)
    }
    onQueryChanged: {
        root.cursor = 0
        root.contextRow = null
    }

    readonly property var current: root.results.length ? root.results[Math.min(root.cursor, root.results.length - 1)] : null

    function move(step) {
        const n = root.results.length
        if (!n)
            return
        root.cursor = (root.cursor + step + n) % n
    }

    function moveTo(index) {
        if (index >= 0 && index < root.results.length)
            root.cursor = index
    }

    // Runs a row. Returns true when the launcher should close.
    function activate(row) {
        if (!row)
            return false
        switch (row.kind) {
        case "app":
            SearchService.launchApp(row.app.entry)
            return true
        case "action":
            SearchService.launchAction(row.app.entry, row.action)
            return true
        case "window":
            SearchService.focusWindow(row.address)
            return true
        case "calc":
            SearchService.copyText(String(row.value).replace(/\u2212/g, "-"))
            return true
        case "web":
            SearchService.openUrl(row.url)
            return true
        case "file":
            SearchService.openPath(row.path)
            return true
        case "script":
            SearchService.runScript(row.path)
            return true
        case "run":
            if (!row.command.length)
                return false
            SearchService.runCommand(row.command, row.terminal)
            return true
        case "help":
            root.fill(row.complete)
            return false
        }
        return false
    }

    // Tab: the text a row completes to (a path, a name, a prefix).
    signal fillRequested(string text)

    function fill(text) {
        const t = String(text || "")
        if (t.length)
            root.fillRequested(t)
    }

    function complete() {
        if (root.current)
            root.fill(root.current.complete)
    }

    // Shift+Enter: an app's actions; again (or Esc) goes back.
    function toggleContext() {
        if (root.contextRow) {
            root.contextRow = null
            return
        }
        const row = root.current
        if (row && row.kind === "app") {
            root.contextRow = row
            root.cursor = 0
        }
    }

    function nth(index) {
        return index >= 0 && index < root.results.length ? root.results[index] : null
    }
}
