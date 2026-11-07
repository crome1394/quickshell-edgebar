import QtQuick
import qs.services
import qs.theme

// Hover tip for a bar widget. Put it inside the widget and bind `show` to
// its hover. After the hover delay it asks TipService for the shared tip,
// which BarTipHost draws outside the bar: below a top bar, above a bottom
// bar, beside a side bar. No window of its own.
Item {
    id: root

    property string edge: "top"
    required property string message
    required property bool show

    readonly property bool wanted: root.show && root.message.length > 0

    width: 0
    height: 0

    function sync() {
        if (!root.wanted) {
            delay.stop()
            TipService.release(root.parent)
        } else if (TipService.target === root.parent) {
            TipService.request(root.parent, root.message, root.edge)
        } else if (!delay.running) {
            delay.restart()
        }
    }

    onWantedChanged: root.sync()
    onMessageChanged: root.sync()
    Component.onDestruction: TipService.release(root.parent)

    Timer {
        id: delay
        interval: Theme.tooltipDelay
        onTriggered: {
            if (root.wanted)
                TipService.request(root.parent, root.message, root.edge)
        }
    }
}
