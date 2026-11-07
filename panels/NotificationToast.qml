pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.theme

// One popup card from the built-in server: the newest notification of a
// group (with "+N" when an app sent several). Styles: compact (one line),
// standard, large (big image on top). Optional app color stripe, big image
// previews, and a progress bar for the time left. It closes after the
// timeout (the sender's own if shorter), pauses while hovered, and stays
// for critical ones. A click runs the default action or dismisses; ✕
// dismisses the whole group. Slides or fades in and out (Popups → Motion).
Item {
    id: root

    // Notifications in this card, oldest first.
    required property var notifications
    required property var look
    required property bool fromLeft

    readonly property Notification latest: root.notifications.length ? root.notifications[root.notifications.length - 1] : null
    readonly property int extra: Math.max(0, root.notifications.length - 1)
    readonly property bool critical: !!root.latest && root.latest.urgency === NotificationUrgency.Critical
    readonly property string style: root.look.style
    readonly property var allActions: root.latest ? Array.from(root.latest.actions) : []
    readonly property var actions: root.allActions.filter((a) => a.identifier !== "default")
    readonly property var defaultAction: root.allActions.find((a) => a.identifier === "default") ?? null
    readonly property color stripe: root.latest ? PopupSettings.appColor(root.latest.appName, root.look) : "transparent"
    readonly property bool hasStripe: root.stripe.a > 0

    // A real image (screenshot, album art), not just the app icon.
    readonly property string picture: {
        const img = root.latest ? String(root.latest.image || "") : ""
        if (!img.length)
            return ""
        const path = NotificationService.localImagePath(img)
        if (path.length)
            return "file://" + path
        return img.charAt(0) === "/" ? "file://" + img : img
    }
    readonly property string icon: root.latest ? IconService.url(String(root.latest.appIcon || "")) : ""
    readonly property bool preview: root.picture.length > 0 && root.style !== "compact"
        && (root.style === "large" || root.look.bigImages)
    readonly property string thumb: root.preview ? root.icon : (root.picture.length ? root.picture : root.icon)

    readonly property int timeoutMs: {
        if (!root.latest)
            return 0
        const own = Number(root.latest.expireTimeout)
        const mine = NotificationSettings.timeoutValue() * 1000
        if (root.critical || (mine === 0 && !(own > 0)))
            return 0
        if (own > 0 && (mine === 0 || own < mine))
            return own
        return mine
    }

    property real remaining: 1
    property bool closing: false
    property real slide: 0

    implicitHeight: card.implicitHeight
    opacity: 0

    // Close every notification in the card, after the exit motion.
    function close(dismissed) {
        if (root.closing)
            return
        root.closing = true
        if (root.look.motion === "none") {
            root.finish(dismissed)
            return
        }
        exitAnim.dismissed = dismissed
        exitAnim.start()
    }

    function finish(dismissed) {
        const list = root.notifications.slice()
        for (let i = 0; i < list.length; i++) {
            if (dismissed)
                list[i].dismiss()
            else
                list[i].expire()
        }
    }

    function restartTimer() {
        countdown.stop()
        root.remaining = 1
        if (root.timeoutMs > 0)
            countdown.start()
    }

    onLatestChanged: root.restartTimer()

    Component.onCompleted: {
        root.slide = root.look.motion === "slide" ? (root.fromLeft ? -1 : 1) * root.width : 0
        if (root.look.motion === "none") {
            root.opacity = 1
            root.slide = 0
        } else {
            enterAnim.start()
        }
        root.restartTimer()
    }

    NumberAnimation {
        id: countdown
        target: root
        property: "remaining"
        from: 1
        to: 0
        duration: Math.max(1, root.timeoutMs)
        paused: running && hover.hovered
        onFinished: {
            if (root.remaining <= 0)
                root.close(false)
        }
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Theme.popupMotionMs; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "slide"; to: 0; duration: Theme.popupMotionMs; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: exitAnim
        property bool dismissed: false
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Theme.popupMotionMs; easing.type: Easing.InCubic }
        NumberAnimation {
            target: root
            property: "slide"
            to: root.look.motion === "slide" ? (root.fromLeft ? -1 : 1) * root.width : 0
            duration: Theme.popupMotionMs
            easing.type: Easing.InCubic
        }
        onFinished: root.finish(exitAnim.dismissed)
    }

    Rectangle {
        id: card
        x: root.slide
        width: root.width
        implicitHeight: body.implicitHeight + Theme.space * 2 + (bar.visible ? bar.height : 0)
        radius: Theme.radius
        clip: true
        color: root.look.glass > 0 ? Qt.rgba(Theme.barBg.r, Theme.barBg.g, Theme.barBg.b, root.look.glass / 100) : Theme.barBg
        border.width: Theme.borderWidth
        border.color: root.critical ? Theme.danger : (hover.hovered ? Theme.accent : Theme.border)

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.defaultAction)
                    root.defaultAction.invoke()
                else
                    root.close(true)
            }
        }

        // App color stripe along the left edge, inside the rounded corners.
        Rectangle {
            visible: root.hasStripe
            x: Theme.borderWidth
            y: Theme.radius
            width: Theme.popupStripeWidth
            height: parent.height - Theme.radius * 2
            radius: width / 2
            color: root.stripe
        }

        Column {
            id: body
            x: Theme.space + (root.hasStripe ? Theme.popupStripeWidth : 0)
            y: Theme.space
            width: parent.width - Theme.space * 2 - (root.hasStripe ? Theme.popupStripeWidth : 0)
            spacing: Theme.tabGap

            // Big image on top: large style, or any style with previews on.
            // The whole image is fitted (scaled up when small), not cropped.
            Rectangle {
                visible: root.preview && previewImage.status === Image.Ready
                width: parent.width
                height: visible ? Math.round(width * Theme.popupPreviewRatio) : 0
                radius: Theme.radiusSm
                color: Theme.thumbBackdrop

                Image {
                    id: previewImage
                    anchors.fill: parent
                    source: root.preview ? root.picture : ""
                    sourceSize.width: root.look.width * 2
                    sourceSize.height: Math.round(root.look.width * 2 * Theme.popupPreviewRatio)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }
            }

            Row {
                width: parent.width
                spacing: Theme.space

                Image {
                    id: thumbImage
                    readonly property int size: root.style === "compact" ? Theme.chip : root.look.image
                    visible: root.thumb.length > 0 && status === Image.Ready
                    width: visible ? size : 0
                    height: size
                    source: root.thumb
                    sourceSize.width: size * 2
                    sourceSize.height: size * 2
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Column {
                    width: parent.width - (thumbImage.visible ? thumbImage.width + parent.spacing : 0)
                    spacing: Theme.tabGap

                    Item {
                        width: parent.width
                        height: headText.implicitHeight

                        Text {
                            id: headText
                            anchors.left: parent.left
                            anchors.right: countBadge.left
                            anchors.rightMargin: Theme.tabGap
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            text: root.latest
                                ? (root.style === "compact"
                                    ? String(root.latest.appName || "Notification") + " · " + String(root.latest.summary || "")
                                    : String(root.latest.appName || "Notification"))
                                : ""
                            color: root.style === "compact" ? Theme.text : Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: root.style === "compact" ? Theme.fontPx : Theme.smallPx
                            font.bold: root.style === "compact"
                        }

                        Rectangle {
                            id: countBadge
                            anchors.right: closeText.left
                            anchors.rightMargin: Theme.tabGap
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.extra > 0
                            width: visible ? countText.implicitWidth + Theme.space : 0
                            height: countText.implicitHeight + Theme.borderWidth * 2
                            radius: height / 2
                            color: Theme.accentDim

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: "+" + root.extra
                                color: Theme.text
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.smallPx
                                font.bold: true
                            }
                        }

                        Text {
                            id: closeText
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            color: closeMouse.containsMouse ? Theme.danger : Theme.subtext
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                            font.bold: true

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                anchors.margins: -Theme.tabGap
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close(true)
                            }
                        }
                    }

                    Text {
                        visible: root.style !== "compact" && text.length > 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: root.latest ? String(root.latest.summary || "") : ""
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: true
                    }

                    Text {
                        visible: root.style !== "compact" && root.look.lines > 0 && text.length > 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: Math.max(1, root.style === "large" ? root.look.lines * 2 : root.look.lines)
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                        text: root.latest ? String(root.latest.body || "") : ""
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }
                }
            }

            Flow {
                visible: root.style !== "compact" && root.actions.length > 0
                width: parent.width
                spacing: Theme.tabGap

                Repeater {
                    model: root.actions
                    delegate: Rectangle {
                        id: actionChip
                        required property NotificationAction modelData
                        width: actionLabel.implicitWidth + Theme.space * 2
                        height: Theme.fieldHeight - Theme.tabGap
                        radius: Theme.radiusSm
                        color: actionMouse.containsMouse ? Theme.hover : Theme.pillBg
                        border.width: Theme.borderWidth
                        border.color: actionMouse.containsMouse ? Theme.accent : Theme.border

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            textFormat: Text.PlainText
                            text: actionChip.modelData.text
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.smallPx
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actionChip.modelData.invoke()
                        }
                    }
                }
            }
        }

        // Time left, shrinking toward the close; pauses while hovered.
        Rectangle {
            id: bar
            visible: root.look.progress && root.timeoutMs > 0
            x: Theme.radius
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.borderWidth * 2
            width: (parent.width - Theme.radius * 2) * root.remaining
            height: Theme.popupProgressHeight
            radius: height / 2
            color: root.hasStripe ? root.stripe : Theme.accent
        }
    }
}
