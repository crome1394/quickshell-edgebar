pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// The on-screen display card: a symbol or cover, a title and detail, and
// a level bar. Exists only while OsdHost shows something. Clicks pass
// through it. Colors follow the theme unless the look sets its own.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    required property var item
    required property var look
    // False while fading out.
    required property bool showing

    property bool entered: false

    readonly property bool hasBar: Number(root.item.value) >= 0
    readonly property bool useArt: root.look.art && String(root.item.art || "").length > 0
    readonly property color ink: root.look.text === "auto" ? Theme.text : root.look.text
    readonly property color fill: root.item.muted ? Theme.subtext : (root.look.accent === "auto" ? Theme.accent : root.look.accent)
    readonly property int textPx: Math.max(Theme.smallPx, Math.round(Theme.fontPx * root.look.textSize / 100))
    readonly property int glyphPx: Math.round(Theme.iconPx * 1.6 * root.look.textSize / 100)
    readonly property int pad: Theme.space * 2

    Component.onCompleted: root.entered = true

    screen: ScreenService.mainScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    anchors.top: root.look.vplace === "top"
    anchors.bottom: root.look.vplace === "bottom"
    anchors.left: root.look.hplace === "left"
    anchors.right: root.look.hplace === "right"
    // qmllint disable missing-property
    margins.top: root.look.margin
    margins.bottom: root.look.margin
    margins.left: root.look.margin
    margins.right: root.look.margin
    // qmllint enable missing-property
    implicitWidth: root.look.width
    implicitHeight: card.height
    // An empty input region: clicks go to whatever is underneath.
    mask: Region {}

    Rectangle {
        id: card
        width: parent.width
        height: Math.max(row.implicitHeight, root.useArt ? Theme.osdArt : 0) + root.pad * 2
        radius: Theme.radius
        color: root.look.glass > 0 ? Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, root.look.glass / 100) : Theme.barBg
        border.width: root.look.border ? Theme.borderWidth : 0
        border.color: Theme.border
        opacity: root.entered && root.showing ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.osdFadeMs; easing.type: Easing.OutQuad }
        }

        Row {
            id: row
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.pad * 2
            spacing: Theme.space * 1.5

            Item {
                width: root.useArt ? Theme.osdArt : glyph.implicitWidth
                height: root.useArt ? Theme.osdArt : glyph.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    visible: root.useArt
                    anchors.fill: parent
                    source: root.useArt ? String(root.item.art) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: Theme.osdArt * 2
                    sourceSize.height: Theme.osdArt * 2
                }

                Text {
                    id: glyph
                    visible: !root.useArt
                    text: String(root.item.glyph || "")
                    color: root.item.muted ? Theme.subtext : root.ink
                    font.family: Theme.iconFont
                    font.pixelSize: root.glyphPx
                }
            }

            Column {
                width: parent.width - parent.spacing - (root.useArt ? Theme.osdArt : glyph.implicitWidth)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.tabGap

                Item {
                    width: parent.width
                    height: title.implicitHeight

                    Text {
                        id: title
                        width: parent.width - percent.implicitWidth - (percent.text.length ? Theme.space : 0)
                        elide: Text.ElideRight
                        text: String(root.item.title || "")
                        color: root.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textPx
                        font.bold: true
                    }

                    Text {
                        id: percent
                        anchors.right: parent.right
                        text: String(root.item.percent || "")
                        color: root.item.muted ? Theme.subtext : root.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textPx
                    }
                }

                Text {
                    visible: text.length > 0
                    width: parent.width
                    elide: Text.ElideRight
                    text: String(root.item.detail || "")
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(Theme.smallPx, root.textPx - 2)
                }

                Rectangle {
                    visible: root.hasBar
                    width: parent.width
                    height: Theme.osdBarHeight
                    radius: height / 2
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.15)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Number(root.item.value)))
                        height: parent.height
                        radius: height / 2
                        color: root.fill

                        Behavior on width {
                            NumberAnimation { duration: Theme.osdFadeMs; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
