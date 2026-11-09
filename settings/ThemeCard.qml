pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// One theme in Settings → Theme: a small bar drawn in the theme's own
// colors, its name, and its accent, alert, weekday, and ok swatches.
// Clicking drafts it. A saved theme also shows ✕ to delete it.
Rectangle {
    id: root

    required property var theme
    required property bool active
    property bool removable: false
    property string note: ""

    signal chosen()
    signal removeRequested()

    // Previewed with the glass set in System → Transparency, as it would look.
    readonly property var p: ThemeBuilder.build(ThemeBuilder.withGlass(root.theme, ThemeStore.glass, ""))

    implicitHeight: Theme.themeCardHeight
    radius: Theme.radius
    color: root.p.colPage
    border.width: root.active ? Theme.borderWidth * 2 : Theme.borderWidth
    border.color: root.active ? Theme.accent : (cardMouse.containsMouse ? Theme.subtext : Theme.border)

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen()
    }

    // The mini bar: a pill with the accent, an active workspace, the clock.
    Rectangle {
        id: miniBar
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        height: Theme.themePreviewHeight
        radius: Theme.radiusSm
        color: root.p.colBar
        border.width: Theme.borderWidth
        border.color: root.p.colBarBorder

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.tabGap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.wsGap

            Rectangle {
                width: Theme.chip
                height: Theme.chip - Theme.wsGap
                radius: Theme.radiusSm
                color: root.p.colWsActive

                Text {
                    anchors.centerIn: parent
                    text: "1"
                    color: root.p.colWsActiveFg
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: true
                }
            }

            Rectangle {
                width: Theme.chip
                height: Theme.chip - Theme.wsGap
                radius: Theme.radiusSm
                color: root.p.colSurface
                border.width: Theme.borderWidth
                border.color: root.p.colBorder

                Text {
                    anchors.centerIn: parent
                    text: "2"
                    color: root.p.colWsIdleFg
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Rectangle {
                width: Theme.chip
                height: Theme.chip - Theme.wsGap
                radius: Theme.radiusSm
                color: root.p.colHover
                border.width: Theme.borderWidth
                border.color: root.p.colAccent

                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.tabGap
                    height: Theme.tabGap
                    radius: width / 2
                    color: root.p.colAccent
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            text: "12:30"
            color: root.p.colFg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallPx
            font.bold: true
        }
    }

    Text {
        id: nameText
        anchors.left: parent.left
        anchors.leftMargin: Theme.space
        anchors.right: swatches.left
        anchors.rightMargin: Theme.tabGap
        anchors.top: miniBar.bottom
        anchors.topMargin: Theme.tabGap
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: String(root.theme.name || "")
        color: root.p.colFg
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    Text {
        anchors.left: nameText.left
        anchors.right: nameText.right
        anchors.top: nameText.bottom
        elide: Text.ElideRight
        text: root.note
        visible: root.note.length > 0
        color: root.p.colFgMuted
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    Row {
        id: swatches
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.top: miniBar.bottom
        anchors.topMargin: Theme.tabGap + Theme.borderWidth * 2
        spacing: Theme.borderWidth * 3

        Repeater {
            model: [root.p.colAccent, root.p.colDanger, root.p.colWeekday, root.p.colOk]
            delegate: Rectangle {
                required property color modelData
                width: Theme.smallPx
                height: Theme.smallPx
                radius: width / 2
                color: modelData
                border.width: Theme.borderWidth
                border.color: root.p.colBorder
            }
        }
    }

    // Delete a saved theme.
    Rectangle {
        visible: root.removable
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.tabGap
        width: Theme.chip
        height: Theme.chip
        radius: Theme.radiusSm
        color: removeMouse.containsMouse ? Theme.hover : Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: removeMouse.containsMouse ? Theme.danger : Theme.border

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: removeMouse.containsMouse ? Theme.danger : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: true
        }

        MouseArea {
            id: removeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.removeRequested()

            HoverTip {
                message: "Delete the saved theme " + String(root.theme.name || "")
                show: removeMouse.containsMouse
            }
        }
    }
}
