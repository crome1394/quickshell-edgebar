import QtQuick
import qs.config
import qs.theme

// Hover magnify and click jump for one icon or one icon cell.
// The host applies mag and jumpY. Stats and volume do not use this.
Item {
    id: root

    required property string edge
    property bool hovered: false
    // Launcher, tray, and workspace cells pass a cosine falloff.
    property bool neighbors: false
    property real neighbor: 1
    // Launcher cells stay active when Apply to is Application Launcher.
    property bool always: false

    readonly property bool growIn: root.edge === "bottom" || root.edge === "left"
    readonly property bool live: root.always || Config.dockAllIcons()

    property real mag: {
        if (!root.live || !Config.dockMagnify())
            return 1
        if (root.neighbors)
            return root.neighbor > 1 ? root.neighbor : 1
        if (!root.hovered)
            return 1
        return Config.dockPercentValue()
    }
    property real jumpY: 0

    Behavior on mag {
        NumberAnimation {
            duration: Theme.dockRiseMs
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: jumpAnim
        NumberAnimation {
            target: root
            property: "jumpY"
            to: root.growIn ? -Config.dockJumpValue() : Config.dockJumpValue()
            duration: Theme.dockRiseMs
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "jumpY"
            to: 0
            duration: Theme.dockSettleMs
            easing.type: Easing.OutBounce
        }
        onStopped: root.jumpY = 0
    }

    onMagChanged: {
        if (root.mag <= 1.01 && !jumpAnim.running)
            root.jumpY = 0
    }

    function play() {
        if (!root.live || !Config.dockJumpOn())
            return
        jumpAnim.restart()
    }
}
