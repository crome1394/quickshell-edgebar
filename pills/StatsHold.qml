import QtQuick
import qs.services

// Keeps StatsService sampling while the pill that owns this exists.
// gpu is true while that pill shows GPU or VRAM.
QtObject {
    id: hold

    required property bool gpu

    property bool held: false
    property bool heldGpu: false

    Component.onCompleted: {
        StatsService.retain(hold.gpu)
        hold.heldGpu = hold.gpu
        hold.held = true
    }

    onGpuChanged: {
        if (!hold.held)
            return
        StatsService.release(hold.heldGpu)
        StatsService.retain(hold.gpu)
        hold.heldGpu = hold.gpu
    }

    Component.onDestruction: {
        if (hold.held)
            StatsService.release(hold.heldGpu)
    }
}
