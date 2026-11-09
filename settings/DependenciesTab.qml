pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.theme

// Settings → System → Dependencies. Checks the programs, fonts, and services
// the bar needs, so a missing one after a reinstall does not fail silently.
// The check runs when this page opens and when Recheck is pressed.
Item {
    id: root

    readonly property var dep: DependencyService
    readonly property int scrollGutter: Theme.space + Theme.tabGap
    readonly property var areas: {
        const out = []
        const list = root.dep.programs
        for (let i = 0; i < list.length; i++) {
            if (out.indexOf(list[i].area) < 0)
                out.push(list[i].area)
        }
        return out
    }
    readonly property int missingRequired: root.dep.missingPrograms().concat(root.dep.missingFonts()).filter(p => p.need === "required").length
        + root.dep.stoppedServices().filter(s => s.need === "required").length
    readonly property int missingAll: root.dep.missingPrograms().length + root.dep.missingFonts().length + root.dep.stoppedServices().length
    property bool copied: false

    function summary() {
        if (root.dep.checking)
            return "Checking…"
        if (!root.dep.checkedOnce)
            return ""
        if (root.missingAll === 0)
            return "Everything the bar uses is installed and running."
        const parts = []
        if (root.missingRequired)
            parts.push(root.missingRequired + " required")
        if (root.missingAll - root.missingRequired)
            parts.push((root.missingAll - root.missingRequired) + " optional")
        return parts.join(" and ") + " missing or stopped. Required ones break a core widget; optional ones turn off one feature."
    }

    Component.onCompleted: root.dep.check()

    component GroupTitle: Text {
        width: parent ? parent.width : 0
        topPadding: Theme.tabGap
        color: Theme.accent
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontPx
        font.bold: true
    }

    component SmallButton: Rectangle {
        id: button
        required property string label
        property string tip: ""
        signal clicked()
        width: buttonText.implicitWidth + Theme.space * 2
        height: Theme.fieldHeight
        radius: Theme.radiusSm
        color: buttonMouse.containsMouse ? Theme.hover : Theme.pillBg
        border.width: Theme.borderWidth
        border.color: buttonMouse.containsMouse ? Theme.accent : Theme.border

        Text {
            id: buttonText
            anchors.centerIn: parent
            text: button.label
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: Theme.smallPx
            font.bold: true
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()

            HoverTip {
                message: button.tip
                show: buttonMouse.containsMouse && button.tip.length > 0
            }
        }
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: pageScroll
            policy: ScrollBar.AsNeeded
            width: Theme.scrollBarWidth
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: Theme.scrollBarWidth
                radius: width / 2
                color: pageScroll.pressed || pageScroll.hovered ? Theme.accent : Theme.subtext
            }
        }

        Column {
            id: body
            x: Theme.sectionInset
            width: Math.max(0, scroll.width - root.scrollGutter - Theme.sectionInset * 2)
            spacing: Theme.tabGap

            SectionHeader {
                width: parent.width
                title: "Dependencies"
                hint: "Programs, fonts, and services the bar uses. A missing one does not stop the bar; the widget that needs it just does nothing."
            }

            Row {
                width: parent.width
                spacing: Theme.space

                Text {
                    width: parent.width - recheck.width - Theme.space
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.WordWrap
                    text: root.summary()
                    color: root.missingRequired ? Theme.danger : (root.missingAll ? Theme.accent : Theme.ok)
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontPx
                }

                SmallButton {
                    id: recheck
                    label: "Recheck"
                    tip: "Check everything again"
                    onClicked: root.dep.check()
                }
            }

            // One install line for everything missing that has a package.
            Rectangle {
                visible: root.dep.installLine().length > 0
                width: parent.width
                height: Theme.fieldHeight + Theme.space
                radius: Theme.radiusSm
                color: Theme.fieldBg
                border.width: Theme.borderWidth
                border.color: Theme.border

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space
                    anchors.right: copyButton.left
                    anchors.rightMargin: Theme.space
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: root.dep.installLine()
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallPx
                }

                SmallButton {
                    id: copyButton
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.tabGap
                    anchors.verticalCenter: parent.verticalCenter
                    label: root.copied ? "Copied" : "Copy"
                    tip: "Copy this command to paste in a terminal"
                    onClicked: {
                        Quickshell.clipboardText = root.dep.installLine()
                        root.copied = true
                    }
                }
            }

            Text {
                visible: root.dep.checkedOnce && (root.dep.installLine().length > 0 || root.dep.stoppedServices().length > 0)
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Or run scripts/install-deps.sh in a terminal: it installs the missing packages and enables and starts stopped services, asking before each step. Add --dry-run to only look."
                color: Theme.subtext
                font.family: Theme.uiFont
                font.pixelSize: Theme.smallPx
            }

            Repeater {
                model: root.areas
                delegate: Column {
                    id: area
                    required property string modelData
                    width: body.width
                    spacing: 0

                    GroupTitle {
                        text: area.modelData
                    }

                    Repeater {
                        model: root.dep.programs.filter(p => p.area === area.modelData)
                        delegate: DependencyRow {
                            required property var modelData
                            width: area.width
                            name: modelData.name
                            use: modelData.use
                            need: modelData.need
                            known: root.dep.checkedOnce
                            ok: !!root.dep.found[modelData.name]
                            detail: root.dep.found[modelData.name] || (String(modelData.pkg || "").length ? "Install " + modelData.pkg : "Get it from " + String(modelData.from || "its project page"))
                        }
                    }
                }
            }

            GroupTitle {
                visible: root.dep.settingRows.length > 0
                text: "Your settings"
            }

            Repeater {
                model: root.dep.settingRows
                delegate: DependencyRow {
                    required property var modelData
                    width: body.width
                    name: modelData.name
                    use: modelData.use
                    need: modelData.need
                    known: root.dep.checkedOnce
                    ok: !!root.dep.found[modelData.name]
                    detail: root.dep.found[modelData.name] || "Not found. Install it, or change this setting."
                }
            }

            GroupTitle {
                text: "Fonts"
            }

            Repeater {
                model: root.dep.fonts
                delegate: DependencyRow {
                    required property var modelData
                    width: body.width
                    name: modelData.name
                    use: modelData.use
                    need: modelData.need
                    known: root.dep.checkedOnce
                    ok: !!root.dep.fontFound[modelData.name]
                    detail: root.dep.fontFound[modelData.name] ? "" : "Install " + modelData.pkg + ", or add the font to ~/.local/share/fonts"
                }
            }

            GroupTitle {
                text: "Services"
            }

            Repeater {
                model: root.dep.services
                delegate: DependencyRow {
                    required property var modelData
                    width: body.width
                    readonly property string state: String(root.dep.serviceState[modelData.name] || "")
                    name: modelData.name
                    use: modelData.use
                    need: modelData.need
                    known: root.dep.checkedOnce
                    ok: state === "active"
                    detail: (modelData.scope === "user" ? "user service" : "system service") + " · " + (state.length ? state : "unknown")
                }
            }
        }
    }
}
