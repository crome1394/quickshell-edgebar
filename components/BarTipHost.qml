import QtQuick
import Quickshell
import qs.services
import qs.theme

// Draws the shared bar tooltip (TipService) next to the item that asked
// for it, on the outer side of its bar. One instance lives in shell.qml.
// The label is measured once, without wrapping feedback, so sizing the
// popup never loops.
Item {
    id: root

    // Hidden for a frame when the target changes, so the popup re-anchors.
    property bool settled: false
    readonly property Item target: TipService.target

    onTargetChanged: {
        root.settled = false
        if (root.target)
            Qt.callLater(() => root.settled = root.target !== null)
    }

    // Point on the outer edge of the target's bar window, centered on the
    // target. It is worked out in window coordinates, then mapped into the
    // target's own coordinates (the anchor rect is relative to the anchor
    // item), which also undoes the 90° turn of pills on side bars.
    function place() {
        const item = root.target
        if (!item)
            return
        const content = item.Window.contentItem
        if (!content)
            return
        const box = item.mapToItem(content, 0, 0, item.width, item.height)
        const cx = box.x + box.width / 2
        const cy = box.y + box.height / 2
        const edge = TipService.edge
        let wx = cx
        let wy = content.height
        let flags = Edges.Bottom
        if (edge === "bottom") {
            wy = 0
            flags = Edges.Top
        } else if (edge === "left") {
            wx = content.width
            wy = cy
            flags = Edges.Right
        } else if (edge === "right") {
            wx = 0
            wy = cy
            flags = Edges.Left
        }
        const local = item.mapFromItem(content, wx, wy)
        const x = Math.round(local.x)
        const y = Math.round(local.y)
        const anchor = tipPopup.anchor
        // qmllint disable missing-property
        anchor.edges = flags
        anchor.gravity = flags
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    TextMetrics {
        id: measure
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
        text: TipService.message
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: tipPopup
        visible: root.settled && root.target !== null && TipService.message.length > 0
        color: "transparent"
        // qmllint disable missing-property
        implicitWidth: tipLabel.width + Theme.space * 2
        implicitHeight: tipLabel.implicitHeight + Theme.tabGap * 2
        anchor.item: root.target
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: Theme.pillBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                id: tipLabel
                x: Theme.space
                y: Theme.tabGap
                width: Math.min(Math.ceil(measure.advanceWidth) + 1, Theme.popupWidth)
                wrapMode: Text.WordWrap
                text: TipService.message
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: tipPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.place()
        }
    }
}
