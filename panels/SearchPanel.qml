pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.search
import qs.services
import qs.theme

// The launcher, Pop Launcher style: a search box near the top of the main
// monitor with results under it. Type to search; Enter runs the
// highlighted row; Tab completes; ? lists the prefixes. A click outside
// closes. shell.qml creates this only while SearchService.open, so a
// closed launcher runs and reads nothing. Keys: search/SearchKeys.qml.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: window

    screen: ScreenService.mainScreen
    color: Config.searchDim ? Theme.freshRssScrim : "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    SearchModel {
        id: finder
        onFillRequested: (text) => {
            search.text = text
            search.cursorPosition = search.text.length
        }
    }

    SearchKeys {
        id: keys
    }

    // Where the pointer last was. Rows sliding under a still pointer do
    // not take the highlight; moving does.
    property point lastPointer: Qt.point(-1, -1)

    function pointerMoved(at, index) {
        const first = window.lastPointer.x < 0
        if (at.x === window.lastPointer.x && at.y === window.lastPointer.y)
            return
        window.lastPointer = at
        if (!first)
            finder.moveTo(index)
    }

    function activate(row) {
        if (finder.activate(row))
            SearchService.hide()
    }

    function run(action) {
        if (action.indexOf("pick") === 0) {
            const row = finder.nth(Number(action.substring(4)) - 1)
            if (row)
                window.activate(row)
            return
        }
        switch (action) {
        case "down": finder.move(1); break
        case "up": finder.move(-1); break
        case "pageDown": finder.moveTo(Math.min(finder.results.length - 1, finder.cursor + list.pageRows)); break
        case "pageUp": finder.moveTo(Math.max(0, finder.cursor - list.pageRows)); break
        case "open": window.activate(finder.current); break
        case "context": finder.toggleContext(); break
        case "complete": finder.complete(); break
        case "escape":
            if (finder.contextRow)
                finder.contextRow = null
            else if (search.text.length)
                search.text = ""
            else
                SearchService.hide()
            break
        }
    }

    function handleKey(event) {
        const action = keys.actionFor(event)
        if (!action.length)
            return
        window.run(action)
        event.accepted = true
    }

    // A click outside the card closes.
    MouseArea {
        anchors.fill: parent
        onClicked: SearchService.hide()
    }

    Rectangle {
        id: card
        readonly property int pad: Theme.space * 1.5
        readonly property int shownRows: Math.min(finder.results.length, finder.maxRows)
        readonly property int listHeight: card.shownRows * (Theme.searchRowHeight + list.spacing)
        readonly property int fullHeight: card.pad * 2 + Theme.searchFieldHeight
            + (card.shownRows > 0 ? Theme.space + card.listHeight : 0) + Theme.space + Theme.keyCapHeight
        // The tallest the card gets, so a centered card does not jump as results change.
        readonly property int tallest: card.pad * 2 + Theme.searchFieldHeight + Theme.space * 2 + Theme.keyCapHeight
            + finder.maxRows * (Theme.searchRowHeight + list.spacing)

        x: Math.round((window.width - card.width) / 2)
        y: Config.searchPlace === "center" ? Math.max(Theme.space, Math.round((window.height - card.tallest) / 2))
            : Math.round(window.height * Theme.searchTopShare)
        width: Math.min(Theme.searchWidth, window.width - Theme.space * 4)
        height: card.fullHeight
        radius: Theme.radius
        // Solid even when the bar itself is see-through.
        color: Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border

        // Clicks on the card stay on the card.
        MouseArea {
            anchors.fill: parent
        }

        TextField {
            id: search
            x: card.pad
            y: card.pad
            width: card.width - card.pad * 2
            height: Theme.searchFieldHeight
            focus: true
            verticalAlignment: Text.AlignVCenter
            placeholderText: finder.contextRow ? "Actions for " + finder.contextRow.name + "  ·  Esc goes back" : "Search apps, windows, files…  (? for prefixes)"
            leftPadding: Theme.space * 4
            color: Theme.text
            placeholderTextColor: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx + 2
            maximumLength: Theme.searchQueryMax
            background: Rectangle {
                radius: Theme.radiusSm
                color: Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: search.activeFocus ? Theme.accent : Theme.border

                Text {
                    x: Theme.space * 1.25
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.searchGlyph
                    color: Theme.subtext
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.fontPx + 2
                }
            }
            onTextChanged: finder.query = text
            // Before the text box, so arrows, Enter, Tab, and Esc reach the list.
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: (event) => window.handleKey(event)
        }

        ListView {
            id: list
            readonly property int pageRows: Math.max(1, finder.maxRows - 1)
            x: card.pad
            anchors.top: search.bottom
            anchors.topMargin: Theme.space
            width: card.width - card.pad * 2
            height: card.listHeight
            visible: card.shownRows > 0
            clip: true
            spacing: Theme.borderWidth * 2
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            model: finder.results
            currentIndex: finder.cursor
            onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: SearchRow {
                required property var modelData
                required property int index
                width: list.width - Theme.scrollBarWidth
                row: modelData
                glyph: finder.glyphFor(modelData)
                current: index === finder.cursor
                number: index + 1
                onHovered: (at) => window.pointerMoved(at, index)
                onClicked: window.activate(modelData)
                onRightClicked: {
                    finder.moveTo(index)
                    finder.toggleContext()
                }
            }
        }

        Flow {
            id: hintRow
            x: card.pad
            anchors.bottom: parent.bottom
            anchors.bottomMargin: card.pad
            width: card.width - card.pad * 2
            height: Theme.keyCapHeight
            clip: true
            spacing: Theme.space * 2

            Repeater {
                model: keys.hints
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

    Component.onCompleted: {
        search.text = SearchService.startQuery
        search.cursorPosition = search.text.length
        search.forceActiveFocus()
    }
}
