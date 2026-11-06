pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.theme

Rectangle {
    id: root

    required property var families
    signal chosen(string family)
    signal dismiss()

    property string filter: ""

    function choose(family) {
        root.chosen(family)
    }

    function matches() {
        const query = root.filter.toLowerCase()
        const all = root.families || []
        const out = []
        if (!query.length || "bar font".indexOf(query) >= 0)
            out.push("")
        for (let i = 0; i < all.length && out.length < 80; i++) {
            const name = String(all[i])
            if (!query.length || name.toLowerCase().indexOf(query) >= 0)
                out.push(name)
        }
        return out
    }

    color: Theme.pageBg
    border.width: Theme.borderWidth
    border.color: Theme.border
    radius: Theme.radius

    TextField {
        id: search
        anchors.left: parent.left
        anchors.right: closeButton.left
        anchors.top: parent.top
        anchors.margins: Theme.space
        anchors.rightMargin: Theme.space
        height: Theme.fieldHeight
        placeholderText: "Search fonts"
        selectByMouse: true
        color: Theme.text
        placeholderTextColor: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        leftPadding: 8
        rightPadding: 8
        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: search.activeFocus ? Theme.accent : Theme.border
        }
        onTextChanged: root.filter = text
        Keys.onEscapePressed: (event) => {
            root.dismiss()
            event.accepted = true
        }
    }

    Rectangle {
        id: closeButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space
        width: Theme.fieldHeight
        height: Theme.fieldHeight
        radius: Theme.radiusSm
        color: closeMouse.containsMouse ? Theme.hover : Theme.pillBg
        border.width: Theme.borderWidth
        border.color: Theme.border
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: Theme.text
            font.pixelSize: Theme.fontPx
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismiss()
        }
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: search.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        contentWidth: width
        contentHeight: names.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: names
            width: flick.width

            Repeater {
                model: root.matches()
                delegate: Rectangle {
                    id: row
                    required property string modelData
                    required property int index
                    width: parent.width
                    height: Theme.fieldHeight
                    color: rowMouse.containsMouse ? Theme.hover : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        elide: Text.ElideRight
                        text: row.modelData.length ? row.modelData : "Bar font"
                        color: Theme.text
                        font.family: row.modelData.length ? row.modelData : Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(row.modelData)
                    }
                }
            }
        }
    }

    function resetSearch() {
        root.filter = ""
        search.text = ""
        search.forceActiveFocus()
    }

    Component.onCompleted: root.resetSearch()

    onVisibleChanged: {
        if (visible)
            root.resetSearch()
    }
}
