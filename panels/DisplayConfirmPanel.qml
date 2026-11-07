pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.settings
import qs.theme

// "Keep this display mode?" — a small window centered on the monitor being
// changed, shown while DisplayService tries a mode or an arrangement.
// Settings steps aside meanwhile and returns to System → Display after.
// A layer surface with no anchors, so the compositor keeps it centered
// even as the resolution changes. Enter keeps, Escape goes back.
// shell.qml creates it only while a change is pending.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root

    readonly property var job: DisplayService.pending
    readonly property bool asking: DisplayService.countdown > 0
    readonly property string output: root.job && root.job.specs.length ? String(root.job.specs[0].output) : ""

    screen: {
        const list = Quickshell.screens
        for (let i = 0; i < list.length; i++) {
            if (String(list[i].name) === root.output)
                return list[i]
        }
        return ScreenService.mainScreen
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-display-confirm"
    WlrLayershell.keyboardFocus: root.asking ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    implicitWidth: Theme.displayConfirmWidth
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + Theme.space * 3
        radius: Theme.radius
        color: Theme.pageBg
        border.width: Theme.borderWidth * 2
        border.color: Theme.accent

        Item {
            anchors.fill: parent
            focus: true
            Keys.onReturnPressed: DisplayService.keep()
            Keys.onEnterPressed: DisplayService.keep()
            Keys.onEscapePressed: DisplayService.revert("Back to the previous setup.")
        }

        Column {
            id: col
            x: Theme.space * 1.5
            y: Theme.space * 1.5
            width: parent.width - Theme.space * 3
            spacing: Theme.space

            Text {
                width: parent.width
                text: !root.job ? "" : (root.job.kind === "layout" ? "Keep this arrangement?" : "Keep this display mode?")
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx + 2
                font.bold: true
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: !root.job ? ""
                    : (root.asking
                        ? root.output + ": " + root.job.label + ". Going back in " + DisplayService.countdown + " s."
                        : "Applying " + root.job.label + " on " + root.output + " and checking…")
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Rectangle {
                visible: root.asking
                width: parent.width
                height: Theme.popupProgressHeight + 1
                radius: height / 2
                color: Theme.pillBg

                Rectangle {
                    width: parent.width * DisplayService.countdown / Theme.displayConfirmSeconds
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width {
                        NumberAnimation { duration: 950 }
                    }
                }
            }

            Row {
                visible: root.asking
                spacing: Theme.tabGap

                ChipButton {
                    label: "Keep"
                    active: true
                    bold: true
                    minWidth: Theme.fieldHeight * 3
                    tip: "Keep it" + (DisplayService.managedFile.length ? " and save it (Enter)" : " (Enter)")
                    onClicked: DisplayService.keep()
                }

                ChipButton {
                    label: "Go back"
                    minWidth: Theme.fieldHeight * 3
                    tip: "Return to the previous setup now (Escape)"
                    onClicked: DisplayService.revert("Back to the previous setup.")
                }
            }
        }
    }
}
