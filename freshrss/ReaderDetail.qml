pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
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
        x: Theme.space * 2
        y: Theme.space * 2
        width: parent.width - Theme.space * 4
        spacing: Theme.space

        // Feed actions for the feed under the cursor.
        Item {
            visible: root.reader.actionFeedId.length > 0
            width: parent.width
            height: feedActions.height

            Text {
                anchors.left: parent.left
                anchors.right: feedActions.left
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.reader.actionFeedTitle
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            Row {
                id: feedActions
                anchors.right: parent.right
                spacing: Theme.tabGap

                ActionChip {
                    label: "Feed read"
                    caps: ["Shift", "r"]
                    tip: "Every article in this feed, on the server"
                    onClicked: FreshRssService.markFeedRead(root.reader.actionFeedId)
                }

                ActionChip {
                    label: "Feed unread"
                    caps: ["Shift", "u"]
                    tip: "The loaded articles of this feed"
                    onClicked: FreshRssService.markFeedUnread(root.reader.actionFeedId)
                }
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
                ? "Move to an article on the left with ↑ ↓ or j k. Press ? for every shortcut."
                : (FreshRssService.loading ? "Loading…" : "No articles here. Try another scope or more days.")
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }

        Text {
            visible: !!root.item
            width: parent.width
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.item ? root.item.feed : ""
            color: Theme.accent
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
        }

        Text {
            visible: !!root.item
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.item ? (root.item.starred ? "★ " : "") + root.item.title : ""
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost
            font.bold: true
        }

        Text {
            visible: !!root.item
            width: parent.width
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.item ? (root.item.author.length ? root.item.author + " · " : "") + root.stamp(root.item.published) : ""
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Flow {
            visible: !!root.item
            width: parent.width
            spacing: Theme.tabGap

            ActionChip {
                label: "Open"
                caps: ["b"]
                tip: "Open the article in the browser"
                enabled: !!root.item && root.item.url.length > 0
                onClicked: FreshRssService.openInBrowser(root.item.url)
            }

            ActionChip {
                label: "Copy link"
                caps: ["c"]
                tip: "Copy the article's address"
                enabled: !!root.item && root.item.url.length > 0
                onClicked: {
                    FreshRssService.copyLink(root.item.url)
                    root.copied(root.item.url)
                }
            }

            ActionChip {
                visible: !!root.item && root.item.videoUrl.length > 0
                label: "▶ Play"
                caps: ["v"]
                tip: "Play the video in mpv. YouTube needs yt-dlp."
                onClicked: FreshRssService.playInMpv(root.item.videoUrl)
            }

            ActionChip {
                label: root.item && root.item.read ? "Mark unread" : "Mark read"
                caps: [root.item && root.item.read ? "u" : "r"]
                tip: "Space also switches read and unread"
                onClicked: FreshRssService.setRead(root.item, !root.item.read)
            }

            ActionChip {
                label: "Web page"
                caps: ["f"]
                active: root.reader.fullWanted
                enabled: !!root.item && root.item.url.length > 0
                tip: "Show the article's web page here instead of the feed text"
                onClicked: root.reader.toggleFull()
            }

            ActionChip {
                label: "Always for this feed"
                active: !!root.item && FreshRssSettings.isFullFeed(root.item.feedId)
                enabled: !!root.item && root.item.url.length > 0
                tip: "Open every article of this feed as its web page"
                onClicked: FreshRssSettings.setFullFeedLive(root.item.feedId, !FreshRssSettings.isFullFeed(root.item.feedId))
            }

            ActionChip {
                label: root.item && root.item.starred ? "★ Starred" : "☆ Star"
                caps: ["s"]
                active: !!root.item && root.item.starred
                tip: "Star or unstar the article"
                onClicked: FreshRssService.setStarred(root.item, !root.item.starred)
            }
        }

        Rectangle {
            visible: !!root.item
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }
    }

    Flickable {
        id: bodyScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.space * 2
        anchors.rightMargin: Theme.space
        anchors.topMargin: Theme.space
        anchors.bottomMargin: Theme.space
        visible: !!root.item
        contentWidth: width
        contentHeight: bodyColumn.implicitHeight
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

        Column {
            id: bodyColumn
            width: bodyScroll.width - Theme.scrollBarWidth - Theme.tabGap
            spacing: Theme.space

            // Lead picture (a video's still frame). Click: play or open.
            Item {
                visible: lead.status === Image.Ready
                width: parent.width
                height: visible ? Math.min(Theme.freshRssLeadImageMax, lead.paintedHeight) : 0

                Image {
                    id: lead
                    width: parent.width
                    height: Theme.freshRssLeadImageMax
                    source: root.item ? root.item.image : ""
                    sourceSize.width: Theme.freshRssWidth
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignTop
                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    visible: !!root.item && root.item.videoUrl.length > 0
                    x: (lead.paintedWidth - width) / 2
                    y: (parent.height - height) / 2
                    width: Theme.fieldHeight * 2
                    height: width
                    radius: width / 2
                    color: Theme.freshRssScrim

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: Theme.borderWidth * 2
                        text: "▶"
                        color: Theme.text
                        font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost
                    }
                }

                MouseArea {
                    x: 0
                    width: lead.paintedWidth
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.item.videoUrl.length)
                            FreshRssService.playInMpv(root.item.videoUrl)
                        else
                            FreshRssService.openInBrowser(root.item.url)
                    }
                }
            }

            // Web page view status while it loads or when it failed.
            Text {
                visible: text.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: !root.reader.fullWanted || !root.reader.page ? (root.reader.fullWanted ? "Loading the web page…" : "")
                    : (root.reader.page.state === "loading" ? "Loading the web page…"
                        : (root.reader.page.state === "failed" ? root.reader.page.html + " Showing the feed text." : ""))
                color: root.reader.page && root.reader.page.state === "failed" ? Theme.danger : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.italic: true
            }

            Text {
                id: bodyText
                width: parent.width
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                // Rich text ignores linkColor, so links get the accent by style.
                text: !root.item ? ""
                    : "<style>a { color: " + Theme.accent + "; }</style>" + (root.reader.fullWanted && root.reader.page && root.reader.page.state === "ready" ? root.reader.page.html
                        : (root.item.html.length ? root.item.html : "<i>No text. Open it in the browser.</i>"))
                color: Theme.text
                linkColor: Theme.accent
                lineHeight: Theme.freshRssBodyLineHeight
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                onLinkActivated: (link) => FreshRssService.openInBrowser(link)

                HoverHandler {
                    cursorShape: bodyText.hoveredLink.length ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    // New article: back to the top.
    onItemChanged: bodyScroll.contentY = 0
}
