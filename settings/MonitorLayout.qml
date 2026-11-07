pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// Settings → System → Display → Arrangement. The enabled monitors drawn to
// scale where Hyprland places them. Drag one next to another: on release it
// snaps to the nearest free side (left, right, above, below), edges lined
// up when close. Apply tries the arrangement (with Keep or Go back, like a
// mode change); Reset drops the draft.
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

    // Fixed while dragging so the canvas does not rescale under the pointer.
    property var view: ({ k: 1, ox: 0, oy: 0 })

    function fit() {
        const names = Object.keys(root.rects)
        if (!names.length || canvas.width <= 0)
            return
        const r = names.map((n) => root.rects[n])
        // Room around the monitors to drag into: one largest monitor each side.
        const spare = Math.max.apply(null, r.map((x) => Math.max(x.w, x.h)))
        const minX = Math.min.apply(null, r.map((x) => x.x)) - spare
        const minY = Math.min.apply(null, r.map((x) => x.y)) - spare / 2
        const maxX = Math.max.apply(null, r.map((x) => x.x + x.w)) + spare
        const maxY = Math.max.apply(null, r.map((x) => x.y + x.h)) + spare / 2
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

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: screen.modelData.name
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
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
