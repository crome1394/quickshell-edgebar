import QtQuick
import Quickshell.Wayland
import qs.services
import qs.theme

// One window capture. The source stays empty while the overview is closed.
Item {
    id: root

    required property string addr
    required property bool livePreview
    readonly property bool hasContent: capture.hasContent

    ScreencopyView {
        id: capture
        anchors.fill: parent
        captureSource: root.blank ? null : OverviewService.waylandSource(root.addr)
        live: root.livePreview && OverviewService.open

        function grabStill() {
            if (!OverviewService.open || capture.live || !capture.captureSource)
                return
            Qt.callLater(function () {
                if (!OverviewService.open || capture.live || !capture.captureSource)
                    return
                capture.captureFrame()
            })
        }

        onCaptureSourceChanged: capture.grabStill()
        onLiveChanged: capture.grabStill()
    }

    // A still can come back empty: Hyprland fails a copy while a window is
    // resizing (a new window re-tiles the others) or has just opened, and
    // Quickshell then ends that capture for good. Retrying clears the source
    // for a moment so a new capture starts. After a few tries the colored
    // placeholder stays.
    property int tries: 0
    property bool blank: false

    Timer {
        interval: Theme.overviewGrabRetryMs
        repeat: true
        running: OverviewService.open && !capture.hasContent
            && !!OverviewService.waylandSource(root.addr) && root.tries < Theme.overviewGrabRetries
        onTriggered: {
            root.tries += 1
            root.blank = true
            Qt.callLater(function () {
                root.blank = false
            })
        }
    }
}
