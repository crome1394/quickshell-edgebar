import QtQuick
import qs.components
import qs.config
import qs.services
import qs.theme

// Speaker | microphone. Loaded only while the Audio widget is on the bar.
// Levels come from AudioLevels, which keeps its own node copies.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1

    property string tipText: "Audio"

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property int px: Math.max(Theme.statFontMin, Math.round(root.theme.fontPx * root.ui * root.widthFactor))
    readonly property int gap: Math.max(4, Math.round(Theme.tabGap * root.ui))
    readonly property int barW: Math.max(Theme.statGaugeMinWidth, Math.round(Theme.audioBarWidth * root.ui * root.widthFactor))
    readonly property int barH: Math.max(Theme.statGaugeMinHeight, Math.round(Theme.audioBarHeight * root.ui))
    readonly property int barR: Math.max(1, Math.round(Theme.audioBarRadius * root.ui))

    function fillWidth(level) {
        const span = root.barW * Math.max(0, Math.min(1, Number(level) / 100))
        if (!(span > 0))
            return 0
        return Math.max(2, Math.min(root.barW, span))
    }

    function levelInk(ok, muted, level) {
        if (!ok || muted)
            return root.theme.colFgMuted
        return Theme.audioSpeakerColor(level)
    }

    AudioLevels {
        id: levels
    }

    implicitWidth: row.implicitWidth + root.gap * 2
    implicitHeight: root.cell
    radius: Theme.radiusSm
    color: root.theme.colSurface
    border.width: Theme.borderWidth
    border.color: outMouse.containsMouse || inMouse.containsMouse ? root.theme.colAccent : root.theme.colBorder

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Item {
            width: outFace.implicitWidth
            height: root.cell

            Row {
                id: outFace
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(2, Math.round(Theme.statValGap * root.ui))

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: levels.outMute ? "\uf026" : "\uf028"
                    color: root.levelInk(levels.outOk, levels.outMute, levels.outVol)
                    opacity: levels.outMute ? Theme.widgetOffOpacity : 1
                    font.family: root.theme.iconFont
                    font.pixelSize: root.icon
                }

                Item {
                    width: root.barW
                    height: root.barH
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: root.barR
                        color: root.theme.colStatTrack
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.fillWidth(levels.outVol)
                        height: root.barH
                        radius: root.barR
                        color: root.levelInk(levels.outOk, levels.outMute, levels.outVol)
                        opacity: levels.outMute ? Theme.widgetOffOpacity : 1
                    }
                }

                Text {
                    visible: Config.audioShowPercent && levels.outOk
                    anchors.verticalCenter: parent.verticalCenter
                    text: levels.outVol + "%"
                    color: root.levelInk(levels.outOk, levels.outMute, levels.outVol)
                    opacity: levels.outMute ? Theme.widgetOffOpacity : 1
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.px
                    font.bold: true
                }
            }

            MouseArea {
                id: outMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.RightButton
                onContainsMouseChanged: {
                    if (outMouse.containsMouse)
                        root.tipText = levels.outMute ? "Speaker muted · Right: unmute · Wheel: volume" : "Speaker · Right: mute · Wheel: volume"
                }
                onClicked: levels.toggleMute("out")
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y === 0)
                        return
                    levels.nudge("out", wheel.angleDelta.y > 0 ? 1 : -1)
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "|"
            color: root.theme.colFgMuted
            font.family: root.theme.fontFamily
            font.pixelSize: root.px
        }

        Item {
            width: inFace.implicitWidth
            height: root.cell

            Row {
                id: inFace
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.max(2, Math.round(Theme.statValGap * root.ui))

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: levels.inMute ? "\uf131" : "\uf130"
                    color: root.levelInk(levels.inOk, levels.inMute, levels.inVol)
                    opacity: levels.inMute ? Theme.widgetOffOpacity : 1
                    font.family: root.theme.iconFont
                    font.pixelSize: root.icon
                }

                Item {
                    width: root.barW
                    height: root.barH
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: root.barR
                        color: root.theme.colStatTrack
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.fillWidth(levels.inVol)
                        height: root.barH
                        radius: root.barR
                        color: root.levelInk(levels.inOk, levels.inMute, levels.inVol)
                        opacity: levels.inMute ? Theme.widgetOffOpacity : 1
                    }
                }

                Text {
                    visible: Config.audioShowPercent && levels.inOk
                    anchors.verticalCenter: parent.verticalCenter
                    text: levels.inVol + "%"
                    color: root.levelInk(levels.inOk, levels.inMute, levels.inVol)
                    opacity: levels.inMute ? Theme.widgetOffOpacity : 1
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.px
                    font.bold: true
                }
            }

            MouseArea {
                id: inMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.RightButton
                onContainsMouseChanged: {
                    if (inMouse.containsMouse)
                        root.tipText = levels.inMute ? "Microphone muted · Right: unmute · Wheel: volume" : "Microphone · Right: mute · Wheel: volume"
                }
                onClicked: levels.toggleMute("in")
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y === 0)
                        return
                    levels.nudge("in", wheel.angleDelta.y > 0 ? 1 : -1)
                }
            }
        }
    }

    BarTip {
        edge: root.edge
        message: root.tipText
        show: outMouse.containsMouse || inMouse.containsMouse
    }
}
