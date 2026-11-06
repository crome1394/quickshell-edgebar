pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

Rectangle {
    id: root

    required property string widgetId
    required property string label
    required property bool shown
    required property bool divider
    required property int percent

    signal toggled()
    signal scaleEdited(int percent)
    signal dragAt(string widgetId, real x, real y)
    signal dragFinished(bool commit)

    property real pressX: 0
    property real pressY: 0
    property bool armed: false

    readonly property int scaleStripWidth: (4 * Theme.chip) + (2 * Theme.chip) + (5 * Theme.tabGap)

    function round5(value) {
        let n = Math.round(Number(value) / 5) * 5
        if (n < 80)
            n = 80
        if (n > 180)
            n = 180
        return n
    }

    implicitHeight: Theme.dividerRowHeight
    radius: Theme.radiusSm
    color: Theme.pillBg
    border.width: Theme.borderWidth
    border.color: Theme.border
    opacity: root.shown ? 1 : Theme.widgetOffOpacity

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space
        anchors.rightMargin: Theme.space
        spacing: Theme.tabGap

        Rectangle {
            id: grip
            width: Theme.chip
            height: Theme.chip
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.radiusSm
            color: gripMouse.containsMouse ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "||"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: gripMouse
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.SizeAllCursor
                onPressed: (mouse) => {
                    root.pressX = mouse.x
                    root.pressY = mouse.y
                    root.armed = false
                }
                onPositionChanged: (mouse) => {
                    if (!gripMouse.pressed)
                        return
                    const dx = mouse.x - root.pressX
                    const dy = mouse.y - root.pressY
                    const slop = Theme.space * Theme.space
                    if (!root.armed && (dx * dx + dy * dy) < slop)
                        return
                    root.armed = true
                    const point = gripMouse.mapToItem(null, mouse.x, mouse.y)
                    root.dragAt(root.widgetId, point.x, point.y)
                }
                onReleased: {
                    if (root.armed)
                        root.dragFinished(true)
                    root.armed = false
                }
                onCanceled: {
                    if (root.armed)
                        root.dragFinished(false)
                    root.armed = false
                }
            }
        }

        Rectangle {
            width: Theme.toggleWidth
            height: Theme.chip
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.radiusSm
            color: toggleMouse.containsMouse ? Theme.hover : "transparent"
            border.width: Theme.borderWidth
            border.color: root.shown ? Theme.ok : Theme.danger

            Text {
                anchors.centerIn: parent
                text: root.shown ? "✓" : "✕"
                color: root.shown ? Theme.ok : Theme.danger
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        Text {
            width: Math.max(1, parent.width - Theme.chip - Theme.toggleWidth - scaleRow.width - Theme.tabGap * 3)
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.label
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            id: scaleRow
            width: root.scaleStripWidth + Math.ceil(percentText.implicitWidth) + Theme.tabGap
            height: parent.height
            spacing: Theme.tabGap

            Text {
                id: percentText
                width: Math.ceil(percentText.implicitWidth)
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: root.percent + "%"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            IntSlider {
                width: root.scaleStripWidth
                anchors.verticalCenter: parent.verticalCenter
                from: 80
                to: 180
                step: 5
                value: root.percent
                onChanged: (value) => {
                    const next = root.round5(value)
                    if (next !== root.percent)
                        root.scaleEdited(next)
                }
            }
        }
    }
}
