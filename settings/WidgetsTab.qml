import QtQuick
import qs.theme

Item {
    id: root

    property string section: "bars"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "bars" || id === "activewindow" || id === "stats")
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
            { id: "bars", label: "Bars" },
            { id: "activewindow", label: "Active Window" },
            { id: "stats", label: "System Stats" }
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
        active: root.section === "bars"
        sourceComponent: Component { WidgetBarsTab {} }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "activewindow"
        sourceComponent: Component { ActiveWindowTab {} }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "stats"
        source: active ? Qt.resolvedUrl("SystemStatsTab.qml") : ""
    }
}
