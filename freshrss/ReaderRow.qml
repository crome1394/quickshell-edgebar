import QtQuick
import qs.settings
import qs.theme

// One row in the reader list: a feed header (unread count from the
// server), a day header, or an article (dot while unread, ★ when starred,
// ▶ for video). `current` is the keyboard cursor; `chosen` is the article
// shown on the right.
Rectangle {
    id: root

    required property var row
    required property bool current
    required property bool chosen

    signal clicked()
    signal doubleClicked()

    readonly property string kind: String(root.row.kind || "")
    readonly property var item: root.row.item || null
    readonly property int indent: root.kind === "feed" ? 0 : (root.kind === "day" ? 1 : 2)

    implicitHeight: Theme.freshRssRowHeight
    radius: Theme.radiusSm
    color: root.chosen ? Theme.accentDim : (rowMouse.containsMouse ? Theme.hover : (root.kind === "feed" ? Theme.sectionBg : "transparent"))
    border.width: root.current ? Theme.borderWidth : 0
    border.color: Theme.accent

    function timeText(epoch) {
        const d = new Date(epoch * 1000)
        return d.toLocaleTimeString(Qt.locale(), "HH:mm")
    }

    Text {
        id: marker
        x: Theme.tabGap + root.indent * Theme.space * 2
        width: Theme.space * 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.kind === "item"
            ? (root.item && !root.item.read ? "●" : "")
            : (root.row.open ? "▾" : "▸")
        color: root.kind === "item" ? Theme.accent : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: root.kind === "item" ? Theme.smallPx - 2 : Theme.smallPx
    }

    Text {
        id: label
        anchors.left: marker.right
        anchors.right: side.left
        anchors.rightMargin: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: root.kind === "item" && root.item
            ? (root.item.starred ? "★ " : "") + (root.item.videoUrl.length ? "▶ " : "") + root.item.title
            : String(root.row.title || "")
        color: root.kind === "item" && root.item && root.item.read ? Theme.subtext : Theme.text
        font.family: Theme.uiFont
        font.pixelSize: root.kind === "day" ? Theme.smallPx : Theme.fontPx
        font.bold: root.kind === "feed" || (root.kind === "item" && root.item && !root.item.read)
    }

    Text {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (root.kind === "item")
                return root.item ? root.timeText(root.item.published) : ""
            if (root.kind === "feed")
                return (root.row.unread > 0 ? root.row.unread + " · " : "") + root.row.count
            return String(root.row.count)
        }
        color: root.kind === "feed" && root.row.unread > 0 ? Theme.accent : Theme.subtext
        font.family: Theme.fontFamily
        font.pixelSize: Theme.smallPx
        font.bold: root.kind === "feed" && root.row.unread > 0
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()

        HoverTip {
            message: root.kind === "feed"
                ? (root.row.unread > 0 ? root.row.unread + " unread on the server · " : "") + root.row.count + " loaded"
                : (root.kind === "item" && root.item ? root.item.feed + (root.item.author.length ? " · " + root.item.author : "") : "")
            show: rowMouse.containsMouse && message.length > 0
        }
    }
}
