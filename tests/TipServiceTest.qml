import QtQuick
import Quickshell
import qs.services
import "tests"

// TipService: one tip at a time, released only by its owner.
ShellRoot {
    Check { id: t }
    Item { id: a }
    Item { id: b }

    Component.onCompleted: {
        TipService.request(a, "A tip", "bottom")
        t.eq("request shows it", [TipService.target === a, TipService.message, TipService.edge], [true, "A tip", "bottom"])
        TipService.request(b, "B tip", "top")
        t.eq("a newer request takes over", [TipService.target === b, TipService.message], [true, "B tip"])
        TipService.release(a)
        t.eq("a stale release is ignored", TipService.target === b, true)
        TipService.release(b)
        t.eq("owner release hides it", [TipService.target, TipService.message], [null, ""])
        TipService.request(a, "", "top")
        t.eq("empty text is ignored", TipService.target, null)
        t.done()
    }
}
