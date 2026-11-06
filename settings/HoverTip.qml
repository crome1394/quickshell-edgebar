import QtQuick
import QtQuick.Controls
import qs.theme

// Hover tip for a settings control. Future settings pages use this,
// the same way they use Theme.sectionInset for the page layout.
// Set show from the control's hover. A HoverHandler does not take clicks:
//   HoverHandler { id: hover }
//   HoverTip { message: "…"; show: hover.hovered }
ToolTip {
    id: tip

    required property string message
    required property bool show

    visible: tip.show && tip.message.length > 0
    text: tip.message
    delay: Theme.tooltipDelay
    leftPadding: Theme.space
    rightPadding: Theme.space
    topPadding: Theme.tabGap
    bottomPadding: Theme.tabGap

    contentItem: Text {
        text: tip.text
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: Theme.smallPx
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: Theme.pillBg
        border.width: Theme.borderWidth
        border.color: Theme.border
    }
}
