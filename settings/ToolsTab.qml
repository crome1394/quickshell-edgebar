import QtQuick
import qs.theme

// Settings → Tools: settings for desktop helpers the bar does not draw,
// started by Hyprland keybinds or hypridle: Capture and Screensaver.
Item {
    id: root

    property string section: "capture"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "capture" || id === "screensaver")
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
            { id: "capture", label: "Capture" },
            { id: "screensaver", label: "Screensaver" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: capturePage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "capture"
        source: capturePage.active ? Qt.resolvedUrl("CaptureTab.qml") : ""
    }

    Loader {
        id: screensaverPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "screensaver"
        source: screensaverPage.active ? Qt.resolvedUrl("ScreensaverTab.qml") : ""
    }
}
