import QtQuick
import qs.settings
import qs.theme

// One row in the reader list: a feed header (unread badge from the
// server), a day header, or an article (dot while unread, ★ when starred,
// ▶ for video). `current` is the keyboard cursor, the only highlighted
// row; the article it is on is the one shown on the right. Feed and
// article titles wrap up to Theme.freshRssTitleLines lines. A feed shows
// its site icon, or its first letter when there is none.
Rectangle {
    id: root

    required property var row
    required property bool current

    signal clicked()
    signal doubleClicked()

    readonly property string kind: String(root.row.kind || "")
    readonly property var item: root.row.item || null
    readonly property bool unreadItem: root.kind === "item" && !!root.item && !root.item.read
    readonly property int indent: root.kind === "feed" ? 0 : (root.kind === "day" ? 1 : 2)

    implicitHeight: Math.max(Theme.freshRssRowHeight, label.implicitHeight + Theme.freshRssRowPad * 2)
    radius: Theme.radiusSm
    color: root.current ? Theme.accentDim : (root.kind === "feed" ? Theme.sectionBg : "transparent")

    function timeText(epoch) {
        const d = new Date(epoch * 1000)
        return d.toLocaleTimeString(Qt.locale(), "HH:mm")
    }

    // Cursor bar along the left edge.
    Rectangle {
        visible: root.current
        x: 0
        y: Theme.freshRssRowPad / 2
        width: Theme.freshRssCursorBar
        height: parent.height - Theme.freshRssRowPad
        radius: width / 2
        color: Theme.accent
    }

    Text {
        id: marker
        x: Theme.space + root.indent * Theme.space * 2
        width: Theme.space * 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.kind === "item"
            ? (root.unreadItem ? "●" : "")
            : (root.row.open ? "▾" : "▸")
        color: root.kind === "item" ? Theme.accent : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: root.kind === "item" ? Theme.smallPx - 2 : Theme.smallPx
    }

    Item {
        id: iconBox
        visible: root.kind === "feed"
        anchors.left: marker.right
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? Theme.freshRssIconSize : 0
        height: Theme.freshRssIconSize

        Rectangle {
            anchors.fill: parent
            visible: siteIcon.status !== Image.Ready
            radius: Theme.radiusSm / 2
            color: Theme.accentDim

            Text {
                anchors.centerIn: parent
                text: String(root.row.title || "?").replace(/^[^A-Za-z0-9]+/, "").charAt(0).toUpperCase()
                color: Theme.wsActiveText
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx - 2
                font.bold: true
            }
        }

        Image {
            id: siteIcon
            anchors.fill: parent
            source: root.kind === "feed" ? String(root.row.icon || "") : ""
            sourceSize.width: Theme.freshRssIconSize * 2
            sourceSize.height: Theme.freshRssIconSize * 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }
    }

    Text {
        id: label
        anchors.left: iconBox.right
        anchors.leftMargin: root.kind === "feed" ? Theme.space : 0
        anchors.right: side.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: root.kind === "day" ? Text.NoWrap : Text.WordWrap
        maximumLineCount: root.kind === "day" ? 1 : Theme.freshRssTitleLines
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: root.kind === "item" && root.item
            ? (root.item.starred ? "★ " : "") + (root.item.videoUrl.length ? "▶ " : "") + root.item.title
            : String(root.row.title || "")
        color: root.kind === "day" || (root.kind === "item" && !root.unreadItem) ? Theme.subtext : Theme.text
        font.family: Theme.uiFont
        font.pixelSize: root.kind === "day" ? Theme.smallPx : Theme.fontPx
        font.bold: root.kind === "feed" || root.unreadItem
        font.capitalization: root.kind === "day" ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: root.kind === "day" ? 1 : 0
    }

    Row {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.tabGap

        // Unread badge on a feed.
        Rectangle {
            visible: root.kind === "feed" && root.row.unread > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(height, badgeText.implicitWidth + Theme.space)
            height: Theme.freshRssBadgeHeight
            radius: height / 2
            color: Theme.accent

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: String(root.row.unread || 0)
                color: Theme.wsActiveText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallPx
                font.bold: true
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.kind === "item"
                ? (root.item ? root.timeText(root.item.published) : "")
                : String(root.row.count)
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallPx
        }
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
