import QtQuick
import qs.theme

Item {
    id: root

    property string section: "region"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "region" || id === "clock")
            root.section = id
    }

    onRevealSerialChanged: root.applyReveal()
    Component.onCompleted: root.applyReveal()

    signal closeRequested()

    TabStrip {
        id: sections
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        model: [
            { id: "region", label: "Region" },
            { id: "clock", label: "Clock" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: regionPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "region"
        sourceComponent: Component { RegionTab {} }
    }

    Connections {
        target: regionPage.item
        function onCloseRequested() {
            root.closeRequested()
        }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "clock"
        sourceComponent: Component { ClockFormatTab {} }
    }
}
