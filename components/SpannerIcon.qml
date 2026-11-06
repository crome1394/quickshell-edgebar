import QtQuick

Text {
    required property var theme

    property int pixelSize: theme.iconPx

    font.family: theme.iconFont
    font.pixelSize: pixelSize
    text: "\uf0ad"
    color: theme.colFg
    renderType: Text.QtRendering
}
