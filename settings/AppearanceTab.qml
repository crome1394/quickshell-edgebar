import QtQuick
import qs.theme

// Settings → Appearance: Theme (colors, fonts, presets) and Wallpaper.
// Each section loads only while it is shown.
Item {
    id: root

    property string section: "theme"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "theme" || id === "wallpaper")
            root.section = id
    }

    onRevealSerialChanged: root.applyReveal()
    Component.onCompleted: root.applyReveal()

    TabStrip {
        id: sections
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        model: [
            { id: "theme", label: "Theme" },
            { id: "wallpaper", label: "Wallpaper" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: themePage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "theme"
        source: themePage.active ? Qt.resolvedUrl("ThemeTab.qml") : ""
    }

    Loader {
        id: wallpaperPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "wallpaper"
        source: wallpaperPage.active ? Qt.resolvedUrl("WallpaperTab.qml") : ""
    }
}
