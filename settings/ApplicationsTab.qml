import QtQuick
import qs.theme

Item {
    id: root

    property string section: "launcher"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "launcher" || id === "menu" || id === "freshrss")
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
            { id: "launcher", label: "App Launcher" },
            { id: "menu", label: "Application Menu" },
            { id: "freshrss", label: "FreshRSS" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: launcherPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "launcher"
        source: launcherPage.active ? Qt.resolvedUrl("AppLauncherTab.qml") : ""
    }

    Loader {
        id: menuPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "menu"
        source: menuPage.active ? Qt.resolvedUrl("AppMenuTab.qml") : ""
    }

    Loader {
        id: freshRssPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "freshrss"
        source: freshRssPage.active ? Qt.resolvedUrl("FreshRssTab.qml") : ""
    }
}
