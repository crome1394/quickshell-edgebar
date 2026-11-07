pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.clipboard
import qs.components
import qs.config
import qs.services
import qs.theme

// The clipboard viewer: a card in the middle of the main monitor over a
// dimmed screen. Type to search; the list (newest first) is on the left
// and the highlighted entry shows in full on the right. Enter or a click
// copies it and closes, so Ctrl+V pastes it. Tab or Alt+Z zooms the
// preview to fill the card. shell.qml creates this only
// while ClipboardService.open. Keys: clipboard/ClipKeys.qml.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: window

    screen: ScreenService.mainScreen
    color: Theme.freshRssScrim
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    ClipModel {
        id: clips
    }

    ClipKeys {
        id: clipKeys
    }

    // Zoom (Tab or Alt+Z): the preview fills the card; ↑↓ still step
    // through the results and PgUp/PgDn scroll the preview.
    property bool zoomed: false

    // Where the pointer last was. Rows sliding under a still pointer (the
    // keys scrolled the list) do not take the highlight; moving does.
    property point lastPointer: Qt.point(-1, -1)

    // The first report only records where the pointer starts, so the
    // newest entry stays highlighted when the viewer opens under the mouse.
    function pointerMoved(at, index) {
        const first = window.lastPointer.x < 0
        if (at.x === window.lastPointer.x && at.y === window.lastPointer.y)
            return
        window.lastPointer = at
        if (!first)
            clips.moveTo(index)
    }

    function copy(entry) {
        if (ClipboardService.copy(entry))
            ClipboardService.hide()
    }

    function run(action) {
        if (action.indexOf("pick") === 0) {
            const e = clips.nth(Number(action.substring(4)))
            if (e)
                window.copy(e)
            return
        }
        switch (action) {
        case "down": clips.move(1); break
        case "up": clips.move(-1); break
        case "pageDown":
            if (window.zoomed)
                preview.scrollPage(1)
            else
                clips.move(list.pageRows)
            break
        case "pageUp":
            if (window.zoomed)
                preview.scrollPage(-1)
            else
                clips.move(-list.pageRows)
            break
        case "zoom":
            window.zoomed = !window.zoomed && !!clips.current
            break
        case "first": clips.moveTo(0); break
        case "last": clips.moveTo(clips.filtered.length - 1); break
        case "copy": window.copy(clips.current); break
        case "delete":
            if (clips.current)
                ClipboardService.remove(clips.current)
            break
        case "escape":
            if (window.zoomed)
                window.zoomed = false
            else if (search.text.length)
                search.text = ""
            else
                ClipboardService.hide()
            break
        }
    }

    function handleKey(event) {
        const action = clipKeys.actionFor(event)
        if (!action.length)
            return
        window.run(action)
        event.accepted = true
    }

    // A click on the dimmed area closes.
    MouseArea {
        anchors.fill: parent
        onClicked: ClipboardService.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Theme.clipboardWidth, window.width - Theme.space * 4)
        height: Math.min(Theme.clipboardHeight, window.height - Theme.space * 4)
        radius: Theme.radius
        // Solid even when the bar itself is see-through.
        color: Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border
        Keys.onPressed: (event) => window.handleKey(event)

        // Clicks on the card stay on the card.
        MouseArea {
            anchors.fill: parent
        }

        Row {
            id: topRow
            x: Theme.space * 2
            y: Theme.space * 2
            width: parent.width - Theme.space * 4
            spacing: Theme.space

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.clipboardGlyph
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost / 2
            }

            TextField {
                id: search
                width: parent.width - x - countText.width - parent.spacing
                height: Theme.fieldHeight
                focus: true
                verticalAlignment: Text.AlignVCenter
                placeholderText: "Search the clipboard history…"
                leftPadding: Theme.space
                color: Theme.text
                placeholderTextColor: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: Theme.fieldBg
                    border.width: Theme.borderWidth
                    border.color: search.activeFocus ? Theme.accent : Theme.border
                }
                onTextChanged: clips.search = text
                // Before the text box, so arrows, Enter, and Esc reach the list.
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: (event) => window.handleKey(event)
            }

            Text {
                id: countText
                anchors.verticalCenter: parent.verticalCenter
                text: clips.search.length ? clips.filtered.length + " of " + ClipboardService.entries.length
                    : ClipboardService.entries.length + " saved"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        ListView {
            id: list
            readonly property int pageRows: Math.max(1, Math.floor(height / Theme.clipboardRowHeight) - 1)
            anchors.left: parent.left
            anchors.top: topRow.bottom
            anchors.bottom: hintRow.top
            anchors.margins: Theme.space * 2
            visible: !window.zoomed
            width: Math.round((card.width - Theme.space * 4) * Theme.clipboardListShare)
            clip: true
            spacing: Theme.borderWidth * 2
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            model: clips.filtered
            currentIndex: clips.cursor
            onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: ClipRow {
                required property var modelData
                required property int index
                width: list.width - Theme.scrollBarWidth
                entry: modelData
                current: index === clips.cursor
                number: index + 1
                onHovered: (at) => window.pointerMoved(at, index)
                onClicked: window.copy(modelData)
                onDeleteClicked: ClipboardService.remove(modelData)
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space * 2
                visible: list.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: {
                    if (!ClipboardService.checked || ClipboardService.loading)
                        return "Loading…"
                    if (!ClipboardService.available)
                        return "Clipboard history needs cliphist.\nInstall it with: sudo pacman -S cliphist"
                    if (!ClipboardSettings.enabled())
                        return "History is off. Turn it on in Settings → Tools → Clipboard."
                    if (clips.search.length)
                        return "Nothing matches."
                    return "Nothing copied yet.\nCopy something and it shows up here."
                }
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        ClipPreview {
            id: preview
            anchors.left: window.zoomed ? parent.left : list.right
            anchors.right: parent.right
            anchors.top: topRow.bottom
            anchors.bottom: hintRow.top
            anchors.leftMargin: window.zoomed ? Theme.space * 2 : Theme.space
            anchors.rightMargin: Theme.space * 2
            anchors.topMargin: Theme.space * 2
            anchors.bottomMargin: Theme.space * 2
            entry: clips.current
            zoomed: window.zoomed
            where: clips.filtered.length ? (clips.cursor + 1) + " of " + clips.filtered.length : ""
            onCopyClicked: window.copy(clips.current)
            onDeleteClicked: {
                if (clips.current)
                    ClipboardService.remove(clips.current)
            }
        }

        Flow {
            id: hintRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space * 2
            height: Theme.keyCapHeight
            clip: true
            spacing: Theme.space * 2

            Repeater {
                model: window.zoomed ? clipKeys.zoomHints : clipKeys.hints
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
    }

    Component.onCompleted: search.forceActiveFocus()
}
