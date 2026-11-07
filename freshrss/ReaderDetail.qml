pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.settings
import qs.theme

// The article pane: feed actions for the feed under the cursor, the
// article's actions, and its text. Links open in the browser. Images in
// the article show as [image] links, so nothing loads from the network.
Rectangle {
    id: root

    required property ReaderModel reader

    signal copied(string what)

    readonly property var item: root.reader.selected

    radius: Theme.radius
    color: Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    function stamp(epoch) {
        return new Date(epoch * 1000).toLocaleString(Qt.locale(), "ddd d MMM yyyy, HH:mm")
    }

    Column {
        id: head
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        spacing: Theme.tabGap

        Flow {
            visible: root.reader.actionFeedId.length > 0
            width: parent.width
            spacing: Theme.tabGap

            Text {
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                width: Math.min(implicitWidth, parent.width / 2)
                elide: Text.ElideRight
                text: root.reader.actionFeedTitle
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            ChipButton {
                label: "Mark feed read"
                tip: "Every article in this feed, on the server (Shift+R)"
                onClicked: FreshRssService.markFeedRead(root.reader.actionFeedId)
            }

            ChipButton {
                label: "Mark feed unread"
                tip: "The loaded articles of this feed (Shift+U)"
                onClicked: FreshRssService.markFeedUnread(root.reader.actionFeedId)
            }
        }

        Rectangle {
            visible: root.reader.actionFeedId.length > 0
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }

        Text {
            visible: !root.item
            width: parent.width
            wrapMode: Text.WordWrap
            text: FreshRssService.items.length
                ? "Pick an article on the left (Enter or →), or step through them with j and k."
                : (FreshRssService.loading ? "Loading…" : "No articles here. Try another scope or more days.")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Text {
            visible: !!root.item
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.item ? root.item.title : ""
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx + 3
            font.bold: true
        }

        Text {
            visible: !!root.item
            width: parent.width
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.item ? root.item.feed + (root.item.author.length ? " · " + root.item.author : "") + " · " + root.stamp(root.item.published) : ""
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Flow {
            visible: !!root.item
            width: parent.width
            spacing: Theme.tabGap

            ChipButton {
                label: "Open in browser"
                tip: "Open the article (b)"
                enabled: !!root.item && root.item.url.length > 0
                onClicked: FreshRssService.openInBrowser(root.item.url)
            }

            ChipButton {
                label: "Copy link"
                tip: "Copy the article's address (c)"
                enabled: !!root.item && root.item.url.length > 0
                onClicked: {
                    FreshRssService.copyLink(root.item.url)
                    root.copied(root.item.url)
                }
            }

            ChipButton {
                visible: !!root.item && root.item.videoUrl.length > 0
                label: "Play in mpv"
                tip: "Play the video in mpv (v). YouTube needs yt-dlp."
                onClicked: FreshRssService.playInMpv(root.item.videoUrl)
            }

            ChipButton {
                label: root.item && root.item.read ? "Mark unread" : "Mark read"
                tip: "m"
                onClicked: FreshRssService.setRead(root.item, !root.item.read)
            }

            ChipButton {
                label: root.item && root.item.starred ? "★ Unstar" : "☆ Star"
                active: !!root.item && root.item.starred
                tip: "Shift+S"
                onClicked: FreshRssService.setStarred(root.item, !root.item.starred)
            }
        }
    }

    Flickable {
        id: bodyScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space
        visible: !!root.item
        contentWidth: width
        contentHeight: bodyText.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: bodyBar
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: bodyBar.pressed || bodyBar.hovered ? Theme.accent : Theme.subtext
            }
        }

        Text {
            id: bodyText
            width: bodyScroll.width - Theme.scrollBarWidth - Theme.tabGap
            wrapMode: Text.WordWrap
            textFormat: Text.RichText
            text: root.item ? (root.item.html.length ? root.item.html : "<i>No text. Open it in the browser.</i>") : ""
            color: Theme.text
            linkColor: Theme.accent
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            onLinkActivated: (link) => FreshRssService.openInBrowser(link)

            HoverHandler {
                cursorShape: bodyText.hoveredLink.length ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    // New article: back to the top.
    onItemChanged: bodyScroll.contentY = 0
}
