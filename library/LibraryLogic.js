.pragma library

// The App Library's folder rules, with no UI and no I/O, so tests can run
// them directly. A folder holds the apps you put in it plus, like Pop's
// library, every app in its categories; an app taken out of a folder it
// is in by category is remembered as hidden from it.
//   { name, categories: [Freedesktop category], apps: [desktop id], hidden: [desktop id] }

const foldersMax = 24
const nameMax = 32
const appsMax = 400

// Pop's library starts with these three.
const defaultFolders = [
    { name: "Office", categories: ["Office"], apps: [], hidden: [] },
    { name: "System", categories: ["System"], apps: [], hidden: [] },
    { name: "Utilities", categories: ["Utility"], apps: [], hidden: [] }
]

function nameNorm(text) {
    return String(text || "").replace(/[\u0000-\u001f]/g, " ").replace(/\s+/g, " ").trim().substring(0, nameMax)
}

function idList(src, max) {
    const out = []
    const list = Array.isArray(src) ? src : []
    for (let i = 0; i < list.length && out.length < max; i++) {
        const id = String(list[i] || "").trim()
        if (id.length > 0 && id.length <= 200 && !/[\r\n\/]/.test(id) && out.indexOf(id) < 0)
            out.push(id)
    }
    return out
}

function folderNorm(src) {
    if (!src || typeof src !== "object")
        return null
    const name = nameNorm(src.name)
    if (!name.length)
        return null
    const categories = idList(src.categories, 12).filter((c) => /^[A-Za-z0-9-]{1,40}$/.test(c))
    return { name: name, categories: categories, apps: idList(src.apps, appsMax), hidden: idList(src.hidden, appsMax) }
}

function copyDefaults() {
    return defaultFolders.map((f) => folderNorm(f))
}

// The saved folders (JSON text). Empty or broken text gives Pop's defaults.
function foldersFrom(text) {
    let parsed = null
    try {
        parsed = JSON.parse(String(text || ""))
    } catch (e) {
        parsed = null
    }
    if (!Array.isArray(parsed))
        return copyDefaults()
    const out = []
    for (let i = 0; i < parsed.length && out.length < foldersMax; i++) {
        const f = folderNorm(parsed[i])
        if (f && !out.some((o) => o.name.toLowerCase() === f.name.toLowerCase()))
            out.push(f)
    }
    return out
}

function sameAsDefaults(folders) {
    return JSON.stringify(folders) === JSON.stringify(copyDefaults())
}

// app: { id, categories: [] }
function inFolder(app, folder) {
    if (!app || !folder)
        return false
    if (folder.hidden.indexOf(app.id) >= 0)
        return false
    if (folder.apps.indexOf(app.id) >= 0)
        return true
    const cats = app.categories || []
    for (let i = 0; i < folder.categories.length; i++) {
        if (cats.indexOf(folder.categories[i]) >= 0)
            return true
    }
    return false
}

function inAnyFolder(app, folders) {
    for (let i = 0; i < folders.length; i++) {
        if (inFolder(app, folders[i]))
            return true
    }
    return false
}

// The apps a view shows. folder -1 is Library Home: every app, or with
// hideFoldered only those in no folder (Pop's library).
function viewApps(apps, folders, folder, hideFoldered) {
    if (folder >= 0 && folder < folders.length)
        return apps.filter((a) => inFolder(a, folders[folder]))
    if (!hideFoldered)
        return apps.slice()
    return apps.filter((a) => !inAnyFolder(a, folders))
}

function cloneAll(folders) {
    return folders.map((f) => ({ name: f.name, categories: f.categories.slice(), apps: f.apps.slice(), hidden: f.hidden.slice() }))
}

// Each change returns a new list, or the same list when nothing changes.

function nameTaken(folders, name, except) {
    const want = nameNorm(name).toLowerCase()
    return folders.some((f, i) => i !== except && f.name.toLowerCase() === want)
}

// A free name like "New Folder 2".
function freeName(folders, base) {
    const b = nameNorm(base) || "New Folder"
    if (!nameTaken(folders, b, -1))
        return b
    for (let n = 2; n < 100; n++) {
        const candidate = nameNorm(b + " " + n)
        if (!nameTaken(folders, candidate, -1))
            return candidate
    }
    return b
}

function create(folders, name) {
    if (folders.length >= foldersMax)
        return folders
    const clean = freeName(folders, name)
    const next = cloneAll(folders)
    next.push({ name: clean, categories: [], apps: [], hidden: [] })
    return next
}

function rename(folders, index, name) {
    const clean = nameNorm(name)
    if (index < 0 || index >= folders.length || !clean.length || nameTaken(folders, clean, index))
        return folders
    const next = cloneAll(folders)
    next[index].name = clean
    return next
}

function remove(folders, index) {
    if (index < 0 || index >= folders.length)
        return folders
    const next = cloneAll(folders)
    next.splice(index, 1)
    return next
}

function move(folders, from, to) {
    if (from < 0 || from >= folders.length || to < 0 || to >= folders.length || from === to)
        return folders
    const next = cloneAll(folders)
    const item = next.splice(from, 1)[0]
    next.splice(to, 0, item)
    return next
}

function addApp(folders, index, app) {
    if (index < 0 || index >= folders.length || !app || inFolder(app, folders[index]))
        return folders
    const next = cloneAll(folders)
    const f = next[index]
    f.hidden = f.hidden.filter((id) => id !== app.id)
    if (!inFolder(app, f) && f.apps.length < appsMax)
        f.apps.push(app.id)
    return next
}

function removeApp(folders, index, app) {
    if (index < 0 || index >= folders.length || !app || !inFolder(app, folders[index]))
        return folders
    const next = cloneAll(folders)
    const f = next[index]
    f.apps = f.apps.filter((id) => id !== app.id)
    // Still in by category: remember it as taken out.
    if (inFolder(app, f) && f.hidden.length < appsMax)
        f.hidden.push(app.id)
    return next
}
