pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.theme

// Settings tabs drawn as colored index dividers.
//   edge "bottom": the main tabs, hanging from the page; each its own color
//                  (TabColors), the active color recorded for the sections.
//   edge "top":    a page's section tabs, standing on it; shades of the
//                  active main color, at most Theme.indexTabMaxWidth wide.
// The active tab is taller and flush with a strip of its color along the
// page edge; the rest are shorter and dimmed until hovered. Labels shrink
// to fit and pick dark or light text per color.
// Same API as TabStrip: model [{ id, label }], currentId, selected(id).
Item {
    id: root

    required property var model
    property string currentId: ""
    property string edge: "bottom"

    signal selected(string tabId)

    readonly property bool standing: root.edge === "top"
    readonly property int count: root.model ? root.model.length : 0
    readonly property real overlap: Theme.indexTabOverlap
    readonly property real tabWidth: {
        const fill = root.count ? (root.width + root.overlap * (root.count - 1)) / root.count : root.width
        return root.standing ? Math.min(fill, Theme.indexTabMaxWidth) : fill
    }
    readonly property int activeIndex: {
        for (let i = 0; i < root.count; i++) {
            if (String(root.model[i].id) === root.currentId)
                return i
        }
        return 0
    }

    function colorAt(i) {
        return root.standing ? TabColors.sectionColor(i) : TabColors.mainColor(i, root.count)
    }

    readonly property color activeColor: root.colorAt(root.activeIndex)

    onActiveColorChanged: {
        if (!root.standing)
            TabColors.activeColor = root.activeColor
    }
    Component.onCompleted: {
        if (!root.standing)
            TabColors.activeColor = root.activeColor
    }

    implicitHeight: Theme.indexTabEdge + Theme.indexTabHeight

    // The page edge in the active tab's color.
    Rectangle {
        z: root.count + 1
        y: root.standing ? root.height - Theme.indexTabEdge : 0
        width: parent.width
        height: Theme.indexTabEdge
        color: root.activeColor
    }

    Repeater {
        model: root.model
        delegate: Item {
            id: tab
            required property var modelData
            required property int index

            readonly property bool active: tab.index === root.activeIndex
            readonly property color fill: root.colorAt(tab.index)
            readonly property real drop: tab.active || hover.containsMouse ? 0 : Theme.indexTabInset
            readonly property real s: Theme.indexTabSlant
            readonly property real r: Theme.indexTabRadius

            x: tab.index * (root.tabWidth - root.overlap)
            // Hanging tabs grow down from the edge; standing tabs grow up to it.
            y: root.standing ? tab.drop : Theme.indexTabEdge - Theme.borderWidth
            // Active on top, then left over right, like a fanned stack.
            z: tab.active ? root.count + 2 : root.count - tab.index
            width: root.tabWidth
            height: Theme.indexTabHeight - tab.drop + (root.standing ? Theme.borderWidth : 0)

            Behavior on height {
                NumberAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
            }
            Behavior on y {
                NumberAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: tab.active || hover.containsMouse ? 1 : Theme.indexTabIdleOpacity

                // Wide side on the page, narrow rounded side away from it.
                ShapePath {
                    fillColor: tab.fill
                    strokeColor: tab.active ? "transparent" : Theme.border
                    strokeWidth: tab.active ? 0 : Theme.borderWidth
                    startX: 0
                    startY: root.standing ? tab.height : 0
                    PathLine { x: tab.width; y: root.standing ? tab.height : 0 }
                    PathLine { x: tab.width - tab.s; y: root.standing ? tab.r : tab.height - tab.r }
                    PathArc {
                        x: tab.width - tab.s - tab.r
                        y: root.standing ? 0 : tab.height
                        radiusX: tab.r
                        radiusY: tab.r
                        direction: root.standing ? PathArc.Counterclockwise : PathArc.Clockwise
                    }
                    PathLine { x: tab.s + tab.r; y: root.standing ? 0 : tab.height }
                    PathArc {
                        x: tab.s
                        y: root.standing ? tab.r : tab.height - tab.r
                        radiusX: tab.r
                        radiusY: tab.r
                        direction: root.standing ? PathArc.Counterclockwise : PathArc.Clockwise
                    }
                    PathLine { x: 0; y: root.standing ? tab.height : 0 }
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: tab.s + Theme.borderWidth * 2
                anchors.rightMargin: tab.s + Theme.borderWidth * 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Long labels shrink a little to fit, then cut off.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Theme.indexTabMinPx
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: String(tab.modelData.label || "")
                color: TabColors.inkFor(tab.fill)
                opacity: tab.active || hover.containsMouse ? 1 : Theme.indexTabIdleOpacity
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
                font.capitalization: Font.AllUppercase
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(String(tab.modelData.id || ""))

                HoverTip {
                    message: String(tab.modelData.label || "")
                    show: hover.containsMouse && !tab.active
                }
            }
        }
    }
}
