pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.theme

// Settings → Applications → FreshRSS. Server: address, user, and API
// password, with Test (log in without saving) and Save server (writes
// ~/.config/freshrss-quickshell/freshrss.env, mode 600). Reader: how often
// the badge checks, how much to load, and whether Filters start open;
// Apply saves those.
Item {
    id: root

    readonly property var draft: FreshRssSettings.editor.value
    readonly property int scrollGutter: Theme.space + Theme.tabGap

    property string serverStatus: ""
    property bool serverBad: false
    property bool testing: false

    function fillServer() {
        urlField.text = FreshRssService.baseUrl
        userField.text = FreshRssService.user
        passField.text = FreshRssService.password
    }

    Component.onCompleted: root.fillServer()

    Connections {
        target: FreshRssService
        function onEnvLoadedChanged() {
            root.fillServer()
        }
        function onNoticeChanged() {
            if (FreshRssService.notice.length) {
                root.serverStatus = FreshRssService.notice
                root.serverBad = false
            }
        }
    }

    function test() {
        root.testing = true
        root.serverStatus = "Testing…"
        root.serverBad = false
        FreshRssService.testServer(urlField.text, userField.text, passField.text, (ok, message) => {
            root.testing = false
            root.serverStatus = message
            root.serverBad = !ok
        })
    }

    function save() {
        const error = FreshRssService.saveServer(urlField.text, userField.text, passField.text)
        root.serverStatus = error.length ? error : "Saving…"
        root.serverBad = error.length > 0
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: pageScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: pageScroll.pressed || pageScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            width: Math.max(0, scroll.width - root.scrollGutter)
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Server"
                hint: "Saved to ~/.config/freshrss-quickshell/freshrss.env (outside git, readable only by you). Use the API password from FreshRSS Profile → API password, not your login password. Turn the FreshRSS widget on under Widgets."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Address"

                    TextBox {
                        id: urlField
                        width: parent.width
                        placeholderText: "https://rss.example.com"
                    }
                }

                FormRow {
                    width: parent.width
                    label: "User"

                    TextBox {
                        id: userField
                        width: parent.width
                        placeholderText: "FreshRSS user name"
                    }
                }

                FormRow {
                    width: parent.width
                    label: "API password"

                    Row {
                        width: parent.width
                        spacing: Theme.tabGap

                        TextBox {
                            id: passField
                            width: parent.width - showButton.width - parent.spacing
                            echoMode: showButton.active ? TextInput.Normal : TextInput.Password
                            placeholderText: "Profile → API password"
                        }

                        ChipButton {
                            id: showButton
                            label: active ? "Hide" : "Show"
                            tip: "Show or hide the password"
                            onClicked: active = !active
                        }
                    }
                }

                Row {
                    spacing: Theme.tabGap

                    ChipButton {
                        label: root.testing ? "Testing…" : "Test"
                        enabled: !root.testing
                        tip: "Log in with these values without saving them"
                        onClicked: root.test()
                    }

                    ChipButton {
                        label: "Save server"
                        bold: true
                        tip: "Write these values to the env file"
                        onClicked: root.save()
                    }

                    ChipButton {
                        label: "Revert"
                        tip: "Put back the saved values"
                        onClicked: {
                            root.fillServer()
                            root.serverStatus = ""
                        }
                    }
                }

                Text {
                    visible: root.serverStatus.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.serverStatus
                    color: root.serverBad ? Theme.danger : Theme.ok
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                Text {
                    visible: urlField.text.trim().startsWith("http://")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "This address uses http://, so the password crosses the network unencrypted. Use https:// if the server has it."
                    color: Theme.danger
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }

            Item {
                width: parent.width
                height: Theme.space
            }

            SectionHeader {
                width: parent.width
                title: "Reader"
                hint: "The reader window also changes days and limits as you use it. Apply saves this section."
            }

            Column {
                x: Theme.sectionInset
                width: parent.width - Theme.sectionInset * 2
                spacing: Theme.space

                FormRow {
                    width: parent.width
                    label: "Check every"

                    IntSlider {
                        width: parent.width
                        from: 1
                        to: Theme.freshRssPollMax
                        value: root.draft.pollMin
                        readout: root.draft.pollMin + " min"
                        tip: "How often the bar asks for the unread count, while the widget is on a bar or the reader is open"
                        onChanged: (value) => FreshRssSettings.editor.set("pollMin", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Max days"

                    ChoiceChips {
                        width: parent.width
                        values: Theme.freshRssMaxDaysChoices
                        current: root.draft.maxDays
                        zeroLabel: "No limit"
                        onPicked: (value) => FreshRssSettings.editor.set("maxDays", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Per feed"

                    ChoiceChips {
                        width: parent.width
                        values: Theme.freshRssPerFeedChoices
                        current: root.draft.perFeed
                        onPicked: (value) => FreshRssSettings.editor.set("perFeed", value)
                    }
                }

                FormRow {
                    width: parent.width
                    label: "Max items"

                    ChoiceChips {
                        width: parent.width
                        values: Theme.freshRssItemLimitChoices
                        current: root.draft.itemLimit
                        onPicked: (value) => FreshRssSettings.editor.set("itemLimit", value)
                    }
                }

                CheckRow {
                    width: parent.width
                    title: "Open with Filters showing"
                    detail: "Search, max days, and limits under the chips"
                    checked: root.draft.filtersOpen
                    onToggled: FreshRssSettings.editor.set("filtersOpen", !root.draft.filtersOpen)
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Per feed applies to All and Read, which load each feed. Max items applies to Unread and Starred. Open the reader with the pill or `qs ipc call freshRss toggle` (bind it to a key)."
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }
            }
        }
    }

    DraftFooter {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        applyEnabled: FreshRssSettings.editor.dirty
        undoEnabled: FreshRssSettings.editor.canUndo
        applyTip: "Save the reader options"
        undoTip: "Drop an unsaved draft, or put back the last applied one"
        resetTip: "Check every " + Theme.freshRssPollDefault + " min, " + Theme.freshRssMaxDaysDefault + " days, " + Theme.freshRssPerFeedDefault + " per feed, " + Theme.freshRssItemLimitDefault + " items, Filters open. Apply saves it."
        onApplyClicked: FreshRssSettings.editor.apply()
        onUndoClicked: FreshRssSettings.editor.undo()
        onResetClicked: FreshRssSettings.editor.reset()
    }
}
