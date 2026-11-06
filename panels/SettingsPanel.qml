pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
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

    function pushReveal(loader, tab) {
        const item = loader.item
        if (!item)
            return
        item.revealSection = window.revealTab === tab ? window.revealSection : ""
        item.revealSerial = window.revealTab === tab ? window.revealSerial : 0
    }

    onClosed: {
        if (!window.remapping)
            window.visible = false
    }

    onRevealSerialChanged: {
        window.pushReveal(applicationsPage, "applications")
        window.pushReveal(connectivityPage, "connectivity")
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
                width: 28
                height: 24
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
            id: wallpaperPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: tabs.top
            anchors.margins: Theme.space
            active: window.visible && window.currentTab === "wallpaper"
            visible: window.currentTab === "wallpaper"
            source: wallpaperPage.active ? Qt.resolvedUrl("../settings/WallpaperTab.qml") : ""
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
        }

        Connections {
            target: regionPage.item
            function onCloseRequested() {
                window.hide()
            }
        }

        TabStrip {
            id: tabs
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space
            model: [
                { id: "bar", label: "Bar" },
                { id: "widgets", label: "Widgets" },
                { id: "wallpaper", label: "Wallpaper" },
                { id: "applications", label: "Applications" },
                { id: "connectivity", label: "Connectivity" },
                { id: "audio", label: "Audio" },
                { id: "notifications", label: "Notifications" },
                { id: "region", label: "Region & Clock" }
            ]
            currentId: window.currentTab
            onSelected: (tabId) => { window.currentTab = tabId }
        }

        MouseArea {
            z: 2
            width: 18
            height: 18
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
