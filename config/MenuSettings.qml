pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Applications → Application Menu: the pill symbol, its font, and the
// command it runs. The command is split on spaces and never run through
// a shell.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function symbolValue(raw) {
        const text = Config.symbolClamp(raw)
        return text.length ? text : Theme.menuSymbolDefault
    }

    function pxNorm(value) {
        const n = Math.round(Number(value))
        if (n >= Theme.menuFontMin && n <= Theme.menuFontMax)
            return n
        return 0
    }

    function pxValue() {
        const n = root.pxNorm(Config.menuFontPx)
        return n >= Theme.menuFontMin ? n : Theme.iconPx
    }

    // argv for a command line, [] when empty, null when it is not allowed.
    function argvFromLine(line) {
        const raw = String(line || "").trim()
        if (!raw.length)
            return []
        if (raw.length > Theme.menuCommandMax)
            return null
        const parts = raw.split(/\s+/)
        if (!parts.length || !Config.programOk(parts[0]))
            return null
        const command = [String(parts[0]).trim()]
        for (let i = 1; i < parts.length && command.length < 13; i++) {
            if (!Config.argOk(parts[i]))
                return null
            command.push(parts[i])
        }
        return command
    }

    function commandLine(stored) {
        let parsed = []
        try {
            parsed = JSON.parse(String(stored || "[]"))
        } catch (e) {
            parsed = []
        }
        if (!parsed || parsed.length === undefined)
            return ""
        const parts = []
        for (let i = 0; i < parsed.length; i++) {
            const token = String(parsed[i] || "")
            if (token.length)
                parts.push(token)
        }
        return parts.join(" ")
    }

    // The saved command as argv, for the pill.
    function savedArgv() {
        return root.argvFromLine(root.commandLine(Config.menuCommand))
    }

    // Text fields keep what was typed; signature() compares what would save.
    function normalize(src) {
        let command = String(src.command || "").replace(/[\r\n]/g, " ")
        if (command.length > Theme.menuCommandMax)
            command = command.substring(0, Theme.menuCommandMax)
        return {
            symbol: Config.symbolClamp(src.symbol),
            font: Config.fontClamp(src.font),
            px: root.pxNorm(src.px),
            bold: !!src.bold,
            italic: !!src.italic,
            color: Config.colorNorm(src.color),
            command: command
        }
    }

    function signature(src) {
        const v = root.normalize(src)
        v.symbol = root.symbolValue(v.symbol)
        v.command = v.command.trim()
        return JSON.stringify(v)
    }

    function snapshot() {
        return root.normalize({
            symbol: root.symbolValue(Config.menuSymbol),
            font: Config.menuFont,
            px: Config.menuFontPx,
            bold: Config.menuBold,
            italic: Config.menuItalic,
            color: Config.menuColor,
            command: root.commandLine(Config.menuCommand)
        })
    }

    function defaults() {
        return { symbol: Theme.menuSymbolDefault, font: "", px: 0, bold: false, italic: false, color: "", command: "" }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        const argv = root.argvFromLine(clean.command) || []
        Config.saveFields(() => {
            Config.menuSymbol = root.symbolValue(clean.symbol)
            Config.menuFont = clean.font
            Config.menuFontPx = clean.px
            Config.menuBold = clean.bold
            Config.menuItalic = clean.italic
            Config.menuColor = clean.color
            Config.menuCommand = JSON.stringify(argv)
        })
    }

    // False, with nothing saved, when the command is not allowed.
    function apply() {
        if (!root.editor.dirty)
            return true
        if (root.argvFromLine(root.editor.draft.command) === null)
            return false
        root.editor.apply()
        return true
    }

    function setFontPx(value) {
        const n = Math.round(Number(value))
        root.editor.set("px", Math.max(Theme.menuFontMin, Math.min(Theme.menuFontMax, n)))
    }
}
