import QtQuick
import Quickshell
import qs.services
import qs.theme

// One open window in the Transparency menu's Add override list: icon,
// app name, and window class. Clicking adds an override for that class.
Rectangle {
    id: root

    required property var theme
    required property string cls
    required property bool added

    signal picked(string cls, string label)

    // Looked up again once the app list has loaded.
    readonly property var entry: DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(root.cls) : null
    readonly property string name: root.entry && root.entry.name ? String(root.entry.name) : root.cls
    readonly property string iconSource: root.entry ? IconService.url(String(root.entry.icon || "")) : ""

    implicitHeight: Theme.fieldHeight
    radius: Theme.radiusSm
    color: rowMouse.containsMouse && !root.added ? root.theme.colHover : "transparent"
    opacity: root.added ? Theme.widgetOffOpacity : 1

    Image {
        id: rowIcon
        x: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.chip
        height: Theme.chip
        source: root.iconSource
        sourceSize.width: width
        sourceSize.height: height
        asynchronous: true
    }

    Text {
        anchors.left: rowIcon.right
        anchors.leftMargin: Theme.space
        anchors.right: rowState.left
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: root.name === root.cls ? root.cls : root.name + "  ·  " + root.cls
        color: root.theme.colFg
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
    }

    Text {
        id: rowState
        anchors.right: parent.right
        anchors.rightMargin: Theme.space
        anchors.verticalCenter: parent.verticalCenter
        text: root.added ? "Added" : "+ Add"
        color: root.added ? root.theme.colFgMuted : root.theme.colAccent
        font.family: root.theme.uiFont
        font.pixelSize: root.theme.smallPx
        font.bold: !root.added
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.added
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked(root.cls, root.name)
    }
}
