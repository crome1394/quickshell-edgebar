pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.theme

// One window preview in the overview.
Item {
    id: root

    required property var placement
    required property bool selected
    required property int cornerRadius
    required property int hoverBorder
    required property int selectBorder
    required property bool showLabel
    required property bool desktopMode
    required property bool livePreview

    signal hoverOn()
    signal activate()
    signal closeRequested()
    signal dragMoved(real x, real y)
    signal dragFinished(real x, real y)
    signal dragCanceled()

    property bool dragging: false
    property real pressX: 0
    property real pressY: 0

    x: root.placement.x
    y: root.placement.y
    width: Math.max(Theme.space, root.placement.w)
    height: Math.max(Theme.space, root.placement.h)
    z: previewMouse.pressed ? 20 : (root.selected ? 2 : 1)

    Rectangle {
        x: -Theme.barPad
        y: -Theme.barPad
        width: parent.width + Theme.barPad * 2
        height: parent.height + Theme.barPad * 2
        radius: root.cornerRadius + Theme.wsGap
        color: Theme.pageBg
        opacity: 0.38
        z: -1
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.fieldBg
        clip: true
        border.width: root.selected ? root.selectBorder : (previewMouse.containsMouse ? root.hoverBorder : 0)
        border.color: root.selected ? Theme.accent : Theme.text

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: frame.border.width
            anchors.rightMargin: frame.border.width
            anchors.topMargin: frame.border.width
            anchors.bottomMargin: frame.border.width
            visible: !shot.hasContent
            color: OverviewService.hueColor(root.placement.appId || root.placement.title, 0.35, 0.28)

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.space
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.placement.appId || root.placement.title
                color: Theme.text
                font.pixelSize: Math.max(Theme.smallPx, Math.min(Theme.fontPx + Theme.space, root.height * 0.12))
                font.family: Theme.uiFont
            }
        }

        OverviewCapture {
            id: shot
            anchors.fill: parent
            anchors.leftMargin: frame.border.width
            anchors.rightMargin: frame.border.width
            anchors.topMargin: frame.border.width
            anchors.bottomMargin: frame.border.width
            addr: String(root.placement.addr || "")
            livePreview: root.livePreview
        }
    }

    Rectangle {
        visible: root.desktopMode
        z: 30
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Theme.space
        anchors.topMargin: Theme.space
        width: Theme.chip
        height: Theme.chip
        radius: Theme.chip / 2
        color: closeMouse.containsMouse ? Theme.danger : Theme.accentDim

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: Theme.text
            font.pixelSize: Theme.smallPx
            font.bold: true
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        visible: root.showLabel && (previewMouse.containsMouse || root.selected)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: Theme.tabGap
        width: Math.min(root.width, titleText.implicitWidth + Theme.space * 2)
        height: Theme.chip
        radius: Theme.chip / 2
        color: Theme.fieldBg

        Text {
            id: titleText
            anchors.centerIn: parent
            width: Math.min(root.width - Theme.space, Theme.popupWidth)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: String(root.placement.title || "")
            color: Theme.text
            font.pixelSize: Theme.smallPx
            font.family: Theme.uiFont
        }
    }

    MouseArea {
        id: previewMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse)
                root.hoverOn()
        }
        onPressed: function (mouse) {
            root.pressX = mouse.x
            root.pressY = mouse.y
            root.dragging = false
            root.hoverOn()
        }
        onPositionChanged: function (mouse) {
            if (!(mouse.buttons & Qt.LeftButton))
                return
            if (Math.abs(mouse.x - root.pressX) + Math.abs(mouse.y - root.pressY) > Theme.space)
                root.dragging = true
            if (!root.dragging)
                return
            root.dragMoved(mouse.x, mouse.y)
        }
        onReleased: function (mouse) {
            if (root.dragging)
                root.dragFinished(mouse.x, mouse.y)
            else
                root.activate()
            root.dragging = false
        }
        onCanceled: {
            root.dragging = false
            root.dragCanceled()
        }
    }
}
