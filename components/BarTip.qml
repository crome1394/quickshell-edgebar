import QtQuick
import Quickshell
import qs.theme

// Hover tip for a bar widget. A Qt ToolTip is clipped by the bar window and
// lands on the widget. This is a separate layer, outside the bar: below a top
// bar, above a bottom bar, to the right of a left bar, and to the left of a
// right bar.
Item {
    id: root

    property string edge: "top"
    required property string message
    required property bool show

    property bool armed: false

    width: 0
    height: 0

    function sync() {
        if (root.show && root.message.length > 0) {
            if (!root.armed && !delay.running)
                delay.restart()
            return
        }
        delay.stop()
        root.armed = false
    }

    // Point on the outer edge of the bar window, centered on this widget.
    function place() {
        const anchorItem = root.parent
        if (!anchorItem)
            return
        const content = anchorItem.Window.contentItem
        if (!content)
            return
        const bounds = anchorItem.mapToItem(content, 0, 0, anchorItem.width, anchorItem.height)
        const cx = Math.round(bounds.x + bounds.width / 2)
        const cy = Math.round(bounds.y + bounds.height / 2)
        let x = cx
        let y = Math.round(content.height)
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (root.edge === "bottom") {
            y = 0
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width)
            y = cy
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (root.edge === "right") {
            x = 0
            y = cy
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const anchor = tipPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = grow
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    onShowChanged: root.sync()
    onMessageChanged: root.sync()

    Timer {
        id: delay
        interval: Theme.tooltipDelay
        repeat: false
        onTriggered: root.armed = true
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: tipPopup
        visible: root.armed && root.show && root.message.length > 0
        color: "transparent"
        // qmllint disable missing-property
        implicitWidth: tipLabel.width + Theme.space * 2
        implicitHeight: tipLabel.implicitHeight + Theme.tabGap * 2
        anchor.item: root.parent
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
                width: Math.min(implicitWidth, Theme.popupWidth)
                wrapMode: Text.WordWrap
                text: root.message
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
