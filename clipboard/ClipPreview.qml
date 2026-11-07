pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.settings
import qs.theme

// The right pane: the highlighted entry in full. Text shows as it was
// copied (code in the fixed-width font) and can be selected to copy just
// a part; pictures show whole. Loads a moment after the cursor stops, one
// entry at a time, and only while the viewer is open.
Rectangle {
    id: root

    required property var entry
    // Zoomed: the pane fills the viewer. `where` is "3 of 12" for its header.
    property bool zoomed: false
    property string where: ""

    signal copyClicked()
    signal deleteClicked()

    property string fullText: ""
    property string imageUrl: ""
    property bool loading: false
    // A zoomed picture shown at full size (click to switch), else fitted.
    property bool fullSize: false

    // PgUp / PgDn while zoomed: scroll the text or the full-size picture.
    function scrollPage(step) {
        const f = (root.isImage ? picture : scroller.contentItem) as Flickable
        if (!f || f.contentHeight <= f.height)
            return
        f.contentY = Math.max(0, Math.min(f.contentHeight - f.height, f.contentY + step * f.height * 0.9))
    }

    onZoomedChanged: {
        if (!root.zoomed)
            root.fullSize = false
    }

    readonly property bool isImage: !!root.entry && root.entry.kind === "image"
    readonly property bool mono: !!root.entry && root.entry.kind !== "text" && root.entry.kind !== "link"

    radius: Theme.radius
    color: Theme.fieldBg
    border.width: Theme.borderWidth
    border.color: Theme.border

    onEntryChanged: {
        root.fullText = ""
        root.imageUrl = ""
        root.fullSize = false
        root.loading = !!root.entry
        loadDelay.restart()
    }

    Timer {
        id: loadDelay
        interval: Theme.clipboardPreviewDelayMs
        onTriggered: {
            const e = root.entry
            if (!e)
                return
            if (e.kind === "image") {
                ClipboardService.previewImage(e, (url) => {
                    if (root.entry && root.entry.id === e.id) {
                        root.imageUrl = url
                        root.loading = false
                    }
                })
            } else {
                ClipboardService.previewText(e, (text) => {
                    if (root.entry && root.entry.id === e.id) {
                        root.fullText = text
                        root.loading = false
                    }
                })
            }
        }
    }

    Item {
        id: head
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        height: Theme.fieldHeight
        visible: !!root.entry

        Text {
            anchors.left: parent.left
            anchors.right: actions.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: {
                if (!root.entry)
                    return ""
                const pos = root.zoomed && root.where.length ? root.where + " · " : ""
                if (root.isImage)
                    return pos + "Picture" + (root.entry.detail.length ? " · " + root.entry.detail : "")
                        + (root.zoomed ? (root.fullSize ? " · full size" : " · fitted") : "")
                const t = root.fullText.length ? root.fullText : root.entry.preview
                const lines = t.split("\n").length
                return pos + t.length + " characters" + (lines > 1 ? " · " + lines + " lines" : "")
            }
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.tabGap

            ActionChip {
                label: "Copy"
                caps: ["Enter"]
                tip: "Copy to the clipboard and close; then paste with Ctrl+V"
                onClicked: root.copyClicked()
            }

            ActionChip {
                label: "Delete"
                caps: ["Shift", "Del"]
                tip: "Remove from the history"
                onClicked: root.deleteClicked()
            }
        }
    }

    Rectangle {
        id: rule
        visible: !!root.entry
        anchors.top: head.bottom
        anchors.topMargin: Theme.space
        x: Theme.space
        width: parent.width - Theme.space * 2
        height: Theme.borderWidth
        color: Theme.border
    }

    Item {
        anchors.top: rule.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space

        Text {
            anchors.centerIn: parent
            visible: !root.entry || (root.loading && root.isImage)
            text: root.entry ? "Loading…" : "Nothing selected."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        // Fitted, or (zoomed, after a click) full size to drag around.
        Flickable {
            id: picture
            anchors.fill: parent
            visible: root.isImage && root.imageUrl.length > 0
            clip: true
            contentWidth: root.fullSize ? Math.max(width, shot.implicitWidth) : width
            contentHeight: root.fullSize ? Math.max(height, shot.implicitHeight) : height
            interactive: root.fullSize
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: root.fullSize ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
            ScrollBar.horizontal: ScrollBar { policy: root.fullSize ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

            // Fitted: decoded no bigger than the pane needs.
            Image {
                id: fitted
                visible: !root.fullSize
                width: picture.width
                height: picture.height
                source: root.isImage && !root.fullSize ? root.imageUrl : ""
                sourceSize.width: Math.max(1, Math.round(picture.width * 2))
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
            }

            // Full size: no size set, so it takes the picture's own.
            Image {
                id: shot
                visible: root.fullSize
                source: root.isImage && root.fullSize ? root.imageUrl : ""
                asynchronous: true
                cache: false
            }

            MouseArea {
                width: picture.contentWidth
                height: picture.contentHeight
                enabled: root.zoomed
                cursorShape: root.zoomed ? (root.fullSize ? Qt.ClosedHandCursor : Qt.PointingHandCursor) : Qt.ArrowCursor
                onClicked: {
                    root.fullSize = !root.fullSize
                    picture.contentX = 0
                    picture.contentY = 0
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width
            visible: root.isImage && !root.loading && !root.imageUrl.length
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "This picture cannot be previewed, but Enter still copies it."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        ScrollView {
            id: scroller
            anchors.fill: parent
            visible: !!root.entry && !root.isImage
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

            TextEdit {
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.PlainText
                wrapMode: root.mono ? TextEdit.NoWrap : TextEdit.Wrap
                width: root.mono ? Math.max(scroller.width, implicitWidth) : scroller.width
                text: root.entry ? (root.fullText.length ? root.fullText : root.entry.preview) : ""
                color: Theme.text
                selectionColor: Theme.accentDim
                selectedTextColor: Theme.text
                font.family: root.mono ? Theme.fontFamily : Theme.uiFont
                font.pixelSize: Theme.fontPx
            }
        }
    }
}
