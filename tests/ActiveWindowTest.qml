import QtQuick
import Quickshell
import qs.config
import "tests"

// Active Window layout: every part once, unknown ids dropped, missing parts
// added at the end in the default order.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const S = ActiveWindowSettings
        t.eq("default order", S.layoutNorm(""), ["icon", "class", "title", "pid"])
        t.eq("custom order kept", S.layoutNorm(["pid", "class", "title", "icon"]), ["pid", "class", "title", "icon"])
        t.eq("unknown dropped, missing appended", S.layoutNorm(["title", "nope", "title"]), ["title", "icon", "class", "pid"])
        t.eq("json string", S.layoutNorm("[\"pid\",\"icon\",\"class\",\"title\"]"), ["pid", "icon", "class", "title"])
        t.eq("labels", [S.layoutLabel("icon"), S.layoutLabel("class"), S.layoutLabel("title"), S.layoutLabel("pid")], ["Icon", "Class", "Title", "PID"])
        t.done()
    }
}
