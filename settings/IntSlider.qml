import QtQuick
import qs.theme

// Track with step buttons on the right. The buttons move by `step`.
Item {
    id: root

    required property int from
    required property int to
    required property int value
    property int step: 1
    property string tip: ""
    // Shown between the decrease and increase buttons. Empty hides it.
    property string readout: ""
    property bool showSwatch: false
    property color swatch: "#000000"
    readonly property bool hovered: trackMouse.containsMouse || swatchMouse.containsMouse || downMouse.containsMouse || upMouse.containsMouse
    readonly property bool canDecrease: root.value > root.from
    readonly property bool canIncrease: root.value < root.to

    signal changed(int value)
    signal swatchClicked()

    implicitHeight: Theme.fieldHeight

    function nudge(dir) {
        const step = Math.max(1, root.step)
        const k = Math.round((root.value - root.from) / step)
        let next = root.from + (k + dir) * step
        if (dir < 0 && next >= root.value)
            next = root.from + (k - 1) * step
        if (dir > 0 && next <= root.value)
            next = root.from + (k + 1) * step
        if (next < root.from)
            next = root.from
        if (next > root.to)
            next = root.to
        if (next !== root.value)
            root.changed(next)
    }

    function pick(x) {
        const span = Math.max(1, track.width)
        const t = Math.max(0, Math.min(1, x / span))
        const next = Math.round(root.from + t * (root.to - root.from))
        if (next !== root.value)
            root.changed(next)
    }

    Row {
        anchors.fill: parent
        spacing: Theme.tabGap

        Item {
            id: track
            width: {
                const readout = readoutLabel.visible ? readoutLabel.width + Theme.tabGap : 0
                const swatch = root.showSwatch ? Theme.chip + Theme.tabGap : 0
                return Math.max(Theme.chip, parent.width - downButton.width - upButton.width - readout - swatch - Theme.tabGap * 2)
            }
            height: parent.height

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.fieldBg

                Rectangle {
                    width: {
                        const span = Math.max(1, root.to - root.from)
                        return parent.width * (root.value - root.from) / span
                    }
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
                x: {
                    const span = Math.max(1, root.to - root.from)
                    const t = (root.value - root.from) / span
                    return Math.max(0, Math.min(parent.width - width, t * parent.width - width / 2))
                }
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => root.pick(mouse.x)
                onPositionChanged: (mouse) => {
                    if (pressed)
                        root.pick(mouse.x)
                }

                HoverTip {
                    message: root.tip
                    show: trackMouse.containsMouse && root.tip.length > 0
                }
            }
        }

        Rectangle {
            id: swatchButton
            visible: root.showSwatch
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            color: root.swatch
            border.width: Theme.borderWidth
            border.color: Theme.border

            MouseArea {
                id: swatchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.swatchClicked()

                HoverTip {
                    message: "Color"
                    show: swatchMouse.containsMouse
                }
            }
        }

        Rectangle {
            id: downButton
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            opacity: root.canDecrease ? 1 : 0.45
            color: downMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "−"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            MouseArea {
                id: downMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canDecrease ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.canDecrease)
                        root.nudge(-1)
                }

                HoverTip {
                    message: "Decrease"
                    show: downMouse.containsMouse
                }
            }
        }

        Text {
            id: readoutLabel
            visible: root.readout.length > 0
            width: root.readout.length ? Math.max(Theme.chip * 2, implicitWidth) : 0
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.readout
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Rectangle {
            id: upButton
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            opacity: root.canIncrease ? 1 : 0.45
            color: upMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "+"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            MouseArea {
                id: upMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canIncrease ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.canIncrease)
                        root.nudge(1)
                }

                HoverTip {
                    message: "Increase"
                    show: upMouse.containsMouse
                }
            }
        }
    }
}
