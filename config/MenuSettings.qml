pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Applications → Application Menu: the pill icon (a font symbol or an
// SVG/PNG image), its look, what a click opens, and the command run in
// place of the App Library when the built-in one is off. The command is split
// on spaces and never run through a shell.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function symbolValue(raw) {
        const text = Config.symbolClamp(raw)
        return text.length ? text : Theme.menuSymbolDefault
    }

    function modeNorm(value) {
        return String(value || "") === "image" ? "image" : "symbol"
    }

    // An absolute path to an .svg, .svgz, or .png file, or "".
    // Accepts a file:// URL from a file dialog.
    function imagePathNorm(raw) {
        let path = String(raw || "").trim()
        if (path.indexOf("file://") === 0) {
            try {
                path = decodeURIComponent(path.substring(7))
            } catch (e) {
                return ""
            }
        }
        if (!path.length || path.charAt(0) !== "/" || path.length > Theme.menuImagePathMax)
            return ""
        if (/[\r\n\0]/.test(path) || !/\.(svg|svgz|png)$/i.test(path))
            return ""
        return path
    }

    // A file:// URL for an Image, with each path part escaped.
    function imageUrl(path) {
        const clean = root.imagePathNorm(path)
        if (!clean.length)
            return ""
        return "file://" + clean.split("/").map(encodeURIComponent).join("/")
    }

    // Saved values, for the pill.
    function modeValue() {
        return root.modeNorm(Config.menuIconMode)
    }

    function imageValue() {
        return root.imagePathNorm(Config.menuImagePath)
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
        return Config.commandArgv(line, Theme.menuCommandMax)
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

    // What a click opens: "library" (the App Library, or the command when
    // the built-in library is off) or "search" (the launcher).
    function actionNorm(value) {
        return String(value || "") === "search" ? "search" : "library"
    }

    function actionValue() {
        return root.actionNorm(Config.menuAction)
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
            mode: root.modeNorm(src.mode),
            image: root.imagePathNorm(src.image),
            tint: !!src.tint,
            command: command,
            action: root.actionNorm(src.action)
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
            mode: Config.menuIconMode,
            image: Config.menuImagePath,
            tint: Config.menuImageTint,
            command: root.commandLine(Config.menuCommand),
            action: Config.menuAction
        })
    }

    function defaults() {
        return {
            symbol: Theme.menuSymbolDefault,
            font: "",
            px: 0,
            bold: false,
            italic: false,
            color: "",
            mode: "symbol",
            image: "",
            tint: false,
            command: "",
            action: "library"
        }
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
            Config.menuIconMode = clean.mode
            Config.menuImagePath = clean.image
            Config.menuImageTint = clean.tint
            Config.menuCommand = JSON.stringify(argv)
            Config.menuAction = clean.action
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

    // From a file dialog. A file that is not SVG or PNG is ignored.
    function setImage(url) {
        const path = root.imagePathNorm(url)
        if (!path.length)
            return false
        root.editor.edit({ image: path, mode: "image" })
        return true
    }

    function setFontPx(value) {
        const n = Math.round(Number(value))
        root.editor.set("px", Math.max(Theme.menuFontMin, Math.min(Theme.menuFontMax, n)))
    }
}
