.pragma library

// Default apps: read and rewrite mimeapps.list, the common-task groups,
// which app opens a type, and the problems check. Pure JavaScript: the
// service reads the files and passes their text in.
//
// A "state" is what this page edits in ~/.config/mimeapps.list:
//   { defaults: { type: [ids] }, added: { type: [ids] }, removed: { type: [ids] } }
// for [Default Applications], [Added Associations], [Removed Associations].
// Ids are desktop file names ("mpv.desktop").
//
// A "ctx" is everything else resolve() and problems() need:
//   state        the (draft) state
//   system       [ state-like {defaults, added} ] from the system files, highest first
//   cache        { type: [ids] } apps that say they open a type (mimeinfo.cache)
//   aliases      { alias: canonical }
//   parents      { type: [parent types] }
//   installed(id) true when the desktop file exists
//   nameOf(id)   the app's display name

var sectionNames = {
    defaults: "Default Applications",
    added: "Added Associations",
    removed: "Removed Associations"
}
var stateKeys = ["defaults", "added", "removed"]

var typeRe = /^[A-Za-z0-9][A-Za-z0-9.+_-]*\/[A-Za-z0-9*][A-Za-z0-9.+_*-]*$/
var idRe = /^[A-Za-z0-9_][A-Za-z0-9._+-]*\.desktop$/

// The common tasks. `glyph` is a Nerd Font icon (nf-md). `key` types rank
// the app choices. Picking an app sets every type in the group that the
// app says it can open (all of them for an app that declares none).
// Terminals are not a file type, so they are not here.
var groups = [
    { id: "browser", label: "Web browser", glyph: "\u{F059F}", key: ["x-scheme-handler/https", "x-scheme-handler/http"],
      types: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html", "application/xhtml+xml", "x-scheme-handler/about", "x-scheme-handler/unknown"] },
    { id: "email", label: "Email", glyph: "\u{F01EE}", key: ["x-scheme-handler/mailto"],
      types: ["x-scheme-handler/mailto"] },
    { id: "files", label: "File manager", glyph: "\u{F024B}", key: ["inode/directory"],
      types: ["inode/directory"] },
    { id: "text", label: "Text editor", glyph: "\u{F0219}", key: ["text/plain"],
      types: ["text/plain", "text/markdown"] },
    { id: "code", label: "Code", glyph: "\u{F0169}", key: ["text/x-python", "text/x-shellscript"],
      types: ["text/x-python", "text/x-shellscript", "text/x-c", "text/x-c++", "text/x-rust", "text/x-go", "text/x-java",
              "application/javascript", "application/typescript", "application/json", "application/xml", "text/x-toml", "text/x-yaml"] },
    { id: "images", label: "Images", glyph: "\u{F02E9}", key: ["image/png", "image/jpeg"],
      types: ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml", "image/bmp", "image/tiff",
              "image/avif", "image/heic", "image/jxl", "image/x-icon"] },
    { id: "video", label: "Video", glyph: "\u{F0381}", key: ["video/mp4", "video/matroska"],
      types: ["video/mp4", "video/matroska", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo",
              "video/mpeg", "video/ogg", "video/mp2t", "video/x-flv"] },
    { id: "music", label: "Music", glyph: "\u{F075A}", key: ["audio/mpeg", "audio/flac"],
      types: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav", "audio/aac", "audio/opus", "audio/x-m4a",
              "audio/x-vorbis+ogg", "audio/x-opus+ogg"] },
    { id: "pdf", label: "PDF", glyph: "\u{F0226}", key: ["application/pdf"],
      types: ["application/pdf"] },
    { id: "ebooks", label: "E-books", glyph: "\u{F05DA}", key: ["application/epub+zip"],
      types: ["application/epub+zip"] },
    { id: "documents", label: "Documents", glyph: "\u{F022C}", key: ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
      types: ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword",
              "application/vnd.oasis.opendocument.text", "application/rtf"] },
    { id: "spreadsheets", label: "Spreadsheets", glyph: "\u{F021B}", key: ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
      types: ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.ms-excel",
              "application/vnd.oasis.opendocument.spreadsheet", "text/csv"] },
    { id: "slides", label: "Slides", glyph: "\u{F0227}", key: ["application/vnd.openxmlformats-officedocument.presentationml.presentation"],
      types: ["application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.ms-powerpoint",
              "application/vnd.oasis.opendocument.presentation"] },
    { id: "archives", label: "Archives", glyph: "\u{F003C}", key: ["application/zip", "application/x-compressed-tar"],
      types: ["application/zip", "application/x-tar", "application/x-compressed-tar", "application/x-xz-compressed-tar",
              "application/x-zstd-compressed-tar", "application/x-7z-compressed", "application/vnd.rar", "application/gzip"] }
]

function groupById(id) {
    for (let i = 0; i < groups.length; i++) {
        if (groups[i].id === id)
            return groups[i]
    }
    return null
}

// Every type a group sets, for Reset.
function groupTypes() {
    const out = []
    for (let i = 0; i < groups.length; i++)
        out.push.apply(out, groups[i].types)
    return out
}

function validType(type) {
    return typeRe.test(String(type || ""))
}

function validId(id) {
    return idRe.test(String(id || ""))
}

function isWildcard(type) {
    return String(type || "").indexOf("*") >= 0
}

function splitIds(value) {
    const out = []
    const parts = String(value || "").split(";")
    for (let i = 0; i < parts.length; i++) {
        const id = parts[i].trim()
        if (validId(id) && out.indexOf(id) < 0)
            out.push(id)
    }
    return out
}

function emptyState() {
    return { defaults: {}, added: {}, removed: {} }
}

// A clean copy: valid types and ids only, no repeats, no empty lists,
// keys in sorted order so two states compare as text.
function normalize(src) {
    const s = src || {}
    const out = emptyState()
    for (let k = 0; k < stateKeys.length; k++) {
        const name = stateKeys[k]
        const map = s[name] || {}
        const keys = Object.keys(map).filter(validType).sort()
        for (let i = 0; i < keys.length; i++) {
            // A list that came through a QML signal is array-like, not an Array.
            const raw = map[keys[i]]
            const list = raw && typeof raw === "object" && typeof raw.length === "number"
                ? Array.prototype.slice.call(raw) : splitIds(raw)
            const ids = []
            for (let j = 0; j < list.length; j++) {
                const id = String(list[j] || "").trim()
                if (validId(id) && ids.indexOf(id) < 0)
                    ids.push(id)
            }
            if (ids.length)
                out[name][keys[i]] = ids
        }
    }
    return out
}

// Lines of an ini file as { section, key, value } (key "" for headers,
// comments, and blanks). A repeated key keeps its last value, as GLib does.
function lines(text) {
    const rows = String(text || "").split("\n")
    const out = []
    let section = ""
    for (let i = 0; i < rows.length; i++) {
        const raw = rows[i].replace(/\r$/, "")
        const t = raw.trim()
        const header = /^\[([^\]]+)\]$/.exec(t)
        if (header) {
            section = header[1].trim()
            out.push({ raw: raw, section: section, header: true, key: "" })
            continue
        }
        const eq = t.indexOf("=")
        if (!t.length || t.charAt(0) === "#" || eq < 1) {
            out.push({ raw: raw, section: section, header: false, key: "" })
            continue
        }
        out.push({ raw: raw, section: section, header: false, key: t.slice(0, eq).trim(), value: t.slice(eq + 1).trim() })
    }
    return out
}

// mimeapps.list text to a state. Wildcard keys are kept so the problems
// check can report them.
function parse(text) {
    const out = emptyState()
    const rows = lines(text)
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i]
        if (!row.key.length)
            continue
        for (let k = 0; k < stateKeys.length; k++) {
            if (row.section === sectionNames[stateKeys[k]] && validType(row.key))
                out[stateKeys[k]][row.key] = splitIds(row.value)
        }
    }
    return normalize(out)
}

// mimeinfo.cache text to { type: [ids] }.
function parseCache(text) {
    const out = {}
    const rows = lines(text)
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i]
        if (row.key.length && row.section === "MIME Cache" && validType(row.key))
            out[row.key] = splitIds(row.value)
    }
    return out
}

// Several caches into one, earlier first (the user's folder goes first).
function mergeCaches(list) {
    const out = {}
    for (let i = 0; i < (list || []).length; i++) {
        const cache = list[i] || {}
        const keys = Object.keys(cache)
        for (let k = 0; k < keys.length; k++) {
            const have = out[keys[k]] || []
            const more = cache[keys[k]] || []
            for (let j = 0; j < more.length; j++) {
                if (have.indexOf(more[j]) < 0)
                    have.push(more[j])
            }
            out[keys[k]] = have
        }
    }
    return out
}

// "alias canonical" or "child parent" lines.
function parsePairs(text) {
    const out = []
    const rows = String(text || "").split("\n")
    for (let i = 0; i < rows.length; i++) {
        const parts = rows[i].trim().split(/\s+/)
        if (parts.length === 2 && validType(parts[0]) && validType(parts[1]))
            out.push(parts)
    }
    return out
}

function parseAliases(text) {
    const out = {}
    const pairs = parsePairs(text)
    for (let i = 0; i < pairs.length; i++)
        out[pairs[i][0]] = pairs[i][1]
    return out
}

function parseParents(text) {
    const out = {}
    const pairs = parsePairs(text)
    for (let i = 0; i < pairs.length; i++) {
        const list = out[pairs[i][0]] || []
        list.push(pairs[i][1])
        out[pairs[i][0]] = list
    }
    return out
}

function canonical(type, aliases) {
    const a = aliases || {}
    return a[type] || type
}

// canonical -> [aliases], built once per aliases object.
var reverseFor = null
var reverseMap = null
function reverseAliases(a) {
    if (reverseFor !== a) {
        reverseMap = {}
        const keys = Object.keys(a)
        for (let i = 0; i < keys.length; i++) {
            const list = reverseMap[a[keys[i]]] || []
            list.push(keys[i])
            reverseMap[a[keys[i]]] = list
        }
        reverseFor = a
    }
    return reverseMap
}

// The type and every other name for it, the asked-for name first.
function sameType(type, aliases) {
    const a = aliases || {}
    const main = canonical(type, a)
    const out = [type]
    if (main !== type)
        out.push(main)
    const others = reverseAliases(a)[main] || []
    for (let i = 0; i < others.length; i++) {
        if (out.indexOf(others[i]) < 0)
            out.push(others[i])
    }
    return out
}

// Parent types, nearest first. Every text/* type is also plain text.
function ancestors(type, ctx) {
    const parents = (ctx && ctx.parents) || {}
    const aliases = (ctx && ctx.aliases) || {}
    const out = []
    const queue = [canonical(type, aliases)]
    while (queue.length && out.length < 32) {
        const next = queue.shift()
        const up = (parents[next] || []).slice()
        if (next.indexOf("text/") === 0 && next !== "text/plain")
            up.push("text/plain")
        for (let i = 0; i < up.length; i++) {
            const p = canonical(up[i], aliases)
            if (p !== type && out.indexOf(p) < 0) {
                out.push(p)
                queue.push(p)
            }
        }
    }
    return out
}

function installed(ctx, id) {
    return !!(ctx && typeof ctx.installed === "function" && ctx.installed(id))
}

function nameOf(ctx, id) {
    if (ctx && typeof ctx.nameOf === "function") {
        const name = String(ctx.nameOf(id) || "")
        if (name.length)
            return name
    }
    return String(id || "").replace(/\.desktop$/, "")
}

function firstInstalled(ctx, map, names, skip) {
    if (!map)
        return ""
    for (let n = 0; n < names.length; n++) {
        const ids = map[names[n]] || []
        for (let i = 0; i < ids.length; i++) {
            if (!(skip && skip[ids[i]]) && installed(ctx, ids[i]))
                return ids[i]
        }
    }
    return ""
}

// Apps that say they open this type, from the caches and the system
// files' added associations. The user's own added list is not counted:
// it fills up with every "Open with" pick.
function declaredBy(type, ctx) {
    const names = sameType(type, ctx.aliases)
    const out = []
    const sources = [ctx.cache || {}]
    const system = ctx.system || []
    for (let s = 0; s < system.length; s++)
        sources.push((system[s] && system[s].added) || {})
    for (let s = 0; s < sources.length; s++) {
        for (let n = 0; n < names.length; n++) {
            const ids = sources[s][names[n]] || []
            for (let i = 0; i < ids.length; i++) {
                if (out.indexOf(ids[i]) < 0)
                    out.push(ids[i])
            }
        }
    }
    return out
}

// Each app's declared types, from the caches. Built once per cache.
var indexFor = null
var indexMap = null
function appTypes(id, ctx) {
    const cache = ctx.cache || {}
    if (indexFor !== cache) {
        indexMap = {}
        const keys = Object.keys(cache)
        for (let i = 0; i < keys.length; i++) {
            const ids = cache[keys[i]]
            for (let j = 0; j < ids.length; j++) {
                const list = indexMap[ids[j]] || []
                list.push(keys[i])
                indexMap[ids[j]] = list
            }
        }
        indexFor = cache
    }
    return indexMap[id] || []
}

function family(type) {
    return String(type || "").split("/")[0]
}

// An app looks wrong for a type only when it declares file types and none
// share the type's family (text, image, x-scheme-handler, …). An app that
// declares nothing cannot be judged, so it is never flagged.
function looksWrong(id, type, ctx) {
    if (declares(id, type, ctx))
        return false
    const own = appTypes(id, ctx)
    if (!own.length)
        return false
    const wanted = [family(type)].concat(ancestors(type, ctx).map(family))
    for (let i = 0; i < own.length; i++) {
        if (wanted.indexOf(family(own[i])) >= 0)
            return false
    }
    return true
}

// True when the app says it opens this type or one of its parents.
function declares(id, type, ctx) {
    if (declaredBy(type, ctx).indexOf(id) >= 0)
        return true
    const up = ancestors(type, ctx)
    for (let i = 0; i < up.length; i++) {
        if (declaredBy(up[i], ctx).indexOf(id) >= 0)
            return true
    }
    return false
}

// Which app opens a type and why, close to xdg-open and GLib:
// your defaults, the system's defaults, your added list, the system's
// added lists, then the first app that says it opens the type. Your
// removed list takes an app out of the last step. Wildcards are ignored,
// as both do.
//   { id, source: "you" | "system" | "added" | "auto" | "" }
function resolve(type, ctx) {
    const names = sameType(type, ctx.aliases)
    const state = ctx.state || emptyState()
    const system = ctx.system || []
    let id = firstInstalled(ctx, state.defaults, names, null)
    if (id)
        return { id: id, source: "you" }
    for (let s = 0; s < system.length; s++) {
        id = firstInstalled(ctx, system[s] && system[s].defaults, names, null)
        if (id)
            return { id: id, source: "system" }
    }
    id = firstInstalled(ctx, state.added, names, null)
    if (id)
        return { id: id, source: "added" }
    for (let s = 0; s < system.length; s++) {
        id = firstInstalled(ctx, system[s] && system[s].added, names, null)
        if (id)
            return { id: id, source: "added" }
    }
    const skip = {}
    for (let n = 0; n < names.length; n++) {
        const gone = (state.removed || {})[names[n]] || []
        for (let i = 0; i < gone.length; i++)
            skip[gone[i]] = true
    }
    id = firstInstalled(ctx, ctx.cache, names, skip)
    if (id)
        return { id: id, source: "auto" }
    return { id: "", source: "" }
}

// A group's types that some installed app can open. Types nothing can open
// do not count toward "Mixed".
function liveTypes(group, ctx) {
    const out = []
    for (let i = 0; i < group.types.length; i++) {
        const t = group.types[i]
        if (resolve(t, ctx).id.length)
            out.push(t)
    }
    return out
}

// What a group opens with now:
//   { id: the one app or "", mixed, apps: [{ id, count }], rows: [{ type, id, source }] }
function groupState(group, ctx) {
    const rows = []
    const counts = {}
    const order = []
    for (let i = 0; i < group.types.length; i++) {
        const t = group.types[i]
        const r = resolve(t, ctx)
        rows.push({ type: t, id: r.id, source: r.source })
        if (!r.id.length)
            continue
        if (!counts[r.id]) {
            counts[r.id] = 0
            order.push(r.id)
        }
        counts[r.id] += 1
    }
    order.sort((a, b) => counts[b] - counts[a])
    const apps = order.map((id) => ({ id: id, count: counts[id] }))
    return {
        id: apps.length === 1 ? apps[0].id : "",
        mixed: apps.length > 1,
        apps: apps,
        rows: rows
    }
}

// Installed apps for a group's picker: apps that open its key types first,
// then by how many of its types they open, then by name.
function candidates(group, ctx) {
    const score = {}
    const keyed = {}
    for (let i = 0; i < group.types.length; i++) {
        const t = group.types[i]
        const ids = declaredBy(t, ctx)
        for (let j = 0; j < ids.length; j++) {
            if (!installed(ctx, ids[j]))
                continue
            score[ids[j]] = (score[ids[j]] || 0) + 1
            if (group.key.indexOf(t) >= 0)
                keyed[ids[j]] = true
        }
    }
    const ids = Object.keys(score)
    ids.sort((a, b) => {
        if (!!keyed[a] !== !!keyed[b])
            return keyed[a] ? -1 : 1
        if (score[a] !== score[b])
            return score[b] - score[a]
        return nameOf(ctx, a).localeCompare(nameOf(ctx, b))
    })
    return ids
}

function copyState(state) {
    return normalize(JSON.parse(JSON.stringify(state || emptyState())))
}

// Set one type's default list (null or [] removes your line).
function setDefault(state, type, ids) {
    const next = copyState(state)
    if (ids && ids.length)
        next.defaults[type] = ids.slice()
    else
        delete next.defaults[type]
    return normalize(next)
}

// The types of a group an app would be set for.
function typesFor(group, id, ctx) {
    const own = group.types.filter((t) => declares(id, t, ctx))
    return own.length ? own : group.types.slice()
}

// Make an app the default for a group.
function setGroup(state, group, id, ctx) {
    let next = copyState(state)
    const types = typesFor(group, id, ctx)
    for (let i = 0; i < types.length; i++)
        next = setDefault(next, types[i], [id])
    return next
}

// Installed apps for one type's picker: apps that declare it, then apps
// that declare a parent type (plain text editors for a code file).
function typeCandidates(type, ctx) {
    const out = []
    const lists = [declaredBy(type, ctx)]
    const up = ancestors(type, ctx)
    for (let i = 0; i < up.length; i++)
        lists.push(declaredBy(up[i], ctx))
    for (let l = 0; l < lists.length; l++) {
        const ids = lists[l].filter((id) => installed(ctx, id) && out.indexOf(id) < 0)
        ids.sort((a, b) => nameOf(ctx, a).localeCompare(nameOf(ctx, b)))
        out.push.apply(out, ids)
    }
    return out
}

// Every type worth listing: the shared-mime-info list, the caches, and
// the types in your file (wildcards left out), sorted.
function allTypes(known, ctx) {
    const seen = {}
    const out = []
    function add(t) {
        if (validType(t) && !isWildcard(t) && !seen[t]) {
            seen[t] = true
            out.push(t)
        }
    }
    for (let i = 0; i < (known || []).length; i++)
        add(known[i])
    const state = ctx.state || emptyState()
    const sources = [ctx.cache || {}, state.defaults, state.added, state.removed]
    for (let s = 0; s < sources.length; s++) {
        const keys = Object.keys(sources[s])
        for (let i = 0; i < keys.length; i++)
            add(keys[i])
    }
    out.sort()
    return out
}

// The types in your file, sorted.
function yourTypes(state) {
    const s = state || emptyState()
    const keys = Object.keys(s.defaults).concat(Object.keys(s.added), Object.keys(s.removed))
    return keys.filter((t, i) => !isWildcard(t) && keys.indexOf(t) === i).sort()
}

// Families for All file types, in the order shown. `glyph` is nf-md.
var families = [
    { id: "links", label: "Links", glyph: "\u{F0337}" },
    { id: "folders", label: "Folders", glyph: "\u{F024B}" },
    { id: "text", label: "Text and code", glyph: "\u{F0219}" },
    { id: "image", label: "Images", glyph: "\u{F02E9}" },
    { id: "audio", label: "Audio", glyph: "\u{F075A}" },
    { id: "video", label: "Video", glyph: "\u{F0381}" },
    { id: "application", label: "Documents and other files", glyph: "\u{F0214}" },
    { id: "font", label: "Fonts", glyph: "\u{F06D6}" },
    { id: "other", label: "Other", glyph: "\u{F01D8}" }
]

function familyOf(type) {
    const top = family(type)
    if (top === "x-scheme-handler")
        return "links"
    if (top === "inode")
        return "folders"
    for (let i = 0; i < families.length; i++) {
        if (families[i].id === top)
            return top
    }
    return "other"
}

// Types as list rows under family headers:
//   { header: true, family, label, glyph, count, open } and { header: false, type }
// A family's types are listed only when it is open, or when `all` is set
// (while searching). Families with no types are left out.
function familyRows(types, open, all) {
    const buckets = {}
    for (let i = 0; i < (types || []).length; i++) {
        const f = familyOf(types[i])
        const list = buckets[f] || []
        list.push(types[i])
        buckets[f] = list
    }
    const out = []
    for (let i = 0; i < families.length; i++) {
        const f = families[i]
        const list = buckets[f.id] || []
        if (!list.length)
            continue
        const shown = !!all || !!(open && open[f.id])
        out.push({ header: true, family: f.id, label: f.label, glyph: f.glyph, count: list.length, open: shown, type: "" })
        if (!shown)
            continue
        for (let j = 0; j < list.length; j++)
            out.push({ header: false, family: f.id, label: "", glyph: "", count: 0, open: false, type: list[j] })
    }
    return out
}

// Installed apps with what they open by default and what else they say
// they can open, by name:
//   [{ id, defaults: [types], others: [types] }]
// `types` is the list to check defaults over (allTypes()).
function appsSummary(types, ctx) {
    const by = {}
    function get(id) {
        if (!by[id])
            by[id] = { id: id, defaults: [], others: [] }
        return by[id]
    }
    const isDefault = {}
    for (let i = 0; i < (types || []).length; i++) {
        const r = resolve(types[i], ctx)
        if (r.id.length) {
            get(r.id).defaults.push(types[i])
            isDefault[r.id + " " + types[i]] = true
        }
    }
    const cache = ctx.cache || {}
    const keys = Object.keys(cache).sort()
    for (let i = 0; i < keys.length; i++) {
        if (isWildcard(keys[i]))
            continue
        const ids = cache[keys[i]]
        for (let j = 0; j < ids.length; j++) {
            if (!isDefault[ids[j] + " " + keys[i]] && installed(ctx, ids[j]))
                get(ids[j]).others.push(keys[i])
        }
    }
    const out = Object.keys(by).filter((id) => installed(ctx, id)).map((id) => by[id])
    out.sort((a, b) => nameOf(ctx, a.id).localeCompare(nameOf(ctx, b.id)))
    return out
}

// Your Open with list for a type: move an app by delta (-1 up, +1 down)
// or take it out (delta 0).
function moveAdded(state, type, id, delta) {
    const next = copyState(state)
    const list = (next.added[type] || []).slice()
    const at = list.indexOf(id)
    if (at < 0)
        return next
    list.splice(at, 1)
    if (delta !== 0)
        list.splice(Math.max(0, Math.min(list.length, at + delta)), 0, id)
    if (list.length)
        next.added[type] = list
    else
        delete next.added[type]
    return normalize(next)
}

// Your defaults for every group type removed, so the system decides.
// Other lines (scheme handlers, file types not in a group) stay.
function resetGroups(state) {
    let next = copyState(state)
    const types = groupTypes()
    for (let i = 0; i < types.length; i++)
        next = setDefault(next, types[i], null)
    return next
}

// The app to suggest for a type when its default is broken or odd:
// what its other names open with, else the first app that declares it.
function suggestion(type, ctx, avoid) {
    const names = sameType(type, ctx.aliases)
    for (let n = 1; n < names.length; n++) {
        const r = resolve(names[n], ctx)
        if (r.id && r.id !== avoid && declares(r.id, type, ctx))
            return r.id
    }
    // Then what the rest of its common task opens with.
    for (let g = 0; g < groups.length; g++) {
        if (groups[g].types.indexOf(type) < 0)
            continue
        const apps = groupState(groups[g], ctx).apps
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id !== avoid && declares(apps[i].id, type, ctx))
                return apps[i].id
        }
    }
    const ids = declaredBy(type, ctx)
    for (let i = 0; i < ids.length; i++) {
        if (ids[i] !== avoid && installed(ctx, ids[i]))
            return ids[i]
    }
    return ""
}

function problemKey(kind, type, id) {
    return kind + ":" + type + "=" + id
}

// Things wrong in your mimeapps.list, each with at most one fix:
//   { key, kind, type, id, text, fixLabel, edit: { section, type, ids }, canKeep }
// edit.ids null removes the line. `kept` lists problem keys to leave out.
function problems(ctx, kept) {
    const state = ctx.state || emptyState()
    const skip = {}
    for (let i = 0; i < (kept || []).length; i++)
        skip[kept[i]] = true
    const out = []
    function add(p) {
        if (!skip[p.key])
            out.push(p)
    }

    // Lines that name an app that is not installed.
    for (let k = 0; k < stateKeys.length; k++) {
        const section = stateKeys[k]
        const map = state[section]
        const types = Object.keys(map)
        for (let i = 0; i < types.length; i++) {
            const type = types[i]
            if (isWildcard(type))
                continue
            const ids = map[type]
            const gone = ids.filter((id) => !installed(ctx, id))
            if (!gone.length)
                continue
            let keep = ids.filter((id) => installed(ctx, id))
            const goneText = gone.map((id) => id.replace(/\.desktop$/, "")).join(", ")
            let fixLabel = "Remove " + goneText
            if (section === "defaults" && !keep.length) {
                const better = suggestion(type, ctx, "")
                if (better.length) {
                    keep = [better]
                    fixLabel = "Use " + nameOf(ctx, better)
                }
            }
            const where = section === "defaults" ? "opens with" : (section === "added" ? "lists" : "removes")
            add({
                key: problemKey("missing", type, gone.join(",")),
                kind: "missing",
                type: type,
                id: gone[0],
                gone: gone,
                text: type + " " + where + " " + goneText + ", which is not installed.",
                fixLabel: fixLabel,
                edit: { section: section, type: type, ids: keep.length ? keep : null },
                canKeep: false
            })
        }
    }

    // Wildcards: neither xdg-open nor GLib reads them.
    for (let k = 0; k < stateKeys.length; k++) {
        const section = stateKeys[k]
        const types = Object.keys(state[section])
        for (let i = 0; i < types.length; i++) {
            if (!isWildcard(types[i]))
                continue
            add({
                key: problemKey("wildcard", types[i], section),
                kind: "wildcard",
                type: types[i],
                id: "",
                text: types[i] + " is not a real type, so apps ignore this line. Set the group below instead.",
                fixLabel: "Remove the line",
                edit: { section: section, type: types[i], ids: null },
                canKeep: false
            })
        }
    }

    // Two names for one type that open with different apps.
    const seen = {}
    const types = Object.keys(state.defaults)
    for (let i = 0; i < types.length; i++) {
        const type = types[i]
        const main = canonical(type, ctx.aliases)
        if (main === type || seen[type] || isWildcard(type))
            continue
        const mine = resolve(type, ctx).id
        const theirs = resolve(main, ctx).id
        if (!mine.length || !theirs.length || mine === theirs)
            continue
        seen[type] = true
        add({
            key: problemKey("alias", type, mine),
            kind: "alias",
            type: type,
            id: mine,
            text: type + " is another name for " + main + ", but it opens with " + nameOf(ctx, mine) + " instead of " + nameOf(ctx, theirs) + ".",
            fixLabel: "Use " + nameOf(ctx, theirs) + " for both",
            edit: { section: "defaults", type: type, ids: [theirs] },
            canKeep: true
        })
    }

    // A default app that does not say it can open the type.
    for (let i = 0; i < types.length; i++) {
        const type = types[i]
        if (isWildcard(type))
            continue
        const ids = state.defaults[type].filter((id) => installed(ctx, id))
        if (!ids.length || !looksWrong(ids[0], type, ctx))
            continue
        const better = suggestion(type, ctx, ids[0])
        add({
            key: problemKey("odd", type, ids[0]),
            kind: "odd",
            type: type,
            id: ids[0],
            text: type + " opens with " + nameOf(ctx, ids[0]) + ", which is made for other kinds of files.",
            fixLabel: better.length ? "Use " + nameOf(ctx, better) : "Remove the line",
            edit: { section: "defaults", type: type, ids: better.length ? [better] : null },
            canKeep: true
        })
    }
    return out
}

function listText(items, most) {
    const shown = items.slice(0, most)
    const rest = items.length - shown.length
    if (rest > 0)
        return shown.join(", ") + " and " + rest + " more"
    if (shown.length <= 1)
        return shown.join("")
    return shown.slice(0, -1).join(", ") + " and " + shown[shown.length - 1]
}

// Problems as cards: one per missing app (or set of apps), one for every
// wildcard line, and one per alias or odd default.
//   { key, kind, text, note, types, fixLabel, edits, keys, canKeep }
function problemGroups(list, ctx) {
    const out = []
    const byGone = {}
    const wild = []
    for (let i = 0; i < (list || []).length; i++) {
        const p = list[i]
        if (p.kind === "missing") {
            const k = p.gone.join(",")
            if (!byGone[k]) {
                byGone[k] = { gone: p.gone, items: [] }
                out.push({ placeholder: "missing", key: k })
            }
            byGone[k].items.push(p)
        } else if (p.kind === "wildcard") {
            if (!wild.length)
                out.push({ placeholder: "wildcard", key: "" })
            wild.push(p)
        } else {
            out.push({
                key: p.key, kind: p.kind, text: p.text, note: "", types: [p.type],
                fixLabel: p.fixLabel, edits: [p.edit], keys: [p.key], canKeep: p.canKeep
            })
        }
    }
    for (let i = 0; i < out.length; i++) {
        const slot = out[i]
        if (slot.placeholder === "missing") {
            const g = byGone[slot.key]
            const names = g.gone.map((id) => id.replace(/\.desktop$/, ""))
            const types = g.items.map((p) => p.type).filter((t, j, a) => a.indexOf(t) === j)
            const takers = []
            for (let j = 0; j < g.items.length; j++) {
                const e = g.items[j].edit
                if (g.items[j].edit.section === "defaults" && e.ids && e.ids.length) {
                    const name = nameOf(ctx, e.ids[0])
                    if (takers.indexOf(name) < 0)
                        takers.push(name)
                }
            }
            out[i] = {
                key: "missing:" + slot.key,
                kind: "missing",
                text: listText(names, 3) + (names.length === 1 ? " is" : " are") + " not installed, but your file still names "
                    + (names.length === 1 ? "it" : "them") + " for " + (types.length === 1 ? types[0] : types.length + " types: " + listText(types, 4)) + ".",
                note: takers.length ? "Where it was the default, " + listText(takers, 3) + " takes over." : "",
                types: types,
                fixLabel: "Remove " + (names.length === 1 ? names[0] : "them"),
                edits: g.items.map((p) => p.edit),
                keys: g.items.map((p) => p.key),
                canKeep: false
            }
        } else if (slot.placeholder === "wildcard") {
            const types = wild.map((p) => p.type)
            out[i] = {
                key: "wildcard",
                kind: "wildcard",
                text: listText(types, 4) + (types.length === 1 ? " is a wildcard" : " are wildcards") + ". xdg-open and apps ignore "
                    + (types.length === 1 ? "it" : "them") + "; set the rows under Common tasks instead.",
                note: "",
                types: types,
                fixLabel: types.length === 1 ? "Remove the line" : "Remove these " + types.length + " lines",
                edits: wild.map((p) => p.edit),
                keys: wild.map((p) => p.key),
                canKeep: false
            }
        }
    }
    return out
}

// Apply several fixes in order.
function applyEdits(state, edits) {
    let next = copyState(state)
    for (let i = 0; i < (edits || []).length; i++)
        next = applyEdit(next, edits[i])
    return next
}

// Apply a problem's fix to a state.
function applyEdit(state, edit) {
    const next = copyState(state)
    if (!edit || stateKeys.indexOf(edit.section) < 0)
        return next
    const map = next[edit.section]
    if (edit.ids && edit.ids.length)
        map[edit.type] = edit.ids.slice()
    else
        delete map[edit.type]
    return normalize(next)
}

function sameState(a, b) {
    return JSON.stringify(normalize(a)) === JSON.stringify(normalize(b))
}

function formatIds(ids) {
    return ids.join(";") + ";"
}

// New file text: only the lines whose values changed between `before` and
// `after` are touched. Comments, other sections, other keys, and their
// order stay as they were. New keys go at the end of their section; a
// missing section is added at the end of the file.
function rewrite(text, before, after) {
    const a = normalize(before)
    const b = normalize(after)
    const rows = lines(text)
    const changed = {}
    for (let k = 0; k < stateKeys.length; k++) {
        const name = stateKeys[k]
        const keys = Object.keys(a[name]).concat(Object.keys(b[name]))
        const set = {}
        for (let i = 0; i < keys.length; i++) {
            const t = keys[i]
            if (JSON.stringify(a[name][t] || null) !== JSON.stringify(b[name][t] || null))
                set[t] = true
        }
        changed[sectionNames[name]] = { state: name, keys: set, written: {} }
    }

    const out = []
    const lastLine = {}
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i]
        const plan = changed[row.section]
        if (plan && row.key.length && plan.keys[row.key]) {
            const ids = b[plan.state][row.key]
            if (ids && !plan.written[row.key]) {
                out.push(row.key + "=" + formatIds(ids))
                plan.written[row.key] = true
                lastLine[row.section] = out.length - 1
            }
            continue
        }
        out.push(row.raw)
        if (plan && (row.header || row.key.length))
            lastLine[row.section] = out.length - 1
    }

    // Trailing blank lines go (one newline is added back at the end).
    // lastLine never points at a blank line, so this is safe.
    while (out.length && out[out.length - 1].trim() === "")
        out.pop()

    for (let k = 0; k < stateKeys.length; k++) {
        const name = sectionNames[stateKeys[k]]
        const plan = changed[name]
        const extra = []
        const keys = Object.keys(plan.keys).sort()
        for (let i = 0; i < keys.length; i++) {
            const ids = b[plan.state][keys[i]]
            if (ids && !plan.written[keys[i]])
                extra.push(keys[i] + "=" + formatIds(ids))
        }
        if (!extra.length)
            continue
        if (lastLine[name] === undefined) {
            if (out.length && out[out.length - 1].trim() !== "")
                out.push("")
            out.push("[" + name + "]")
            out.push.apply(out, extra)
            lastLine[name] = out.length - 1
            continue
        }
        const at = lastLine[name] + 1
        out.splice.apply(out, [at, 0].concat(extra))
        const names = Object.keys(lastLine)
        for (let i = 0; i < names.length; i++) {
            if (lastLine[names[i]] >= at)
                lastLine[names[i]] += extra.length
        }
        lastLine[name] = at + extra.length - 1
    }
    return out.join("\n") + "\n"
}
