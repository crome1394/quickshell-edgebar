pragma ComponentBehavior: Bound
import QtQuick

// The Tailscale mark as a 3×3 grid of dots: the middle row and the bottom
// middle dot are solid, the rest faint. When off, every dot is faint.
Item {
    id: root

    required property int size
    required property color ink
    property bool on: true

    readonly property real dot: root.size / 4
    readonly property real step: (root.size - root.dot) / 2
    readonly property var solid: [3, 4, 5, 7]
    readonly property real faint: 0.28

    implicitWidth: root.size
    implicitHeight: root.size

    Repeater {
        model: 9
        delegate: Rectangle {
            id: dotItem
            required property int index
            x: (dotItem.index % 3) * root.step
            y: Math.floor(dotItem.index / 3) * root.step
            width: root.dot
            height: root.dot
            radius: width / 2
            color: root.ink
            opacity: root.on && root.solid.indexOf(dotItem.index) >= 0 ? 1 : root.faint
        }
    }
}
