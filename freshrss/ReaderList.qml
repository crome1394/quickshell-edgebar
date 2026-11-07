pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.theme

// The reader's left pane: feeds, days, and articles. A click moves the
// cursor there and opens the row; a double-click plays a video in mpv or
// opens the article in the browser. The cursor row stays in view. Keys
// are handled by FreshRssPanel, so the list's own arrow keys are off.
ListView {
    id: root

    required property ReaderModel reader

    clip: true
    spacing: Theme.borderWidth * 2
    keyNavigationEnabled: false
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: true
    model: root.reader.rows
    currentIndex: root.reader.cursor

    ScrollBar.vertical: ScrollBar {
        id: listBar
        policy: ScrollBar.AsNeeded
        width: Theme.scrollBarWidth
        padding: 0
        background: Item {}
        contentItem: Rectangle {
            implicitWidth: Theme.scrollBarWidth
            radius: width / 2
            color: listBar.pressed || listBar.hovered ? Theme.accent : Theme.subtext
        }
    }

    onCurrentIndexChanged: root.positionViewAtIndex(root.currentIndex, ListView.Contain)

    // An opened feed or day moves to the top, so its articles show below.
    // Later, so the new rows are in place first.
    Connections {
        target: root.reader
        function onRevealRequested(key) {
            Qt.callLater(() => {
                const at = root.reader.rowIndex(key)
                if (at >= 0)
                    root.positionViewAtIndex(at, ListView.Beginning)
            })
        }
    }

    delegate: ReaderRow {
        required property var modelData
        required property int index
        width: root.width - Theme.scrollBarWidth - Theme.tabGap
        row: modelData
        current: index === root.reader.cursor
        onClicked: {
            root.forceActiveFocus()
            root.reader.cursor = index
            if (modelData.kind === "item")
                root.reader.select(modelData.item)
            else
                root.reader.toggleRow(modelData)
        }
        onDoubleClicked: {
            if (modelData.kind !== "item")
                return
            if (modelData.item.videoUrl.length)
                FreshRssService.playInMpv(modelData.item.videoUrl)
            else
                FreshRssService.openInBrowser(modelData.item.url)
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - Theme.space * 4
        visible: root.count === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: FreshRssService.loading ? "Loading…" : (root.reader.searching ? "No matches." : "Nothing loaded.")
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
    }
}
