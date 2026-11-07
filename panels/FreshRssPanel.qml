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
// Keys (not while typing in search, except Esc, Ctrl+F, Ctrl+R):
//   w s ↑ ↓  move the cursor        Space a ←  open or close feed or day
//   Enter d →  open article / header   j k  next or previous article
//   / Ctrl+F  search    b  browser    c  copy link    v  play in mpv
//   m  read/unread    Shift+S  star    Shift+R  feed read   Shift+U  feed unread
//   r Ctrl+R  reload   Esc  leave search, clear it, or close
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

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            if (window.typing)
                window.leaveSearch()
            else if (readerState.search.length)
                controls.clearSearch()
            else
                FreshRssService.hide()
        }
    }
    Shortcut { sequence: "Ctrl+F"; context: Qt.WindowShortcut; onActivated: controls.focusSearch() }
    Shortcut { sequence: "Ctrl+R"; context: Qt.WindowShortcut; onActivated: readerState.reload() }
    Shortcut { sequence: "/"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: controls.focusSearch() }
    Shortcut { sequence: "R"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.reload() }
    Shortcut { sequence: "W"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(-1) }
    Shortcut { sequence: "S"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(1) }
    Shortcut { sequence: "Up"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(-1) }
    Shortcut { sequence: "Down"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(1) }
    Shortcut { sequence: "PgUp"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(-10) }
    Shortcut { sequence: "PgDown"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.moveCursor(10) }
    Shortcut { sequence: "Space"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.toggleAtCursor() }
    Shortcut { sequence: "A"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.toggleAtCursor() }
    Shortcut { sequence: "Left"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.toggleAtCursor() }
    Shortcut { sequence: "Return"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.activateCursor() }
    Shortcut { sequence: "Enter"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.activateCursor() }
    Shortcut { sequence: "D"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.activateCursor() }
    Shortcut { sequence: "Right"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.activateCursor() }
    Shortcut { sequence: "J"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.nextArticle(1) }
    Shortcut { sequence: "K"; context: Qt.WindowShortcut; enabled: !window.typing; onActivated: readerState.nextArticle(-1) }
    Shortcut {
        sequence: "B"
        context: Qt.WindowShortcut
        enabled: !window.typing && !!window.item
        onActivated: FreshRssService.openInBrowser(window.item.url)
    }
    Shortcut {
        sequence: "C"
        context: Qt.WindowShortcut
        enabled: !window.typing && !!window.item
        onActivated: {
            FreshRssService.copyLink(window.item.url)
            window.say("Copied the link.")
        }
    }
    Shortcut {
        sequence: "V"
        context: Qt.WindowShortcut
        enabled: !window.typing && !!window.item
        onActivated: {
            if (!FreshRssService.playInMpv(window.item.videoUrl))
                window.say("This article has no video.")
        }
    }
    Shortcut {
        sequence: "M"
        context: Qt.WindowShortcut
        enabled: !window.typing && !!window.item
        onActivated: FreshRssService.setRead(window.item, !window.item.read)
    }
    Shortcut {
        sequence: "Shift+S"
        context: Qt.WindowShortcut
        enabled: !window.typing && !!window.item
        onActivated: FreshRssService.setStarred(window.item, !window.item.starred)
    }
    Shortcut {
        sequence: "Shift+R"
        context: Qt.WindowShortcut
        enabled: !window.typing && readerState.actionFeedId.length > 0
        onActivated: FreshRssService.markFeedRead(readerState.actionFeedId)
    }
    Shortcut {
        sequence: "Shift+U"
        context: Qt.WindowShortcut
        enabled: !window.typing && readerState.actionFeedId.length > 0
        onActivated: FreshRssService.markFeedUnread(readerState.actionFeedId)
    }

    Item {
        anchors.fill: parent

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

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.leftMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.freshRssGlyph + "  FreshRSS"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            Text {
                anchors.left: titleText.right
                anchors.leftMargin: Theme.space * 2
                anchors.right: refreshButton.left
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: FreshRssService.loading ? "Loading…"
                    : FreshRssService.unread + " unread · " + readerState.filtered.length + " shown of " + FreshRssService.items.length
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Rectangle {
                id: refreshButton
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.tabGap
                anchors.verticalCenter: parent.verticalCenter
                width: refreshLabel.implicitWidth + Theme.space * 2
                height: Theme.fieldHeight - Theme.tabGap
                radius: Theme.radiusSm
                color: refreshMouse.containsMouse ? Theme.hover : "transparent"
                border.width: Theme.borderWidth
                border.color: Theme.border

                Text {
                    id: refreshLabel
                    anchors.centerIn: parent
                    text: "Reload"
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: readerState.reload()
                }
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.chip + Theme.tabGap
                height: Theme.chip
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

        Text {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space
            elide: Text.ElideRight
            text: "w/s ↑/↓ move · Space/← open-close · Enter/→ open · j/k articles · / search · b browser · c copy link · v mpv · m read · ⇧S star · ⇧R/⇧U feed read/unread · r reload · Esc"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }
}
