pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// A closed box that opens its choices underneath. Each choice has id, label, and an optional tip.
Item {
    id: root

    required property var choices
    required property string currentId
    property string emptyLabel: "Custom"
    property string tip: ""
    property bool open: false

    signal picked(string id)

    function labelFor(id) {
        const list = root.choices || []
        const want = String(id || "")
        for (let i = 0; i < list.length; i++) {
            if (list[i] && String(list[i].id) === want)
                return String(list[i].label || "")
        }
        return root.emptyLabel
    }

    readonly property int optionCount: (root.choices && root.choices.length) ? root.choices.length : 0
    readonly property int menuHeight: root.optionCount * Theme.fieldHeight

    implicitHeight: Theme.fieldHeight + (root.open ? root.menuHeight + Theme.borderWidth : 0)

    Rectangle {
        id: box
        width: parent.width
        height: Theme.fieldHeight
        radius: Theme.radiusSm
        color: boxMouse.containsMouse ? Theme.hover : Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: root.open ? Theme.accent : Theme.border

        Text {
            anchors.fill: parent
            anchors.leftMargin: Theme.space
            anchors.rightMargin: Theme.chip
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.labelFor(root.currentId)
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            text: root.open ? "▴" : "▾"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        MouseArea {
            id: boxMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open

            HoverTip {
                message: root.tip
                show: boxMouse.containsMouse && !root.open && root.tip.length > 0
            }
        }
    }

    Rectangle {
        visible: root.open
        y: Theme.fieldHeight + Theme.borderWidth
        width: parent.width
        height: root.menuHeight
        radius: Theme.radiusSm
        color: Theme.pageBg
        border.width: Theme.borderWidth
        border.color: Theme.border
        clip: true

        Column {
            width: parent.width

            Repeater {
                model: root.choices
                delegate: Rectangle {
                    id: option
                    required property var modelData
                    required property int index
                    readonly property string optionId: String(option.modelData.id || "")
                    readonly property bool chosen: option.optionId === root.currentId
                    readonly property string optionTip: String(option.modelData.tip || "")

                    width: parent.width
                    height: Theme.fieldHeight
                    color: option.chosen ? Theme.accentDim : (optionMouse.containsMouse ? Theme.hover : "transparent")

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space
                        anchors.rightMargin: Theme.space
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: String(option.modelData.label || "")
                        color: option.chosen ? Theme.wsActiveText : Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: option.chosen
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.picked(option.optionId)
                            root.open = false
                        }

                        HoverTip {
                            message: option.optionTip.length ? option.optionTip : String(option.modelData.label || "")
                            show: optionMouse.containsMouse
                        }
                    }
                }
            }
        }
    }
}
