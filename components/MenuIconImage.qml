import QtQuick
import QtQuick.Effects

// An SVG or PNG drawn as a square icon. With `tint` on, the image's shape is
// filled with `ink`, for one-color SVGs. Off keeps its own colors.
// `ready` is false while loading and when the file is missing or broken,
// so the caller can show its symbol instead.
Item {
    id: root

    required property url source
    required property int px
    required property color ink
    property bool tint: false

    readonly property bool ready: art.status === Image.Ready
    readonly property bool failed: art.status === Image.Error

    implicitWidth: root.px
    implicitHeight: root.px

    Image {
        id: art
        anchors.fill: parent
        source: root.source
        sourceSize.width: root.px
        sourceSize.height: root.px
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        visible: !root.tint
        layer.enabled: root.tint
    }

    // The ink color, cut out by the image's alpha. Threshold 0.5 with spread
    // 1 maps alpha 0..1 straight through, keeping antialiased edges.
    Rectangle {
        id: fill
        anchors.fill: parent
        visible: false
        color: root.ink
        layer.enabled: root.tint
    }

    Loader {
        anchors.fill: parent
        active: root.tint
        sourceComponent: Component {
            MultiEffect {
                source: fill
                maskEnabled: true
                maskSource: art
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }
    }
}
