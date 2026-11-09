pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// System → Display → Edges: space kept clear around one monitor for a TV
// that crops its picture (overscan). The bars on that monitor move inward
// and windows stay inside. It is plain bar and window placement, so it
// works the same on any computer and graphics card. Saves at once.
Column {
    id: root

    required property string monitor

    readonly property var inset: DisplaySettings.insetsFor(root.monitor)
    readonly property bool even: root.inset.top === root.inset.bottom && root.inset.top === root.inset.left && root.inset.top === root.inset.right
    property bool eachEdge: false
    readonly property bool guiding: DisplaySettings.guideMonitor === root.monitor && root.monitor.length > 0

    readonly property var edgeRows: [
        { id: "top", label: "Top" },
        { id: "bottom", label: "Bottom" },
        { id: "left", label: "Left" },
        { id: "right", label: "Right" }
    ]

    onMonitorChanged: {
        root.eachEdge = !root.even
        if (DisplaySettings.guideMonitor.length)
            DisplaySettings.guideMonitor = root.monitor
    }
    Component.onCompleted: root.eachEdge = !root.even
    Component.onDestruction: DisplaySettings.guideMonitor = ""

    spacing: Theme.space

    Text {
        width: root.width
        text: "Edges"
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    Text {
        width: root.width
        wrapMode: Text.WordWrap
        text: "For a TV that cuts off the edges of the picture. Best fixed on the TV itself (often Picture Size → Fit to Screen, or Just Scan); if it has no such setting, keep this much clear around " + root.monitor + ": its bars move inward and windows stay inside."
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    Row {
        spacing: Theme.tabGap

        ChipButton {
            label: root.guiding ? "Hide guide" : "Show guide"
            active: root.guiding
            tip: "Draw a frame on " + root.monitor + " at these edges; move the sliders until it just fits on the TV"
            onClicked: DisplaySettings.guideMonitor = root.guiding ? "" : root.monitor
        }

        ChipButton {
            label: "Set each edge"
            active: root.eachEdge
            tip: "Top, bottom, left, and right separately"
            onClicked: root.eachEdge = !root.eachEdge
        }

        ChipButton {
            label: "None"
            enabled: DisplaySettings.hasInsets(root.monitor)
            opacity: enabled ? 1 : 0.5
            tip: "Use the whole screen again"
            onClicked: DisplaySettings.setInset(root.monitor, "all", 0)
        }
    }

    FormRow {
        visible: !root.eachEdge
        width: root.width
        label: "All edges"

        IntSlider {
            width: parent.width
            from: 0
            to: Theme.displayInsetMax
            step: Theme.displayInsetStep
            value: Math.max(root.inset.top, root.inset.bottom, root.inset.left, root.inset.right)
            readout: Math.max(root.inset.top, root.inset.bottom, root.inset.left, root.inset.right) + " px"
            tip: "The same on every side. TVs often crop 2–5% (about 20–50 px at 1080p)."
            onChanged: (value) => DisplaySettings.setInset(root.monitor, "all", value)
        }
    }

    Repeater {
        model: root.eachEdge ? root.edgeRows : []
        delegate: FormRow {
            id: edgeRow
            required property var modelData
            width: root.width
            label: String(edgeRow.modelData.label)

            IntSlider {
                width: parent.width
                from: 0
                to: Theme.displayInsetMax
                step: Theme.displayInsetStep
                value: Number(root.inset[edgeRow.modelData.id]) || 0
                readout: (Number(root.inset[edgeRow.modelData.id]) || 0) + " px"
                tip: "Space kept clear at the " + String(edgeRow.modelData.label).toLowerCase() + " of " + root.monitor
                onChanged: (value) => DisplaySettings.setInset(root.monitor, String(edgeRow.modelData.id), value)
            }
        }
    }
}
