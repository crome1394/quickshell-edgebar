pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.theme

// One popup from the built-in notification server: icon or image, app,
// summary, body, and action buttons. It closes after the timeout set in
// Settings → Notifications (or the sender's own, if shorter), pauses while
// hovered, and stays for critical ones. A click runs the default action,
// or dismisses it; ✕ dismisses it.
Rectangle {
    id: root

    required property Notification notification

    readonly property bool critical: root.notification.urgency === NotificationUrgency.Critical
    readonly property var allActions: Array.from(root.notification.actions)
    readonly property var actions: root.allActions.filter((a) => a.identifier !== "default")
    readonly property var defaultAction: root.allActions.find((a) => a.identifier === "default") ?? null
    readonly property int timeoutMs: {
        const own = Number(root.notification.expireTimeout)
        const mine = NotificationSettings.timeoutValue() * 1000
        if (root.critical || (mine === 0 && !(own > 0)))
            return 0
        if (own > 0 && (mine === 0 || own < mine))
            return own
        return mine
    }
    readonly property string imageSource: {
        const img = String(root.notification.image || "")
        if (img.length)
            return img.charAt(0) === "/" ? "file://" + img : img
        return IconService.url(String(root.notification.appIcon || ""))
    }

    width: Theme.notificationToastWidth
    implicitHeight: content.implicitHeight + Theme.space * 2
    radius: Theme.radius
    color: Theme.barBg
    border.width: Theme.borderWidth
    border.color: root.critical ? Theme.danger : (hover.hovered ? Theme.accent : Theme.border)

    HoverHandler {
        id: hover
    }

    Timer {
        interval: Math.max(1, root.timeoutMs)
        running: root.timeoutMs > 0 && !hover.hovered
        onTriggered: root.notification.expire()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.defaultAction)
                root.defaultAction.invoke()
            else
                root.notification.dismiss()
        }
    }

    Row {
        id: content
        x: Theme.space
        y: Theme.space
        width: parent.width - Theme.space * 2
        spacing: Theme.space

        Image {
            id: picture
            visible: root.imageSource.length > 0 && status === Image.Ready
            width: visible ? Theme.notificationToastImage : 0
            height: Theme.notificationToastImage
            source: root.imageSource
            sourceSize.width: Theme.notificationToastImage * 2
            sourceSize.height: Theme.notificationToastImage * 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Column {
            width: parent.width - (picture.visible ? picture.width + parent.spacing : 0)
            spacing: Theme.tabGap

            Item {
                width: parent.width
                height: appText.implicitHeight

                Text {
                    id: appText
                    anchors.left: parent.left
                    anchors.right: closeText.left
                    anchors.rightMargin: Theme.space
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: String(root.notification.appName || "Notification")
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                }

                Text {
                    id: closeText
                    anchors.right: parent.right
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
                        onClicked: root.notification.dismiss()
                    }
                }
            }

            Text {
                visible: text.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: String(root.notification.summary || "")
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
                font.bold: true
            }

            Text {
                visible: text.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: Theme.notificationToastBodyLines
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: String(root.notification.body || "")
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Flow {
                visible: root.actions.length > 0
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
    }
}
