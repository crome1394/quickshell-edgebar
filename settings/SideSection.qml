import QtQuick
import qs.theme

// A settings section with its title on a bar down the left side, turned
// counter-clockwise (reads bottom to top), and its content to the right.
// With `collapsible`, clicking the bar folds the section sideways to just
// the bar, and clicking again opens it. The hint shows as a hover tip.
// Put the content inside; it gets the width beside the bar.
Item {
    id: root

    required property string title
    property string hint: ""
    property bool collapsible: false
    property bool expanded: true

    signal toggled()

    default property alias content: body.data

    readonly property bool showing: !root.collapsible || root.expanded

    implicitHeight: Math.max(bar.implicitHeight, root.showing ? body.childrenRect.height : 0)

    Rectangle {
        id: bar
        implicitHeight: barText.implicitWidth + Theme.space * 4
        width: Theme.sideHeaderWidth
        height: Math.max(implicitHeight, root.height)
        radius: Theme.radiusSm
        color: barMouse.containsMouse && root.collapsible ? Theme.hover : Theme.sectionBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        // The accent sliver, like the top headers, along the bar's left edge.
        Rectangle {
            x: Theme.borderWidth
            y: Theme.radiusSm
            width: Theme.borderWidth * 3
            height: parent.height - Theme.radiusSm * 2
            radius: width / 2
            color: Theme.accent
        }

        Text {
            id: barText
            anchors.centerIn: parent
            rotation: -90
            text: root.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            font.bold: true
        }

        Text {
            visible: root.collapsible
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.tabGap
            text: root.expanded ? "›" : "‹"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
            font.bold: true
        }

        MouseArea {
            id: barMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.collapsible)
                    root.toggled()
            }

            HoverTip {
                message: root.hint + (root.collapsible ? (root.hint.length ? " " : "") + (root.expanded ? "Click to fold." : "Click to open.") : "")
                show: barMouse.containsMouse && message.length > 0
            }
        }
    }

    Item {
        id: body
        visible: root.showing
        x: bar.width + Theme.space
        width: Math.max(0, root.width - bar.width - Theme.space)
        height: childrenRect.height
        clip: true
    }
}
