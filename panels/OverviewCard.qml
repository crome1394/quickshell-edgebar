pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.theme

// One workspace card on the overview strip.
Item {
    id: root

    required property var modelData
    required property int index
    readonly property var card: root.modelData
    required property bool active
    required property bool drop
    required property bool horizontal
    required property real pitchW
    required property real pitchH
    required property real cardW
    required property real cardH
    required property int cornerRadius
    required property bool showLabel
    required property bool numbers
    required property bool livePreview

    signal chosen()

    readonly property bool numbered: root.numbers && !root.card.all && !root.card.special
    readonly property string markText: {
        if (root.card.all)
            return "All"
        if (root.card.phantom && !Config.ovLive().ovDynamic)
            return "+"
        return ""
    }

    x: root.horizontal ? root.index * root.pitchW : 0
    y: root.horizontal ? 0 : root.index * root.pitchH
    width: root.pitchW
    height: root.pitchH

    Column {
        anchors.centerIn: parent
        spacing: Theme.wsGap
        width: root.cardW

        Text {
            visible: root.showLabel
            width: root.cardW
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: OverviewService.cardCaption(root.card)
            color: (!root.numbered && root.card.color && String(root.card.color).length)
                ? root.card.color
                : (root.active ? Theme.wsActiveText : Theme.text)
            font.pixelSize: Theme.smallPx
            font.bold: root.numbered ? true : root.card.bold !== false
            font.italic: root.numbered ? false : !!root.card.italic
            font.family: (root.numbered || !(root.card.font && String(root.card.font).length))
                ? Theme.uiFont
                : root.card.font
        }

        Rectangle {
            id: face
            width: root.cardW
            height: root.cardH
            radius: root.cornerRadius
            color: root.card.phantom ? Theme.hover : Theme.fieldBg
            border.width: root.drop ? Theme.borderWidth * 3 : ((root.active || cardMouse.containsMouse) ? Theme.borderWidth * 2 : Theme.borderWidth)
            border.color: (root.drop || root.active) ? Theme.accent : (cardMouse.containsMouse ? Theme.text : Theme.border)
            clip: true

            Repeater {
                model: root.card.minis || []
                delegate: Item {
                    id: mini
                    required property var modelData
                    required property int index
                    x: mini.modelData.x
                    y: mini.modelData.y
                    width: Math.max(Theme.wsGap, mini.modelData.w)
                    height: Math.max(Theme.wsGap, mini.modelData.h)

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.borderWidth
                        visible: !miniShot.hasContent
                        color: OverviewService.hueColor(mini.modelData.appId || mini.modelData.title, 0.45, 0.62)
                    }

                    OverviewCapture {
                        id: miniShot
                        anchors.fill: parent
                        addr: String(mini.modelData.addr || "")
                        livePreview: root.livePreview
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.markText.length > 0
                text: root.markText
                color: Theme.text
                font.pixelSize: Theme.fontPx
                font.family: Theme.uiFont
                font.bold: true
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen()
            }
        }
    }
}
