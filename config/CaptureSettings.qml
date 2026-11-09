pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Tools → Capture: value helpers and the page draft. The saved values are
// not in bar-layout.json: they live in ~/.config/hypr/capture.conf, read by
// scripts/capture-screenshot and scripts/ocr-region. The file is
// key=value lines; the scripts parse it (never source it) and check every
// value again, so a hand edit cannot run code.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string configHome: {
        const xdg = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        return xdg.length ? xdg : root.home + "/.config"
    }
    readonly property string confPath: root.configHome + "/hypr/capture.conf"
    // In the bar's scripts/ (install-deps.sh links them into ~/.local/bin for keybinds).
    readonly property string screenshotScript: Quickshell.shellDir + "/scripts/capture-screenshot"
    readonly property string ocrScript: Quickshell.shellDir + "/scripts/ocr-region"
    readonly property string defaultFolder: root.home + "/Pictures"

    // Screenshot modes the script takes, for the Try buttons.
    readonly property var modes: [
        { id: "smart", label: "Smart", tip: "Drag a region, or click a window or the screen" },
        { id: "region", label: "Region", tip: "Drag any region" },
        { id: "windows", label: "Window", tip: "Pick a window or the screen from outlines" },
        { id: "fullscreen", label: "Screen", tip: "The focused monitor, at once" }
    ]

    // Names for common tesseract language codes. Others show their code.
    readonly property var langNames: ({
        eng: "English", deu: "German", fra: "French", spa: "Spanish", ita: "Italian",
        por: "Portuguese", nld: "Dutch", eus: "Basque", cat: "Catalan", pol: "Polish",
        rus: "Russian", ukr: "Ukrainian", tur: "Turkish", swe: "Swedish", nor: "Norwegian",
        dan: "Danish", fin: "Finnish", ces: "Czech", ell: "Greek", heb: "Hebrew",
        ara: "Arabic", hin: "Hindi", jpn: "Japanese", kor: "Korean",
        chi_sim: "Chinese (simplified)", chi_tra: "Chinese (traditional)"
    })

    // The editors capture-screenshot looks for when none is set, in its order.
    readonly property var editorChoices: ["tack", "satty", "swappy", "tensaku-edit"]

    // Last values read from capture.conf, already normalized. Set by the service.
    property var saved: root.normalize({})
    property bool loaded: false

    // What the scripts fall back to on this machine, found by the service:
    // installed editors (in editorChoices order) and the XDG Pictures folder.
    // A blank saved value shows as these, so the page shows what is used.
    property var editors: []
    property string picturesDir: "~/Pictures"

    signal saveRequested(var values)

    function langLabel(code) {
        const name = root.langNames[code]
        return name ? name : String(code)
    }

    // One line, no control characters. Not trimmed, so a field can be typed into.
    function clean(text) {
        return String(text || "").replace(/[\x00-\x1f\x7f]/g, "").substring(0, Theme.toolPathMax)
    }

    function folderOk(text) {
        const p = String(text || "").trim()
        return p.length === 0 || p.charAt(0) === "/" || p.indexOf("~/") === 0 || p === "~"
    }

    // One program name or path, no arguments. Matches the scripts' check.
    function programOk(text) {
        return /^([A-Za-z0-9._\/~+][A-Za-z0-9._\/~+-]*)?$/.test(String(text || "").trim())
    }

    function langOk(code) {
        return /^[A-Za-z0-9_]+$/.test(String(code || ""))
    }

    // "eng+deu" → ["eng", "deu"], bad parts dropped, eng when empty.
    function langList(text) {
        const out = []
        const parts = String(text || "").split("+")
        for (let i = 0; i < parts.length; i++) {
            const code = parts[i].trim()
            if (root.langOk(code) && out.indexOf(code) < 0)
                out.push(code)
        }
        return out.length ? out : ["eng"]
    }

    // Draft edit for one language chip. The last language cannot be removed.
    function toggleLang(code) {
        const list = root.langList(root.editor.value.ocrLang)
        const at = list.indexOf(code)
        if (at >= 0) {
            if (list.length === 1)
                return
            list.splice(at, 1)
        } else if (root.langOk(code)) {
            list.push(code)
        }
        root.editor.set("ocrLang", list.join("+"))
    }

    function expand(path) {
        const p = String(path || "").trim()
        if (p === "~")
            return root.home
        return p.indexOf("~/") === 0 ? root.home + p.substring(1) : p
    }

    function valid(n) {
        return root.folderOk(n.shotDir) && root.programOk(n.shotEditor) && root.programOk(n.ocrCommand)
    }

    // ── Draft ───────────────────────────────────────────────────────────
    function normalize(src) {
        const s = src || {}
        return {
            shotDir: root.clean(s.shotDir),
            shotEditor: root.clean(s.shotEditor),
            shotFreeze: s.shotFreeze !== false,
            shotNotify: s.shotNotify !== false,
            ocrLang: root.langList(s.ocrLang).join("+"),
            ocrFreeze: s.ocrFreeze !== false,
            ocrCopy: s.ocrCopy !== false,
            ocrNotify: s.ocrNotify !== false,
            ocrCommand: root.clean(s.ocrCommand)
        }
    }

    // Blank folder or editor → what the script would use.
    function withFallbacks(n) {
        if (!n.shotDir.trim().length)
            n.shotDir = root.picturesDir
        if (!n.shotEditor.trim().length && root.editors.length)
            n.shotEditor = root.editors[0]
        return n
    }

    function snapshot() {
        return root.withFallbacks(root.normalize(root.saved))
    }

    function defaults() {
        return root.withFallbacks(root.normalize({}))
    }

    function commit(obj) {
        root.saveRequested(root.normalize(obj))
    }

    // ── capture.conf ────────────────────────────────────────────────────
    function parse(text) {
        const v = {}
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (/^\s*(#|$)/.test(line) || line.indexOf("=") < 0)
                continue
            v[line.substring(0, line.indexOf("=")).replace(/ /g, "")] = line.substring(line.indexOf("=") + 1)
        }
        return root.normalize({
            shotDir: v.screenshot_dir,
            shotEditor: v.screenshot_editor,
            shotFreeze: v.screenshot_freeze !== "0",
            shotNotify: v.screenshot_notify !== "0",
            ocrLang: v.ocr_lang,
            ocrFreeze: v.ocr_freeze !== "0",
            ocrCopy: v.ocr_copy !== "0",
            ocrNotify: v.ocr_notify !== "0",
            ocrCommand: v.ocr_command
        })
    }

    // The whole file, or "" when a value would be refused.
    function confText(obj) {
        const n = root.normalize(obj)
        if (!root.valid(n))
            return ""
        const flag = (b) => b ? "1" : "0"
        return [
            "# Managed by Quickshell (Settings → Tools → Capture).",
            "# Read by the bar's scripts/capture-screenshot and scripts/ocr-region.",
            "screenshot_dir=" + n.shotDir.trim(),
            "screenshot_editor=" + n.shotEditor.trim(),
            "screenshot_freeze=" + flag(n.shotFreeze),
            "screenshot_notify=" + flag(n.shotNotify),
            "ocr_lang=" + n.ocrLang,
            "ocr_freeze=" + flag(n.ocrFreeze),
            "ocr_copy=" + flag(n.ocrCopy),
            "ocr_notify=" + flag(n.ocrNotify),
            "ocr_command=" + n.ocrCommand.trim(),
            ""
        ].join("\n")
    }

    // Capture keybinds from a Hyprland Lua file: hl.bind("KEYS", hl.dsp.exec_cmd("CMD"))
    // with an optional "--#Group# description" comment. Read-only.
    function parseBinds(text) {
        const out = []
        const lines = String(text || "").split("\n")
        const re = /^\s*hl\.bind\(\s*"([^"]+)"\s*,\s*hl\.dsp\.exec_cmd\(\s*"([^"]+)"\s*\)\s*\)\s*(?:--(?:#[^#]*#)?\s*(.*))?$/
        for (let i = 0; i < lines.length; i++) {
            const m = re.exec(lines[i])
            if (!m || !/(capture-screenshot|ocr-region)/.test(m[2]))
                continue
            out.push({
                keys: m[1],
                ocr: /ocr-region/.test(m[2]),
                what: (m[3] || "").trim() || m[2].replace(/^.*\//, "")
            })
        }
        return out
    }
}
