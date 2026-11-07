pragma ComponentBehavior: Bound
import QtQuick
import qs.theme

// Section tabs. With Settings' index-divider style on (and indexAllowed),
// they draw as dividers standing on the page in shades of the active main
// tab's color (IndexTabStrip, edge "top"); otherwise as flat chips.
Item {
    id: root

    required property var model
    property string currentId: ""
    property bool indexAllowed: true
    readonly property bool indexed: root.indexAllowed && TabColors.indexed

    signal selected(string tabId)

    function choose(tabId) {
        root.selected(tabId)
    }

    readonly property int count: root.model ? root.model.length : 0
    readonly property int rows: {
        if (root.count <= 1)
            return 1
        const oneRow = root.count * Theme.tabMinWidth + Math.max(0, root.count - 1) * Theme.tabGap
        return oneRow <= root.width ? 1 : 2
    }
    readonly property int perRow: Math.max(1, Math.ceil(root.count / Math.max(1, root.rows)))
    readonly property real chipWidth: {
        const gaps = Theme.tabGap * Math.max(0, root.perRow - 1)
        return Math.max(1, (root.width - gaps) / root.perRow)
    }
    readonly property var rowsData: {
        void root.width
        void root.currentId
        void root.chipWidth
        const out = []
        for (let row = 0; row < root.rows; row++)
            out.push(root.rowTabs(row))
        return out
    }

    implicitHeight: root.indexed
        ? Theme.indexTabEdge + Theme.indexTabHeight
        : root.rows * Theme.tabHeight + Math.max(0, root.rows - 1) * Theme.tabGap

    Loader {
        active: root.indexed
        width: root.width
        sourceComponent: Component {
            IndexTabStrip {
                edge: "top"
                model: root.model
                currentId: root.currentId
                onSelected: (tabId) => root.choose(tabId)
            }
        }
    }

    function rowTabs(row) {
        const tabs = root.model || []
        const start = row * root.perRow
        const end = Math.min(tabs.length, start + root.perRow)
        const out = []
        for (let i = start; i < end; i++) {
            out.push({
                tabId: String(tabs[i].id || ""),
                label: String(tabs[i].label || ""),
                chipWidth: root.chipWidth,
                selected: String(tabs[i].id || "") === root.currentId
            })
        }
        return out
    }

    Repeater {
        model: root.indexed ? [] : root.rowsData
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            x: 0
            y: index * (Theme.tabHeight + Theme.tabGap)
            width: parent.width
            height: Theme.tabHeight

            Repeater {
                model: row.modelData
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    x: index * (chip.modelData.chipWidth + Theme.tabGap)
                    y: 0
                    width: chip.modelData.chipWidth
                    height: Theme.tabHeight
                    radius: Theme.radiusSm
                    color: chip.modelData.selected ? Theme.accentDim : (chipMouse.containsMouse ? Theme.hover : Theme.pillBg)
                    border.width: Theme.borderWidth
                    border.color: chip.modelData.selected ? Theme.accent : Theme.border

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - Theme.space
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: String(chip.modelData.label || "")
                        color: chip.modelData.selected ? Theme.wsActiveText : Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        font.bold: !!chip.modelData.selected
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(String(chip.modelData.tabId || ""))
                    }
                }
            }
        }
    }
}
