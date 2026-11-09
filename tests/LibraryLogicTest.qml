import QtQuick
import Quickshell
import qs.library
import "tests"

// The App Library's folder rules: Pop's defaults, membership by category
// or by hand, taking an app out, and folder edits.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const L = LibraryLogic
        const defaults = L.foldersFrom("")
        t.eq("Pop's three", defaults.map((f) => f.name), ["Office", "System", "Utilities"])
        t.ok("defaults saved as defaults", L.sameAsDefaults(defaults))
        t.eq("broken text gives defaults", L.foldersFrom("{oops").length, 3)
        t.eq("saved empty list stays empty", L.foldersFrom("[]").length, 0)
        t.eq("duplicate and nameless dropped", L.foldersFrom(JSON.stringify([{ name: "A" }, { name: "a" }, { name: " " }])).map((f) => f.name), ["A"])

        const writer = { id: "writer.desktop", categories: ["Office"] }
        const game = { id: "game.desktop", categories: ["Game"] }
        const apps = [writer, game]
        t.ok("in by category", L.inFolder(writer, defaults[0]))
        t.eq("Home hides foldered apps", L.viewApps(apps, defaults, -1, true).map((a) => a.id), ["game.desktop"])
        t.eq("Home can list every app", L.viewApps(apps, defaults, -1, false).length, 2)
        t.eq("a folder's apps", L.viewApps(apps, defaults, 0, true).map((a) => a.id), ["writer.desktop"])

        // Add by hand, take out (remembered when in by category), add back.
        let f = L.addApp(defaults, 1, game)
        t.ok("added by hand", L.inFolder(game, f[1]) && f[1].apps.indexOf("game.desktop") >= 0)
        t.ok("defaults untouched", !L.inFolder(game, defaults[1]))
        f = L.removeApp(f, 0, writer)
        t.ok("category app taken out", !L.inFolder(writer, f[0]) && f[0].hidden.indexOf("writer.desktop") >= 0)
        f = L.addApp(f, 0, writer)
        t.ok("and put back", L.inFolder(writer, f[0]) && f[0].hidden.length === 0)
        t.ok("adding twice changes nothing", L.addApp(f, 0, writer) === f)

        // Folder edits.
        let g = L.create(defaults, "Games")
        t.eq("created", g.map((x) => x.name), ["Office", "System", "Utilities", "Games"])
        t.eq("free name", L.create(g, "Games")[4].name, "Games 2")
        t.ok("rename to a taken name refused", L.rename(g, 3, "office") === g)
        t.eq("renamed", L.rename(g, 3, "  Play  ")[3].name, "Play")
        t.eq("moved", L.move(g, 3, 0).map((x) => x.name), ["Games", "Office", "System", "Utilities"])
        t.eq("removed", L.remove(g, 0).map((x) => x.name), ["System", "Utilities", "Games"])
        t.ok("bad index refused", L.remove(g, 9) === g && L.rename(g, -1, "x") === g)
        t.eq("long names cut", L.nameNorm("x".repeat(80)).length, L.nameMax)
        t.done()
    }
}
