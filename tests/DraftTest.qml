import QtQuick
import Quickshell
import qs.config
import "tests"

// Draft: the Apply / Undo / Reset behavior every settings page shares.
ShellRoot {
    Check { id: t }

    QtObject {
        id: fakeOwner
        property var saved: ({ a: 1, b: "x" })
        function snapshot() { return fakeOwner.saved }
        function normalize(o) { return { a: Math.max(0, Math.round(Number(o.a) || 0)), b: String(o.b || "") } }
        function commit(o) { fakeOwner.saved = fakeOwner.normalize(o) }
        function defaults() { return { a: 0, b: "" } }
    }

    Draft { id: d; owner: fakeOwner }

    Component.onCompleted: {
        t.eq("starts clean", [d.dirty, d.canUndo], [false, false])
        t.eq("value follows saved", d.value, { a: 1, b: "x" })
        d.set("a", 5)
        t.eq("edit makes it dirty", [d.dirty, d.value.a, fakeOwner.saved.a], [true, 5, 1])
        d.set("a", 1)
        t.eq("editing back is clean", d.dirty, false)
        d.set("a", -3)
        t.eq("normalize applies", d.value.a, 0)
        d.apply()
        t.eq("apply saves", [fakeOwner.saved.a, d.dirty, d.canUndo], [0, false, true])
        d.undo()
        t.eq("undo restores", fakeOwner.saved.a, 1)
        d.reset()
        t.eq("reset drafts defaults", [d.dirty, d.value], [true, { a: 0, b: "" }])
        d.undo()
        t.eq("undo drops the draft", [d.dirty, fakeOwner.saved.a], [false, 1])
        t.done()
    }
}
