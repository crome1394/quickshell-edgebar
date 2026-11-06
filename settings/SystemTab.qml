import QtQuick
import qs.theme

// Settings → System: Dependencies and Display.
Item {
    id: root

    property string section: "dependencies"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "dependencies" || id === "display")
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
            { id: "dependencies", label: "Dependencies" },
            { id: "display", label: "Display" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: dependenciesPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "dependencies"
        source: dependenciesPage.active ? Qt.resolvedUrl("DependenciesTab.qml") : ""
    }

    Loader {
        id: displayPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "display"
        source: displayPage.active ? Qt.resolvedUrl("DisplayTab.qml") : ""
    }
}
