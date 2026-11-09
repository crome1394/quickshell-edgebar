.pragma library

// Code Aid's snippet rules, with no UI and no I/O, so tests can run them
// directly. A snippet file is the rofi-code-aid format:
//   line 1   the label, "language · name"
//   ---      a line by itself
//   the rest the code
// The code may mark blanks to fill before copying: {{name}}, or
// {{name:default}}. The same name (case counts) fills every place it
// appears. {{clipboard}} fills with what was last copied.

const nameMax = 80
const bodyMax = 20000

// Languages in the order rofi-code-aid listed them, and their names.
const languageOrder = ["bash", "c / c++", "rust", "java", "python", "javascript", "typescript", "css", "qml", "html",
    "lua", "sql", "git", "regex", "docker", "markdown"]
const languageNames = {
    "bash": "Bash", "c / c++": "C / C++", "rust": "Rust", "java": "Java", "python": "Python",
    "javascript": "JavaScript", "typescript": "TypeScript", "css": "CSS", "qml": "QML", "html": "HTML",
    "lua": "Lua", "sql": "SQL", "git": "Git", "regex": "Regex", "docker": "Docker", "markdown": "Markdown"
}

function languageName(lang) {
    const key = String(lang || "")
    return languageNames[key] || (key.length ? key.charAt(0).toUpperCase() + key.substring(1) : "Other")
}

function languageRank(lang) {
    const i = languageOrder.indexOf(String(lang || ""))
    return i < 0 ? languageOrder.length : i
}

function clean(text, max) {
    return String(text || "").replace(/[\u0000-\u001f]/g, " ").replace(/\s+/g, " ").trim().substring(0, max)
}

// "language · name" → { language, name }. A label with no " · " is "other".
function splitLabel(label) {
    const text = clean(label, nameMax * 2)
    const at = text.indexOf(" · ")
    if (at < 0)
        return { language: "other", name: text }
    return { language: text.substring(0, at).trim().toLowerCase(), name: text.substring(at + 3).trim() }
}

function makeLabel(language, name) {
    const lang = clean(language, 30).toLowerCase() || "other"
    return lang + " · " + clean(name, nameMax)
}

// A file's text → { label, language, name, body }, or null when it is not
// a snippet. The code keeps its lines as written, without the newline
// that ends the file, so pasting does not add an empty line (or run a
// one-line command in a terminal).
function parse(text) {
    const raw = String(text || "").replace(/\r\n/g, "\n")
    const first = raw.indexOf("\n")
    if (first < 0)
        return null
    const label = clean(raw.substring(0, first), nameMax * 2)
    if (!label.length || label === "---")
        return null
    const rest = raw.substring(first + 1)
    let body
    if (rest.indexOf("---\n") === 0)
        body = rest.substring(4)
    else if (rest === "---")
        body = ""
    else {
        const sep = rest.indexOf("\n---\n")
        if (sep < 0)
            return null
        body = rest.substring(sep + 5)
    }
    body = body.replace(/\n$/, "").substring(0, bodyMax)
    const parts = splitLabel(label)
    return { label: label, language: parts.language, name: parts.name, body: body }
}

// The file text for a snippet (ends in a newline, as rofi-code-aid writes).
function serialize(label, body) {
    return clean(label, nameMax * 2) + "\n---\n" + String(body || "").replace(/\r\n/g, "\n").replace(/\n$/, "") + "\n"
}

// A file name for a label: lowercase words joined by dashes.
function fileName(label) {
    const parts = splitLabel(label)
    const lang = parts.language === "c / c++" ? "c" : parts.language
    const slug = (lang + " " + parts.name).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
    return (slug || "snippet").substring(0, 60)
}

// The file names this tool writes and deletes.
function fileNameOk(name) {
    return /^[a-z0-9][a-z0-9-]{0,80}$/.test(String(name || ""))
}

// Blanks in order, each once: [{ name, def }].
const fieldPattern = /\{\{\s*([A-Za-z][A-Za-z0-9_ ]{0,30}?)\s*(?::([^{}\n]*))?\}\}/g

function fields(body) {
    const out = []
    const seen = {}
    const text = String(body || "")
    fieldPattern.lastIndex = 0
    let m
    while ((m = fieldPattern.exec(text)) !== null) {
        const name = m[1]
        if (seen[name])
            continue
        seen[name] = true
        out.push({ name: name, def: m[2] !== undefined ? m[2] : "", clipboard: name.toLowerCase() === "clipboard" })
    }
    return out
}

// The code with each blank filled: what was typed, else its default,
// else its name. {{clipboard}} takes the clipboard text.
function fill(body, values, clipboard) {
    const vals = values || {}
    return String(body || "").replace(fieldPattern, (whole, name, def) => {
        if (name.toLowerCase() === "clipboard")
            return String(clipboard || "").replace(/\n$/, "")
        const typed = vals[name]
        if (typed !== undefined && String(typed).length)
            return String(typed)
        return def !== undefined && def.length ? def : name
    })
}

// How well a query matches a snippet: name first, then language, then code.
function score(query, snip) {
    const words = String(query || "").toLowerCase().trim().split(/\s+/).filter((w) => w.length)
    if (!words.length)
        return 1
    const name = String(snip.name || "").toLowerCase()
    const lang = (String(snip.language || "") + " " + languageName(snip.language)).toLowerCase()
    const body = String(snip.body || "").toLowerCase()
    let total = 0
    for (let i = 0; i < words.length; i++) {
        const w = words[i]
        let s = 0
        if (name.indexOf(w) === 0)
            s = 100
        else if (new RegExp("\\b" + w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).test(name))
            s = 80
        else if (name.indexOf(w) > 0)
            s = 60
        else if (lang.indexOf(w) >= 0)
            s = 50
        else if (body.indexOf(w) >= 0)
            s = 20
        if (!s)
            return 0
        total += s
    }
    return total / words.length
}

// Sort snippets into languages, each sorted by name:
// [{ language, title, snips: [...] }].
function group(snips) {
    const map = {}
    for (let i = 0; i < snips.length; i++) {
        const s = snips[i]
        if (!map[s.language])
            map[s.language] = []
        map[s.language].push(s)
    }
    const langs = Object.keys(map).sort((a, b) => languageRank(a) - languageRank(b) || a.localeCompare(b))
    return langs.map((l) => ({ language: l, title: languageName(l), snips: map[l].sort((a, b) => a.name.localeCompare(b.name)) }))
}
