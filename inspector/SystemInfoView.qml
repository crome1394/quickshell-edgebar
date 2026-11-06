pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.settings
import qs.theme

// Inspector → System Info: hardware and OS summary from fastfetch. Click a
// row to copy its value. fastfetch runs when this page first opens and on
// Refresh, nothing in the background.
Item {
    id: root

    required property string query

    signal copied(string text)

    readonly property var rows: {
        const q = root.query.trim().toLowerCase()
        const list = SystemInfoService.entries
        return q.length ? list.filter((e) => (e.label + "\n" + e.value).toLowerCase().indexOf(q) >= 0) : list
    }

    Component.onCompleted: SystemInfoService.ensure()

    Text {
        id: tools
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.fieldHeight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: SystemInfoService.loading && !SystemInfoService.title.length ? "Collecting system information…" : SystemInfoService.title
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    Text {
        id: errorText
        visible: SystemInfoService.error.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tools.bottom
        anchors.topMargin: Theme.space
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        text: SystemInfoService.error
        color: Theme.danger
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: errorText.visible ? errorText.bottom : tools.bottom
        anchors.topMargin: Theme.space
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: bar.pressed || bar.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: scroll.width - Theme.space - Theme.tabGap
            spacing: Theme.borderWidth

            Text {
                visible: SystemInfoService.loaded && root.rows.length === 0 && SystemInfoService.entries.length > 0
                width: parent.width
                text: "Nothing matches the search."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }

            Repeater {
                model: root.rows
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: body.width
                    height: Math.max(Theme.fieldHeight, valueText.implicitHeight + Theme.tabGap)
                    radius: Theme.radiusSm
                    color: rowMouse.containsMouse ? Theme.hover : (row.index % 2 ? "transparent" : Theme.sectionBg)

                    Text {
                        id: labelText
                        x: Theme.space
                        width: Theme.inspectorLabelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: String(row.modelData.label)
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    Text {
                        id: valueText
                        anchors.left: labelText.right
                        anchors.leftMargin: Theme.space
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        text: String(row.modelData.value)
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copied(String(row.modelData.value))

                        HoverTip {
                            message: "Copy " + row.modelData.label
                            show: rowMouse.containsMouse
                        }
                    }
                }
            }
        }
    }

    // Always visible, like the footer of a settings page.
    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.fieldHeight

        Text {
            anchors.left: parent.left
            anchors.right: buttons.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: SystemInfoService.loading ? "Running fastfetch…" : (SystemInfoService.entries.length ? SystemInfoService.entries.length + " rows from fastfetch  ·  click a row to copy it" : "")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Theme.sectionInset
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.tabGap

            FooterButton {
                label: "Refresh"
                enabled: !SystemInfoService.loading && !SystemInfoService.missing
                tip: "Run fastfetch again"
                onClicked: SystemInfoService.refresh()
            }

            FooterButton {
                label: "Copy all"
                enabled: SystemInfoService.entries.length > 0
                tip: "Copy every row as text"
                onClicked: root.copied(SystemInfoService.copyText())
            }
        }
    }
}
