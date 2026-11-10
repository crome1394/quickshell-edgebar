import QtQuick
import Quickshell
import qs.defaultapps
import "tests"

// Default apps: reading and rewriting mimeapps.list, which app opens a
// type, the common-task groups, and the problems check.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const L = DefaultAppsLogic
        const file = [
            "# my defaults",
            "[Added Associations]",
            "audio/*=mpv.desktop",
            "text/plain=code.desktop;draw.desktop;",
            "",
            "[Default Applications]",
            "text/plain=draw.desktop",
            "video/matroska=mpv.desktop",
            "video/x-matroska=mpv-2.desktop",
            "bad key=mpv.desktop",
            "x-scheme-handler/https=web.desktop;",
            "",
            "[Other]",
            "keep=me",
            ""
        ].join("\n")

        // Reading.
        const s = L.parse(file)
        t.eq("defaults read", Object.keys(s.defaults), ["text/plain", "video/matroska", "video/x-matroska", "x-scheme-handler/https"])
        t.eq("lists split", s.added["text/plain"], ["code.desktop", "draw.desktop"])
        t.ok("wildcard kept for the check", !!s.added["audio/*"])
        t.eq("bad ids dropped", L.splitIds("a.desktop; ;rm -rf;b.desktop;a.desktop"), ["a.desktop", "b.desktop"])
        t.eq("array-like lists kept", L.normalize({ added: { "a/b": { 0: "x.desktop", 1: "y.desktop", length: 2 } } }).added["a/b"], ["x.desktop", "y.desktop"])
        t.ok("normalize is stable", L.sameState(s, L.normalize(JSON.parse(JSON.stringify(s)))))

        // Rewriting touches only changed lines.
        t.eq("no change, same text", L.rewrite(file, s, s), file)
        let next = L.setDefault(s, "text/plain", ["code.desktop"])
        let text = L.rewrite(file, s, next)
        t.ok("changed line", text.indexOf("\ntext/plain=code.desktop;\n[") < 0 && text.indexOf("[Default Applications]\ntext/plain=code.desktop;") >= 0)
        t.ok("other lines kept", text.indexOf("# my defaults") === 0 && text.indexOf("bad key=mpv.desktop") >= 0 && text.indexOf("[Other]\nkeep=me") >= 0)
        t.ok("other section's same key kept", text.indexOf("[Added Associations]\naudio/*=mpv.desktop\ntext/plain=code.desktop;draw.desktop;") >= 0)
        next = L.setDefault(next, "image/png", ["view.desktop"])
        text = L.rewrite(file, s, next)
        t.ok("new key at the end of its section", text.indexOf("x-scheme-handler/https=web.desktop;\nimage/png=view.desktop;\n\n[Other]") >= 0)
        next = L.setDefault(next, "video/x-matroska", null)
        text = L.rewrite(file, s, next)
        t.ok("removed line gone", text.indexOf("x-matroska") < 0)
        t.ok("round trip", L.sameState(L.parse(text), next))
        const fresh = L.rewrite("", L.emptyState(), L.setDefault(L.emptyState(), "text/plain", ["code.desktop"]))
        t.eq("empty file gets a section", fresh, "[Default Applications]\ntext/plain=code.desktop;\n")
        const twice = "[Default Applications]\na/b=x.desktop\na/b=y.desktop\n"
        t.eq("repeated key written once", L.rewrite(twice, L.parse(twice), L.setDefault(L.parse(twice), "a/b", ["z.desktop"])), "[Default Applications]\na/b=z.desktop;\n")

        // Resolving.
        const apps = { "mpv.desktop": "mpv", "code.desktop": "Code", "draw.desktop": "Draw", "web.desktop": "Web", "view.desktop": "Viewer", "vlc.desktop": "VLC" }
        const ctx = {
            state: s,
            system: [{ defaults: { "image/png": ["view.desktop"] }, added: {} }],
            cache: L.mergeCaches([
                { "text/plain": ["code.desktop"], "video/matroska": ["vlc.desktop"], "application/x-drawing": ["draw.desktop"], "x-scheme-handler/http": ["web.desktop"] },
                L.parseCache("[MIME Cache]\nvideo/matroska=mpv.desktop;vlc.desktop;\nvideo/mp4=mpv.desktop;vlc.desktop;\nx-scheme-handler/https=web.desktop;\nimage/png=view.desktop;\n")
            ]),
            aliases: L.parseAliases("video/x-matroska video/matroska\n"),
            parents: L.parseParents("text/x-python application/x-executable\n"),
            installed: (id) => apps[id] !== undefined,
            nameOf: (id) => apps[id] || ""
        }
        t.eq("caches merged in order", ctx.cache["video/matroska"], ["vlc.desktop", "mpv.desktop"])
        t.eq("your default wins", L.resolve("video/matroska", ctx), { id: "mpv.desktop", source: "you" })
        t.eq("missing default falls through to the other name", L.resolve("video/x-matroska", ctx), { id: "mpv.desktop", source: "you" })
        t.eq("system default", L.resolve("image/png", ctx), { id: "view.desktop", source: "system" })
        t.eq("first app that opens it", L.resolve("video/mp4", ctx), { id: "mpv.desktop", source: "auto" })
        t.eq("nothing", L.resolve("font/ttf", ctx), { id: "", source: "" })
        const removed = Object.assign({}, ctx, { state: L.normalize({ removed: { "video/mp4": ["mpv.desktop"] } }) })
        t.eq("removed list skipped", L.resolve("video/mp4", removed).id, "vlc.desktop")
        t.ok("text types inherit plain text", L.ancestors("text/x-python", ctx).indexOf("text/plain") >= 0)
        t.ok("declares through a parent", L.declares("code.desktop", "text/x-python", ctx))

        // Groups.
        const video = L.groupById("video")
        const vs = L.groupState(video, ctx)
        t.ok("one app for video", !vs.mixed && vs.id === "mpv.desktop")
        t.eq("picker: same score sorts by name", L.candidates(video, ctx), ["mpv.desktop", "vlc.desktop"])
        const set = L.setGroup(s, video, "vlc.desktop", ctx)
        t.eq("group sets the types the app opens", Object.keys(set.defaults).filter((k) => k.indexOf("video/") === 0), ["video/matroska", "video/mp4", "video/x-matroska"])
        t.ok("mixed after one change", L.groupState(video, Object.assign({}, ctx, { state: L.setDefault(s, "video/mp4", ["vlc.desktop"]) })).mixed)
        t.ok("reset drops group lines only", Object.keys(L.resetGroups(s).defaults).join() === "")
        t.ok("reset keeps other lines", !!L.resetGroups(L.setDefault(s, "x-scheme-handler/steam", ["steam.desktop"])).defaults["x-scheme-handler/steam"])

        // One type.
        t.eq("type picker: declared, then parent's", L.typeCandidates("text/x-python", ctx), ["code.desktop"])
        t.ok("all types: known, caches, and yours", ["font/ttf", "video/mp4", "text/plain"].every((x) => L.allTypes(["font/ttf"], ctx).indexOf(x) >= 0))
        t.ok("all types leave out wildcards", L.allTypes([], ctx).indexOf("audio/*") < 0)
        t.eq("your types", L.yourTypes(s), ["text/plain", "video/matroska", "video/x-matroska", "x-scheme-handler/https"])
        t.eq("move up", L.moveAdded(s, "text/plain", "draw.desktop", -1).added["text/plain"], ["draw.desktop", "code.desktop"])
        t.eq("move past the end stays", L.moveAdded(s, "text/plain", "draw.desktop", 1).added["text/plain"], ["code.desktop", "draw.desktop"])
        t.eq("take out", L.moveAdded(s, "text/plain", "code.desktop", 0).added["text/plain"], ["draw.desktop"])
        t.ok("last one out drops the line", !L.moveAdded(L.moveAdded(s, "text/plain", "code.desktop", 0), "text/plain", "draw.desktop", 0).added["text/plain"])

        // Families and apps.
        t.eq("families", ["x-scheme-handler/https", "inode/directory", "text/x-python", "model/stl", "font/ttf"].map(L.familyOf), ["links", "folders", "text", "other", "font"])
        const rows = L.familyRows(["video/mp4", "text/plain", "video/webm"], { video: true }, false)
        t.eq("family rows: headers in order, open one listed", rows.map((r) => r.header ? "#" + r.family + r.count : r.type), ["#text1", "#video2", "video/mp4", "video/webm"])
        t.eq("searching opens every family", L.familyRows(["text/plain"], {}, true).length, 2)
        const sum = L.appsSummary(["video/mp4", "video/matroska", "text/plain"], ctx)
        const mpvRow = sum.filter((a) => a.id === "mpv.desktop")[0]
        t.eq("app defaults", mpvRow.defaults, ["video/mp4", "video/matroska"])
        const vlcRow = sum.filter((a) => a.id === "vlc.desktop")[0]
        t.eq("app can also open", vlcRow.others, ["video/matroska", "video/mp4"])
        t.ok("apps by name", sum.map((a) => a.id).indexOf("code.desktop") < sum.map((a) => a.id).indexOf("mpv.desktop"))

        // Problems.
        const found = L.problems(ctx, [])
        const kinds = found.map((p) => p.kind + " " + p.type)
        t.ok("missing app found", kinds.indexOf("missing video/x-matroska") >= 0)
        t.ok("wildcard found", kinds.indexOf("wildcard audio/*") >= 0)
        t.ok("odd default found", kinds.indexOf("odd text/plain") >= 0)
        t.ok("https to its own browser is fine", kinds.join().indexOf("https") < 0)
        const missing = found.filter((p) => p.kind === "missing")[0]
        t.eq("missing fix uses the other name's app", missing.edit, { section: "defaults", type: "video/x-matroska", ids: ["mpv.desktop"] })
        const odd = found.filter((p) => p.kind === "odd")[0]
        t.eq("odd fix", odd.fixLabel, "Use Code")
        t.ok("odd can be kept", odd.canKeep)
        const quiet = Object.assign({}, ctx, { state: L.normalize({ defaults: { "video/webm": ["mpv.desktop"], "x-scheme-handler/about": ["web.desktop"], "text/x-rust": ["nothing.desktop"] } }) })
        apps["nothing.desktop"] = "Declares nothing"
        t.eq("same family or nothing declared is not flagged", L.problems(quiet, []).filter((p) => p.kind === "odd").map((p) => p.type), [])
        t.ok("kept problems left out", L.problems(ctx, [odd.key]).every((p) => p.key !== odd.key))
        // Cards: one per missing app, one for all wildcards.
        const two = L.normalize(Object.assign({}, s, { added: Object.assign({}, s.added, { "image/*": ["view.desktop"], "video/mp4": ["mpv-2.desktop"] }) }))
        const cards = L.problemGroups(L.problems(Object.assign({}, ctx, { state: two }), []), ctx)
        const gone = cards.filter((c) => c.kind === "missing")
        t.eq("one card per missing app", gone.length, 1)
        t.eq("card lists its lines", gone[0].types, ["video/x-matroska", "video/mp4"])
        t.ok("card says who takes over", gone[0].note.indexOf("mpv") >= 0)
        t.eq("one wildcard card", cards.filter((c) => c.kind === "wildcard").map((c) => c.types), [["audio/*", "image/*"]])
        let cleaned = two
        for (const c of cards)
            cleaned = L.applyEdits(cleaned, c.edits)
        t.eq("cards fix everything", L.problems(Object.assign({}, ctx, { state: cleaned }), []).length, 0)
        t.eq("list text", L.listText(["a", "b", "c", "d", "e"], 3), "a, b, c and 2 more")

        let fixed = s
        for (const p of found)
            fixed = L.applyEdit(fixed, p.edit)
        const after = L.problems(Object.assign({}, ctx, { state: fixed }), [])
        t.eq("every fix clears its problem", after.map((p) => p.kind + " " + p.type), [])
        t.done()
    }
}
