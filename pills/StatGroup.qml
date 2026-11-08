import QtQuick
import qs.components
import qs.theme

// One metric on the System Stats pill: label, optional bar, percent, and
// value. Each text part has its own style, { font, bold, italic, size }
// (see StatStyle); font "" is the bar font.
Rectangle {
    id: root

    required property var theme
    required property string edge
    required property string label
    required property string percentText
    required property string valueText
    required property string percentSample
    required property string valueSample
    required property color percentColor
    required property color valueColor
    required property color gaugeColor
    required property bool showGauge
    required property int gaugeWidth
    required property bool known
    required property real fraction
    required property int sectionHeight
    required property real ui
    required property real widthFactor
    required property string tip
    required property color labelColor
    required property var labelStyle
    required property var percentStyle
    required property var valueStyle

    signal activated(int button)

    // True while this section is grown or jumping, so the pill can draw it on top.
    readonly property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real faceScale: Math.max(0.5, root.ui * root.widthFactor)
    function family(style) {
        const name = style && style.font ? String(style.font) : ""
        return name.length ? name : root.theme.fontFamily
    }

    function pxOf(style) {
        return Theme.barTextPx(root.ui, root.widthFactor, style ? style.size : 100)
    }

    readonly property string labelFamily: root.family(root.labelStyle)
    readonly property int labelPx: root.pxOf(root.labelStyle)
    readonly property string percentFamily: root.family(root.percentStyle)
    readonly property int percentPx: root.pxOf(root.percentStyle)
    readonly property string valueFamily: root.family(root.valueStyle)
    readonly property int valuePx: root.pxOf(root.valueStyle)
    readonly property int innerPad: Math.max(3, Math.round(Theme.statInnerPad * root.faceScale))
    readonly property int rowGap: Math.max(3, Math.round(Theme.statRowGap * root.faceScale))
    readonly property int valGap: Math.max(2, Math.round(Theme.statValGap * root.faceScale))
    readonly property int gaugeW: Math.max(Theme.statGaugeMinWidth, Math.round(root.gaugeWidth * root.faceScale))
    readonly property int gaugeH: Math.max(Theme.statGaugeMinHeight, Math.round(Theme.statGaugeHeight * root.faceScale))
    readonly property int gaugeR: Math.max(1, Math.round(Theme.statGaugeRadius * root.faceScale))

    function fillWidth() {
        if (!root.known)
            return 0
        const span = root.gaugeW * Math.max(0, Math.min(1, root.fraction))
        return Math.max(2, Math.min(root.gaugeW, span))
    }

    implicitWidth: Math.ceil(inner.implicitWidth) + root.innerPad * 2
    implicitHeight: root.sectionHeight
    width: root.implicitWidth
    height: root.sectionHeight
    radius: Theme.radiusSm
    color: hit.containsMouse ? root.theme.colHover : "transparent"
    border.width: hit.containsMouse ? Theme.borderWidth : 0
    border.color: hit.containsMouse ? root.theme.colAccent : "transparent"
    z: root.dockHot ? 1 : 0
    transform: [
        Scale {
            xScale: dock.mag
            yScale: dock.mag
            origin.x: root.width / 2
            origin.y: dock.growIn ? root.height : 0
        },
        Translate { y: dock.jumpY }
    ]

    // Only the hovered section grows, not the whole pill.
    DockFace {
        id: dock
        edge: root.edge
        hovered: hit.containsMouse
    }

    Behavior on color {
        ColorAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
    }

    TextMetrics {
        id: pctBox
        font.family: root.percentFamily
        font.pixelSize: root.percentPx
        font.bold: !!root.percentStyle.bold
        font.italic: !!root.percentStyle.italic
        text: root.percentSample
    }

    TextMetrics {
        id: valBox
        font.family: root.valueFamily
        font.pixelSize: root.valuePx
        font.bold: !!root.valueStyle.bold
        font.italic: !!root.valueStyle.italic
        text: root.valueSample
    }

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: root.rowGap

        Item {
            width: nameLabel.implicitWidth
            height: nameLabel.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: nameLabel
                text: root.label
                color: hit.containsMouse ? root.theme.colAccent : root.labelColor
                font.family: root.labelFamily
                font.pixelSize: root.labelPx
                font.bold: !!root.labelStyle.bold
                font.italic: !!root.labelStyle.italic
            }
        }

        Item {
            visible: root.showGauge
            width: root.gaugeW
            height: root.gaugeH
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: root.gaugeR
                color: root.theme.colStatTrack
            }

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.fillWidth()
                height: root.gaugeH
                radius: root.gaugeR
                color: root.gaugeColor

                Behavior on width {
                    NumberAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
                }
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.valGap

            Item {
                width: pctBox.advanceWidth
                height: pctLabel.implicitHeight

                Text {
                    id: pctLabel
                    width: parent.width
                    height: parent.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: root.percentText
                    color: root.percentColor
                    font.family: root.percentFamily
                    font.pixelSize: root.percentPx
                    font.bold: !!root.percentStyle.bold
                    font.italic: !!root.percentStyle.italic
                }
            }

            Item {
                width: barLabel.implicitWidth
                height: barLabel.implicitHeight

                Text {
                    id: barLabel
                    text: "|"
                    color: root.theme.colStatSeparator
                    font.family: root.valueFamily
                    font.pixelSize: root.valuePx
                    font.italic: !!root.valueStyle.italic
                }
            }

            Item {
                width: valBox.advanceWidth
                height: valLabel.implicitHeight

                Text {
                    id: valLabel
                    width: parent.width
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.valueText
                    color: root.valueColor
                    font.family: root.valueFamily
                    font.pixelSize: root.valuePx
                    font.bold: !!root.valueStyle.bold
                    font.italic: !!root.valueStyle.italic
                }
            }
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            dock.play()
            root.activated(mouse.button)
        }
    }

    BarTip {
        edge: root.edge
        message: root.tip
        show: hit.containsMouse
    }
}
