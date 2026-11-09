pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.codeaid
import qs.components
import qs.config
import qs.services
import qs.settings
import qs.theme

// Code Aid: copy a code snippet. Snippets by language on the left (Recent
// first); the highlighted one's code on the right, with its blanks to
// fill. Enter copies (going to the blanks first when there are any).
// Snippets can be added, edited, and deleted here. shell.qml creates this
// only while CodeAidService.open. Keys: codeaid/CodeAidKeys.qml.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: window

    screen: ScreenService.mainScreen
    color: Theme.freshRssScrim
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-codeaid"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    CodeAidModel {
        id: aid
    }

    CodeAidKeys {
        id: keys
    }

    property point lastPointer: Qt.point(-1, -1)
    property bool confirmDelete: false
    property string flash: ""

    function pointerMoved(at, pick) {
        const first = window.lastPointer.x < 0
        if (at.x === window.lastPointer.x && at.y === window.lastPointer.y)
            return
        window.lastPointer = at
        if (!first)
            aid.moveTo(pick)
    }

    function copyNow() {
        const s = aid.current
        if (!s)
            return
        CodeAidService.copy(aid.filled, s.label)
        window.flash = "Copied " + s.name
        if (CodeAidSettings.closeOnCopy())
            closeTimer.restart()
        else
            flashTimer.restart()
        search.forceActiveFocus()
    }

    // Enter: to the blanks first, or copy when there are none.
    function pick() {
        if (aid.typedFields.length)
            window.focusField(0)
        else
            window.copyNow()
    }

    // Each blank row watches this and takes focus when it is its turn.
    property int focusIndex: -1
    property int focusSerial: 0

    function focusField(i) {
        const n = aid.typedFields.length
        if (!n)
            return
        window.focusIndex = ((i % n) + n) % n
        window.focusSerial += 1
    }

    function edit(snip) {
        editor.openFor(snip, snip ? snip.language : (aid.current ? aid.current.language : ""))
    }

    function askDelete() {
        if (!aid.current)
            return
        if (window.confirmDelete) {
            CodeAidService.remove(aid.current)
            window.confirmDelete = false
        } else {
            window.confirmDelete = true
            confirmTimer.restart()
        }
    }

    function run(action) {
        switch (action) {
        case "down": aid.move(1); break
        case "up": aid.move(-1); break
        case "pageDown": aid.moveTo(Math.min(aid.count - 1, aid.cursor + 10)); break
        case "pageUp": aid.moveTo(Math.max(0, aid.cursor - 10)); break
        case "pick": window.pick(); break
        case "copyNow": window.copyNow(); break
        case "fields": window.focusField(0); break
        case "edit": if (aid.current) window.edit(aid.current); break
        case "new": window.edit(null); break
        case "delete": window.askDelete(); break
        case "escape":
            if (search.text.length)
                search.text = ""
            else
                CodeAidService.hide()
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

    Timer {
        id: closeTimer
        interval: Theme.codeAidFlashMs
        onTriggered: CodeAidService.hide()
    }

    Timer {
        id: flashTimer
        interval: Theme.codeAidFlashMs * 2
        onTriggered: window.flash = ""
    }

    Timer {
        id: confirmTimer
        interval: Theme.copiedFlashMs * 2
        onTriggered: window.confirmDelete = false
    }

    // A click on the dimmed area closes.
    MouseArea {
        anchors.fill: parent
        onClicked: CodeAidService.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Theme.codeAidWidth, window.width - Theme.space * 4)
        height: Math.min(Theme.codeAidHeight, window.height - Theme.space * 4)
        radius: Theme.radius
        color: Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, 1)
        border.width: Theme.borderWidth
        border.color: Theme.border

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
                text: Theme.codeAidGlyph
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: Theme.fontPx + Theme.freshRssTitleBoost / 2
            }

            TextField {
                id: search
                width: parent.width - x - countText.width - newButton.width - parent.spacing * 2
                height: Theme.fieldHeight
                focus: true
                verticalAlignment: Text.AlignVCenter
                placeholderText: "Search snippets, languages, or code…"
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
                onTextChanged: aid.query = text
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: (event) => window.handleKey(event)
            }

            Text {
                id: countText
                anchors.verticalCenter: parent.verticalCenter
                text: aid.searching ? aid.count + " of " + aid.snippets.length : aid.snippets.length + " snippets"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            ChipButton {
                id: newButton
                anchors.verticalCenter: parent.verticalCenter
                label: "New"
                tip: "Add a snippet (Ctrl+T)"
                onClicked: window.edit(null)
            }
        }

        ListView {
            id: list
            anchors.left: parent.left
            anchors.top: topRow.bottom
            anchors.bottom: hintRow.top
            anchors.margins: Theme.space * 2
            width: Math.round((card.width - Theme.space * 4) * Theme.codeAidListShare)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            model: aid.rows
            currentIndex: aid.currentRow
            onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: SnippetRow {
                required property var modelData
                width: list.width - Theme.scrollBarWidth
                row: modelData
                current: modelData.kind === "snip" && modelData.pick === aid.cursor
                showLanguage: aid.searching
                onHovered: (at) => window.pointerMoved(at, modelData.pick)
                onClicked: {
                    aid.moveTo(modelData.pick)
                    window.pick()
                }
                onRightClicked: {
                    aid.moveTo(modelData.pick)
                    window.edit(modelData.snip)
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space * 2
                visible: list.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: {
                    if (!CodeAidService.store || !CodeAidService.store.ready)
                        return "Loading…"
                    if (aid.searching)
                        return "Nothing matches."
                    return "No snippets in " + CodeAidService.dir + " yet.\nAdd one with New."
                }
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        // The highlighted snippet: its blanks, its code, and actions.
        Item {
            id: pane
            anchors.left: list.right
            anchors.right: parent.right
            anchors.top: topRow.bottom
            anchors.bottom: hintRow.top
            anchors.leftMargin: Theme.space
            anchors.rightMargin: Theme.space * 2
            anchors.topMargin: Theme.space * 2
            anchors.bottomMargin: Theme.space * 2
            visible: aid.current !== null

            Column {
                id: head
                width: parent.width
                spacing: Theme.tabGap

                Row {
                    width: parent.width
                    spacing: Theme.space

                    Text {
                        width: parent.width - actions.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: aid.current ? aid.current.name : ""
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx + 1
                        font.bold: true
                    }

                    Row {
                        id: actions
                        spacing: Theme.tabGap

                        ChipButton {
                            label: "Copy"
                            active: true
                            tip: "Copy the code, blanks filled (Enter in a blank, or Ctrl+Enter)"
                            onClicked: window.copyNow()
                        }

                        ChipButton {
                            label: "Edit"
                            tip: "Change this snippet (Ctrl+E)"
                            onClicked: window.edit(aid.current)
                        }

                        ChipButton {
                            label: window.confirmDelete ? "Click again" : "Delete"
                            active: window.confirmDelete
                            tip: "Delete this snippet's file (Shift+Del twice)"
                            onClicked: window.askDelete()
                        }
                    }
                }

                Text {
                    text: aid.current ? CodeAidLogic.languageName(aid.current.language) + "  ·  " + aid.current.file : ""
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                // Blanks: type into each; the code below fills as you type.
                Repeater {
                    id: blanks
                    model: aid.typedFields
                    delegate: Row {
                        id: blank
                        required property var modelData
                        required property int index
                        width: head.width
                        spacing: Theme.space

                        Connections {
                            target: window
                            function onFocusSerialChanged() {
                                if (window.focusIndex === blank.index) {
                                    field.forceActiveFocus()
                                    field.selectAll()
                                }
                            }
                        }

                        Text {
                            width: Math.round(head.width * 0.25)
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: blank.modelData.name
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.smallPx
                        }

                        TextBox {
                            id: field
                            width: head.width - Math.round(head.width * 0.25) - parent.spacing
                            placeholderText: blank.modelData.def.length ? blank.modelData.def : blank.modelData.name
                            font.family: Theme.fontFamily
                            text: aid.valueOf(blank.modelData.name)
                            onTextEdited: aid.setValue(blank.modelData.name, text)
                            Keys.onPressed: (event) => {
                                const shift = (event.modifiers & Qt.ShiftModifier) !== 0
                                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    window.focusField(blank.index + (shift || event.key === Qt.Key_Backtab ? -1 : 1))
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    window.copyNow()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    search.forceActiveFocus()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: aid.usesClipboard
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: aid.clipboard.length ? "{{clipboard}} puts in what you copied: " + aid.clipboard.split("\n")[0]
                        : "{{clipboard}} is empty: copy the code to wrap first."
                    color: aid.clipboard.length ? Theme.subtext : Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: head.bottom
                anchors.topMargin: Theme.space
                anchors.bottom: parent.bottom
                radius: Theme.radiusSm
                color: Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: Theme.border

                Flickable {
                    id: codeScroll
                    anchors.fill: parent
                    anchors.margins: Theme.space
                    contentWidth: code.implicitWidth
                    contentHeight: code.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                    Text {
                        id: code
                        text: aid.filled
                        textFormat: Text.PlainText
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallPx + 1
                    }
                }

                Rectangle {
                    visible: window.flash.length > 0
                    anchors.centerIn: parent
                    width: flashText.implicitWidth + Theme.space * 3
                    height: Theme.fieldHeight
                    radius: height / 2
                    color: Theme.accent

                    Text {
                        id: flashText
                        anchors.centerIn: parent
                        text: window.flash
                        color: Theme.wsActiveText
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx + 1
                        font.bold: true
                    }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: Theme.space * 2
            anchors.bottom: hintRow.top
            visible: CodeAidService.error.length > 0
            text: CodeAidService.error
            color: Theme.danger
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
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

        SnippetEditor {
            id: editor
            languages: aid.languages
            onSaveRequested: (snip, language, name, body) => {
                const why = CodeAidService.save(snip, language, name, body)
                if (why.length) {
                    editor.problem = why
                    return
                }
                editor.close()
                window.pendingLabel = CodeAidLogic.makeLabel(language, name)
                search.forceActiveFocus()
            }
            onCancelled: {
                editor.close()
                search.forceActiveFocus()
            }
        }
    }

    // After a save, keep the snippet highlighted once its file is read.
    property string pendingLabel: ""
    Connections {
        target: aid
        function onRowsChanged() {
            if (window.pendingLabel.length && aid.moveToLabel(window.pendingLabel))
                window.pendingLabel = ""
        }
    }

    Component.onCompleted: search.forceActiveFocus()
}
