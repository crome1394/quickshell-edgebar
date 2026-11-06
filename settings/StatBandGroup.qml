pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.theme

// Three utilization steps for one System Stats metric.
Column {
    id: group

    required property string metric
    required property string title

    signal colorRequested(int slot)

    spacing: Theme.space

    Text {
        width: group.width
        text: group.title
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    Repeater {
        model: [
            { slot: 0, label: "Up to low", tip: "Percent at or under this uses the low color" },
            { slot: 1, label: "Up to mid", tip: "Percent at or under this uses the mid color" },
            { slot: 2, label: "Up to high", tip: "Percent at or under this uses the high color. Above it uses the peak color" }
        ]
        delegate: Column {
            id: band
            required property var modelData
            required property int index
            width: group.width
            spacing: Theme.tabGap

            Text {
                width: parent.width
                text: String(band.modelData.label || "")
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            IntSlider {
                width: parent.width
                from: 0
                to: 100
                step: 5
                value: StatsSettings.bandAt(group.metric, band.modelData.slot)
                readout: StatsSettings.bandAt(group.metric, band.modelData.slot) + "%"
                tip: String(band.modelData.tip || "")
                showSwatch: true
                swatch: StatsSettings.colorAt(group.metric, band.modelData.slot)
                onChanged: (value) => StatsSettings.setBand(group.metric, band.modelData.slot, value)
                onSwatchClicked: group.colorRequested(band.modelData.slot)
            }
        }
    }

    Row {
        width: group.width
        height: Theme.fieldHeight
        spacing: Theme.tabGap

        Text {
            width: parent.width - Theme.chip - Theme.tabGap
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: "Above high"
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
        }

        Rectangle {
            width: Theme.chip
            height: parent.height
            radius: Theme.radiusSm
            color: StatsSettings.colorAt(group.metric, 3)
            border.width: Theme.borderWidth
            border.color: Theme.border

            MouseArea {
                id: peakMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: group.colorRequested(3)

                HoverTip {
                    message: "Color above the high step"
                    show: peakMouse.containsMouse
                }
            }
        }
    }
}
