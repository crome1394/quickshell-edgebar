pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.settings
import qs.theme

// Real toplevel so Hyprland window rules can match it.
// Title: Settings
FloatingWindow {
    id: window

    title: "Settings"
    implicitWidth: Theme.settingsWidth
    implicitHeight: Theme.settingsHeight
    minimumSize: Qt.size(Theme.settingsMinWidth, Theme.settingsMinHeight)
    color: Theme.pageBg
    visible: false

    property string currentTab: "bar"
    // Hidden while a display change is tried; reopen on Display after.
    property bool awayForDisplay: false
    property bool remapping: false
    property int showGeneration: 0
    property int revealSerial: 0
    property string revealTab: ""
    property string revealSection: ""

    // Closing from the compositor hides the surface but leaves the
    // wants-visible flag set. visible then reads false, and assigning
    // true does not map a window until that flag is cleared. Clearing
    // and mapping on the same frame is also a no-op.
    function show() {
        if (window.visible && window.backingWindowVisible)
            return
        const token = ++window.showGeneration
        window.remapping = true
        window.minimized = false
        window.visible = false
        ScreenService.fitWindow(window, Theme.settingsWidth, Theme.settingsHeight, Theme.settingsMinWidth, Theme.settingsMinHeight)
        Qt.callLater(() => {
            if (token !== window.showGeneration)
                return
            window.remapping = false
            window.minimized = false
            window.visible = true
        })
    }

    function hide() {
        window.showGeneration++
        window.remapping = false
        window.releaseFocus()
        window.visible = false
    }

    function releaseFocus() {
        const content = window.contentItem
        if (content)
            content.forceActiveFocus()
    }

    function jump(tab, section) {
        window.currentTab = tab
        window.revealTab = tab
        window.revealSection = section
        window.revealSerial = window.revealSerial + 1
        search.closeSearch()
    }

    // Each tab's sections, for openTab and listTabs. Keep in step with the
    // sub-tabs each page shows (its applyReveal()).
    readonly property var tabSections: ({
        bar: ["workspaces", "overview", "dock"],
        widgets: ["bars", "activewindow", "stats"],
        appearance: ["theme", "wallpaper"],
        applications: ["search", "library", "launcher", "menu", "freshrss"],
        connectivity: ["network", "bluetooth"],
        audio: [],
        notifications: ["notifications", "osd"],
        region: ["region", "clock"],
        system: ["dependencies", "display", "transparency"],
        tools: ["capture", "screensaver", "recording", "nightlight", "clipboard", "codeaid"]
    })

    // One line per tab: "widgets: bars activewindow stats".
    function tabList() {
        const list = tabs.model
        const lines = []
        for (let i = 0; i < list.length; i++) {
            const parts = window.tabSections[list[i].id] || []
            lines.push(list[i].id + (parts.length ? ": " + parts.join(" ") : ""))
        }
        return lines.join("\n")
    }

    // True when `tab` is one of the tab ids along the bottom.
    function knownTab(tab) {
        const list = tabs.model
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === tab)
                return true
        }
        return false
    }

    function pushReveal(loader, tab) {
        const item = loader.item
        if (!item)
            return
        item.revealSection = window.revealTab === tab ? window.revealSection : ""
        item.revealSerial = window.revealTab === tab ? window.revealSerial : 0
    }

    // qs ipc call settings open | close | toggle
    // qs ipc call settings openTab applications menu   a tab and section ("" for none)
    // qs ipc call settings listTabs                    every tab and its sections
    // qs ipc call settings currentTab                  "tab" or "closed"
    // Sections are listed in tabSections; an unknown one is refused.
    IpcHandler {
        target: "settings"

        function open(): void {
            window.show()
        }

        function close(): void {
            window.hide()
        }

        function toggle(): void {
            if (window.visible)
                window.hide()
            else
                window.show()
        }

        function openTab(tab: string, section: string): string {
            let id = String(tab || "").trim()
            let part = String(section || "").trim()
            // Theme and Wallpaper became sections of Appearance.
            if (id === "theme" || id === "wallpaper") {
                part = id
                id = "appearance"
            }
            if (!window.knownTab(id))
                return "unknown tab: " + id + " (qs ipc call settings listTabs)"
            const parts = window.tabSections[id] || []
            if (part.length && parts.indexOf(part) < 0)
                return "unknown section for " + id + ": " + part + (parts.length ? " (sections: " + parts.join(", ") + ")" : " (it has none)")
            window.jump(id, part)
            window.show()
            return "ok"
        }

        function listTabs(): string {
            return window.tabList()
        }

        function currentTab(): string {
            return window.visible ? window.currentTab : "closed"
        }
    }

    Connections {
        target: DisplayService
        function onTryStarted() {
            if (window.visible) {
                window.awayForDisplay = true
                window.hide()
            }
        }
        function onTryEnded() {
            if (!window.awayForDisplay)
                return
            window.awayForDisplay = false
            window.jump("system", "display")
            window.show()
        }
    }

    onClosed: {
        if (!window.remapping)
            window.visible = false
    }

    onRevealSerialChanged: {
        window.pushReveal(appearancePage, "appearance")
        window.pushReveal(notificationsPage, "notifications")
        window.pushReveal(applicationsPage, "applications")
        window.pushReveal(connectivityPage, "connectivity")
        window.pushReveal(systemPage, "system")
        window.pushReveal(toolsPage, "tools")
    }

    Shortcut {
        sequence: "Escape"
        enabled: window.visible
        context: Qt.WindowShortcut
        onActivated: {
            if (search.open)
                search.closeSearch()
            else
                window.hide()
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: window.visible
        context: Qt.WindowShortcut
        onActivated: search.openSearch()
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: header
            z: 4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Theme.headerHeight
            color: Theme.barBg

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.space
                text: "Settings"
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            SettingsSearch {
                id: search
                anchors.right: closeButton.left
                anchors.rightMargin: Theme.tabGap
                anchors.verticalCenter: parent.verticalCenter
                onPicked: (tab, section) => window.jump(tab, section)
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
                    onClicked: window.hide()
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: search.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onPressed: window.startSystemMove()
            }
        }

        Loader {
            id: page
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            // Stay loaded across the Widgets tab so an unapplied workspace draft survives.
            active: window.visible && (window.currentTab === "bar" || window.currentTab === "widgets")
            visible: window.currentTab === "bar"
            sourceComponent: Component {
                BarTab {
                    revealSerial: window.revealTab === "bar" ? window.revealSerial : 0
                    revealSection: window.revealTab === "bar" ? window.revealSection : ""
                }
            }
        }

        Loader {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "widgets"
            visible: window.currentTab === "widgets"
            sourceComponent: Component {
                WidgetsTab {
                    revealSerial: window.revealTab === "widgets" ? window.revealSerial : 0
                    revealSection: window.revealTab === "widgets" ? window.revealSection : ""
                }
            }
        }



        Loader {
            id: appearancePage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "appearance"
            visible: window.currentTab === "appearance"
            source: appearancePage.active ? Qt.resolvedUrl("../settings/AppearanceTab.qml") : ""
            onLoaded: window.pushReveal(appearancePage, "appearance")
        }

        Loader {
            id: applicationsPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "applications"
            visible: window.currentTab === "applications"
            source: applicationsPage.active ? Qt.resolvedUrl("../settings/ApplicationsTab.qml") : ""
            onLoaded: window.pushReveal(applicationsPage, "applications")
        }

        Loader {
            id: connectivityPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "connectivity"
            visible: window.currentTab === "connectivity"
            source: connectivityPage.active ? Qt.resolvedUrl("../settings/ConnectivityTab.qml") : ""
            onLoaded: window.pushReveal(connectivityPage, "connectivity")
        }

        Loader {
            id: audioPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "audio"
            visible: window.currentTab === "audio"
            source: audioPage.active ? Qt.resolvedUrl("../settings/AudioTab.qml") : ""
        }

        Loader {
            id: regionPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "region"
            visible: window.currentTab === "region"
            sourceComponent: Component {
                RegionClockTab {
                    revealSerial: window.revealTab === "region" ? window.revealSerial : 0
                    revealSection: window.revealTab === "region" ? window.revealSection : ""
                }
            }
        }

        Loader {
            id: notificationsPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "notifications"
            visible: window.currentTab === "notifications"
            source: notificationsPage.active ? Qt.resolvedUrl("../settings/NotificationsTab.qml") : ""
            onLoaded: window.pushReveal(notificationsPage, "notifications")
        }

        Loader {
            id: systemPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "system"
            visible: window.currentTab === "system"
            source: systemPage.active ? Qt.resolvedUrl("../settings/SystemTab.qml") : ""
            onLoaded: window.pushReveal(systemPage, "system")
        }

        Loader {
            id: toolsPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "tools"
            visible: window.currentTab === "tools"
            source: toolsPage.active ? Qt.resolvedUrl("../settings/ToolsTab.qml") : ""
            onLoaded: window.pushReveal(toolsPage, "tools")
        }

        Connections {
            target: regionPage.item
            function onCloseRequested() {
                window.hide()
            }
        }

        // The main tabs: index dividers (default) or flat chips, chosen in
        // Appearance → Theme → Settings window.
        Item {
            id: tabs
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space
            anchors.topMargin: 0
            height: (strip.item as Item)?.implicitHeight ?? Theme.tabHeight

            readonly property var model: [
                { id: "bar", label: "Bar" },
                { id: "widgets", label: "Widgets" },
                { id: "appearance", label: "Appearance" },
                { id: "applications", label: "Applications" },
                { id: "connectivity", label: "Connectivity" },
                { id: "audio", label: "Audio" },
                { id: "notifications", label: "Notifications" },
                { id: "region", label: "Region & Clock" },
                { id: "system", label: "System" },
                { id: "tools", label: "Tools" }
            ]

            Loader {
                id: strip
                width: parent.width
                sourceComponent: Config.settingsTabStyle === "flat" ? flatTabs : indexTabs
            }

            Component {
                id: flatTabs
                TabStrip {
                    model: tabs.model
                    currentId: window.currentTab
                    onSelected: (tabId) => { window.currentTab = tabId }
                }
            }

            Component {
                id: indexTabs
                IndexTabStrip {
                    model: tabs.model
                    currentId: window.currentTab
                    onSelected: (tabId) => { window.currentTab = tabId }
                }
            }
        }

        MouseArea {
            z: 2
            width: Theme.resizeGrip
            height: Theme.resizeGrip
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeFDiagCursor
            onPressed: {
                window.releaseFocus()
                window.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
            }
        }
    }
}
