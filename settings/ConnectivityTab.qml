import QtQuick
import qs.theme

Item {
    id: root

    property string section: "network"
    property int revealSerial: 0
    property string revealSection: ""

    function applyReveal() {
        const id = root.revealSection
        if (id === "network" || id === "bluetooth")
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
            { id: "network", label: "Network" },
            { id: "bluetooth", label: "Bluetooth" }
        ]
        currentId: root.section
        onSelected: (tabId) => { root.section = tabId }
    }

    Loader {
        id: networkPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "network"
        source: networkPage.active ? Qt.resolvedUrl("NetworkTab.qml") : ""
    }

    Loader {
        id: bluetoothPage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sections.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.space
        active: root.section === "bluetooth"
        source: bluetoothPage.active ? Qt.resolvedUrl("BluetoothTab.qml") : ""
    }
}
