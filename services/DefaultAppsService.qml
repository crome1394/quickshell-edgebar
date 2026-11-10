pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.defaultapps
import qs.theme

// Default apps (Settings → Applications → Default Apps).
// Reads ~/.config/mimeapps.list, the system's mimeapps.list files, the
// mimeinfo.cache files (which apps say they open which types), and the
// type aliases and parents from shared-mime-info. Writes only
// ~/.config/mimeapps.list, atomically, after copying it to
// mimeapps.list.bak. Nothing is read until a page calls retain(), and
// every file is let go after release(). The only process is xdg-mime,
// once per Test a file click.
Singleton {
    id: root

    property int users: 0
    readonly property bool active: root.users > 0

    function retain() {
        root.users += 1
    }

    function release() {
        root.users = Math.max(0, root.users - 1)
    }

    // ── Where the files are (XDG base directories) ──────────────────────
    function envList(name, fallback) {
        const raw = String(Quickshell.env(name) || "")
        const list = (raw.length ? raw : fallback).split(":").filter((p) => p.length > 0 && p.charAt(0) === "/")
        return list
    }

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string configHome: {
        const v = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        return v.charAt(0) === "/" ? v : root.home + "/.config"
    }
    readonly property string dataHome: {
        const v = String(Quickshell.env("XDG_DATA_HOME") || "")
        return v.charAt(0) === "/" ? v : root.home + "/.local/share"
    }
    readonly property var configDirs: root.envList("XDG_CONFIG_DIRS", "/etc/xdg")
    readonly property var dataDirs: root.envList("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    readonly property var desktops: String(Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase().split(":")
        .filter((d) => /^[a-z0-9_-]+$/.test(d))

    // Where each type's description file lives, for MimeComment.
    readonly property var mimeDirs: [root.dataHome].concat(root.dataDirs).map((d) => d + "/mime")

    readonly property string listPath: root.configHome + "/mimeapps.list"
    readonly property string backupPath: root.listPath + ".bak"

    // Every file read besides ours, highest priority first within a kind.
    //   override  ~/.config/<desktop>-mimeapps.list (wins over ours)
    //   system    the other mimeapps.list files
    //   cache     mimeinfo.cache, the user's folder first
    //   aliases / parents / types  shared-mime-info
    readonly property var reads: {
        const out = []
        for (const d of root.desktops)
            out.push({ kind: "override", path: root.configHome + "/" + d + "-mimeapps.list" })
        for (const dir of root.configDirs) {
            for (const d of root.desktops)
                out.push({ kind: "system", path: dir + "/" + d + "-mimeapps.list" })
            out.push({ kind: "system", path: dir + "/mimeapps.list" })
        }
        out.push({ kind: "system", path: root.dataHome + "/applications/mimeapps.list" })
        for (const dir of root.dataDirs) {
            for (const d of root.desktops)
                out.push({ kind: "system", path: dir + "/applications/" + d + "-mimeapps.list" })
            out.push({ kind: "system", path: dir + "/applications/mimeapps.list" })
        }
        for (const dir of [root.dataHome].concat(root.dataDirs)) {
            out.push({ kind: "cache", path: dir + "/applications/mimeinfo.cache" })
            out.push({ kind: "aliases", path: dir + "/mime/aliases" })
            out.push({ kind: "parents", path: dir + "/mime/subclasses" })
            out.push({ kind: "types", path: dir + "/mime/types" })
        }
        return out
    }

    // ── What was read ───────────────────────────────────────────────────
    property var texts: ({})
    property int readCount: 0
    property bool userLoaded: false
    property bool userReadable: true
    property string userText: ""
    property string error: ""
    property bool saving: false

    readonly property bool ready: root.active && root.userLoaded && root.readCount >= root.reads.length

    function gotText(index, text) {
        const next = Object.assign({}, root.texts)
        if (next[index] === undefined)
            root.readCount += 1
        next[index] = String(text || "")
        root.texts = next
    }

    function textsOf(kind) {
        const out = []
        for (let i = 0; i < root.reads.length; i++) {
            if (root.reads[i].kind === kind && root.texts[i] !== undefined && root.texts[i].length)
                out.push(root.texts[i])
        }
        return out
    }

    readonly property var systemStates: root.textsOf("override").concat(root.textsOf("system")).map((t) => DefaultAppsLogic.parse(t))
    readonly property bool overrideActive: root.textsOf("override").some((t) => {
        const s = DefaultAppsLogic.parse(t)
        return Object.keys(s.defaults).length > 0
    })
    readonly property var cache: DefaultAppsLogic.mergeCaches(root.textsOf("cache").map((t) => DefaultAppsLogic.parseCache(t)))
    readonly property var aliases: DefaultAppsLogic.parseAliases(root.textsOf("aliases").join("\n"))
    readonly property var parents: DefaultAppsLogic.parseParents(root.textsOf("parents").join("\n"))
    // Every type shared-mime-info knows, for All file types.
    readonly property var knownTypes: root.textsOf("types").join("\n").split("\n").map((t) => t.trim()).filter((t) => t.length > 0)

    // ── Apps ────────────────────────────────────────────────────────────
    // Reading the list starts Quickshell's scan; byId() finds nothing before.
    readonly property int appCount: DesktopEntries.applications ? DesktopEntries.applications.values.length : 0

    function entry(id) {
        const bare = String(id || "").replace(/\.desktop$/, "")
        return bare.length ? DesktopEntries.byId(bare) : null
    }

    function installed(id) {
        return root.appCount >= 0 && root.entry(id) !== null
    }

    function appName(id) {
        const e = root.entry(id)
        return e ? String(e.name || "") : ""
    }

    function appIcon(id) {
        const e = root.entry(id)
        return e ? String(e.icon || "") : ""
    }

    // Apps in the menu, for "Show all apps".
    function allApps() {
        const values = root.appCount >= 0 && DesktopEntries.applications ? DesktopEntries.applications.values : []
        const out = []
        for (let i = 0; i < values.length; i++) {
            const e = values[i]
            if (e && !e.noDisplay)
                out.push(String(e.id) + ".desktop")
        }
        out.sort((a, b) => root.appName(a).localeCompare(root.appName(b)))
        return out
    }

    // Everything the logic needs, for the draft being edited.
    readonly property var ctx: ({
        state: DefaultAppsSettings.editor.value,
        system: root.systemStates,
        cache: root.cache,
        aliases: root.aliases,
        parents: root.parents,
        appCount: root.appCount,
        installed: root.installed,
        nameOf: root.appName
    })

    // Problems in the draft, as cards (DefaultAppsLogic.problemGroups).
    readonly property var problems: root.ready
        ? DefaultAppsLogic.problemGroups(DefaultAppsLogic.problems(root.ctx, DefaultAppsSettings.kept()), root.ctx) : []

    // ── Test a file ─────────────────────────────────────────────────────
    // { path, type, error }; type is "" until xdg-mime answers.
    property var test: ({ path: "", type: "", error: "" })

    function testFile(raw) {
        let path = String(raw || "").trim()
        if (path.indexOf("~/") === 0)
            path = root.home + path.slice(1)
        if (!path.length)
            return
        if (path.charAt(0) !== "/" || path.length > 4096 || /[\n\r\0]/.test(path)) {
            root.test = { path: path, type: "", error: "Give a full path, starting with / or ~/." }
            return
        }
        if (typeProbe.running)
            return
        root.test = { path: path, type: "", error: "" }
        // The path is one argument, never shell text.
        root.probeStarted = false
        typeProbe.command = ["xdg-mime", "query", "filetype", path]
        typeProbe.running = true
        probeWatch.restart()
    }

    property bool probeStarted: false

    // A missing program never starts and never exits.
    Timer {
        id: probeWatch
        interval: Theme.defaultAppsProbeStartMs
        onTriggered: {
            if (!root.probeStarted && root.test.type === "" && root.test.error === "")
                root.test = { path: root.test.path, type: "", error: "xdg-mime is not installed (it comes with xdg-utils)." }
        }
    }

    function clearTest() {
        root.test = { path: "", type: "", error: "" }
    }

    Process {
        id: typeProbe
        stdout: StdioCollector {
            id: probeOut
            waitForEnd: true
        }
        onStarted: root.probeStarted = true
        onExited: (code) => {
            const type = String(probeOut.text || "").trim().split(/[;\s]/)[0]
            const ok = code === 0 && DefaultAppsLogic.validType(type)
            root.test = {
                path: root.test.path,
                type: ok ? type : "",
                error: ok ? "" : "Could not tell what kind of file that is. Check the path."
            }
        }
    }

    // ── Writing ─────────────────────────────────────────────────────────
    function readUser(text) {
        root.userText = String(text || "")
        root.userLoaded = true
        DefaultAppsSettings.saved = DefaultAppsLogic.parse(root.userText)
    }

    function write(next) {
        if (!root.userLoaded || !root.userReadable) {
            root.error = "Could not read " + root.listPath + ", so it was not changed."
            return
        }
        const text = root.userText
        const out = DefaultAppsLogic.rewrite(text, DefaultAppsSettings.saved, next)
        if (out === text)
            return
        root.error = ""
        root.saving = true
        if (text.length)
            backupFile.setText(text)
        userFile.setText(out)
    }

    Connections {
        target: DefaultAppsSettings
        function onWriteRequested(state) {
            root.write(state)
        }
    }

    onActiveChanged: {
        if (root.active)
            return
        root.texts = ({})
        root.readCount = 0
        root.userLoaded = false
        root.userText = ""
        root.error = ""
    }

    FileView {
        id: userFile
        path: root.active ? root.listPath : ""
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: userFile.reload()
        onLoaded: {
            root.userReadable = true
            root.readUser(userFile.text())
        }
        onLoadFailed: (error) => {
            // No file yet is fine: the first Apply makes one.
            root.userReadable = error === FileViewError.FileNotFound
            root.readUser("")
            if (!root.userReadable)
                root.error = "Could not read " + root.listPath + "."
        }
        onSaved: {
            root.saving = false
            root.readUser(userFile.text())
        }
        onSaveFailed: {
            root.saving = false
            root.error = "Could not save " + root.listPath + "."
            userFile.reload()
        }
    }

    FileView {
        id: backupFile
        path: root.active ? root.backupPath : ""
        preload: false
        atomicWrites: true
        printErrors: false
    }

    Instantiator {
        active: root.active
        model: root.reads
        delegate: FileView {
            id: view
            required property var modelData
            required property int index
            path: String(view.modelData.path)
            watchChanges: true
            printErrors: false
            onFileChanged: view.reload()
            onLoaded: root.gotText(view.index, view.text())
            onLoadFailed: root.gotText(view.index, "")
        }
    }
}
