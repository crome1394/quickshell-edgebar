.pragma library

// The launcher's search rules, with no UI and no I/O, so tests can run
// them directly: how a query picks a mode (Pop Launcher's prefixes), how
// well a result matches, launch history, web search rules, and parsing
// script headers and the recent-files list.

// Lowercase with accents folded, for matching.
function fold(text) {
    return String(text || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
}

// How well one query word matches one text, both folded: 0 for no match,
// up to 100 for the whole text. loose also allows letters in order with
// gaps ("ffx" for Firefox); that is only used on names, since in long
// descriptions nearly anything matches that way.
function wordScore(q, t, loose) {
    if (!q.length || !t.length)
        return 0
    if (t === q)
        return 100
    if (t.indexOf(q) === 0)
        return 90 - Math.min(20, (t.length - q.length) * 0.5)
    const words = t.split(/[\s\-_.\/]+/).filter((w) => w.length > 0)
    for (let i = 0; i < words.length; i++) {
        if (words[i].indexOf(q) === 0)
            return 75 - Math.min(10, i)
    }
    const at = t.indexOf(q)
    if (at >= 0)
        return 60 - Math.min(20, at)
    if (q.length >= 2) {
        const initials = words.map((w) => w.charAt(0)).join("")
        if (initials.indexOf(q) === 0)
            return 55
    }
    if (!loose)
        return 0
    // Letters in order with gaps: a weak match, weaker with more gaps.
    let from = 0
    let last = -1
    let gaps = 0
    for (let i = 0; i < q.length; i++) {
        const k = t.indexOf(q.charAt(i), from)
        if (k < 0)
            return 0
        if (last >= 0)
            gaps += k - last - 1
        last = k
        from = k + 1
    }
    return Math.max(1, 40 - gaps * 2)
}

// Score a query against weighted fields: [{ text, weight, loose }].
// Every query word must match some field; the score is the average of
// each word's best weighted match. 0 means no match.
function fieldsScore(query, fields) {
    const words = fold(query).trim().split(/\s+/).filter((w) => w.length > 0)
    if (!words.length)
        return 0
    const folded = fields.map((f) => ({ text: fold(f.text), weight: Number(f.weight) || 0, loose: f.loose === true }))
    let total = 0
    for (let i = 0; i < words.length; i++) {
        let best = 0
        for (let j = 0; j < folded.length; j++) {
            const s = wordScore(words[i], folded[j].text, folded[j].loose) * folded[j].weight
            if (s > best)
                best = s
        }
        if (best <= 0)
            return 0
        total += best
    }
    return total / words.length
}

// An application: name first, then generic name, keywords, the program,
// and the comment last.
function appScore(query, app) {
    const fields = [
        { text: app.name, weight: 1, loose: true },
        { text: app.genericName, weight: 0.8 },
        { text: (app.keywords || []).join(" "), weight: 0.7 },
        { text: app.program, weight: 0.6 },
        { text: app.comment, weight: 0.4 }
    ]
    return fieldsScore(query, fields)
}

// Launch history: { n: launches, t: last launch in ms }. Recent and
// frequent launches rank higher; the bonus fades over weeks.
function historyBonus(record, nowMs) {
    if (!record || !(Number(record.n) > 0))
        return 0
    const days = Math.max(0, (Number(nowMs) - Number(record.t || 0)) / 86400000)
    const bonus = Math.log2(1 + Number(record.n)) * 8 / (1 + days / 7)
    return Math.min(30, bonus)
}

function historyAdd(history, key, nowMs) {
    const next = Object.assign({}, history || {})
    const old = next[key] || { n: 0, t: 0 }
    next[key] = { n: Math.min(100000, Number(old.n || 0) + 1), t: Number(nowMs) }
    return next
}

// Keep the store small: drop the oldest beyond max entries.
function historyTrim(history, max) {
    const keys = Object.keys(history || {})
    if (keys.length <= max)
        return history
    keys.sort((a, b) => Number(history[b].t || 0) - Number(history[a].t || 0))
    const out = {}
    for (let i = 0; i < max; i++)
        out[keys[i]] = history[keys[i]]
    return out
}

function historyNorm(src) {
    const out = {}
    if (!src || typeof src !== "object" || Array.isArray(src))
        return out
    const keys = Object.keys(src)
    for (let i = 0; i < keys.length; i++) {
        const k = keys[i]
        const r = src[k]
        if (k.length > 300 || !r || typeof r !== "object")
            continue
        const n = Math.round(Number(r.n))
        const t = Math.round(Number(r.t))
        if (n > 0 && t > 0)
            out[k] = { n: Math.min(100000, n), t: t }
    }
    return out
}

// The search modes, Pop Launcher's prefixes. Modes other than "default"
// show only their own results.
const modes = [
    { id: "help", prefixes: ["?"], plugin: "help" },
    { id: "calc", prefixes: ["="], plugin: "calc" },
    { id: "files", prefixes: ["~", "/"], plugin: "files", keep: true },
    { id: "find", prefixes: ["find "], plugin: "find" },
    { id: "recent", prefixes: ["recent "], plugin: "recent" },
    { id: "terminal", prefixes: ["t:", ":"], plugin: "terminal" },
    { id: "background", prefixes: ["run "], plugin: "terminal" }
]

// { mode, rest } for a query. rest is what follows the prefix (kept for
// files, where the prefix is part of the path). A mode whose plugin is
// off falls back to "default".
function parseQuery(text, enabled) {
    const raw = String(text || "")
    const on = enabled || {}
    for (let i = 0; i < modes.length; i++) {
        const m = modes[i]
        if (on[m.plugin] === false)
            continue
        for (let j = 0; j < m.prefixes.length; j++) {
            const p = m.prefixes[j]
            if (raw.toLowerCase().indexOf(p) === 0)
                return { mode: m.id, rest: m.keep ? raw : raw.substring(p.length) }
        }
    }
    return { mode: "default", rest: raw }
}

// The prefixes, for the help list: [{ prefix, text }].
function helpRows(enabled) {
    const on = enabled || {}
    const rows = [
        { plugin: "calc", prefix: "= ", text: "Calculator, with unit conversion (qalc)" },
        { plugin: "files", prefix: "~/", text: "Browse files; Tab completes the path" },
        { plugin: "find", prefix: "find ", text: "Search files by name" },
        { plugin: "recent", prefix: "recent ", text: "Recently opened files" },
        { plugin: "terminal", prefix: "t: ", text: "Run a command in a terminal (also :)" },
        { plugin: "terminal", prefix: "run ", text: "Run a command in the background" },
        { plugin: "web", prefix: "ddg ", text: "Web search; see Settings for every shortcut" }
    ]
    return rows.filter((r) => on[r.plugin] !== false)
}

// Pop Launcher's calculator also answers plain arithmetic: text that
// starts with a digit, a minus, or a parenthesis.
function looksLikeMath(text) {
    const t = String(text || "").trim()
    return t.length > 0 && /^[-0-9(]/.test(t) && /[0-9]/.test(t)
}

// Pop Launcher's default web search rules: the first word picks a rule;
// the rest is the search.
const defaultWebRules = [
    { prefixes: ["ali", "alie"], name: "AliExpress", url: "aliexpress.com/wholesale?SearchText=" },
    { prefixes: ["amazon"], name: "Amazon", url: "amazon.com/s?k=" },
    { prefixes: ["arch"], name: "Arch Wiki", url: "wiki.archlinux.org/index.php?search=" },
    { prefixes: ["bc", "bandcamp"], name: "Bandcamp", url: "bandcamp.com/search?q=" },
    { prefixes: ["bing"], name: "Bing", url: "bing.com/search?q=" },
    { prefixes: ["bs", "brave"], name: "Brave Search", url: "search.brave.com/search?q=" },
    { prefixes: ["crates"], name: "Crates.io", url: "crates.io/search?q=" },
    { prefixes: ["ddg"], name: "DuckDuckGo", url: "duckduckgo.com/?q=" },
    { prefixes: ["dev"], name: "DEV Community", url: "dev.to/search?q=" },
    { prefixes: ["docs"], name: "Docs.rs", url: "docs.rs/" },
    { prefixes: ["eco", "ecosia"], name: "Ecosia", url: "ecosia.org/search?q=" },
    { prefixes: ["fh", "flathub"], name: "Flathub", url: "flathub.org/apps/search?q=" },
    { prefixes: ["gh", "github"], name: "GitHub", url: "github.com/search?q=" },
    { prefixes: ["gist"], name: "GitHub Gist", url: "gist.github.com/search?q=" },
    { prefixes: ["gs", "google"], name: "Google", url: "google.com/search?q=" },
    { prefixes: ["gi"], name: "Google Images", url: "google.com/images?q=" },
    { prefixes: ["gm"], name: "Google Maps", url: "google.com/maps?q=" },
    { prefixes: ["gn"], name: "Google News", url: "google.com/news?q=" },
    { prefixes: ["gsc", "scholar"], name: "Google Scholar", url: "scholar.google.com/scholar?q=" },
    { prefixes: ["kagi"], name: "Kagi", url: "kagi.com/search?q=" },
    { prefixes: ["lib"], name: "Libraries.io", url: "libraries.io/search?q=" },
    { prefixes: ["mdn"], name: "MDN Web Docs", url: "developer.mozilla.org/search?q=" },
    { prefixes: ["npm"], name: "npm", url: "npmjs.com/search?q=" },
    { prefixes: ["rdt", "reddit"], name: "Reddit", url: "reddit.com/search/?q=" },
    { prefixes: ["sc", "sdcl"], name: "SoundCloud", url: "soundcloud.com/search?q=" },
    { prefixes: ["stack"], name: "Stack Overflow", url: "stackoverflow.com/search?q=" },
    { prefixes: ["sp", "startpage"], name: "Startpage", url: "startpage.com/sp/search?query=" },
    { prefixes: ["twitch"], name: "Twitch", url: "twitch.tv/search?term=" },
    { prefixes: ["wiki"], name: "Wikipedia", url: "en.wikipedia.org/w/index.php?search=" },
    { prefixes: ["www"], name: "Open website", url: "https://", raw: true },
    { prefixes: ["yh", "yahoo"], name: "Yahoo!", url: "search.yahoo.com/search?p=" },
    { prefixes: ["yt", "youtube"], name: "YouTube", url: "youtube.com/results?search_query=" }
]

const webRulesMax = 64

// A clean rule, or null: 1 to 6 short lowercase shortcuts, a name, and an
// http(s) address (the scheme may be left off).
function webRuleNorm(src) {
    if (!src || typeof src !== "object")
        return null
    const list = Array.isArray(src.prefixes) ? src.prefixes : String(src.prefixes || "").split(/[\s,]+/)
    const prefixes = []
    for (let i = 0; i < list.length; i++) {
        const p = String(list[i] || "").trim().toLowerCase()
        if (!p.length)
            continue
        // One bad shortcut refuses the rule, so the page can say why.
        if (!/^[a-z0-9]{1,16}$/.test(p) || prefixes.length >= 6)
            return null
        if (prefixes.indexOf(p) < 0)
            prefixes.push(p)
    }
    const name = String(src.name || "").replace(/[\u0000-\u001f]/g, " ").trim().substring(0, 40)
    const url = String(src.url || "").trim()
    if (!prefixes.length || !name.length || !url.length || url.length > 300 || /\s/.test(url))
        return null
    if (url.indexOf("://") >= 0 && !/^https?:\/\//i.test(url))
        return null
    return { prefixes: prefixes, name: name, url: url, raw: src.raw === true }
}

// A saved rule list (JSON text). Empty or broken text gives the defaults.
function webRulesFrom(text) {
    let parsed = null
    try {
        parsed = JSON.parse(String(text || ""))
    } catch (e) {
        parsed = null
    }
    if (!Array.isArray(parsed))
        return defaultWebRules.slice()
    const out = []
    for (let i = 0; i < parsed.length && out.length < webRulesMax; i++) {
        const r = webRuleNorm(parsed[i])
        if (r)
            out.push(r)
    }
    return out
}

// The address to open for a rule and the search words.
function webUrl(rule, terms) {
    const words = String(terms || "").trim()
    let base = String(rule.url || "")
    if (base.indexOf("://") < 0)
        base = "https://" + base
    if (rule.raw)
        return base + words.replace(/^https?:\/\//i, "").replace(/\s+/g, "")
    return base + encodeURIComponent(words)
}

// Web results for a query: the first word picks the rules.
// [{ rule, terms, url }].
function webMatches(text, rules) {
    const raw = String(text || "")
    const m = /^(\S+)\s+(\S.*)$/.exec(raw)
    if (!m)
        return []
    const word = m[1].toLowerCase()
    const terms = m[2].trim()
    const out = []
    for (let i = 0; i < (rules || []).length; i++) {
        const r = rules[i]
        if (r.prefixes.indexOf(word) >= 0)
            out.push({ rule: r, terms: terms, url: webUrl(r, terms) })
    }
    return out
}

// A path typed after ~ or /: { dir, base } with ~ expanded. dir ends in /.
function pathParts(text, home) {
    let t = String(text || "")
    if (t === "~" || t.indexOf("~/") === 0)
        t = String(home || "") + t.substring(1)
    if (t.charAt(0) !== "/")
        return null
    if (t === String(home || ""))
        t += "/"
    const cut = t.lastIndexOf("/")
    return { dir: t.substring(0, cut + 1), base: t.substring(cut + 1) }
}

// The path to show for a full path: ~ for the home folder.
function tildePath(path, home) {
    const h = String(home || "")
    const p = String(path || "")
    if (h.length && (p === h || p.indexOf(h + "/") === 0))
        return "~" + p.substring(h.length)
    return p
}

// Pop Launcher script headers: leading "# key: value" comment lines.
function scriptHeader(text) {
    const out = { name: "", icon: "", description: "", keywords: [] }
    const lines = String(text || "").split("\n")
    for (let i = 0; i < lines.length && i < 40; i++) {
        const line = lines[i].trim()
        if (i === 0 && line.indexOf("#!") === 0)
            continue
        if (!line.length)
            continue
        if (line.charAt(0) !== "#")
            break
        const m = /^#\s*(name|icon|description|keywords)\s*:\s*(.*)$/i.exec(line)
        if (!m)
            continue
        const key = m[1].toLowerCase()
        const value = m[2].trim().substring(0, 200)
        if (key === "keywords")
            out.keywords = value.split(/\s+/).filter((w) => w.length > 0).slice(0, 20)
        else
            out[key] = value
    }
    return out
}

function xmlUnescape(text) {
    return String(text || "").replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">").replace(/&amp;/g, "&")
}

// The recent-files list (~/.local/share/recently-used.xbel): local files
// only, newest first. [{ path, name, modified }].
function recentFiles(xml, max) {
    const out = []
    const re = /<bookmark\b([^>]*)>/g
    const text = String(xml || "")
    let m
    while ((m = re.exec(text)) !== null) {
        const attrs = m[1]
        const href = /\bhref="([^"]*)"/.exec(attrs)
        const mod = /\bmodified="([^"]*)"/.exec(attrs)
        if (!href)
            continue
        const url = xmlUnescape(href[1])
        if (url.indexOf("file://") !== 0)
            continue
        let path = ""
        try {
            path = decodeURIComponent(url.substring(7))
        } catch (e) {
            continue
        }
        const name = path.substring(path.lastIndexOf("/") + 1)
        out.push({ path: path, name: name, modified: mod ? Date.parse(mod[1]) || 0 : 0 })
    }
    out.sort((a, b) => b.modified - a.modified)
    return out.slice(0, max || 200)
}

// Results in order: priority first, then score, then name.
function sortResults(rows) {
    return rows.slice().sort((a, b) => {
        if ((b.priority || 0) !== (a.priority || 0))
            return (b.priority || 0) - (a.priority || 0)
        if ((b.score || 0) !== (a.score || 0))
            return (b.score || 0) - (a.score || 0)
        return String(a.name).localeCompare(String(b.name))
    })
}
