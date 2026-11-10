import QtQuick
import qs.services
import qs.theme

// One line under an app on Default Apps → By app: a small family label, or
// a type with its plain name and what to do with it. A default the app
// holds by your choice can go back to the system; a type it can also open
// can be given to it.
Item {
    id: root

    // A DefaultAppsLogic.familyRows() row (header or type).
    required property var row
    // DefaultAppsLogic.resolve() for the type: { id, source }.
    required property var info
    // True under "Opens by default", false under "Can also open".
    required property bool isDefault

    signal makeClicked()
    signal clearClicked()

    readonly property string type: String(root.row.type || "")

    implicitHeight: root.row.header ? familyText.implicitHeight + Theme.tabGap : Math.max(Theme.fieldHeight, typeCol.implicitHeight)

    Text {
        id: familyText
        visible: !!root.row.header
        anchors.bottom: parent.bottom
        text: String(root.row.glyph || "") + "  " + String(root.row.label || "") + " · " + root.row.count
        color: Theme.accent
        font.family: Theme.iconFont
        font.pixelSize: Theme.smallPx
    }

    Column {
        id: typeCol
        visible: !root.row.header
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - side.width - Theme.space

        Text {
            width: parent.width
            elide: Text.ElideMiddle
            text: root.type
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx + 1
        }

        MimeComment {
            width: parent.width
            type: root.row.header ? "" : root.type
        }
    }

    Row {
        id: side
        visible: !root.row.header
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root.isDefault) {
                    if (root.info.source === "you")
                        return "your choice"
                    if (root.info.source === "system")
                        return "system default"
                    if (root.info.source === "added")
                        return "first in an Open with list"
                    return "first app that opens it"
                }
                if (!root.info.id.length)
                    return "nothing opens it now"
                const name = DefaultAppsService.appName(root.info.id)
                return "now " + (name.length ? name : root.info.id.replace(/\.desktop$/, ""))
            }
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ChipButton {
            visible: root.isDefault && root.info.source === "you"
            label: "Use system default"
            tip: "Remove your line for this type, so the system decides"
            onClicked: root.clearClicked()
        }

        ChipButton {
            visible: !root.isDefault
            label: "Make default"
            tip: "Open this type with this app. Apply saves it."
            onClicked: root.makeClicked()
        }
    }
}
