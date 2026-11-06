pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.services
import qs.theme

Item {
    id: root

    signal closeRequested()

    property string query: ""
    property string pendingId: ""
    property bool userPicked: false

    readonly property bool canApply: {
        const pending = root.pendingId
        return pending.length > 0
            && pending !== RegionService.currentId
            && RegionService.zoneById(pending) !== null
            && !RegionService.applying
            && !RegionService.loading
    }

    function syncPending() {
        if (root.userPicked)
            return
        const current = RegionService.currentId
        if (current.length)
            root.pendingId = current
    }

    function choose(id) {
        const zone = RegionService.zoneById(id)
        if (!zone)
            return
        root.userPicked = true
        root.pendingId = zone.id
    }

    function matches() {
        const q = root.query.trim().toLowerCase()
        const list = RegionService.zones || []
        if (!q.length)
            return []
        const out = []
        for (let i = 0; i < list.length && out.length < 40; i++) {
            const zone = list[i]
            if (!zone)
                continue
            const hay = (String(zone.id) + " " + String(zone.city || "") + " "
                         + String(zone.region || "") + " " + String(zone.comment || "")).toLowerCase()
            if (hay.indexOf(q) >= 0)
                out.push(zone)
        }
        return out
    }

    readonly property var results: {
        void root.query
        void RegionService.zones
        return root.matches()
    }

    readonly property var pendingZone: RegionService.zoneById(root.pendingId)

    function placeLine() {
        const zone = root.pendingZone
        if (!zone)
            return RegionService.loading ? "Reading time zones…" : "Select a region"
        let line = String(zone.city || zone.id)
        if (zone.id === RegionService.currentId)
            line += "  · current"
        return line
    }

    Component.onCompleted: {
        RegionService.ensureLoaded()
        root.syncPending()
    }

    Connections {
        target: RegionService
        function onCurrentIdChanged() {
            root.syncPending()
        }
    }

    Flickable {
        id: scroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.space
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroll.width
            spacing: Theme.space

            SectionHeader {
                width: parent.width
                title: "Region"
                hint: "Search or click the map, then apply. The system time zone changes immediately."
            }

            Item {
                width: parent.width
                height: regionCol.implicitHeight

                Column {
                    id: regionCol
                    x: Theme.sectionInset
                    width: parent.width - Theme.sectionInset * 2
                    spacing: Theme.space

                    Rectangle {
                        width: parent.width
                        height: Theme.regionMapHeight
                        radius: Theme.radiusSm
                        color: Theme.fieldBg
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        clip: true

                        RegionMap {
                            anchors.fill: parent
                            zones: RegionService.zones
                            selectedId: root.pendingId
                            currentId: RegionService.currentId
                            onPicked: (id) => root.choose(id)
                        }
                    }

                    TextField {
                        id: searchField
                        width: parent.width
                        height: Theme.fieldHeight
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true
                        placeholderText: "Search for a city"
                        leftPadding: Theme.space
                        color: Theme.text
                        placeholderTextColor: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                        background: Rectangle {
                            radius: Theme.radiusSm
                            color: searchField.activeFocus ? Theme.hover : Theme.fieldBg
                            border.width: Theme.borderWidth
                            border.color: searchField.activeFocus ? Theme.accent : Theme.border
                        }
                        onTextChanged: root.query = text

                        HoverHandler {
                            id: searchHover
                        }

                        HoverTip {
                            message: "Find a city or region"
                            show: searchHover.hovered
                        }
                    }

                    Text {
                        visible: root.query.trim().length > 0 && root.results.length === 0 && !RegionService.loading
                        width: parent.width
                        text: "No matching cities"
                        color: Theme.subtext
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.smallPx
                    }

                    Repeater {
                        model: root.results
                        delegate: Rectangle {
                            id: hit
                            required property var modelData
                            required property int index
                            readonly property string zoneId: String(hit.modelData.id || "")
                            readonly property bool chosen: hit.zoneId === root.pendingId

                            width: regionCol.width
                            height: Theme.fieldHeight + Theme.space / 2
                            radius: Theme.radiusSm
                            color: hit.chosen ? Theme.accentDim : (hitMouse.containsMouse ? Theme.hover : Theme.pillBg)
                            border.width: Theme.borderWidth
                            border.color: hit.chosen ? Theme.accent : Theme.border

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.space
                                anchors.rightMargin: Theme.space
                                spacing: 0

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: String(hit.modelData.city || "")
                                    color: hit.chosen ? Theme.wsActiveText : Theme.text
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                    font.bold: hit.chosen
                                }
                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: hit.zoneId
                                    color: Theme.subtext
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.smallPx
                                }
                            }

                            MouseArea {
                                id: hitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.choose(hit.zoneId)

                                HoverTip {
                                    message: "Choose " + hit.zoneId
                                    show: hitMouse.containsMouse
                                }
                            }
                        }
                    }

                }
            }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.sectionInset
        anchors.rightMargin: Theme.sectionInset
        height: Theme.footerHeight

        Column {
            anchors.left: parent.left
            anchors.right: applyButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.space
            spacing: Theme.borderWidth

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.placeLine()
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontPx
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: RegionService.error.length > 0 || RegionService.status.length > 0
                text: RegionService.error.length ? RegionService.error : RegionService.status
                color: RegionService.error.length ? Theme.danger : Theme.ok
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }

        Rectangle {
            id: applyButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: applyLabel.implicitWidth + Theme.space * 2
            height: Theme.fieldHeight
            radius: Theme.radiusSm
            opacity: root.canApply ? 1 : 0.45
            color: applyMouse.containsMouse && root.canApply ? Theme.accentDim : Theme.pillBg
            border.width: Theme.borderWidth
            border.color: root.canApply ? Theme.accent : Theme.border

            Text {
                id: applyLabel
                anchors.centerIn: parent
                text: RegionService.applying ? "Applying…" : "Apply region"
                color: root.canApply ? Theme.wsActiveText : Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.canApply)
                        return
                    const id = root.pendingId
                    RegionService.applyZone(id)
                    root.closeRequested()
                }

                HoverTip {
                    message: "Set the system time zone"
                    show: applyMouse.containsMouse
                }
            }
        }
    }
}
