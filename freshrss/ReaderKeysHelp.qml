pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.theme

// The "?" shortcut sheet: every reader key from ReaderKeys, grouped, on a
// card over a dimmed window. ? or Esc (handled by the panel) or a click
// outside the card closes it. Two columns when there is room, else one.
Item {
    id: root

    required property ReaderKeys keys
    property bool open: false

    signal closeRequested()

    visible: root.open

    Rectangle {
        anchors.fill: parent
        color: Theme.freshRssScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Theme.freshRssHelpWidth, root.width - Theme.space * 4)
        height: Math.min(sheet.implicitHeight + Theme.space * 4, root.height - Theme.space * 4)
        radius: Theme.radius
        color: Theme.barBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        // Clicks on the card stay on the card.
        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.space * 2
            contentWidth: width
            contentHeight: sheet.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: sheet
                width: parent.width
                spacing: Theme.space * 2

                Item {
                    width: parent.width
                    height: heading.implicitHeight

                    Text {
                        id: heading
                        anchors.left: parent.left
                        text: "Keyboard shortcuts"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost / 2
                        font.bold: true
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: heading.verticalCenter
                        spacing: Theme.tabGap

                        KeyCap { label: "?"; anchors.verticalCenter: parent.verticalCenter }
                        KeyCap { label: "Esc"; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "to close"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }
                    }
                }

                Flow {
                    id: columns
                    readonly property int columnWidth: width >= Theme.freshRssHelpWidth - Theme.space * 8
                        ? Math.floor((width - spacing) / 2) : width
                    width: parent.width
                    spacing: Theme.space * 2

                    Repeater {
                        model: root.keys.groups
                        delegate: Column {
                            id: group
                            required property var modelData
                            width: columns.columnWidth
                            spacing: Theme.tabGap

                            Text {
                                text: group.modelData.title
                                color: Theme.accent
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1
                            }

                            Repeater {
                                model: group.modelData.keys
                                delegate: Item {
                                    id: line
                                    required property var modelData
                                    width: group.width
                                    height: Math.max(Theme.keyCapHeight, what.implicitHeight) + Theme.tabGap

                                    Row {
                                        id: caps
                                        width: Theme.freshRssHelpKeyColumn
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.tabGap

                                        Repeater {
                                            model: line.modelData.caps
                                            delegate: KeyCap {
                                                required property string modelData
                                                label: modelData
                                            }
                                        }
                                    }

                                    Text {
                                        id: what
                                        anchors.left: caps.right
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        wrapMode: Text.WordWrap
                                        text: line.modelData.text
                                        color: Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.smallPx
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
