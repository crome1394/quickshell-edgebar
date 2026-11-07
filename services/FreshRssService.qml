pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Talks to a FreshRSS server through its Google Reader API, with QML's own
// HTTP client: no curl, no scripts, no process while idle.
//
// Credentials come from ~/.config/freshrss-quickshell/freshrss.env:
//   FRESHRSS_BASE_URL=https://rss.example.com
//   FRESHRSS_USER=me
//   FRESHRSS_API_PASSWORD=…   (Profile → API password, not the login one)
// The file is read as KEY=value text (quotes and backslash escapes as in a
// shell), never run. saveServer() rewrites it atomically, mode 600.
//
// The unread badge checks every few minutes, only while the pill is on a
// bar or the reader is open. The login token stays in memory.
//
//   qs ipc call freshRss toggle | open | close | refresh
Singleton {
    id: root

    readonly property string home: String(Quickshell.env("HOME") || "")
    readonly property string envPath: root.home + "/.config/freshrss-quickshell/freshrss.env"
    readonly property string readTag: "user/-/state/com.google/read"
    readonly property string starTag: "user/-/state/com.google/starred"

    // From the env file.
    property string baseUrl: ""
    property string user: ""
    property string password: ""
    property bool envLoaded: false
    readonly property bool configured: root.baseUrl.length > 0 && root.user.length > 0 && root.password.length > 0

    // Reader window and the pills that show the badge.
    property bool open: false
    property int pillUsers: 0

    property int unread: 0
    property var feedUnread: ({})
    property var subscriptions: []
    property var items: []
    property bool loading: false
    property bool checking: false
    property string error: ""
    property string notice: ""
    property real loadedAt: 0

    // Login state.
    property string auth: ""
    property real authAt: 0
    property string editToken: ""
    property int generation: 0
    // Callers waiting for a login already in progress.
    property var authWaiters: []

    // Requests in flight, so a stuck one can be aborted.
    property var pending: []

    function toggle() {
        root.open = !root.open
    }

    function show() {
        root.open = true
    }

    function hide() {
        root.open = false
    }

    // ── Env file ────────────────────────────────────────────────────────
    // One value as a shell would read it (quoted parts, backslash escapes,
    // a trailing # comment), without running or expanding anything.
    function unquote(raw) {
        const v = String(raw || "").trim()
        let out = ""
        let i = 0
        while (i < v.length) {
            const c = v[i]
            if (c === "'") {
                const end = v.indexOf("'", i + 1)
                if (end < 0)
                    return out + v.substring(i + 1)
                out += v.substring(i + 1, end)
                i = end + 1
            } else if (c === "\"") {
                i++
                while (i < v.length && v[i] !== "\"") {
                    if (v[i] === "\\" && i + 1 < v.length && "\"\\$`".indexOf(v[i + 1]) >= 0)
                        i++
                    out += v[i]
                    i++
                }
                i++
            } else if (c === "\\") {
                if (i + 1 < v.length)
                    out += v[i + 1]
                i += 2
            } else if (/\s/.test(c)) {
                break
            } else {
                out += c
                i++
            }
        }
        return out
    }

    function parseEnv(text) {
        const out = {}
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const m = /^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=(.*)$/.exec(lines[i])
            if (m)
                out[m[1]] = root.unquote(m[2])
        }
        return out
    }

    function urlOk(url) {
        return /^https?:\/\/[^\s"'`<>\\]+$/.test(String(url || ""))
    }

    function lineOk(text) {
        return !/[\r\n\u0000]/.test(String(text || ""))
    }

    function cleanBase(url) {
        return String(url || "").trim().replace(/\/+$/, "").replace(/\/api\/greader\.php$/, "")
    }

    function applyEnv(text) {
        const env = root.parseEnv(text)
        const base = root.cleanBase(env.FRESHRSS_BASE_URL)
        root.baseUrl = root.urlOk(base) ? base : ""
        root.user = String(env.FRESHRSS_USER || "").trim()
        root.password = String(env.FRESHRSS_API_PASSWORD || "")
        root.envLoaded = true
        root.forgetLogin()
        if (root.configured && root.polling)
            root.checkUnread()
    }

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'"
    }

    // Write the env file. Returns an error message, or "" when the write
    // has started. The file is created mode 600 in a mode 700 folder.
    function saveServer(url, name, secret) {
        const base = root.cleanBase(url)
        if (!root.urlOk(base))
            return "The address must start with https:// (or http://) and have no spaces."
        if (!String(name || "").trim().length || !root.lineOk(name))
            return "Enter the FreshRSS user name."
        if (!root.lineOk(secret))
            return "The API password cannot contain line breaks."
        if (envWriter.running)
            return "Still saving the last change."
        envWriter.body = "# FreshRSS server for the Quickshell bar (Settings → Applications → FreshRSS).\n"
            + "# API password = FreshRSS Profile → API password, not the login password.\n"
            + "FRESHRSS_BASE_URL=" + root.shellQuote(base) + "\n"
            + "FRESHRSS_USER=" + root.shellQuote(String(name).trim()) + "\n"
            + "FRESHRSS_API_PASSWORD=" + root.shellQuote(String(secret || "")) + "\n"
        envWriter.running = true
        return ""
    }

    FileView {
        id: envFile
        path: root.envPath
        watchChanges: true
        printErrors: false
        onLoaded: root.applyEnv(envFile.text())
        onLoadFailed: root.applyEnv("")
        onFileChanged: envFile.reload()
    }

    // Fixed script; the path is an argument and the text arrives on stdin.
    Process {
        id: envWriter
        property string body: ""
        command: ["sh", "-c",
            "set -eu; d=$(dirname -- \"$1\"); mkdir -p -m 700 -- \"$d\"; umask 077; "
            + "t=$(mktemp -- \"$1.XXXXXX\"); cat > \"$t\"; chmod 600 -- \"$t\"; mv -f -- \"$t\" \"$1\"",
            "sh", root.envPath]
        stdinEnabled: true
        onStarted: {
            envWriter.write(envWriter.body)
            envWriter.stdinEnabled = false
        }
        onExited: (code) => {
            envWriter.body = ""
            envWriter.stdinEnabled = true
            root.notice = code === 0 ? "Saved the server settings." : ""
            root.error = code === 0 ? "" : "Could not write " + root.envPath + "."
            envFile.reload()
        }
    }

    // ── HTTP ────────────────────────────────────────────────────────────
    function form(fields) {
        const parts = []
        for (let i = 0; i < fields.length; i++)
            parts.push(encodeURIComponent(fields[i][0]) + "=" + encodeURIComponent(String(fields[i][1])))
        return parts.join("&")
    }

    // One request to `base`/api/greader.php`path`. done(status, text).
    function send(base, method, path, body, token, done) {
        const xhr = new XMLHttpRequest()
        const entry = { xhr: xhr, at: Date.now() }
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            root.pending = root.pending.filter((p) => p !== entry)
            done(xhr.status, xhr.responseText || "")
        }
        xhr.open(method, base + "/api/greader.php" + path)
        if (token.length)
            xhr.setRequestHeader("Authorization", "GoogleLogin auth=" + token)
        if (body !== null)
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        root.pending = root.pending.concat([entry])
        xhr.send(body === null ? undefined : body)
    }

    // Abort requests that ran past the time limit.
    Timer {
        interval: Theme.freshRssRequestMs / 4
        repeat: true
        running: root.pending.length > 0
        onTriggered: {
            const now = Date.now()
            const late = root.pending.filter((p) => now - p.at > Theme.freshRssRequestMs)
            for (let i = 0; i < late.length; i++)
                late[i].xhr.abort()
        }
    }

    function forgetLogin() {
        root.auth = ""
        root.authAt = 0
        root.editToken = ""
    }

    function loginText(status, text) {
        if (status === 0)
            return "Could not reach the server."
        if (status === 401 || status === 403)
            return "The server refused the user or API password. Use Profile → API password in FreshRSS, not the login password."
        if (status === 404)
            return "No Google Reader API at this address. Check the address and that the API is on (Settings → Authentication in FreshRSS)."
        return "Login failed (HTTP " + status + ")."
    }

    // Log in to `base` as `name`. done(token, message).
    function login(base, name, secret, done) {
        root.send(base, "POST", "/accounts/ClientLogin",
            root.form([["Email", name], ["Passwd", secret]]), "", (status, text) => {
                const m = /(?:^|\n)Auth=([^\s]+)/.exec(text)
                if (status === 200 && m)
                    done(m[1], "")
                else
                    done("", root.loginText(status, text))
            })
    }

    function withAuth(done) {
        if (!root.configured) {
            done(false)
            return
        }
        if (root.auth.length && Date.now() - root.authAt < Theme.freshRssAuthMs) {
            done(true)
            return
        }
        root.authWaiters = root.authWaiters.concat([done])
        if (root.authWaiters.length > 1)
            return
        root.login(root.baseUrl, root.user, root.password, (token, message) => {
            root.auth = token
            root.authAt = token.length ? Date.now() : 0
            root.editToken = ""
            if (!token.length)
                root.error = message
            const waiting = root.authWaiters
            root.authWaiters = []
            for (let i = 0; i < waiting.length; i++)
                waiting[i](token.length > 0)
        })
    }

    // An API call with login, retried once after a refused token.
    function api(method, path, body, done, retried) {
        root.withAuth((ok) => {
            if (!ok) {
                done(0, "")
                return
            }
            root.send(root.baseUrl, method, path, body, root.auth, (status, text) => {
                if (status === 401 && !retried) {
                    root.forgetLogin()
                    root.api(method, path, body, done, true)
                    return
                }
                done(status, text)
            })
        })
    }

    function parse(text) {
        try {
            return JSON.parse(text)
        } catch (e) {
            return null
        }
    }

    // Test a server without saving it. done(ok, message).
    function testServer(url, name, secret, done) {
        const base = root.cleanBase(url)
        if (!root.urlOk(base)) {
            done(false, "The address must start with https:// (or http://) and have no spaces.")
            return
        }
        root.login(base, String(name || "").trim(), String(secret || ""), (token, message) => {
            if (!token.length) {
                done(false, message)
                return
            }
            root.send(base, "GET", "/reader/api/0/subscription/list?output=json", null, token, (status, text) => {
                const data = root.parse(text)
                if (status === 200 && data && data.subscriptions)
                    done(true, "Connected: " + data.subscriptions.length + " feeds" + (base.startsWith("http://") ? ". The password is sent unencrypted over http://." : "."))
                else
                    done(false, "Logged in, but the feed list failed (HTTP " + status + ").")
            })
        })
    }

    // ── Unread badge ────────────────────────────────────────────────────
    readonly property bool polling: root.configured && (root.pillUsers > 0 || root.open)

    onPollingChanged: {
        if (root.polling)
            root.checkUnread()
    }

    function checkUnread() {
        if (!root.configured || root.checking)
            return
        root.checking = true
        root.api("GET", "/reader/api/0/unread-count?output=json", null, (status, text) => {
            root.checking = false
            const data = root.parse(text)
            if (status !== 200 || !data || !data.unreadcounts) {
                if (status !== 0)
                    root.error = "Unread check failed (HTTP " + status + ")."
                return
            }
            const map = {}
            let total = 0
            for (let i = 0; i < data.unreadcounts.length; i++) {
                const row = data.unreadcounts[i]
                const id = String(row.id || "")
                if (!id.startsWith("feed/"))
                    continue
                const n = Math.max(0, Math.round(Number(row.count)))
                map[id] = n
                total += n
            }
            root.feedUnread = map
            root.unread = total
            if (root.error.startsWith("Unread check"))
                root.error = ""
        })
    }

    Timer {
        interval: FreshRssSettings.pollMin() * 60000
        repeat: true
        running: root.polling
        onTriggered: root.checkUnread()
    }

    // ── Articles ────────────────────────────────────────────────────────
    // Article HTML for the reader: no scripts, frames, forms, or styles,
    // and images become links so nothing loads from the network.
    function cleanHtml(html) {
        let s = String(html || "")
        if (s.length > Theme.freshRssHtmlMax)
            s = s.substring(0, Theme.freshRssHtmlMax)
        s = s.replace(/<!--[\s\S]*?-->/g, "")
        s = s.replace(/<(script|style|iframe|object|embed|form|noscript|svg|video|audio)\b[\s\S]*?<\/\1\s*>/gi, "")
        s = s.replace(/<(script|style|iframe|object|embed|form|input|button|link|meta|base|source|track)\b[^>]*>/gi, "")
        s = s.replace(/<img\b[^>]*?\bsrc\s*=\s*["']?(https?:[^"'\s>]+)[^>]*>/gi, "<a href=\"$1\">[image]</a>")
        s = s.replace(/<img\b[^>]*>/gi, "")
        s = s.replace(/\s(on[a-z]+|style|class|id)\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)/gi, "")
        s = s.replace(/href\s*=\s*["']?\s*(javascript|data|vbscript):[^"'\s>]*["']?/gi, "href=\"#\"")
        return s
    }

    function plainText(html) {
        return String(html || "").replace(/<[^>]*>/g, " ").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'")
            .replace(/\s+/g, " ").trim()
    }

    function isVideoUrl(url) {
        return /^https?:\/\/(www\.|m\.)?(youtube\.com\/(watch|shorts|live)|youtu\.be\/|vimeo\.com\/\d|odysee\.com\/|rumble\.com\/v)/i.test(url)
            || /^https?:\/\/[^?#]+\.(mp4|m4v|webm|mkv|mov)(\?|#|$)/i.test(url)
    }

    function itemNorm(src, feedNames) {
        const cats = src.categories || []
        const href = (src.alternate && src.alternate[0] && src.alternate[0].href)
            || (src.canonical && src.canonical[0] && src.canonical[0].href) || ""
        const url = /^https?:\/\//i.test(href) ? href : ""
        const origin = src.origin || {}
        const feedId = String(origin.streamId || "")
        const encl = (src.enclosure || []).filter((e) => /^video\//.test(String(e.type || "")) && /^https?:\/\//.test(String(e.href || "")))
        const html = root.cleanHtml((src.content && src.content.content) || (src.summary && src.summary.content) || "")
        const plain = root.plainText(html)
        return {
            id: String(src.id || ""),
            title: root.plainText(src.title || "") || "(untitled)",
            feedId: feedId,
            feed: String(origin.title || feedNames[feedId] || "Feed"),
            author: String(src.author || ""),
            published: Math.round(Number(src.published) || Number(src.crawlTimeMsec) / 1000 || 0),
            url: url,
            videoUrl: encl.length ? String(encl[0].href) : (root.isVideoUrl(url) ? url : ""),
            read: cats.indexOf(root.readTag) >= 0,
            starred: cats.indexOf(root.starTag) >= 0,
            html: html,
            search: (String(src.title || "") + " " + String(origin.title || "") + " " + String(src.author || "") + " " + plain.substring(0, Theme.freshRssSearchTextMax)).toLowerCase()
        }
    }

    function streamPath(stream, count, since, extra) {
        return "/reader/api/0/stream/contents/" + encodeURIComponent(stream)
            + "?output=json&n=" + count + (since > 0 ? "&ot=" + since : "") + (extra || "")
    }

    // Load articles for a scope: unread | all | read | starred. Unread and
    // starred are one request each; all and read load each feed (perFeed
    // items) a few at a time, as the old bar did, so busy feeds do not
    // crowd out quiet ones. The server has no "read" stream, so read keeps
    // the read articles from each feed.
    function load(scope, maxDays, perFeed, itemLimit) {
        if (!root.configured) {
            root.error = "FreshRSS is not set up. Add the server in Settings → Applications → FreshRSS."
            return
        }
        const gen = ++root.generation
        const since = maxDays > 0 ? Math.floor(Date.now() / 1000) - maxDays * 86400 : 0
        root.loading = true
        root.error = ""
        root.api("GET", "/reader/api/0/subscription/list?output=json", null, (status, text) => {
            if (gen !== root.generation)
                return
            const data = root.parse(text)
            if (status !== 200 || !data || !data.subscriptions) {
                root.loading = false
                if (!root.error.length)
                    root.error = "Could not load the feed list (HTTP " + status + ")."
                return
            }
            const subs = []
            const names = {}
            for (let i = 0; i < data.subscriptions.length; i++) {
                const s = data.subscriptions[i]
                const cat = s.categories && s.categories[0] ? String(s.categories[0].label || "") : ""
                subs.push({ id: String(s.id || ""), title: String(s.title || s.id || ""), htmlUrl: String(s.htmlUrl || ""), category: cat })
                names[String(s.id || "")] = String(s.title || "")
            }
            root.subscriptions = subs
            if (scope === "unread" || scope === "starred") {
                const path = scope === "unread"
                    ? root.streamPath("user/-/state/com.google/reading-list", itemLimit, since, "&xt=" + encodeURIComponent(root.readTag))
                    : root.streamPath(root.starTag, itemLimit, since, "")
                root.api("GET", path, null, (st, body) => {
                    if (gen !== root.generation)
                        return
                    const d = root.parse(body)
                    root.finishLoad(gen, st === 200 && d ? (d.items || []).map((x) => root.itemNorm(x, names)) : null, st)
                })
                return
            }
            const queue = subs.slice()
            const found = []
            let running = 0
            let failed = 0
            const next = () => {
                if (gen !== root.generation)
                    return
                while (running < Theme.freshRssParallel && queue.length) {
                    const sub = queue.shift()
                    running++
                    root.api("GET", root.streamPath(sub.id, perFeed, since, ""), null, (st, body) => {
                        running--
                        const d = root.parse(body)
                        if (st === 200 && d) {
                            const list = (d.items || []).map((x) => root.itemNorm(x, names))
                            for (let k = 0; k < list.length; k++) {
                                if (scope !== "read" || list[k].read)
                                    found.push(list[k])
                            }
                        } else {
                            failed++
                        }
                        if (!queue.length && running === 0)
                            root.finishLoad(gen, found, failed && !found.length ? st : 200)
                        else
                            next()
                    })
                }
                if (!subs.length)
                    root.finishLoad(gen, [], 200)
            }
            next()
        })
    }

    function finishLoad(gen, list, status) {
        if (gen !== root.generation)
            return
        if (list === null || status !== 200) {
            if (!root.error.length)
                root.error = "Could not load articles (HTTP " + status + ")."
            root.loading = false
            return
        }
        list.sort((a, b) => b.published - a.published)
        root.items = list
        root.loadedAt = Date.now()
        root.loading = false
        root.checkUnread()
    }

    // ── Actions ─────────────────────────────────────────────────────────
    function withEditToken(done) {
        if (root.editToken.length) {
            done(true)
            return
        }
        root.api("GET", "/reader/api/0/token", null, (status, text) => {
            root.editToken = status === 200 ? String(text).trim() : ""
            done(root.editToken.length > 0)
        })
    }

    function update(ids, change) {
        const set = {}
        for (let i = 0; i < ids.length; i++)
            set[ids[i]] = true
        root.items = root.items.map((it) => set[it.id] ? Object.assign({}, it, change) : it)
    }

    // Add or remove a tag on articles. Local state changes at once and
    // goes back if the server refuses.
    function tag(list, tagName, add, field) {
        const ids = list.filter((it) => it && it.id.length).map((it) => it.id)
        if (!ids.length)
            return
        const change = {}
        change[field] = add
        const undo = {}
        undo[field] = !add
        root.update(ids, change)
        root.withEditToken((ok) => {
            if (!ok) {
                root.update(ids, undo)
                root.error = "This server does not allow changes with these credentials."
                return
            }
            const fields = [["T", root.editToken], [add ? "a" : "r", tagName]]
            for (let i = 0; i < ids.length; i++)
                fields.push(["i", ids[i]])
            root.api("POST", "/reader/api/0/edit-tag", root.form(fields), (status) => {
                if (status !== 200) {
                    root.editToken = ""
                    root.update(ids, undo)
                    root.error = "The server did not save the change (HTTP " + status + ")."
                    return
                }
                root.checkUnread()
            })
        })
    }

    function setRead(item, read) {
        if (item && item.read !== read)
            root.tag([item], root.readTag, read, "read")
    }

    function setStarred(item, starred) {
        if (item && item.starred !== starred)
            root.tag([item], root.starTag, starred, "starred")
    }

    // Every article in a feed read on the server (not only those loaded).
    function markFeedRead(feedId) {
        if (!/^feed\/\d+$/.test(String(feedId || "")))
            return
        root.update(root.items.filter((it) => it.feedId === feedId).map((it) => it.id), { read: true })
        root.withEditToken((ok) => {
            if (!ok)
                return
            const body = root.form([["T", root.editToken], ["s", feedId], ["ts", String(Date.now() * 1000)]])
            root.api("POST", "/reader/api/0/mark-all-as-read", body, (status) => {
                if (status !== 200)
                    root.error = "The server did not mark the feed read (HTTP " + status + ")."
                root.checkUnread()
            })
        })
    }

    // The loaded articles of a feed back to unread.
    function markFeedUnread(feedId) {
        root.tag(root.items.filter((it) => it.feedId === feedId && it.read), root.readTag, false, "read")
    }

    function openInBrowser(url) {
        if (/^https?:\/\//i.test(String(url || "")))
            Qt.openUrlExternally(url)
    }

    function playInMpv(url) {
        if (!/^https?:\/\//i.test(String(url || "")))
            return false
        Quickshell.execDetached(["mpv", "--force-window=immediate", "--", String(url)])
        return true
    }

    function copyLink(url) {
        if (String(url || "").length)
            Quickshell.clipboardText = String(url)
    }

    // qs ipc call freshRss toggle    open or close the reader (same as the pill)
    // qs ipc call freshRss open | close
    // qs ipc call freshRss refresh   check the unread count now
    IpcHandler {
        target: "freshRss"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
        function refresh(): void { root.checkUnread() }
    }
}
