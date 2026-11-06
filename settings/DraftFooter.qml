pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// Apply, Undo, and Reset along the bottom of a settings page.
Item {
    id: root

    required property bool applyEnabled
    required property bool undoEnabled
    property bool resetEnabled: true
    required property string applyTip
    required property string undoTip
    required property string resetTip

    signal applyClicked()
    signal undoClicked()
    signal resetClicked()

    implicitHeight: Theme.fieldHeight

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionInset
        anchors.bottom: parent.bottom
        spacing: Theme.tabGap

        Repeater {
            model: [
                { id: "apply", label: "Apply" },
                { id: "undo", label: "Undo" },
                { id: "reset", label: "Reset" }
            ]
            delegate: Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property string action: String(button.modelData.id || "")
                readonly property bool enabledAction: {
                    if (button.action === "apply")
                        return root.applyEnabled
                    if (button.action === "undo")
                        return root.undoEnabled
                    return root.resetEnabled
                }
                readonly property bool applyReady: button.action === "apply" && button.enabledAction

                implicitWidth: buttonLabel.implicitWidth + Theme.space * 2
                implicitHeight: Theme.fieldHeight
                radius: Theme.radiusSm
                opacity: button.enabledAction ? 1 : Theme.widgetOffOpacity
                color: button.applyReady && buttonMouse.containsMouse
                    ? Theme.accentDim
                    : (buttonMouse.containsMouse && button.enabledAction ? Theme.hover : Theme.pillBg)
                border.width: Theme.borderWidth
                border.color: button.applyReady ? Theme.accent : Theme.border

                Text {
                    id: buttonLabel
                    anchors.centerIn: parent
                    text: String(button.modelData.label || "")
                    color: button.applyReady ? Theme.wsActiveText : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.smallPx
                    font.bold: button.action === "apply"
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: button.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!button.enabledAction)
                            return
                        if (button.action === "apply")
                            root.applyClicked()
                        else if (button.action === "undo")
                            root.undoClicked()
                        else
                            root.resetClicked()
                    }

                    HoverTip {
                        message: {
                            if (button.action === "apply")
                                return root.applyTip
                            if (button.action === "undo")
                                return root.undoTip
                            return root.resetTip
                        }
                        show: buttonMouse.containsMouse
                    }
                }
            }
        }
    }
}
