import QtQuick
import Quickshell
import qs.theme

// GNOME Date & Time map. The pictures live in assets/gnome-tz.
// Longitude is shifted -6° and latitude uses the Miller-style range 81°N–59°S.
Item {
    id: root

    required property var zones
    required property string selectedId
    property string currentId: ""

    signal picked(string id)

    property string hoverId: ""

    readonly property url backgroundSource: Qt.resolvedUrl("../assets/gnome-tz/bg.png")
    readonly property url pinSource: Qt.resolvedUrl("../assets/gnome-tz/pin.png")

    function find(id) {
        const want = String(id || "")
        const list = root.zones || []
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].id === want)
                return list[i]
        }
        return null
    }

    readonly property var hoverZone: root.find(root.hoverId)
    readonly property var selectedZone: root.find(root.selectedId)
    readonly property var pinZone: root.selectedZone ? root.selectedZone : root.find(root.currentId)

    function overlayKey(hours) {
        const value = Number(hours)
        if (isNaN(value))
            return ""
        const known = ["-11", "-10", "-9.5", "-9", "-8", "-7", "-6", "-5", "-4",
                       "-3.5", "-3", "-2", "-1", "0", "1", "2", "3", "3.5", "4",
                       "4.5", "5", "5.5", "5.75", "6", "6.5", "7", "8", "9",
                       "9.5", "10", "10.5", "11", "11.5", "12", "12.75", "13", "14"]
        let best = "0"
        let bestD = 99
        for (let i = 0; i < known.length; i++) {
            const gap = Math.abs(Number(known[i]) - value)
            if (gap < bestD) {
                bestD = gap
                best = known[i]
            }
        }
        return best
    }

    readonly property string overlaySource: {
        const zone = root.hoverZone ? root.hoverZone : root.pinZone
        if (!zone)
            return ""
        const key = root.overlayKey(zone.offset)
        if (!key.length)
            return ""
        return String(Qt.resolvedUrl("../assets/gnome-tz/timezone_" + key + ".png"))
    }

    function lonToX(lon, width) {
        const shift = -6
        return (width * (180.0 + Number(lon)) / 360.0) + (width * shift / 180.0)
    }

    function latToY(lat, height) {
        const bottomLat = -59
        const topLat = 81
        const rad = function (deg) { return (deg / 360.0) * Math.PI * 2 }
        const project = function (deg) {
            return 1.25 * Math.log(Math.tan(Math.PI / 4 + 0.4 * rad(deg)))
        }
        const fullRange = 4.6068250867599998
        const topOffset = fullRange * (topLat / 180.0)
        const mapRange = Math.abs(project(bottomLat) - topOffset)
        return Math.abs(project(Number(lat)) - topOffset) / mapRange * height
    }

    function nearestAt(px, py, width, height) {
        const list = root.zones || []
        let best = null
        let bestD = 1e15
        for (let i = 0; i < list.length; i++) {
            const zone = list[i]
            if (!zone)
                continue
            const dx = root.lonToX(zone.lon, width) - px
            const dy = root.latToY(zone.lat, height) - py
            const dist = dx * dx + dy * dy
            if (dist < bestD) {
                bestD = dist
                best = zone
            }
        }
        return best
    }

    function utcLabel(hours) {
        const value = Number(hours)
        if (isNaN(value))
            return "UTC"
        const sign = value < 0 ? "-" : "+"
        const abs = Math.abs(value)
        const whole = Math.floor(abs)
        const minutes = Math.round((abs - whole) * 60)
        if (minutes)
            return "UTC" + sign + whole + ":" + (minutes < 10 ? "0" : "") + minutes
        return "UTC" + sign + whole
    }

    function placeName(zone) {
        if (!zone)
            return ""
        if (zone.comment && String(zone.comment).length)
            return zone.city + ", " + zone.comment
        return zone.city + ", " + zone.region
    }

    Image {
        anchors.fill: parent
        source: root.backgroundSource
        fillMode: Image.Stretch
        asynchronous: true
        cache: true
        smooth: true
    }

    Image {
        anchors.fill: parent
        source: root.overlaySource.length > 0 ? root.overlaySource : root.backgroundSource
        fillMode: Image.Stretch
        asynchronous: true
        cache: true
        smooth: true
        visible: root.overlaySource.length > 0
    }

    Image {
        visible: root.pinZone ? true : false
        width: Theme.iconPx
        height: Theme.iconPx
        source: root.pinSource
        asynchronous: true
        cache: true
        x: root.pinZone ? root.lonToX(root.pinZone.lon, root.width) - width / 2 : 0
        y: root.pinZone ? root.latToY(root.pinZone.lat, root.height) - height : 0
        z: 2
    }

    Rectangle {
        visible: root.hoverZone ? true : false
        z: 3
        x: Math.min(root.width - width - Theme.space, Math.max(Theme.space, mapMouse.mouseX + Theme.space))
        y: Math.min(root.height - height - Theme.space, Math.max(Theme.space, mapMouse.mouseY + Theme.space))
        width: bubbleCol.implicitWidth + Theme.space * 2
        height: bubbleCol.implicitHeight + Theme.space
        radius: Theme.radiusSm
        color: Theme.fieldBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: bubbleCol
            anchors.centerIn: parent
            spacing: Theme.borderWidth
            Text {
                text: root.hoverZone ? root.utcLabel(root.hoverZone.offset) : ""
                color: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
                font.bold: true
            }
            Text {
                text: root.placeName(root.hoverZone)
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }
        }
    }

    MouseArea {
        id: mapMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => {
            const zone = root.nearestAt(mouse.x, mouse.y, root.width, root.height)
            root.hoverId = zone ? String(zone.id) : ""
        }
        onExited: root.hoverId = ""
        onClicked: (mouse) => {
            const zone = root.nearestAt(mouse.x, mouse.y, root.width, root.height)
            if (zone)
                root.picked(String(zone.id))
        }
    }
}
