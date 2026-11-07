import QtQuick
import Quickshell
import qs.config
import "tests"

// DisplaySettings arrangement helpers: logical sizes, snapping a dropped
// monitor to a free side, normalizing, and describing placement.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const D = DisplaySettings
        t.eq("logical size uses scale", D.logicalSize({ width: 3840, height: 2160, scale: 2, transform: 0 }), { w: 1920, h: 1080 })
        t.eq("portrait swaps sides", D.logicalSize({ width: 1920, height: 1080, scale: 1, transform: 1 }), { w: 1080, h: 1920 })

        const main = { x: 0, y: 0, w: 2560, h: 1440 }
        const side = { w: 1920, h: 1080 }
        t.eq("alone goes to 0,0", D.snap(Object.assign({ x: 900, y: 900 }, side), [], 160), { x: 0, y: 0 })
        t.eq("dropped right snaps right, tops aligned", D.snap(Object.assign({ x: 2700, y: 60 }, side), [main], 160), { x: 2560, y: 0 })
        t.eq("dropped left snaps left, height kept", D.snap(Object.assign({ x: -2100, y: 700 }, side), [main], 160), { x: -1920, y: 700 })
        t.eq("bottoms align when close", D.snap(Object.assign({ x: 2600, y: 330 }, side), [main], 160), { x: 2560, y: 360 })
        t.eq("dropped below snaps below", D.snap(Object.assign({ x: 900, y: 1600 }, side), [main], 160), { x: 900, y: 1440 })
        t.eq("near the center line it centers", D.snap(Object.assign({ x: 200, y: 1600 }, side), [main], 160), { x: 320, y: 1440 })
        t.eq("dropped above snaps above, centered when close", D.snap(Object.assign({ x: 380, y: -1200 }, side), [main], 160), { x: 320, y: -1080 })
        const third = { x: 2560, y: 0, w: 1920, h: 1080 }
        const spot = D.snap(Object.assign({ x: 2600, y: 100 }, side), [main, third], 160)
        t.ok("never overlaps a monitor", ![main, third].some((o) => D.overlaps(Object.assign({ w: 1920, h: 1080 }, spot), o)))
        t.eq("normalize moves the top-left to 0,0", D.normalized({ A: { x: -1920, y: 300 }, B: { x: 0, y: 0 } }), { A: { x: 0, y: 300 }, B: { x: 1920, y: 0 } })
        t.eq("relation right", D.relation(main, { x: 2560, y: 0, w: 10, h: 10 }), "right of")
        t.eq("relation above", D.relation(main, { x: 0, y: -10, w: 10, h: 10 }), "above")
        t.done()
    }
}
