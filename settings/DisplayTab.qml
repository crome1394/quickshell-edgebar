import QtQuick
import qs.theme

// Settings → System → Display. A placeholder for resolution and monitor
// settings, which come later.
Item {
    id: root

    Column {
        x: Theme.sectionInset
        width: parent.width - Theme.sectionInset * 2
        spacing: Theme.space

        SectionHeader {
            width: parent.width
            title: "Display"
            hint: "Resolution and monitor settings will live here."
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Nothing to set yet."
            color: Theme.subtext
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontPx
        }
    }
}
