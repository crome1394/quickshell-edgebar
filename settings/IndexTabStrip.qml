pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.theme

// Settings tabs drawn as colored index dividers hanging from the page:
// one color per tab, the active one taller and flush with a strip of its
// color along the page edge, the rest a little shorter and dimmed until
// hovered. Labels pick dark or light text to stay readable on each color.
// Same API as TabStrip: model [{ id, label }], currentId, selected(id).
Item {
    id: root

    required property var model
    property string currentId: ""
    // "rainbow" (fixed colors) or "accent" (hues spread from the accent).
    property string colorMode: "rainbow"

    signal selected(string tabId)

    readonly property int count: root.model ? root.model.length : 0
    readonly property real overlap: Theme.indexTabOverlap
    readonly property real tabWidth: root.count ? (root.width + root.overlap * (root.count - 1)) / root.count : root.width
    readonly property bool light: ThemeStore.activeTheme.tone === "light"
    readonly property int activeIndex: {
        for (let i = 0; i < root.count; i++) {
            if (String(root.model[i].id) === root.currentId)
                return i
        }
        return 0
    }

    implicitHeight: Theme.indexTabEdge + Theme.indexTabHeight

    function colorAt(i) {
        let c
        if (root.colorMode === "accent") {
            const a = Theme.accent
            c = Qt.hsla(((a.hslHue < 0 ? 0 : a.hslHue) + i / Math.max(1, root.count)) % 1, 0.62, root.light ? 0.6 : 0.55, 1)
        } else {
            c = ThemeBuilder.parse(Theme.indexTabColors[i % Theme.indexTabColors.length])
        }
        // Softer on paper themes so the strip does not shout.
        return root.light ? ThemeBuilder.mix(c, Qt.rgba(1, 1, 1, 1), 0.18) : c
    }

    function inkFor(c) {
        return ThemeBuilder.luminance(c) > 0.55 ? Theme.indexTabDarkInk : Theme.indexTabLightInk
    }

    // The page edge in the active tab's color.
    Rectangle {
        z: root.count + 1
        width: parent.width
        height: Theme.indexTabEdge
        color: root.colorAt(root.activeIndex)
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

            x: tab.index * (root.tabWidth - root.overlap)
            y: Theme.indexTabEdge - Theme.borderWidth
            // Active on top, then left over right, like a fanned stack.
            z: tab.active ? root.count + 2 : root.count - tab.index
            width: root.tabWidth
            height: Theme.indexTabHeight - tab.drop

            Behavior on height {
                NumberAnimation { duration: Theme.colorAnimMs; easing.type: Easing.OutQuad }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: tab.active || hover.containsMouse ? 1 : Theme.indexTabIdleOpacity

                ShapePath {
                    fillColor: tab.fill
                    strokeColor: tab.active ? "transparent" : Theme.border
                    strokeWidth: tab.active ? 0 : Theme.borderWidth
                    startX: 0
                    startY: 0
                    PathLine { x: tab.width; y: 0 }
                    PathLine { x: tab.width - Theme.indexTabSlant; y: tab.height - Theme.indexTabRadius }
                    PathArc {
                        x: tab.width - Theme.indexTabSlant - Theme.indexTabRadius
                        y: tab.height
                        radiusX: Theme.indexTabRadius
                        radiusY: Theme.indexTabRadius
                    }
                    PathLine { x: Theme.indexTabSlant + Theme.indexTabRadius; y: tab.height }
                    PathArc {
                        x: Theme.indexTabSlant
                        y: tab.height - Theme.indexTabRadius
                        radiusX: Theme.indexTabRadius
                        radiusY: Theme.indexTabRadius
                    }
                    PathLine { x: 0; y: 0 }
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: Theme.indexTabSlant + Theme.borderWidth * 2
                anchors.rightMargin: Theme.indexTabSlant + Theme.borderWidth * 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Long labels shrink a little to fit, then cut off.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Theme.indexTabMinPx
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: String(tab.modelData.label || "")
                color: root.inkFor(tab.fill)
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
