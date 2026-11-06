pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.theme

// Magnifier in the settings header. Click or Ctrl+F opens the field.
Item {
    id: root

    property bool open: false

    signal picked(string tab, string section)

    function entries() {
        return [
            { tab: "bar", section: "workspaces", title: "Bar · Workspaces", keys: "workspace symbol label font size" },
            { tab: "bar", section: "overview", title: "Bar · Overview", keys: "overview layout strip preview motion workspace" },
            { tab: "bar", section: "dock", title: "Bar · Dock", keys: "dock magnify jump hover icon launcher tray running dot" },
            { tab: "widgets", section: "bars", title: "Widgets · Bars", keys: "bar edge widget placement show" },
            { tab: "widgets", section: "activewindow", title: "Widgets · Active Window", keys: "active window corner width exclude title class" },
            { tab: "widgets", section: "stats", title: "Widgets · System Stats", keys: "cpu memory gpu vram font bold italic threshold terminal btop" },
            { tab: "wallpaper", section: "", title: "Wallpaper", keys: "wallpaper image hyprpaper folder" },
            { tab: "applications", section: "launcher", title: "Applications · App Launcher", keys: "pin launcher application command" },
            { tab: "applications", section: "menu", title: "Applications · Application Menu", keys: "menu symbol glyph command font" },
            { tab: "connectivity", section: "network", title: "Connectivity · Network", keys: "network ip address wifi octet device" },
            { tab: "connectivity", section: "bluetooth", title: "Connectivity · Bluetooth", keys: "bluetooth scan paired adapter" },
            { tab: "audio", section: "", title: "Audio · On the bar", keys: "audio speaker microphone volume scroll percent mute" },
            { tab: "audio", section: "", title: "Audio · Output", keys: "speaker output sink volume mute device" },
            { tab: "audio", section: "", title: "Audio · Input", keys: "microphone input source volume mute device" },
            { tab: "region", section: "region", title: "Region & Clock · Region", keys: "timezone region map city" },
            { tab: "region", section: "clock", title: "Region & Clock · Clock", keys: "clock font format calendar time date" },
            { tab: "notifications", section: "", title: "Notifications · Toasts", keys: "notification toast corner timeout swaync popup" },
            { tab: "notifications", section: "", title: "Notifications · History", keys: "notification history bell counter dnd expand stagger boot" }
        ]
    }

    function matches() {
        const query = field.text.trim().toLowerCase()
        if (!query.length)
            return []
        const all = root.entries()
        const out = []
        for (let i = 0; i < all.length && out.length < 8; i++) {
            const row = all[i]
            const hay = (row.title + " " + row.keys).toLowerCase()
            if (hay.indexOf(query) >= 0)
                out.push(row)
        }
        return out
    }

    function openSearch() {
        root.open = true
        field.forceActiveFocus()
        field.selectAll()
    }

    function closeSearch() {
        root.open = false
        field.text = ""
    }

    function choose(row) {
        if (!row)
            return
        root.picked(String(row.tab || ""), String(row.section || ""))
        root.closeSearch()
    }

    width: root.open ? Theme.popupWidth : 28
    height: Theme.headerHeight

    Rectangle {
        id: searchButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 24
        radius: Theme.radiusSm
        color: searchMouse.containsMouse || root.open ? Theme.hover : "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.border

        Text {
            anchors.centerIn: parent
            text: "\uf002"
            color: Theme.text
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontPx
        }

        MouseArea {
            id: searchMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.open)
                    root.closeSearch()
                else
                    root.openSearch()
            }

            HoverTip {
                message: "Search settings (Ctrl+F)"
                show: searchMouse.containsMouse && !root.open
            }
        }
    }

    TextField {
        id: field
        visible: root.open
        anchors.left: parent.left
        anchors.right: searchButton.left
        anchors.rightMargin: Theme.tabGap
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.fieldHeight
        verticalAlignment: Text.AlignVCenter
        selectByMouse: true
        placeholderText: "Search settings"
        leftPadding: Theme.space
        color: Theme.text
        placeholderTextColor: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        background: Rectangle {
            radius: Theme.radiusSm
            color: field.activeFocus ? Theme.hover : Theme.fieldBg
            border.width: Theme.borderWidth
            border.color: Theme.border
        }
        Keys.onEscapePressed: root.closeSearch()
        onAccepted: {
            const rows = root.matches()
            if (rows.length)
                root.choose(rows[0])
        }
    }

    Rectangle {
        visible: root.open && field.text.trim().length > 0
        z: 2
        width: Theme.popupWidth
        anchors.top: parent.bottom
        anchors.right: parent.right
        height: resultCol.implicitHeight + Theme.space
        radius: Theme.radiusSm
        color: Theme.pageBg
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: resultCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.tabGap
            spacing: Theme.tabGap

            Text {
                visible: root.matches().length === 0
                width: parent.width
                text: "No matching settings"
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Repeater {
                model: root.matches()
                delegate: Rectangle {
                    id: hit
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: Theme.fieldHeight
                    radius: Theme.radiusSm
                    color: hitMouse.containsMouse ? Theme.hover : Theme.pillBg

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space
                        anchors.rightMargin: Theme.space
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: String(hit.modelData.title || "")
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontPx
                    }

                    MouseArea {
                        id: hitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(hit.modelData)
                    }
                }
            }
        }
    }
}
