import QtQuick
import Quickshell
import qs.config
import "tests"

// Active Window layout and pattern: order, on/off, and marks around a part.
ShellRoot {
    Check { id: t }

    function countId(parts, id) {
        let n = 0
        for (let i = 0; i < parts.length; i++) {
            if (parts[i].id === id)
                n++
        }
        return n
    }

    Component.onCompleted: {
        const S = ActiveWindowSettings
        t.eq("default order", S.layoutNorm(""), ["icon", "class", "title", "pid"])
        t.eq("custom order kept", S.layoutNorm(["pid", "class", "title", "icon"]), ["pid", "class", "title", "icon"])
        t.eq("unknown dropped, missing appended", S.layoutNorm(["title", "nope", "title"]), ["title", "icon", "class", "pid"])
        t.eq("json string", S.layoutNorm("[\"pid\",\"icon\",\"class\",\"title\"]"), ["pid", "icon", "class", "title"])
        t.eq("labels", [S.layoutLabel("icon"), S.layoutLabel("class"), S.layoutLabel("title"), S.layoutLabel("pid")], ["Icon", "Class", "Title", "PID"])

        const off = S.formatModel("", "[\"icon\",\"class\",\"title\",\"pid\"]", false)
        t.eq("legacy pid off", S.formatText(off), "icon class title")
        t.eq("legacy pid flag", off[3].on, false)
        const on = S.formatModel("", "[\"icon\",\"class\",\"title\",\"pid\"]", true)
        t.eq("legacy pid on", S.formatText(on), "icon class title pid")
        t.eq("legacy pid on flag", on[3].on, true)
        t.eq("legacy order", S.formatText(S.formatModel("", ["pid", "class", "title", "icon"], true)), "pid class title icon")

        const wrapped = S.formatModel("icon [class] title (pid)")
        t.eq("pattern text", S.formatText(wrapped), "icon [class] title (pid)")
        t.eq("class open", wrapped[1].open, "[")
        t.eq("class close", wrapped[1].close, "]")
        t.eq("pid open", wrapped[3].open, "(")
        t.eq("pid close", wrapped[3].close, ")")
        t.eq("tight brackets", S.formatText(S.formatModel("icon[class]")), "icon[class]")
        t.eq("duplicate icon dropped", countId(S.formatModel("icon icon class"), "icon"), 1)
        t.eq("class inside a word", S.formatText(S.formatModel("myclass icon")), "myclass icon")

        const again = S.formatModel(S.formatJson(off), "[\"icon\",\"class\",\"title\",\"pid\"]", true)
        t.eq("saved pattern ignores old pid switch", again[3].on, false)
        t.eq("json round trip", S.formatText(S.formatModel(S.formatJson(wrapped))), "icon [class] title (pid)")

        const applied = S.formatApply("icon class title", wrapped)
        t.eq("pid stays off", applied[3].on, false)
        t.eq("pid paren kept", applied[3].open, "(")
        t.eq("text after drop", S.formatText(applied), "icon class title")
        t.eq("toggle pid back", S.formatText(S.formatToggle(applied, "pid")), "icon class title (pid)")

        const moved = S.formatMove(wrapped, 3, 0)
        t.eq("pid dragged first", S.formatText(moved), "(pid) icon [class] title")

        const samples = { icon: "◆", class: "app", title: "Window title", pid: "1000" }
        t.eq("plain skips empty pid", S.formatPlain(wrapped, { icon: "◆", class: "app", title: "Window title", pid: "" }), "◆ [app] Window title")
        t.eq("plain hides off pid", S.formatPlain(off, samples), "◆ app Window title")
        t.done()
    }
}
