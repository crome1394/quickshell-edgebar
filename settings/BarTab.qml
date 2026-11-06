import QtQuick
import qs.theme

Item {
    id: root

    property string section: "workspaces"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "workspaces" || id === "overview" || id === "dock")
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
            { id: "workspaces", label: "Workspaces" },
            { id: "overview", label: "Overview" },
            { id: "dock", label: "Dock" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "workspaces"
        sourceComponent: Component { WorkspacesTab {} }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "overview"
        source: active ? Qt.resolvedUrl("OverviewTab.qml") : ""
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "dock"
        source: active ? Qt.resolvedUrl("DockTab.qml") : ""
    }
}
