import QtQuick
import Quickshell
import qs.search
import "tests"

// The launcher's search rules: Pop Launcher prefixes, match scores,
// history, web shortcuts, paths, script headers, and recent files.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        // Prefixes pick a mode; a mode that is off falls back to default.
        const on = {}
        t.eq("plain text is default", SearchLogic.parseQuery("fire", on), { mode: "default", rest: "fire" })
        t.eq("= is the calculator", SearchLogic.parseQuery("= 2+2", on), { mode: "calc", rest: " 2+2" })
        t.eq("~ keeps the path", SearchLogic.parseQuery("~/Doc", on), { mode: "files", rest: "~/Doc" })
        t.eq("/ keeps the path", SearchLogic.parseQuery("/etc", on).mode, "files")
        t.eq("find", SearchLogic.parseQuery("find resume", on), { mode: "find", rest: "resume" })
        t.eq("recent", SearchLogic.parseQuery("recent pdf", on), { mode: "recent", rest: "pdf" })
        t.eq("t: runs in a terminal", SearchLogic.parseQuery("t: htop", on), { mode: "terminal", rest: " htop" })
        t.eq(": runs in a terminal", SearchLogic.parseQuery(":ls", on).mode, "terminal")
        t.eq("run is background", SearchLogic.parseQuery("run notify-send hi", on), { mode: "background", rest: "notify-send hi" })
        t.eq("? is help", SearchLogic.parseQuery("?", on).mode, "help")
        t.eq("finder is not find", SearchLogic.parseQuery("finder", on).mode, "default")
        t.eq("off falls back", SearchLogic.parseQuery("= 2", { calc: false }).mode, "default")
        t.eq("help hides off modes", SearchLogic.helpRows({ web: false }).some((r) => r.plugin === "web"), false)

        // Arithmetic is spotted the way Pop's calculator spots it.
        t.eq("math", [SearchLogic.looksLikeMath("2+2"), SearchLogic.looksLikeMath("-5*3"), SearchLogic.looksLikeMath("(1+2)")], [true, true, true])
        t.eq("not math", [SearchLogic.looksLikeMath("firefox"), SearchLogic.looksLikeMath("-"), SearchLogic.looksLikeMath("")], [false, false, false])

        // Scores: whole > start > word start > inside; loose only on names.
        const s = (q, text, loose) => SearchLogic.wordScore(q, text, loose)
        t.ok("whole beats start", s("fire", "fire") > s("fire", "firefox"))
        t.ok("start beats word", s("fox", "foxit") > s("fox", "fire fox"))
        t.ok("word beats inside", s("fox", "fire fox") > s("fox", "firefox"))
        t.eq("loose letters only when asked", [s("ffx", "firefox", true) > 0, s("ffx", "firefox", false)], [true, 0])
        const firefox = { name: "Firefox", genericName: "Web Browser", keywords: ["internet"], program: "firefox", comment: "Browse the web" }
        const printer = { name: "Print Settings", genericName: "", keywords: [], program: "system-config-printer", comment: "Configure printers" }
        t.ok("name match", SearchLogic.appScore("fire", firefox) > 0)
        t.eq("no loose match in a program or comment", SearchLogic.appScore("fire", printer), 0)
        t.ok("every word must match", SearchLogic.appScore("web browser", firefox) > 0 && SearchLogic.appScore("web zzz", firefox) === 0)
        t.ok("accents fold", SearchLogic.appScore("cafe", { name: "Café", keywords: [] }) > 0)

        // History: more and newer launches rank higher, capped.
        let h = SearchLogic.historyAdd({}, "app:a", 1000)
        h = SearchLogic.historyAdd(h, "app:a", 2000)
        t.eq("history counts", h["app:a"], { n: 2, t: 2000 })
        t.ok("recent beats old", SearchLogic.historyBonus({ n: 3, t: 0 }, 86400000) > SearchLogic.historyBonus({ n: 3, t: 0 }, 86400000 * 60))
        t.ok("bonus is capped", SearchLogic.historyBonus({ n: 99999, t: 1 }, 1) <= 30)
        t.eq("trim keeps the newest", Object.keys(SearchLogic.historyTrim({ a: { n: 1, t: 1 }, b: { n: 1, t: 3 }, c: { n: 1, t: 2 } }, 2)).sort(), ["b", "c"])
        t.eq("history drops bad records", SearchLogic.historyNorm({ ok: { n: 2, t: 5 }, bad: { n: -1, t: 5 }, junk: 3 }), { ok: { n: 2, t: 5 } })

        // Web shortcuts.
        const rules = SearchLogic.webRulesFrom("")
        t.ok("defaults when empty", rules.length === SearchLogic.defaultWebRules.length)
        const m = SearchLogic.webMatches("ddg pop launcher", rules)
        t.eq("ddg match", [m.length, m[0].url], [1, "https://duckduckgo.com/?q=pop%20launcher"])
        t.eq("shortcut alone is no match", SearchLogic.webMatches("ddg", rules).length, 0)
        t.eq("www opens the site", SearchLogic.webMatches("www example.com/a b", rules)[0].url, "https://example.com/ab")
        t.eq("words are encoded", SearchLogic.webMatches("gh a&b", rules)[0].url, "https://github.com/search?q=a%26b")
        t.eq("bad scheme refused", SearchLogic.webRuleNorm({ prefixes: "x", name: "X", url: "javascript:alert(1)://" }), null)
        t.eq("bad prefix refused", SearchLogic.webRuleNorm({ prefixes: "Bad Prefix!", name: "X", url: "x.com/?q=" }), null)
        t.eq("prefix text splits", SearchLogic.webRuleNorm({ prefixes: "a, b", name: "AB", url: "ab.com/?q=" }).prefixes, ["a", "b"])
        t.eq("saved list read", SearchLogic.webRulesFrom(JSON.stringify([{ prefixes: ["z"], name: "Z", url: "z.com/?q=" }, { junk: 1 }])).length, 1)

        // Paths.
        t.eq("~ expands", SearchLogic.pathParts("~/Doc", "/home/me"), { dir: "/home/me/", base: "Doc" })
        t.eq("~ alone is home", SearchLogic.pathParts("~", "/home/me"), { dir: "/home/me/", base: "" })
        t.eq("absolute", SearchLogic.pathParts("/etc/hos", "/home/me"), { dir: "/etc/", base: "hos" })
        t.eq("tilde back", SearchLogic.tildePath("/home/me/x", "/home/me"), "~/x")
        t.eq("not home", SearchLogic.tildePath("/home/meow", "/home/me"), "/home/meow")

        // Pop Launcher script headers.
        const head = SearchLogic.scriptHeader("#!/bin/sh\n# name: VPN\n# icon: network-vpn\n# description: Start the VPN\n# keywords: vpn start\necho hi\n# name: not this")
        t.eq("script header", head, { name: "VPN", icon: "network-vpn", description: "Start the VPN", keywords: ["vpn", "start"] })

        // Recent files: local files only, newest first.
        const xbel = "<xbel><bookmark href=\"file:///home/me/a%20b.txt\" modified=\"2026-01-02T00:00:00Z\"></bookmark>"
            + "<bookmark href=\"https://x.org/\" modified=\"2026-05-01T00:00:00Z\"></bookmark>"
            + "<bookmark href=\"file:///home/me/new.pdf\" modified=\"2026-03-01T00:00:00Z\"></bookmark></xbel>"
        const recent = SearchLogic.recentFiles(xbel, 10)
        t.eq("recent files", recent.map((r) => r.path), ["/home/me/new.pdf", "/home/me/a b.txt"])

        // Order: priority, then score.
        t.eq("sort", SearchLogic.sortResults([{ name: "a", score: 5 }, { name: "b", score: 9 }, { name: "c", priority: 3, score: 1 }]).map((r) => r.name), ["c", "b", "a"])
        t.done()
    }
}
