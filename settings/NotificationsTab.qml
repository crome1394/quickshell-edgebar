import QtQuick
import qs.theme

// Settings → Notifications: Notifications (server, toasts, history) and
// On-Screen Display (volume, microphone, media, brightness). Each section
// loads only while it is shown.
Item {
    id: root

    property string section: "notifications"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "notifications" || id === "osd")
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
            { id: "notifications", label: "Notifications" },
            { id: "osd", label: "On-Screen Display" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: popupsPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "notifications"
        source: popupsPage.active ? Qt.resolvedUrl("NotificationPopupsTab.qml") : ""
    }

    Loader {
        id: osdPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "osd"
        source: osdPage.active ? Qt.resolvedUrl("OsdTab.qml") : ""
    }
}
