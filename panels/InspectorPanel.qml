pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.inspector
import qs.services
import qs.settings
import qs.theme

// Real toplevel so Hyprland window rules can match it.
// Title: Inspector
// shell.qml creates this only while InspectorService.open, so closing it
// (✕, Escape, or the compositor) frees everything.
FloatingWindow {
    id: window

    title: "Inspector"
    implicitWidth: Theme.inspectorWidth
    implicitHeight: Theme.inspectorHeight
    minimumSize: Qt.size(Theme.inspectorMinWidth, Theme.inspectorMinHeight)
    color: Theme.pageBg
    visible: true

    property string notice: ""

    Component.onCompleted: ScreenService.fitWindow(window, Theme.inspectorWidth, Theme.inspectorHeight,
        Theme.inspectorMinWidth, Theme.inspectorMinHeight)

    function copy(text) {
        Quickshell.clipboardText = String(text)
        const one = String(text).split("\n")[0]
        window.notice = "Copied: " + (one.length > 60 ? one.substring(0, 60) + "…" : one)
        noticeTimer.restart()
    }

    function nextTab(step) {
        const list = InspectorService.tabs
        const at = Math.max(0, list.indexOf(InspectorService.tab))
        InspectorService.tab = list[(at + step + list.length) % list.length]
    }

    // The compositor closing the window (killactive) only hides it.
    onVisibleChanged: {
        if (!window.visible)
            InspectorService.hide()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            if (searchField.text.length)
                searchField.text = ""
            else
                InspectorService.hide()
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.WindowShortcut
        onActivated: searchField.forceActiveFocus()
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        context: Qt.WindowShortcut
        onActivated: window.nextTab(1)
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        context: Qt.WindowShortcut
        onActivated: window.nextTab(-1)
    }

    Timer {
        id: noticeTimer
        interval: Theme.copiedFlashMs
        onTriggered: window.notice = ""
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

            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.space
                text: "Inspector"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: searchField.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onPressed: window.startSystemMove()
            }

            PathField {
                id: searchField
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.tabGap
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(Theme.inspectorKeyWidth * 1.5, parent.width / 2)
                value: ""
                placeholderText: "Search this tab (Ctrl+F)"
                tip: "Filters the rows on the open tab. Escape clears it."
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: Theme.space
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.headerButtonWidth
                height: Theme.headerButtonHeight
                radius: Theme.radiusSm
                color: closeMouse.containsMouse ? Theme.hover : "transparent"
                border.width: Theme.borderWidth
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.text
                    font.pixelSize: Theme.fontPx
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: InspectorService.hide()
                }
            }
        }

        TabStrip {
            id: tabs
            // The Inspector keeps flat tabs; dividers are a Settings look.
            indexAllowed: false
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.margins: Theme.space
            model: [
                { id: "bindings", label: "Bindings" },
                { id: "system", label: "System Info" }
            ]
            currentId: InspectorService.tab
            onSelected: (tabId) => { InspectorService.tab = tabId }
        }

        Loader {
            id: page
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabs.bottom
            anchors.bottom: footer.top
            anchors.margins: Theme.space
            sourceComponent: InspectorService.tab === "system" ? systemPage : bindingsPage
        }

        Text {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space
            height: Theme.fieldHeight / 2 + Theme.tabGap
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: window.notice.length ? window.notice : "Escape closes  ·  Ctrl+Tab switches tabs  ·  qs ipc call inspector toggle"
            color: window.notice.length ? Theme.ok : Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }
    }

    Component {
        id: bindingsPage
        BindingsView {
            query: searchField.text
            onCopied: (text) => window.copy(text)
        }
    }

    Component {
        id: systemPage
        SystemInfoView {
            query: searchField.text
            onCopied: (text) => window.copy(text)
        }
    }
}
