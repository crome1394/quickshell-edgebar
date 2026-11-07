import QtQuick
import Quickshell
import qs.clipboard
import qs.services
import "tests"

// Clipboard: reading cliphist's list, entry kinds, search, and keys.
ShellRoot {
    Check { id: t }

    ClipModel { id: m }
    ClipKeys { id: keys }

    Component.onCompleted: {
        const S = ClipboardService
        const k = (p) => S.classify(p).kind
        t.eq("image", S.classify("[[ binary data 33 KiB png 800x600 ]]"), { kind: "image", detail: "33 KiB · 800x600" })
        t.eq("link", k("https://example.com/a?b=1"), "link")
        t.eq("link with spaces is text", k("see https://example.com now"), "text")
        t.eq("hex color", k("#1e1e2e"), "color")
        t.eq("rgb color", k("rgb(10, 20, 30)"), "color")
        t.eq("path", k("~/.config/quickshell/shell.qml"), "path")
        t.eq("absolute path", k("/usr/lib/qt6/qml"), "path")
        t.eq("code", k("const x = foo(); return x;"), "code")
        t.eq("shell command", k("$ git push origin main"), "code")
        t.eq("plain text", k("Meet at noon tomorrow"), "text")

        const list = S.parse("12\thello world\n11\t[[ binary data 2 KiB png 10x10 ]]\nbad line\nx\tnot an id\n9\thttps://a.example\n")
        t.eq("parse keeps good lines", list.map((e) => e.id), ["12", "11", "9"])
        t.eq("parse kinds", list.map((e) => e.kind), ["text", "image", "link"])
        t.ok("ids must be numbers", !S.idOk("1;rm -rf ~") && !S.idOk("") && S.idOk("42"))

        S.entries = list
        t.eq("no search shows all", m.filtered.length, 3)
        m.search = "HELLO"
        t.eq("search ignores case", m.filtered.map((e) => e.id), ["12"])
        m.search = "image"
        t.eq("search by kind", m.filtered.map((e) => e.id), ["11"])
        m.search = ""
        m.moveTo(5)
        t.eq("cursor stays in range", m.cursor, 2)
        t.eq("nth is 1-based", m.nth(1).id, "12")
        t.eq("nth past the end", m.nth(9), null)

        const press = (key, mods) => ({ key: key, modifiers: mods || 0 })
        t.eq("Enter copies", keys.actionFor(press(Qt.Key_Return)), "copy")
        t.eq("Alt+3 picks the third", keys.actionFor(press(Qt.Key_3, Qt.AltModifier)), "pick3")
        t.eq("plain 3 types", keys.actionFor(press(Qt.Key_3)), "")
        t.eq("Shift+Del deletes", keys.actionFor(press(Qt.Key_Delete, Qt.ShiftModifier)), "delete")
        t.eq("plain Del edits the search", keys.actionFor(press(Qt.Key_Delete)), "")
        t.eq("Ctrl+N moves down", keys.actionFor(press(Qt.Key_N, Qt.ControlModifier)), "down")
        t.eq("letters type", keys.actionFor(press(Qt.Key_J)), "")
        t.eq("Tab zooms", keys.actionFor(press(Qt.Key_Tab)), "zoom")
        t.eq("Alt+Z zooms", keys.actionFor(press(Qt.Key_Z, Qt.AltModifier)), "zoom")
        t.eq("plain z types", keys.actionFor(press(Qt.Key_Z)), "")
        t.done()
    }
}
