import QtQuick
import qs.theme

// Settings → Tools: desktop helpers: Capture and Screensaver (started by
// Hyprland keybinds or hypridle), Recording, Night Light, and Clipboard.
Item {
    id: root

    property string section: "capture"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "capture" || id === "screensaver" || id === "recording" || id === "nightlight" || id === "clipboard" || id === "codeaid")
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
            { id: "screensaver", label: "Screensaver" },
            { id: "recording", label: "Recording" },
            { id: "nightlight", label: "Night Light" },
            { id: "clipboard", label: "Clipboard" },
            { id: "codeaid", label: "Code Aid" }
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

    Loader {
        id: recordingPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "recording"
        source: recordingPage.active ? Qt.resolvedUrl("RecordingTab.qml") : ""
    }

    Loader {
        id: nightPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "nightlight"
        source: nightPage.active ? Qt.resolvedUrl("NightLightTab.qml") : ""
    }

    Loader {
        id: clipboardPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "clipboard"
        source: clipboardPage.active ? Qt.resolvedUrl("ClipboardTab.qml") : ""
    }

    Loader {
        id: codeAidPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "codeaid"
        source: codeAidPage.active ? Qt.resolvedUrl("CodeAidTab.qml") : ""
    }
}
