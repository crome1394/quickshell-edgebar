pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.theme

// Magnifier in the settings header. Click or Ctrl+F opens the field.
// Keys: type to filter. Tab or Down moves into the results. Up and Down
// pick a result, Enter opens it, Tab or Shift+Tab goes back to the field,
// and Esc closes. Typing in the results goes back to the field. The mouse
// works as before: hover highlights, click opens.
Item {
    id: root

    property bool open: false
    property int selected: 0
    readonly property var results: root.matches()
    readonly property bool listFocus: resultList.activeFocus

    signal picked(string tab, string section)

    function entries() {
        return [
            { tab: "bar", section: "workspaces", title: "Bar · Workspaces", keys: "workspace symbol label font size" },
            { tab: "bar", section: "overview", title: "Bar · Overview", keys: "overview layout strip preview motion workspace" },
            { tab: "bar", section: "dock", title: "Bar · Dock", keys: "dock magnify jump hover icon launcher tray running dot" },
            { tab: "widgets", section: "bars", title: "Widgets · Bars", keys: "bar edge widget placement show" },
            { tab: "widgets", section: "activewindow", title: "Widgets · Active Window", keys: "active window corner width exclude title class" },
            { tab: "widgets", section: "stats", title: "Widgets · System Stats", keys: "cpu memory gpu vram font bold italic threshold terminal btop" },
            { tab: "wallpaper", section: "", title: "Wallpaper", keys: "wallpaper image hyprpaper folder" },
            { tab: "applications", section: "launcher", title: "Applications · App Launcher", keys: "pin launcher application command" },
            { tab: "applications", section: "menu", title: "Applications · Application Menu", keys: "menu symbol glyph command font" },
            { tab: "connectivity", section: "network", title: "Connectivity · Network", keys: "network ip address wifi octet device" },
            { tab: "connectivity", section: "bluetooth", title: "Connectivity · Bluetooth", keys: "bluetooth scan paired adapter" },
            { tab: "audio", section: "", title: "Audio · On the bar", keys: "audio speaker microphone volume scroll percent mute" },
            { tab: "audio", section: "", title: "Audio · Output", keys: "speaker output sink volume mute device" },
            { tab: "audio", section: "", title: "Audio · Input", keys: "microphone input source volume mute device" },
            { tab: "region", section: "clock", title: "Region & Clock · Clock", keys: "clock font format calendar time date" },
            { tab: "region", section: "region", title: "Region & Clock · Region", keys: "timezone region map city" },
            { tab: "notifications", section: "", title: "Notifications · Toasts", keys: "notification toast corner timeout swaync popup" },
            { tab: "notifications", section: "", title: "Notifications · History", keys: "notification history bell counter dnd expand stagger boot" },
            { tab: "system", section: "dependencies", title: "System · Dependencies", keys: "dependencies packages programs fonts services missing install reinstall check" },
            { tab: "system", section: "transparency", title: "System · Transparency", keys: "transparency opacity transparent dim glass override satty window application" },
            { tab: "system", section: "display", title: "System · Display", keys: "display monitor resolution screen refresh rate hz bit depth 10-bit color mode" },
            { tab: "tools", section: "screensaver", title: "Tools · Screensaver", keys: "screensaver idle hypridle timeout inhibit fullscreen video program script brightness dim ddcutil" },
            { tab: "tools", section: "capture", title: "Tools · Capture", keys: "capture screenshot screen shot print grim slurp freeze ocr text tesseract language satty editor folder keybind" }
        ]
    }

    function matches() {
        const query = field.text.trim().toLowerCase()
        if (!query.length)
            return []
        const all = root.entries()
        const out = []
        for (let i = 0; i < all.length && out.length < 8; i++) {
            const row = all[i]
            const hay = (row.title + " " + row.keys).toLowerCase()
            if (hay.indexOf(query) >= 0)
                out.push(row)
        }
        return out
    }

    function openSearch() {
        root.open = true
        field.forceActiveFocus()
        field.selectAll()
    }

    function closeSearch() {
        root.open = false
        field.text = ""
        root.selected = 0
    }

    function focusResults() {
        if (!root.results.length)
            return
        root.selected = Math.max(0, Math.min(root.selected, root.results.length - 1))
        resultList.forceActiveFocus()
    }

    function focusField() {
        field.forceActiveFocus()
    }

    // Move the highlight; moving up from the first result returns to the field.
    function step(delta) {
        const count = root.results.length
        if (!count)
            return
        const next = root.selected + delta
        if (next < 0) {
            root.focusField()
            return
        }
        root.selected = Math.min(count - 1, next)
    }

    function chooseSelected() {
        const rows = root.results
        if (rows.length)
            root.choose(rows[Math.max(0, Math.min(root.selected, rows.length - 1))])
    }

    function choose(row) {
        if (!row)
            return
        root.picked(String(row.tab || ""), String(row.section || ""))
        root.closeSearch()
    }

    width: root.open ? Theme.popupWidth : 28
    height: Theme.headerHeight

    Rectangle {
        id: searchButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 24
        radius: Theme.radiusSm
        color: searchMouse.containsMouse || root.open ? Theme.hover : "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.border

        Text {
            anchors.centerIn: parent
            text: "\uf002"
            color: Theme.text
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontPx
        }

        MouseArea {
            id: searchMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.open)
                    root.closeSearch()
                else
                    root.openSearch()
            }

            HoverTip {
                message: "Search settings (Ctrl+F)"
                show: searchMouse.containsMouse && !root.open
            }
        }
    }

    TextField {
        id: field
        visible: root.open
        anchors.left: parent.left
        anchors.right: searchButton.left
        anchors.rightMargin: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.fieldHeight
        verticalAlignment: Text.AlignVCenter
        selectByMouse: true
        placeholderText: "Search settings"
        leftPadding: Theme.space
        color: Theme.text
        placeholderTextColor: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        background: Rectangle {
            radius: Theme.radiusSm
            color: field.activeFocus ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border
        }
        onTextChanged: root.selected = 0
        Keys.onEscapePressed: root.closeSearch()
        Keys.onTabPressed: (event) => {
            event.accepted = true
            root.focusResults()
        }
        Keys.onDownPressed: (event) => {
            event.accepted = true
            root.focusResults()
        }
        onAccepted: root.chooseSelected()
    }

    Rectangle {
        id: resultBox
        visible: root.open && field.text.trim().length > 0
        z: 2
        width: Theme.popupWidth
        anchors.top: parent.bottom
        anchors.right: parent.right
        height: resultCol.implicitHeight + Theme.space
        radius: Theme.radiusSm
        color: Theme.pageBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: resultCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.tabGap
            spacing: Theme.tabGap

            Text {
                visible: root.results.length === 0
                width: parent.width
                text: "No matching settings"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            // Takes keyboard focus for the results; the rows draw the highlight.
            Column {
                id: resultList
                width: parent.width
                spacing: Theme.tabGap
                activeFocusOnTab: false

                Keys.onUpPressed: (event) => {
                    event.accepted = true
                    root.step(-1)
                }
                Keys.onDownPressed: (event) => {
                    event.accepted = true
                    root.step(1)
                }
                Keys.onReturnPressed: (event) => {
                    event.accepted = true
                    root.chooseSelected()
                }
                Keys.onEnterPressed: (event) => {
                    event.accepted = true
                    root.chooseSelected()
                }
                Keys.onTabPressed: (event) => {
                    event.accepted = true
                    root.focusField()
                }
                Keys.onBacktabPressed: (event) => {
                    event.accepted = true
                    root.focusField()
                }
                Keys.onEscapePressed: (event) => {
                    event.accepted = true
                    root.closeSearch()
                }
                // Typing goes back to the field, keeping the key.
                Keys.onPressed: (event) => {
                    const ch = String(event.text || "")
                    if (!ch.length || event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                        return
                    if (ch === "\b") {
                        event.accepted = true
                        root.focusField()
                        field.remove(Math.max(0, field.cursorPosition - 1), field.cursorPosition)
                        return
                    }
                    if (ch.charCodeAt(0) < 32)
                        return
                    event.accepted = true
                    root.focusField()
                    field.insert(field.cursorPosition, ch)
                }

                Repeater {
                    model: root.results
                    delegate: Rectangle {
                        id: hit
                        required property var modelData
                        required property int index
                        // The row Enter opens: from the field it is the first match.
                        readonly property bool current: hit.index === root.selected
                        width: resultList.width
                        height: Theme.fieldHeight
                        radius: Theme.radiusSm
                        color: hit.current && root.listFocus ? Theme.accentDim : (hitMouse.containsMouse ? Theme.hover : Theme.pillBg)
                        border.width: Theme.borderWidth
                        border.color: hit.current ? (root.listFocus ? Theme.accent : Theme.border) : "transparent"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space
                            anchors.rightMargin: Theme.space
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: String(hit.modelData.title || "")
                            color: hit.current && root.listFocus ? Theme.wsActiveText : Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontPx
                            font.bold: hit.current && root.listFocus
                        }

                        Text {
                            visible: hit.current
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.space
                            anchors.verticalCenter: parent.verticalCenter
                            text: "↵"
                            color: Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        MouseArea {
                            id: hitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selected = hit.index
                            onClicked: root.choose(hit.modelData)
                        }
                    }
                }
            }

            Text {
                visible: root.results.length > 0
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: root.listFocus ? "↑ ↓ choose · Enter open · Tab back · Esc close" : "Tab or ↓ to choose · Enter opens the first"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }
    }
}
