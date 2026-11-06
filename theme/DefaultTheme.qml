pragma Singleton
import Quickshell
import QtQuick

// Liquid amber. Tint 0.09, 0.07, 0.04, accent #fbbf24, muted #fb7185.
// Bar glass is thinner than pills. Menus and Settings are the opaque glass.
Singleton {
    id: root

    readonly property color colBar: Qt.rgba(0.09, 0.07, 0.04, 0.56)
    readonly property color colBarBorder: Qt.rgba(0.984, 0.749, 0.141, 0.14)
    readonly property color colGlassHighlight: Qt.rgba(1, 1, 1, 0.08)
    readonly property color colBg: Qt.rgba(0.09, 0.07, 0.04, 0.90)
    readonly property color colPage: Qt.rgba(0.09, 0.07, 0.04, 0.90)
    // Section header band. A step lighter than the page, quieter than a card.
    readonly property color colSection: "#2a2418"
    readonly property color colSurface: Qt.rgba(0.09, 0.07, 0.04, 0.72)
    readonly property color colField: "#120e0a"
    // Accent washed over the tint, kept opaque so a hover does not open a hole.
    readonly property color colHover: "#45350f"
    readonly property color colFg: "#f0f4fc"
    readonly property color colFgMuted: "#a8b4c8"
    readonly property color colAccent: "#fbbf24"
    readonly property color colAccentDim: "#604912"
    readonly property color colBorder: Qt.rgba(1, 1, 1, 0.10)
    readonly property color colOk: "#10b981"
    readonly property color colDanger: "#fb7185"
    readonly property color colWsActive: Qt.rgba(0.984, 0.749, 0.141, 0.26)
    readonly property color colWsActiveFg: "#e6fffc"
    readonly property color colWsIdleFg: "#ffffff"
    // Weekday letters on the clock calendar. The preset's muted rose.
    readonly property color colWeekday: "#fb7185"

    // System Stats. Liquid Amber thresholds: low, mid, high, peak.
    // Utilization at or under each step uses that tier. Temperature
    // switches at statTempWarmAt and statTempHotAt.
    readonly property color colStatUtil1: "#10b981"
    readonly property color colStatUtil2: "#f59e0b"
    readonly property color colStatUtil3: "#f97316"
    readonly property color colStatUtil4: "#ef4444"
    readonly property color colStatCpu1: "#e8a0a4"
    readonly property color colStatCpu2: "#ed1c24"
    readonly property color colStatCpu3: "#c4161c"
    readonly property color colStatCpu4: "#ff4500"
    readonly property color colStatMem1: "#5eead4"
    readonly property color colStatMem2: "#22d3ee"
    readonly property color colStatMem3: "#06b6d4"
    readonly property color colStatMem4: "#0284c7"
    readonly property color colStatGpu1: "#76b900"
    readonly property color colStatGpu2: "#c4d600"
    readonly property color colStatGpu3: "#ffc800"
    readonly property color colStatGpu4: "#ff5a00"
    readonly property color colStatVram1: "#76b900"
    readonly property color colStatVram2: "#c4d600"
    readonly property color colStatVram3: "#ffc800"
    readonly property color colStatVram4: "#ff5a00"
    readonly property color colStatTempCool: "#f0f4fc"
    readonly property color colStatTempWarm: "#f0d060"
    readonly property color colStatTempHot: "#fb7185"
    readonly property color colStatSeparator: "#6e7a90"
    readonly property color colStatDivider: Qt.rgba(1, 1, 1, 0.12)
    readonly property color colStatTrack: Qt.rgba(1, 1, 1, 0.10)
    readonly property int statUtilThreshold1: 25
    readonly property int statUtilThreshold2: 50
    readonly property int statUtilThreshold3: 75
    readonly property int statTempWarmAt: 70
    readonly property int statTempHotAt: 85

    // Speaker level on the audio pill. Green, yellow, orange, red.
    readonly property color colAudio1: "#10b981"
    readonly property color colAudio2: "#f59e0b"
    readonly property color colAudio3: "#f97316"
    readonly property color colAudio4: "#ef4444"
    readonly property int audioUtilThreshold1: 25
    readonly property int audioUtilThreshold2: 50
    readonly property int audioUtilThreshold3: 75

    // Window opacity, in percent. 100 is solid. The Transparency menu
    // can override these. A saved 0 means "use the numbers here".
    readonly property int opacityQuickshell: 100
    readonly property int opacitySatty: 100

    readonly property string fontFamily: "MesloLGS Nerd Font"
    readonly property string uiFont: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontPx: 13
    readonly property int smallPx: 11
    readonly property int iconPx: 16
}
