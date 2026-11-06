pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.theme

Rectangle {
    id: root

    required property var theme
    required property int weekStart

    signal dismissed()

    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()

    readonly property int cell: Theme.chip + Theme.space
    readonly property int columns: 7
    readonly property int gridWidth: root.columns * root.cell + (root.columns - 1) * Theme.wsGap
    // Month title, four arrows, and Today. The day grid is narrower than that row.
    readonly property int navWidth: 4 * Theme.chip + 3 * Theme.wsGap
    readonly property int headerNeed: Theme.chip * 6 + root.navWidth + Theme.chip * 4 + Theme.tabGap * 2
    readonly property int weekOrigin: ((root.weekStart % 7) + 7) % 7
    readonly property var weekdayLabels: {
        const names = ["S", "M", "T", "W", "T", "F", "S"]
        const out = []
        for (let i = 0; i < 7; i++)
            out.push(names[(root.weekOrigin + i) % 7])
        return out
    }

    function shift(months) {
        let next = root.month + months
        let y = root.year
        while (next < 0) {
            next += 12
            y -= 1
        }
        while (next > 11) {
            next -= 12
            y += 1
        }
        root.month = next
        root.year = y
    }

    function dayAt(index) {
        const first = new Date(root.year, root.month, 1).getDay()
        const leading = (first - root.weekOrigin + 7) % 7
        const count = new Date(root.year, root.month + 1, 0).getDate()
        const prev = new Date(root.year, root.month, 0).getDate()
        const number = index - leading + 1
        if (number < 1)
            return { n: prev + number, inMonth: false, today: false }
        if (number > count)
            return { n: number - count, inMonth: false, today: false }
        const now = new Date()
        const today = now.getFullYear() === root.year && now.getMonth() === root.month && now.getDate() === number
        return { n: number, inMonth: true, today: today }
    }

    implicitWidth: Math.max(root.gridWidth, root.headerNeed) + Theme.space * 2
    implicitHeight: column.implicitHeight + Theme.space * 2
    radius: Theme.radius
    color: root.theme.colBg
    border.width: Theme.borderWidth
    border.color: root.theme.colBorder
    focus: true
    Component.onCompleted: root.forceActiveFocus()
    Keys.onEscapePressed: (event) => {
        root.dismissed()
        event.accepted = true
    }

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space
        spacing: Theme.tabGap

        Row {
            id: headerRow
            width: parent.width
            height: Theme.fieldHeight
            spacing: Theme.tabGap

            Text {
                width: Math.max(Theme.chip * 6, headerRow.width - navRow.width - todayButton.width - Theme.tabGap * 2)
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: Qt.formatDateTime(new Date(root.year, root.month, 1), "MMMM yyyy")
                color: root.theme.colFg
                font.family: root.theme.uiFont
                font.pixelSize: root.theme.fontPx
                font.bold: true
            }

            Row {
                id: navRow
                width: root.navWidth
                height: parent.height
                spacing: Theme.wsGap

                Repeater {
                    model: [
                        { label: "«", months: -12, tip: "Previous year" },
                        { label: "‹", months: -1, tip: "Previous month" },
                        { label: "›", months: 1, tip: "Next month" },
                        { label: "»", months: 12, tip: "Next year" }
                    ]
                    delegate: Item {
                        id: nav
                        required property var modelData
                        required property int index
                        implicitWidth: Theme.chip
                        implicitHeight: Theme.fieldHeight
                        width: Theme.chip
                        height: Theme.fieldHeight

                        Text {
                            anchors.centerIn: parent
                            text: String(nav.modelData.label || "")
                            color: navMouse.containsMouse ? root.theme.colAccent : root.theme.colFg
                            font.family: root.theme.uiFont
                            font.pixelSize: root.theme.fontPx
                            font.bold: true
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shift(Number(nav.modelData.months))

                            HoverTip {
                                message: String(nav.modelData.tip || "")
                                show: navMouse.containsMouse
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: todayButton
                implicitWidth: todayLabel.implicitWidth + Theme.space * 2
                implicitHeight: Theme.fieldHeight
                width: todayLabel.implicitWidth + Theme.space * 2
                height: Theme.fieldHeight
                radius: Theme.radiusSm
                color: todayMouse.containsMouse ? root.theme.colAccent : root.theme.colSurface

                Text {
                    id: todayLabel
                    anchors.centerIn: parent
                    text: "Today"
                    color: todayMouse.containsMouse ? root.theme.colWsActiveFg : root.theme.colFg
                    font.family: root.theme.uiFont
                    font.pixelSize: root.theme.smallPx
                    font.bold: true
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const now = new Date()
                        root.month = now.getMonth()
                        root.year = now.getFullYear()
                    }

                    HoverTip {
                        message: "Jump to this month"
                        show: todayMouse.containsMouse
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: Theme.chip

            Row {
                x: Math.max(0, Math.round((parent.width - root.gridWidth) / 2))
                width: root.gridWidth
                height: Theme.chip
                spacing: Theme.wsGap

            Repeater {
                model: root.weekdayLabels
                delegate: Item {
                    id: weekday
                    required property var modelData
                    required property int index
                    implicitWidth: root.cell
                    implicitHeight: Theme.chip
                    width: root.cell
                    height: Theme.chip

                    Text {
                        anchors.centerIn: parent
                        text: String(weekday.modelData)
                        color: root.theme.colWeekday
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.fontPx
                        font.bold: true
                    }
                }
            }
            }
        }

        Item {
            width: parent.width
            height: dayGrid.implicitHeight

            Grid {
                id: dayGrid
                x: Math.max(0, Math.round((parent.width - root.gridWidth) / 2))
                columns: root.columns
                rowSpacing: Theme.wsGap
                columnSpacing: Theme.wsGap

            Repeater {
                model: 42
                delegate: Rectangle {
                    id: day
                    required property int index
                    readonly property var info: root.dayAt(day.index)

                    implicitWidth: root.cell
                    implicitHeight: root.cell
                    width: root.cell
                    height: root.cell
                    radius: day.info.today ? root.cell / 2 : Theme.radiusSm
                    color: day.info.today ? root.theme.colAccent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: String(day.info.n)
                        color: day.info.today ? root.theme.colWsActiveFg : (day.info.inMonth ? root.theme.colFg : root.theme.colFgMuted)
                        font.family: root.theme.uiFont
                        font.pixelSize: root.theme.smallPx
                        font.bold: day.info.today
                    }
                }
            }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Current day is highlighted. Click the clock to close."
            color: root.theme.colFgMuted
            font.family: root.theme.uiFont
            font.pixelSize: root.theme.smallPx
        }
    }
}
