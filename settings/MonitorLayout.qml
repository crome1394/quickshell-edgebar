pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → System → Display → Arrangement. The enabled monitors drawn to
// scale where Hyprland places them. Drag one next to another: on release it
// snaps to the nearest free side (left, right, above, below), edges lined
// up when close. A green line marks where two monitors touch: the pointer
// can cross only there. Apply tries the arrangement (with Keep or Go back,
// like a mode change); Reset drops the draft.
Column {
    id: root

    // Enabled monitors from DisplayService.
    required property var monitors
    // The monitor picked above, highlighted here.
    property string selected: ""

    signal picked(string name)

    // name → { x, y } while arranging; empty follows the live layout.
    property var draft: ({})
    property bool dragging: false

    readonly property var rects: {
        const out = {}
        for (let i = 0; i < root.monitors.length; i++) {
            const m = root.monitors[i]
            const size = DisplaySettings.logicalSize(m)
            const at = root.draft[m.name] || { x: m.x, y: m.y }
            out[m.name] = { x: at.x, y: at.y, w: size.w, h: size.h }
        }
        return out
    }
    readonly property bool changed: Object.keys(root.draft).some((name) => {
        const m = root.monitors.find((x) => x.name === name)
        return m && (root.draft[name].x !== m.x || root.draft[name].y !== m.y)
    })

    // Where two monitors touch: { a, b, vertical, at, from, to, aLen, bLen }
    // in layout pixels. The pointer crosses between them only along it.
    readonly property var joins: {
        const names = Object.keys(root.rects)
        const out = []
        const near = (p, q) => Math.abs(p - q) < 1
        for (let i = 0; i < names.length; i++) {
            for (let j = i + 1; j < names.length; j++) {
                const a = root.rects[names[i]]
                const b = root.rects[names[j]]
                if (near(a.x + a.w, b.x) || near(b.x + b.w, a.x)) {
                    const from = Math.max(a.y, b.y)
                    const to = Math.min(a.y + a.h, b.y + b.h)
                    if (to > from)
                        out.push({ a: names[i], b: names[j], vertical: true, at: near(a.x + a.w, b.x) ? b.x : a.x, from: from, to: to, aLen: a.h, bLen: b.h })
                } else if (near(a.y + a.h, b.y) || near(b.y + b.h, a.y)) {
                    const from = Math.max(a.x, b.x)
                    const to = Math.min(a.x + a.w, b.x + b.w)
                    if (to > from)
                        out.push({ a: names[i], b: names[j], vertical: false, at: near(a.y + a.h, b.y) ? b.y : a.y, from: from, to: to, aLen: a.w, bLen: b.w })
                }
            }
        }
        return out
    }

    function joinText(j) {
        const len = Math.round(j.to - j.from)
        const side = (name, total) => len >= Math.round(total) ? "all of " + name + "'s " + Math.round(total) : len + " of " + name + "'s " + Math.round(total)
        return "The pointer crosses between " + j.a + " and " + j.b + " along " + len + " px (" + side(j.a, j.aLen) + ", " + side(j.b, j.bLen) + ")."
    }

    // Fixed while dragging so the canvas does not rescale under the pointer.
    property var view: ({ k: 1, ox: 0, oy: 0 })

    function fit() {
        const names = Object.keys(root.rects)
        if (!names.length || canvas.width <= 0)
            return
        const r = names.map((n) => root.rects[n])
        // Room around the monitors to drag into: a third of the smallest
        // monitor each side, so the monitors themselves stay large.
        const spareX = Math.min.apply(null, r.map((x) => x.w)) / 3
        const spareY = Math.min.apply(null, r.map((x) => x.h)) / 3
        const minX = Math.min.apply(null, r.map((x) => x.x)) - spareX
        const minY = Math.min.apply(null, r.map((x) => x.y)) - spareY
        const maxX = Math.max.apply(null, r.map((x) => x.x + x.w)) + spareX
        const maxY = Math.max.apply(null, r.map((x) => x.y + x.h)) + spareY
        const k = Math.min(canvas.width / (maxX - minX), canvas.height / (maxY - minY))
        root.view = {
            k: k,
            ox: (canvas.width - (maxX - minX) * k) / 2 - minX * k,
            oy: (canvas.height - (maxY - minY) * k) / 2 - minY * k
        }
    }

    function drop(name, px, py) {
        const me = root.rects[name]
        const others = Object.keys(root.rects).filter((n) => n !== name).map((n) => root.rects[n])
        const want = { x: (px - root.view.ox) / root.view.k, y: (py - root.view.oy) / root.view.k, w: me.w, h: me.h }
        const spot = DisplaySettings.snap(want, others, Theme.displaySnapPx)
        const next = {}
        for (const n in root.rects)
            next[n] = { x: root.rects[n].x, y: root.rects[n].y }
        next[name] = spot
        root.draft = next
    }

    function reset() {
        root.draft = ({})
        Qt.callLater(root.fit)
    }

    onMonitorsChanged: {
        if (!root.dragging)
            root.reset()
    }

    spacing: Theme.space

    Rectangle {
        id: canvas
        width: parent.width
        height: Theme.displayLayoutHeight
        radius: Theme.radius
        color: Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        onWidthChanged: root.fit()
        Component.onCompleted: root.fit()

        Repeater {
            model: root.monitors
            delegate: Rectangle {
                id: screen
                required property var modelData
                readonly property var rect: root.rects[screen.modelData.name] || { x: 0, y: 0, w: 1, h: 1 }
                readonly property bool chosen: screen.modelData.name === root.selected

                x: root.view.ox + screen.rect.x * root.view.k
                y: root.view.oy + screen.rect.y * root.view.k
                width: Math.max(1, screen.rect.w * root.view.k)
                height: Math.max(1, screen.rect.h * root.view.k)
                z: drag.active ? 2 : 1
                radius: Theme.radiusSm
                color: screen.chosen ? Theme.accentDim : Theme.pillBg
                border.width: Theme.borderWidth * (screen.chosen ? 2 : 1)
                border.color: screen.chosen || drag.active ? Theme.accent : Theme.border

                Column {
                    anchors.centerIn: parent
                    width: parent.width - Theme.tabGap * 2
                    spacing: 0

                    // Shrinks to fit a small monitor instead of cutting off.
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.smallPx - 2
                        text: screen.modelData.name
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.smallPx - 3
                        text: screen.modelData.width + " × " + screen.modelData.height
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }

                DragHandler {
                    id: drag
                    enabled: root.monitors.length > 1 && !DisplayService.pending
                    cursorShape: Qt.ClosedHandCursor
                    onActiveChanged: {
                        if (drag.active) {
                            root.dragging = true
                        } else {
                            root.drop(screen.modelData.name, screen.x, screen.y)
                            root.dragging = false
                            // Dragging replaced the position bindings; follow the layout again.
                            screen.x = Qt.binding(() => root.view.ox + screen.rect.x * root.view.k)
                            screen.y = Qt.binding(() => root.view.oy + screen.rect.y * root.view.k)
                        }
                    }
                }

                TapHandler {
                    onTapped: root.picked(screen.modelData.name)
                }

                HoverHandler {
                    cursorShape: root.monitors.length > 1 ? Qt.OpenHandCursor : Qt.ArrowCursor
                }
            }
        }

        // The shared edges, drawn over the monitors.
        Repeater {
            model: root.dragging ? [] : root.joins
            delegate: Rectangle {
                id: join
                required property var modelData
                z: 3
                color: Theme.ok
                radius: Theme.displayJoinPx / 2
                x: join.modelData.vertical
                    ? root.view.ox + join.modelData.at * root.view.k - Theme.displayJoinPx / 2
                    : root.view.ox + join.modelData.from * root.view.k
                y: join.modelData.vertical
                    ? root.view.oy + join.modelData.from * root.view.k
                    : root.view.oy + join.modelData.at * root.view.k - Theme.displayJoinPx / 2
                width: join.modelData.vertical ? Theme.displayJoinPx : (join.modelData.to - join.modelData.from) * root.view.k
                height: join.modelData.vertical ? (join.modelData.to - join.modelData.from) * root.view.k : Theme.displayJoinPx
            }
        }

        Text {
            visible: root.monitors.length < 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.space
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.monitors.length ? "Connect another monitor to arrange them." : "No monitors to show."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    // How the picked monitor sits next to the others, in words.
    Text {
        visible: root.monitors.length > 1 && text.length > 0
        width: parent.width
        wrapMode: Text.WordWrap
        text: {
            const me = root.rects[root.selected]
            if (!me)
                return ""
            const parts = []
            for (const n in root.rects) {
                if (n === root.selected)
                    continue
                const rel = DisplaySettings.relation(root.rects[n], me)
                if (rel.length)
                    parts.push(rel + " " + n)
            }
            return parts.length ? root.selected + " is " + parts.join(", ") + "." : ""
        }
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    // Where the pointer can cross, in words; the green lines above.
    Repeater {
        model: root.monitors.length > 1 ? root.joins : []
        delegate: Text {
            required property var modelData
            width: root.width
            wrapMode: Text.WordWrap
            text: root.joinText(modelData)
            color: Theme.ok
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    // A monitor that touches none: the pointer can never reach it.
    Repeater {
        model: root.monitors.length > 1 ? Object.keys(root.rects).filter((n) => !root.joins.some((j) => j.a === n || j.b === n)) : []
        delegate: Text {
            required property string modelData
            width: root.width
            wrapMode: Text.WordWrap
            text: modelData + " touches no other monitor, so the pointer cannot reach it. Drag it against one."
            color: Theme.danger
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    Row {
        visible: root.monitors.length > 1
        spacing: Theme.tabGap

        ChipButton {
            label: "Apply arrangement"
            bold: true
            active: root.changed
            enabled: root.changed && !DisplayService.pending && !DisplayService.busy
            tip: "Try this arrangement; keep it or go back in the window that opens"
            onClicked: DisplayService.applyLayout(DisplaySettings.normalized(root.draft))
        }

        ChipButton {
            label: "Reset"
            enabled: root.changed
            tip: "Back to the current arrangement"
            onClicked: root.reset()
        }
    }
}
