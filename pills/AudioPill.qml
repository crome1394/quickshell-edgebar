import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.theme

// Speaker | microphone. Loaded only while the Audio widget is on the bar.
// With Audio → "Combine into one widget" off, the Speaker and Microphone
// widgets each load this with part "out" or "in" and draw only that side.
// Levels come from AudioLevels, which keeps its own node copies.
Rectangle {
    id: root

    required property var theme
    property string edge: "top"
    property real widthFactor: 1

    property string tipText: "Audio"
    property string screenName: ""
    // "both", "out" (speaker only), or "in" (microphone only).
    property string part: "both"
    readonly property bool menuOpen: AudioMenuService.shownBy(root.screenName, root.part)
    property bool dockHot: dock.mag > 1.01 || Math.abs(dock.jumpY) > 0.5

    readonly property real ui: WidgetService.uiScale
    readonly property int cell: Math.max(1, Math.round((Theme.barHeight - Theme.barPad) * root.ui))
    readonly property int icon: Math.max(1, Math.round(root.theme.iconPx * root.ui * root.widthFactor))
    readonly property int px: Theme.barTextPx(root.ui, root.widthFactor)
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
        return ThemeStore.audioSpeakerColor(level)
    }

    // The whole pill grows as one; either side's click makes it jump.
    HoverHandler {
        id: pillHover
    }

    DockFace {
        id: dock
        edge: root.edge
        hovered: pillHover.hovered
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
    transform: [
        Scale {
            xScale: dock.mag
            yScale: dock.mag
            origin.x: root.width / 2
            origin.y: dock.growIn ? root.height : 0
        },
        Translate { y: dock.jumpY }
    ]

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Item {
            visible: root.part !== "in"
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onContainsMouseChanged: {
                    if (outMouse.containsMouse)
                        root.tipText = levels.outMute ? "Speaker muted · Left: menu · Right: unmute · Wheel: volume" : "Speaker · Left: menu · Right: mute · Wheel: volume"
                }
                onClicked: (mouse) => {
                    dock.play()
                    if (mouse.button === Qt.LeftButton)
                        AudioMenuService.toggle(root.screenName, root.part)
                    else
                        levels.toggleMute("out")
                }
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y === 0)
                        return
                    levels.nudge("out", wheel.angleDelta.y > 0 ? 1 : -1)
                }
            }
        }

        Text {
            visible: root.part === "both"
            anchors.verticalCenter: parent.verticalCenter
            text: "|"
            color: root.theme.colFgMuted
            font.family: root.theme.fontFamily
            font.pixelSize: root.px
        }

        Item {
            visible: root.part !== "out"
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onContainsMouseChanged: {
                    if (inMouse.containsMouse)
                        root.tipText = levels.inMute ? "Microphone muted · Left: menu · Right: unmute · Wheel: volume" : "Microphone · Left: menu · Right: mute · Wheel: volume"
                }
                onClicked: (mouse) => {
                    dock.play()
                    if (mouse.button === Qt.LeftButton)
                        AudioMenuService.toggle(root.screenName, root.part)
                    else
                        levels.toggleMute("in")
                }
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
        show: (outMouse.containsMouse || inMouse.containsMouse) && !root.menuOpen
    }

    function placeMenu() {
        const content = root.Window.contentItem
        if (!content)
            return
        const bounds = root.mapToItem(content, 0, 0, root.width, root.height)
        const cx = Math.round(bounds.x + bounds.width / 2)
        const cy = Math.round(bounds.y + bounds.height / 2)
        let x = cx
        // Closer to the bar than the window's outer edge (Theme.popupGapCut).
        const inset = WidgetService.popupInset(content, root.edge)
        let y = Math.round(content.height) - inset
        let edgeFlags = Edges.Bottom
        let grow = Edges.Bottom
        if (root.edge === "bottom") {
            y = inset
            edgeFlags = Edges.Top
            grow = Edges.Top
        } else if (root.edge === "left") {
            x = Math.round(content.width) - inset
            y = cy
            edgeFlags = Edges.Right
            grow = Edges.Right
        } else if (root.edge === "right") {
            x = inset
            y = cy
            edgeFlags = Edges.Left
            grow = Edges.Left
        }
        const anchor = menuPopup.anchor
        // qmllint disable missing-property
        anchor.edges = edgeFlags
        anchor.gravity = grow
        anchor.rect = Qt.rect(x + 3, y + 3, 1, 1)
        anchor.rect = Qt.rect(x, y, 1, 1)
        // qmllint enable missing-property
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: menuPopup
        visible: root.menuOpen
        color: "transparent"
        grabFocus: true
        implicitWidth: Theme.audioPopupWidth
        // qmllint disable missing-property
        implicitHeight: Math.min(Theme.audioPopupMaxHeight, menu.implicitHeight)
        anchor.item: root
        anchor.adjustment: PopupAdjustment.Slide
        // qmllint enable missing-property
        onClosed: AudioMenuService.hide()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: root.theme.colBg
            border.width: Theme.borderWidth
            border.color: root.theme.colBorder

            AudioMenu {
                id: menu
                anchors.fill: parent
                theme: root.theme
                open: root.menuOpen
                onCloseRequested: AudioMenuService.hide()
            }
        }
    }

    Connections {
        // qmllint disable incompatible-type
        target: menuPopup.anchor
        // qmllint enable incompatible-type
        function onAnchoring() {
            root.placeMenu()
        }
    }
}
