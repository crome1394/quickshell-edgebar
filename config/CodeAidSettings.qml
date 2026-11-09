pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Tools → Code Aid: the snippet picker (CodeAidService). Built in, or a
// command of your own run instead; the snippet folder; and whether it
// closes after copying and lists recent snippets first. Commands are
// split on spaces and never run through a shell.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property string home: String(Quickshell.env("HOME") || "")

    function lineNorm(value) {
        let text = String(value || "").replace(/[\r\n]/g, " ")
        if (text.length > Theme.searchCommandMax)
            text = text.substring(0, Theme.searchCommandMax)
        return text
    }

    function argvFromLine(line) {
        return Config.commandArgv(line, Theme.searchCommandMax)
    }

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

    // An absolute folder, with ~ expanded, or "" when not allowed.
    function dirNorm(value) {
        let d = String(value || "").trim()
        if (d === "~" || d.indexOf("~/") === 0)
            d = root.home + d.substring(1)
        d = d.replace(/\/+$/, "")
        return /^\/[^\u0000-\u001f]{0,400}$/.test(d) ? d : ""
    }

    // Saved values, for the picker.
    function builtIn() {
        return Config.codeAidBuiltIn !== false
    }

    function commandArgv() {
        return root.argvFromLine(root.lineFrom(Config.codeAidCommand)) || []
    }

    function dirValue() {
        return root.dirNorm(Config.codeAidDir) || root.dirNorm(Theme.codeAidDefaultDir)
    }

    function closeOnCopy() {
        return Config.codeAidCloseOnCopy !== false
    }

    function recentFirst() {
        return Config.codeAidRecent !== false
    }

    function normalize(src) {
        const s = src || {}
        return {
            builtIn: s.builtIn !== false,
            command: root.lineNorm(s.command),
            dir: String(s.dir || "").replace(/[\r\n]/g, "").substring(0, 400),
            closeOnCopy: s.closeOnCopy !== false,
            recent: s.recent !== false
        }
    }

    function signature(src) {
        const v = root.normalize(src)
        v.command = v.command.trim()
        v.dir = v.dir.trim()
        return JSON.stringify(v)
    }

    function snapshot() {
        return root.normalize({
            builtIn: Config.codeAidBuiltIn,
            command: root.lineFrom(Config.codeAidCommand),
            dir: Config.codeAidDir,
            closeOnCopy: Config.codeAidCloseOnCopy,
            recent: Config.codeAidRecent
        })
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.codeAidBuiltIn = clean.builtIn
            Config.codeAidCommand = JSON.stringify(root.argvFromLine(clean.command) || [])
            Config.codeAidDir = clean.dir.trim()
            Config.codeAidCloseOnCopy = clean.closeOnCopy
            Config.codeAidRecent = clean.recent
        })
    }

    // Why Apply is refused, or "" when it can save.
    function problem(src) {
        const v = root.normalize(src)
        if (root.argvFromLine(v.command) === null)
            return "The command has a character that is not allowed."
        if (!v.builtIn && !(root.argvFromLine(v.command) || []).length)
            return "With the built-in Code Aid off, give a command to run instead."
        if (v.dir.trim().length && !root.dirNorm(v.dir).length)
            return "The snippet folder must be a full path, like ~/snippets."
        return ""
    }

    function apply() {
        if (!root.editor.dirty)
            return true
        if (root.problem(root.editor.draft).length)
            return false
        root.editor.apply()
        return true
    }
}
