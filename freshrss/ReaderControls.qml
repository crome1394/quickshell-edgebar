pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config
import qs.settings
import qs.theme

// The reader's controls: date, scope, and type chips, collapse and expand,
// and the Filters box (search, max days, per feed or max items). Scope,
// days, and limits reload from the server; the rest filter what is loaded.
Column {
    id: root

    required property ReaderModel reader

    property bool filtersOpen: Config.freshRssFiltersOpen
    readonly property bool searchFocused: searchField.activeFocus

    function focusSearch() {
        root.filtersOpen = true
        searchField.forceActiveFocus()
        searchField.selectAll()
    }

    function clearSearch() {
        searchField.text = ""
    }

    spacing: Theme.tabGap

    Flow {
        width: parent.width
        spacing: Theme.tabGap

        Repeater {
            model: [
                { id: "all", label: "All dates", tip: "Every loaded article" },
                { id: "today", label: "Today", tip: "Articles published today" },
                { id: "week", label: "7 days", tip: "Articles from the last 7 days" }
            ]
            delegate: ChipButton {
                required property var modelData
                label: modelData.label
                tip: modelData.tip
                active: root.reader.dateFilter === modelData.id
                onClicked: root.reader.dateFilter = modelData.id
            }
        }

        Item {
            width: Theme.space
            height: Theme.fieldHeight
        }

        Repeater {
            model: [
                { id: "unread", label: "Unread", tip: "Load unread articles" },
                { id: "all", label: "All", tip: "Load the newest articles of every feed" },
                { id: "read", label: "Read", tip: "Load read articles of every feed" },
                { id: "starred", label: "Starred", tip: "Load starred articles" }
            ]
            delegate: ChipButton {
                required property var modelData
                label: modelData.label
                tip: modelData.tip
                active: root.reader.scope === modelData.id
                onClicked: root.reader.setScope(modelData.id)
            }
        }

        Item {
            width: Theme.space
            height: Theme.fieldHeight
        }

        ChipButton {
            label: "Any type"
            tip: "Every article"
            active: root.reader.typeFilter === "any"
            onClicked: root.reader.typeFilter = "any"
        }

        ChipButton {
            label: "Video"
            tip: "Only articles that link to a video (they can play in mpv)"
            active: root.reader.typeFilter === "video"
            onClicked: root.reader.typeFilter = "video"
        }

        Item {
            width: Theme.space
            height: Theme.fieldHeight
        }

        ChipButton {
            label: "Collapse all"
            tip: "Close every feed"
            onClicked: root.reader.collapseAll()
        }

        ChipButton {
            label: "Expand all"
            tip: "Open every feed"
            onClicked: root.reader.expandAll()
        }

        ChipButton {
            label: root.filtersOpen ? "Filters ▾" : "Filters ▸"
            active: root.filtersOpen
            tip: "Show or hide search, max days, and limits"
            onClicked: {
                root.filtersOpen = !root.filtersOpen
                FreshRssSettings.setFiltersOpenLive(root.filtersOpen)
            }
        }
    }

    Row {
        visible: root.filtersOpen
        width: parent.width
        spacing: Theme.space

        TextField {
            id: searchField
            width: parent.width - daysBox.width - limitBox.width - parent.spacing * 2
            height: Theme.fieldHeight
            verticalAlignment: Text.AlignVCenter
            selectByMouse: true
            placeholderText: "⌕  Search title, feed, author…  (/ or Ctrl+F)"
            leftPadding: Theme.space
            rightPadding: Theme.chip + Theme.space
            color: Theme.text
            placeholderTextColor: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            background: Rectangle {
                radius: Theme.radiusSm
                color: searchField.activeFocus ? Theme.hover : Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: searchField.activeFocus ? Theme.accent : Theme.border
            }
            onTextChanged: root.reader.search = text

            Text {
                visible: searchField.text.length > 0
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: clearMouse.containsMouse ? Theme.danger : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.tabGap
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: searchField.text = ""
                }
            }
        }

        Row {
            id: daysBox
            spacing: Theme.tabGap

            Text {
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                text: "Max days " + (root.reader.maxDays > 0 ? root.reader.maxDays : "∞")
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            ChipButton {
                label: "−"
                tip: "Fewer days"
                onClicked: root.reader.setMaxDays(FreshRssSettings.step(Theme.freshRssMaxDaysChoices, root.reader.maxDays, -1))
            }

            ChipButton {
                label: "+"
                tip: "More days (the last step is no limit)"
                onClicked: root.reader.setMaxDays(FreshRssSettings.step(Theme.freshRssMaxDaysChoices, root.reader.maxDays, 1))
            }
        }

        Row {
            id: limitBox
            readonly property bool perFeedMode: root.reader.scope === "all" || root.reader.scope === "read"
            spacing: Theme.tabGap

            Text {
                height: Theme.fieldHeight
                verticalAlignment: Text.AlignVCenter
                text: limitBox.perFeedMode ? "Per feed " + root.reader.perFeed : "Max items " + root.reader.itemLimit
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            ChipButton {
                label: "−"
                tip: limitBox.perFeedMode ? "Fewer articles per feed" : "Fewer articles"
                onClicked: limitBox.perFeedMode
                    ? root.reader.setPerFeed(FreshRssSettings.step(Theme.freshRssPerFeedChoices, root.reader.perFeed, -1))
                    : root.reader.setItemLimit(FreshRssSettings.step(Theme.freshRssItemLimitChoices, root.reader.itemLimit, -1))
            }

            ChipButton {
                label: "+"
                tip: limitBox.perFeedMode ? "More articles per feed" : "More articles"
                onClicked: limitBox.perFeedMode
                    ? root.reader.setPerFeed(FreshRssSettings.step(Theme.freshRssPerFeedChoices, root.reader.perFeed, 1))
                    : root.reader.setItemLimit(FreshRssSettings.step(Theme.freshRssItemLimitChoices, root.reader.itemLimit, 1))
            }
        }
    }
}
