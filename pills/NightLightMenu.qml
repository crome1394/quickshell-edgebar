pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.settings
import qs.theme

// Right-click menu for the Night Light pill. Same choices as Settings →
// Tools → Night Light: on/off, warmth, and an optional schedule. Changes
// save at once. Laid out like the Tailscale menu: a header switch, sections,
// and a footer.
Item {
    id: root

    required property var theme
    property bool open: false

    signal closeRequested()

    readonly property var light: NightLightService
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    function stateLine() {
        const n = root.light
        if (!n.checked)
            return "Checking…"
        if (!n.available)
            return "Needs hyprsunset"
        let line = (n.on ? "On · " : "Off · ") + n.temp + " K"
        if (Config.nightSchedule)
            line += n.overriding ? " · held" : " · scheduled"
        return line
    }

    function commitStart(field) {
        NightLightSettings.setStartLive(field.text)
        field.text = Qt.binding(() => Config.nightStart)
    }

    function commitEnd(field) {
        NightLightSettings.setEndLive(field.text)
        field.text = Qt.binding(() => Config.nightEnd)
    }

    function cancel(event) {
        event.accepted = true
        root.closeRequested()
    }

    implicitHeight: column.implicitHeight + footerRow.height + Theme.space * 2 + Theme.tabGap

    focus: true

    onOpenChanged: {
        if (root.open) {
            root.light.recheck()
            root.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: (event) => root.cancel(event)

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.closeRequested()
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 0
        color: root.theme.colAccent
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.fontPx
        font.bold: true
    }

    component Note: Text {
        width: parent ? parent.width : 0
        wrapMode: Text.WordWrap
        color: root.theme.colFgMuted
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    Flickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerRow.top
        anchors.margins: Theme.space
        anchors.bottomMargin: Theme.tabGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: column.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: scrollBar.pressed || scrollBar.hovered ? root.theme.colAccent : root.theme.colFgMuted
            }
        }

        Column {
            id: column
            width: Math.max(0, flick.width - root.scrollGutter)
            spacing: Theme.space

            // Header: moon, state, the on/off switch, and close.
            Row {
                width: parent.width
                spacing: Theme.space

                Item {
                    width: root.theme.iconPx
                    height: Theme.fieldHeight

                    Text {
                        anchors.centerIn: parent
                        text: Theme.nightGlyph
                        color: root.light.on ? root.theme.colAccent : root.theme.colFgMuted
                        font.family: root.theme.iconFont
                        font.pixelSize: root.theme.iconPx
                    }
                }

                TailscaleSwitch {
                    width: parent.width - root.theme.iconPx - closeBox.width - Theme.space * 2
                    theme: root.theme
                    label: "Night light · " + root.stateLine()
                    bold: true
                    on: root.light.on
                    tip: root.light.on ? "Turn the night light off" : "Turn the night light on"
                    visible: root.light.available
                    onToggled: (next) => root.light.setOn(next)
                }

                Text {
                    visible: !root.light.available
                    width: parent.width - root.theme.iconPx - closeBox.width - Theme.space * 2
                    height: Theme.fieldHeight
                    verticalAlignment: Text.AlignVCenter
                    text: "Night light · " + root.stateLine()
                    color: root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.fontPx
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeBox
                    width: Theme.fieldHeight
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: closeMouse.containsMouse ? root.theme.colHover : root.theme.colSurface
                    border.width: Theme.borderWidth
                    border.color: root.theme.colBorder

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: root.theme.colFg
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Note {
                visible: root.light.error.length > 0
                text: root.light.error
                color: root.theme.colDanger
            }

            Note {
                visible: root.light.checked && !root.light.available
                text: "hyprsunset is not installed, so the night light cannot change the screen. Install it with: sudo pacman -S hyprsunset"
            }

            // Warmth: the same slider as Settings, with its − and + buttons.
            Rectangle {
                width: parent.width
                implicitHeight: warmthCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: warmthCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "Warmth"
                    }

                    IntSlider {
                        width: parent.width
                        from: Theme.nightTempMin
                        to: Theme.nightTempMax
                        step: Theme.nightTempStep
                        value: root.light.temp
                        readout: root.light.temp + " K"
                        tip: "Lower is warmer and cuts more blue light. 6500 K is neutral; 4000 K is a common evening setting. − and + move by " + Theme.nightTempStep + " K."
                        onChanged: (value) => root.light.setTemp(value)
                    }

                    Note {
                        text: "Left is warmer. The wheel on the pill moves this too."
                    }
                }
            }

            // Schedule: on/off, then the from and to times.
            Rectangle {
                width: parent.width
                implicitHeight: scheduleCol.implicitHeight + Theme.space * 2
                radius: Theme.radiusSm
                color: root.theme.colSurface
                border.width: Theme.borderWidth
                border.color: root.theme.colBorder

                Column {
                    id: scheduleCol
                    x: Theme.space
                    y: Theme.space
                    width: parent.width - Theme.space * 2
                    spacing: Theme.tabGap

                    SectionTitle {
                        text: "Schedule"
                    }

                    TailscaleSwitch {
                        width: parent.width
                        theme: root.theme
                        label: "On a schedule"
                        tip: "Turn the night light on and off at set times. A click on the pill holds until the next switch."
                        on: Config.nightSchedule
                        onToggled: (next) => NightLightSettings.setScheduleLive(next)
                    }

                    Note {
                        visible: Config.nightSchedule
                        text: root.light.overriding
                            ? "Held until the next switch. It stays " + (root.light.on ? "on" : "off") + " until " + (root.light.scheduledNow ? Config.nightEnd : Config.nightStart) + "."
                            : "On from " + Config.nightStart + " to " + Config.nightEnd + ". A time that passes midnight is fine. A click on the pill holds until the next switch."
                    }

                    Row {
                        visible: Config.nightSchedule
                        width: parent.width
                        spacing: Theme.space

                        Text {
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            text: "From"
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                        }

                        TextBox {
                            id: startField
                            width: Theme.fieldHeight * 3
                            text: Config.nightStart
                            placeholderText: "20:00"
                            inputMask: "99:99"
                            onEditingFinished: root.commitStart(startField)
                            Keys.onEscapePressed: (event) => root.cancel(event)
                        }

                        Text {
                            height: Theme.fieldHeight
                            verticalAlignment: Text.AlignVCenter
                            text: "to"
                            color: root.theme.colFgMuted
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                        }

                        TextBox {
                            id: endField
                            width: Theme.fieldHeight * 3
                            text: Config.nightEnd
                            placeholderText: "07:00"
                            inputMask: "99:99"
                            onEditingFinished: root.commitEnd(endField)
                            Keys.onEscapePressed: (event) => root.cancel(event)
                        }
                    }
                }
            }

            Note {
                text: "Left-click the pill to turn night light on or off. Escape or ✕ closes this menu."
            }
        }
    }

    Row {
        id: footerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        spacing: Theme.tabGap
        height: Theme.chip

        MenuChip {
            theme: root.theme
            label: "Recheck"
            tip: "Look for hyprsunset again"
            onClicked: root.light.recheck()
        }
    }
}
