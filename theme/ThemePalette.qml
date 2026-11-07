import QtQuick

// The palette every pill and menu reads (passed down as `theme`). Colors
// come from the active theme through ThemeBuilder, and so do the fonts
// and text size. The default stat and audio colors stay in DefaultTheme.
// Property names match DefaultTheme, so either can stand in for the other.
QtObject {
    id: root

    // ThemeBuilder.build() output.
    required property var colors
    // The active theme's temperature steps, { warmAt, hotAt }.
    required property var temp
    // The active theme's fonts, { ui, bar, size }; "" keeps DefaultTheme's.
    required property var fonts

    readonly property color colBar: root.colors.colBar
    readonly property color colBarBorder: root.colors.colBarBorder
    readonly property color colGlassHighlight: root.colors.colGlassHighlight
    readonly property color colBg: root.colors.colBg
    readonly property color colPage: root.colors.colPage
    readonly property color colSection: root.colors.colSection
    readonly property color colSurface: root.colors.colSurface
    readonly property color colField: root.colors.colField
    readonly property color colHover: root.colors.colHover
    readonly property color colFg: root.colors.colFg
    readonly property color colFgMuted: root.colors.colFgMuted
    readonly property color colAccent: root.colors.colAccent
    readonly property color colAccentDim: root.colors.colAccentDim
    readonly property color colBorder: root.colors.colBorder
    readonly property color colOk: root.colors.colOk
    readonly property color colDanger: root.colors.colDanger
    readonly property color colWsActive: root.colors.colWsActive
    readonly property color colWsActiveFg: root.colors.colWsActiveFg
    readonly property color colWsIdleFg: root.colors.colWsIdleFg
    readonly property color colWeekday: root.colors.colWeekday
    readonly property color colStatTempCool: root.colors.colStatTempCool
    readonly property color colStatTempWarm: root.colors.colStatTempWarm
    readonly property color colStatTempHot: root.colors.colStatTempHot
    readonly property color colStatSeparator: root.colors.colStatSeparator
    readonly property color colStatDivider: root.colors.colStatDivider
    readonly property color colStatTrack: root.colors.colStatTrack

    readonly property int statTempWarmAt: root.temp.warmAt
    readonly property int statTempHotAt: root.temp.hotAt

    readonly property color colStatUtil1: DefaultTheme.colStatUtil1
    readonly property color colStatUtil2: DefaultTheme.colStatUtil2
    readonly property color colStatUtil3: DefaultTheme.colStatUtil3
    readonly property color colStatUtil4: DefaultTheme.colStatUtil4
    readonly property int statUtilThreshold1: DefaultTheme.statUtilThreshold1
    readonly property int statUtilThreshold2: DefaultTheme.statUtilThreshold2
    readonly property int statUtilThreshold3: DefaultTheme.statUtilThreshold3

    readonly property real scale: root.fonts.size / 100
    readonly property string fontFamily: root.fonts.bar.length ? root.fonts.bar : DefaultTheme.fontFamily
    readonly property string uiFont: root.fonts.ui.length ? root.fonts.ui : DefaultTheme.uiFont
    readonly property string iconFont: DefaultTheme.iconFont
    readonly property int fontPx: Math.round(DefaultTheme.fontPx * root.scale)
    readonly property int smallPx: Math.round(DefaultTheme.smallPx * root.scale)
    readonly property int iconPx: Math.round(DefaultTheme.iconPx * root.scale)
}
