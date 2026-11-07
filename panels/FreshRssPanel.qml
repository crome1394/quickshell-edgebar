pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.freshrss
import qs.services
import qs.theme

// Real toplevel so Hyprland window rules can match it.
// Title: FreshRSS
// shell.qml creates this only while FreshRssService.open, so a closed
// reader holds no articles.
//
// Keys: see freshrss/ReaderKeys.qml (also shown in the window with ?).
// One handler reads that table, so Shift is matched exactly (r and
// Shift+R are different keys).
FloatingWindow {
    id: window

    title: "FreshRSS"
    implicitWidth: Theme.freshRssWidth
    implicitHeight: Theme.freshRssHeight
    minimumSize: Qt.size(Theme.freshRssMinWidth, Theme.freshRssMinHeight)
    color: Theme.pageBg
    visible: true

    property string flash: ""
    property int listWidth: FreshRssSettings.listWidth()

    readonly property bool typing: controls.searchFocused
    readonly property var item: readerState.selected
    property bool helpOpen: false

    function say(text) {
        window.flash = text
        flashTimer.restart()
    }

    function leaveSearch() {
        list.forceActiveFocus()
    }

    ReaderModel {
        id: readerState
    }

    Component.onCompleted: {
        ScreenService.fitWindow(window, Theme.freshRssWidth, Theme.freshRssHeight, Theme.freshRssMinWidth, Theme.freshRssMinHeight)
        readerState.reload()
        list.forceActiveFocus()
    }

    // The compositor closing the window only hides it.
    onVisibleChanged: {
        if (!window.visible)
            FreshRssService.hide()
    }

    Timer {
        id: flashTimer
        interval: Theme.copiedFlashMs
        onTriggered: window.flash = ""
    }

    ReaderKeys {
        id: readerKeys
    }

    PageReader {
        id: pageReader
    }

    // Web page view: once the cursor rests on an article that wants its
    // page (f, or the feed's "Always"), fetch it. Kept while the window is open.
    readonly property bool pageNeeded: readerState.fullWanted && !readerState.page
    onPageNeededChanged: {
        if (window.pageNeeded)
            pageDelay.restart()
    }

    Timer {
        id: pageDelay
        interval: Theme.freshRssPageDelayMs
        onTriggered: {
            const it = readerState.selected
            if (!window.pageNeeded || !it)
                return
            const id = it.id
            readerState.setPage(id, { state: "loading", html: "" })
            pageReader.fetch(it.url, (ok, html) => readerState.setPage(id, { state: ok ? "ready" : "failed", html: html }))
        }
    }

    // Moving on cancels a page still loading for the last article.
    Connections {
        target: readerState
        function onSelectedIdChanged() {
            const page = readerState.pages
            for (const id in page) {
                if (page[id].state === "loading" && id !== readerState.selectedId) {
                    pageReader.cancel()
                    readerState.setPage(id, null)
                }
            }
            if (window.pageNeeded)
                pageDelay.restart()
        }
    }

    // r, u, m, and s act on the highlighted article only.
    function needArticle() {
        if (readerState.cursorItem)
            return readerState.cursorItem
        window.say("Move to an article first. Shift+R and Shift+U mark the whole feed.")
        return null
    }

    function markSpace() {
        const target = readerState.spaceTarget()
        if (!target)
            return
        if (target.kind === "feed") {
            if (target.read)
                FreshRssService.markFeedRead(target.feedId)
            else
                FreshRssService.markFeedUnread(target.feedId)
        } else {
            FreshRssService.setReadMany(target.items, target.read)
        }
    }

    // Runs one action from ReaderKeys.
    function run(action) {
        const shown = window.item
        let it = null
        switch (action) {
        case "down": readerState.moveCursor(1); break
        case "up": readerState.moveCursor(-1); break
        case "pageDown": readerState.moveCursor(10); break
        case "pageUp": readerState.moveCursor(-10); break
        case "first": readerState.moveCursorTo(0); break
        case "last": readerState.moveCursorTo(readerState.rows.length - 1); break
        case "nextArticle": readerState.nextArticle(1); break
        case "prevArticle": readerState.nextArticle(-1); break
        case "open": readerState.activateCursor(); break
        case "close": readerState.toggleAtCursor(); break
        case "read":
            it = window.needArticle()
            if (it)
                FreshRssService.setRead(it, true)
            break
        case "unread":
            it = window.needArticle()
            if (it)
                FreshRssService.setRead(it, false)
            break
        case "space": window.markSpace(); break
        case "star":
            it = window.needArticle()
            if (it)
                FreshRssService.setStarred(it, !it.starred)
            break
        case "feedRead":
            if (readerState.actionFeedId.length)
                FreshRssService.markFeedRead(readerState.actionFeedId)
            break
        case "feedUnread":
            if (readerState.actionFeedId.length)
                FreshRssService.markFeedUnread(readerState.actionFeedId)
            break
        case "browser":
            if (shown)
                FreshRssService.openInBrowser(shown.url)
            break
        case "copy":
            if (shown) {
                FreshRssService.copyLink(shown.url)
                window.say("Copied the link.")
            }
            break
        case "full": readerState.toggleFull(); break
        case "mpv":
            if (shown && !FreshRssService.playInMpv(shown.videoUrl))
                window.say("This article has no video.")
            break
        case "find": controls.focusSearch(); break
        case "reload": readerState.reload(); break
        case "help": window.helpOpen = !window.helpOpen; break
        case "escape":
            if (window.typing)
                window.leaveSearch()
            else if (readerState.search.length)
                controls.clearSearch()
            else
                FreshRssService.hide()
            break
        }
    }

    // Key presses not taken by the search box arrive here. While the
    // shortcut sheet is open, ? and Esc close it and other keys wait.
    function handleKey(event) {
        const action = readerKeys.actionFor(event, window.typing)
        if (window.helpOpen) {
            if (action === "help" || action === "escape")
                window.helpOpen = false
            event.accepted = true
            return
        }
        if (!action.length)
            return
        window.run(action)
        event.accepted = true
    }

    Item {
        anchors.fill: parent
        Keys.onPressed: (event) => window.handleKey(event)

        Rectangle {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Theme.headerHeight
            color: Theme.barBg

            MouseArea {
                anchors.fill: parent
                onPressed: window.startSystemMove()
            }

            Row {
                id: titleRow
                anchors.left: parent.left
                anchors.leftMargin: Theme.space * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.freshRssGlyph
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost / 2
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "FreshRSS"
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost / 2
                    font.bold: true
                }

                Rectangle {
                    visible: FreshRssService.unread > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: unreadText.implicitWidth + Theme.space * 2
                    height: Theme.freshRssBadgeHeight
                    radius: height / 2
                    color: Theme.accent

                    Text {
                        id: unreadText
                        anchors.centerIn: parent
                        text: FreshRssService.unread + " unread"
                        color: Theme.wsActiveText
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                        font.bold: true
                    }
                }
            }

            Text {
                anchors.left: titleRow.right
                anchors.leftMargin: Theme.space * 2
                anchors.right: headerActions.left
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: FreshRssService.loading ? "Loading…"
                    : readerState.filtered.length + " shown of " + FreshRssService.items.length
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Row {
                id: headerActions
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.tabGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.tabGap

                ActionChip {
                    label: "Shortcuts"
                    caps: ["?"]
                    active: window.helpOpen
                    onClicked: window.helpOpen = !window.helpOpen
                }

                ActionChip {
                    label: "Reload"
                    caps: ["Ctrl", "r"]
                    onClicked: readerState.reload()
                }
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.fieldHeight
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: closeMouse.containsMouse ? Theme.hover : "transparent"
                border.width: Theme.borderWidth
                border.color: closeMouse.containsMouse ? Theme.danger : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? Theme.danger : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: FreshRssService.hide()
                }
            }
        }

        ReaderControls {
            id: controls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.margins: Theme.space
            reader: readerState
            onSearchDone: window.leaveSearch()
        }

        Text {
            id: message
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: controls.bottom
            anchors.margins: Theme.space
            visible: text.length > 0
            height: visible ? implicitHeight : 0
            wrapMode: Text.WordWrap
            text: FreshRssService.error.length ? FreshRssService.error : window.flash
            color: FreshRssService.error.length ? Theme.danger : Theme.ok
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Item {
            id: split
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: message.visible ? message.bottom : controls.bottom
            anchors.bottom: footer.top
            anchors.margins: Theme.space

            readonly property int leftWidth: Math.max(Theme.freshRssListMin, Math.min(window.listWidth, width - Theme.freshRssDetailMin - handle.width))

            ReaderList {
                id: list
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: split.leftWidth
                reader: readerState
                focus: true
            }

            // Drag to resize the panes; the width is saved on release.
            Rectangle {
                id: handle
                anchors.left: list.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Theme.space
                color: handleMouse.pressed || handleMouse.containsMouse ? Theme.hover : "transparent"
                radius: Theme.radiusSm

                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.borderWidth * 2
                    height: Theme.chip
                    radius: width
                    color: Theme.subtext
                }

                MouseArea {
                    id: handleMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.borderWidth * 2
                    hoverEnabled: true
                    cursorShape: Qt.SplitHCursor
                    property real startX: 0
                    property int startWidth: 0
                    onPressed: (mouse) => {
                        startX = mapToItem(split, mouse.x, 0).x
                        startWidth = split.leftWidth
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            window.listWidth = startWidth + Math.round(mapToItem(split, mouse.x, 0).x - startX)
                    }
                    onReleased: FreshRssSettings.setListWidthLive(split.leftWidth)
                }
            }

            ReaderDetail {
                anchors.left: handle.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                reader: readerState
                onCopied: window.say("Copied the link.")
            }
        }

        // A few common keys; ? shows them all.
        Flow {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space
            height: Theme.keyCapHeight
            clip: true
            spacing: Theme.space * 2

            Repeater {
                model: readerKeys.footer
                delegate: Row {
                    id: hint
                    required property var modelData
                    spacing: Theme.tabGap

                    Repeater {
                        model: hint.modelData.caps
                        delegate: KeyCap {
                            required property string modelData
                            label: modelData
                        }
                    }

                    Text {
                        height: Theme.keyCapHeight
                        verticalAlignment: Text.AlignVCenter
                        text: hint.modelData.text
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }
        }

        ReaderKeysHelp {
            anchors.fill: parent
            keys: readerKeys
            open: window.helpOpen
            onCloseRequested: window.helpOpen = false
        }
    }
}
