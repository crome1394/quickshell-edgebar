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

        FooterButton {
            label: "Apply"
            primary: true
            bold: true
            enabled: root.applyEnabled
            tip: root.applyTip
            onClicked: root.applyClicked()
        }

        FooterButton {
            label: "Undo"
            enabled: root.undoEnabled
            tip: root.undoTip
            onClicked: root.undoClicked()
        }

        FooterButton {
            label: "Reset"
            enabled: root.resetEnabled
            tip: root.resetTip
            onClicked: root.resetClicked()
        }
    }
}
