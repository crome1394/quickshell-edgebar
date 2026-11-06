import QtQuick
import qs.services
import qs.theme

// App icon for a launcher settings row. Falls back to the first letter
// of the name when the icon is missing or fails to load.
Item {
    id: root

    required property string name
    required property string iconName

    readonly property string source: IconService.url(root.iconName)
    readonly property string letter: {
        const label = root.name.trim()
        return label.length ? label.charAt(0).toUpperCase() : "•"
    }

    implicitWidth: Theme.chip

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: Theme.chip
        height: Theme.chip
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        source: root.source
        visible: root.source.length > 0 && iconImage.status !== Image.Error
    }

    Text {
        anchors.centerIn: parent
        visible: !iconImage.visible
        text: root.letter
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }
}
