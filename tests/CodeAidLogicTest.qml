import QtQuick
import Quickshell
import qs.codeaid
import "tests"

// Code Aid's snippet rules: the file format, labels, blanks, search, and
// grouping by language.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const L = CodeAidLogic

        // The rofi-code-aid file format.
        const s = L.parse("bash · for loop\n---\nfor x in y; do\n  :\ndone\n")
        t.eq("parse", [s.label, s.language, s.name, s.body], ["bash · for loop", "bash", "for loop", "for x in y; do\n  :\ndone"])
        t.eq("no separator", L.parse("label\nbody"), null)
        t.eq("no label", L.parse("---\nbody"), null)
        t.eq("empty body", L.parse("css · x\n---").body, "")
        t.eq("separator after notes", L.parse("sql · x\nnotes\n---\nSELECT 1;").body, "SELECT 1;")
        t.eq("windows line ends", L.parse("lua · x\r\n---\r\nend\r\n").body, "end")
        t.eq("label without dot", L.splitLabel("loose"), { language: "other", name: "loose" })
        t.eq("make label", L.makeLabel("  Bash ", " for   loop "), "bash · for loop")
        t.eq("round trip", L.parse(L.serialize("qml · item", "Item {\n}")).body, "Item {\n}")
        t.eq("file ends in a newline", L.serialize("a · b", "x\n"), "a · b\n---\nx\n")
        t.eq("file name", L.fileName("c / c++ · disable a block (#if 0)"), "c-disable-a-block-if-0")
        t.ok("file names it writes", L.fileNameOk("bash-for") && !L.fileNameOk("../x") && !L.fileNameOk(".hidden") && !L.fileNameOk("a b"))

        // Blanks.
        const body = "struct {{Name}} {\n    {{field:value}}: i32,\n}\nimpl {{Name}} {}\n{{clipboard}}"
        t.eq("blanks once each, in order", L.fields(body).map((f) => [f.name, f.def, f.clipboard]),
            [["Name", "", false], ["field", "value", false], ["clipboard", "", true]])
        t.eq("fill typed, default, name", L.fill(body, { Name: "Point" }, "copied\n"),
            "struct Point {\n    value: i32,\n}\nimpl Point {}\ncopied")
        t.eq("unfilled blank shows its name", L.fill("{{Name}}", {}, ""), "Name")
        t.eq("case counts", L.fields("{{name}} {{Name}}").length, 2)
        t.eq("bash braces are not blanks", L.fields("echo \"${items[@]}\" ${#x}").length, 0)
        t.eq("blank inside bash braces", L.fill("\"${{{list:items}}[@]}\"", {}, ""), "\"${items[@]}\"")
        t.eq("dollar then blank", L.fill("\"${{var:choice}}\"", { var: "x" }, ""), "\"$x\"")

        // Search: name first, then language, then code.
        const a = { name: "for loop", language: "bash", body: "done" }
        const b = { name: "struct", language: "rust", body: "for item" }
        t.ok("name beats code", L.score("for", a) > L.score("for", b))
        t.ok("language matches", L.score("rust", b) > 0)
        t.eq("every word must match", L.score("for zzz", a), 0)
        t.eq("empty matches all", L.score("", a), 1)

        // Groups in rofi-code-aid's order; unknown languages after, by name.
        const g = L.group([{ language: "sql", name: "b" }, { language: "zig", name: "a" }, { language: "bash", name: "z" }, { language: "bash", name: "a" }])
        t.eq("group order", g.map((x) => x.title), ["Bash", "SQL", "Zig"])
        t.eq("sorted in a group", g[0].snips.map((x) => x.name), ["a", "z"])
        t.done()
    }
}
