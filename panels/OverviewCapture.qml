import QtQuick
import Quickshell.Wayland
import qs.services

// One window capture. The source stays empty while the overview is closed.
Item {
    id: root

    required property string addr
    required property bool livePreview
    readonly property bool hasContent: capture.hasContent

    ScreencopyView {
        id: capture
        anchors.fill: parent
        captureSource: OverviewService.waylandSource(root.addr)
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
}
