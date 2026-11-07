pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// A row of chips for picking one number from a fixed list. `zeroLabel`
// names 0 (for example "No limit").
Flow {
    id: root

    required property var values
    required property int current
    property string unit: ""
    property string zeroLabel: ""

    signal picked(int value)

    spacing: Theme.tabGap

    Repeater {
        model: root.values
        delegate: ChipButton {
            required property int modelData
            label: modelData === 0 && root.zeroLabel.length ? root.zeroLabel : modelData + root.unit
            active: root.current === modelData
            onClicked: root.picked(modelData)
        }
    }
}
