import QtQuick
import qs.theme

// One line in Code Aid's list: a language heading, or a snippet's name
// (with its language while searching, and a mark when it has blanks).
// Moving the mouse over a snippet highlights it; a click copies it.
Rectangle {
    id: root

    required property var row
    required property bool current
    required property bool showLanguage

    signal hovered(point at)
    signal clicked()
    signal rightClicked()

    readonly property bool header: root.row.kind === "header"
    readonly property bool hasBlanks: !root.header && /\{\{/.test(String(root.row.snip.body || ""))

    implicitHeight: root.header ? Theme.codeAidRowHeight : Theme.codeAidRowHeight
    radius: Theme.radiusSm
    color: root.current ? Theme.accentDim : "transparent"

    Rectangle {
        visible: root.current
        y: Theme.freshRssRowPad / 2
        width: Theme.freshRssCursorBar
        height: parent.height - Theme.freshRssRowPad
        radius: width / 2
        color: Theme.accent
    }

    Text {
        visible: root.header
        x: Theme.space
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.tabGap / 2
        text: String(root.row.title || "").toUpperCase()
        textFormat: Text.PlainText
        color: Theme.accent
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx - 1
        font.bold: true
        font.letterSpacing: 1
    }

    Row {
        visible: !root.header
        x: Theme.space * 1.5
        width: parent.width - x - Theme.space
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.tabGap

        Text {
            width: parent.width - (lang.visible ? lang.width + parent.spacing : 0) - (blanks.visible ? blanks.width + parent.spacing : 0)
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root.header ? "" : String(root.row.snip.name)
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx + 1
        }

        Text {
            id: blanks
            visible: root.hasBlanks
            text: "{ }"
            color: root.current ? Theme.accent : Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallPx - 1
        }

        Text {
            id: lang
            visible: root.showLanguage && !root.header
            text: root.header ? "" : CodeAidLogic.languageName(root.row.snip.language)
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx - 1
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.header
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => root.hovered(mapToGlobal(mouse.x, mouse.y))
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.clicked()
        }
    }
}
