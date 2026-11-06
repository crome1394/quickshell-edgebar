pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The object bar modules receive. DefaultTheme until a switcher exists.
    readonly property var palette: DefaultTheme

    readonly property string fontFamily: root.palette.fontFamily
    readonly property string uiFont: root.palette.uiFont
    readonly property string iconFont: root.palette.iconFont

    readonly property int fontPx: root.palette.fontPx
    readonly property int smallPx: root.palette.smallPx
    readonly property int iconPx: root.palette.iconPx

    readonly property int barHeight: 40
    readonly property int barPad: 6
    // Shortest glass along an enabled bar when it is not spanning.
    readonly property int barMinLength: 120
    // Gap between the bar glass and the screen edge along the bar.
    readonly property int barSideGap: 24
    // Settings pages are already Theme.space inside the window. Section
    // headers use that. Section bodies step in by sectionInset, so the
    // body sits barSideGap from the window edge. Future pages use the same pair.
    readonly property int sectionInset: Math.max(0, root.barSideGap - root.space)
    readonly property int radius: 10
    readonly property int radiusSm: 6
    readonly property int borderWidth: 1
    readonly property int space: 8

    readonly property int wsButtonWidth: 42
    readonly property int wsButtonHeight: 30
    readonly property int wsGap: 4
    readonly property int wsPad: 8
    readonly property int wsIconPx: 16
    readonly property int wsInnerPad: 12
    readonly property int wsLabelMax: 92

    readonly property int settingsWidth: 1040
    readonly property int settingsHeight: 760
    readonly property int settingsMinWidth: 760
    readonly property int settingsMinHeight: 480
    readonly property int settingsTwoColMin: 860
    readonly property int headerHeight: 40
    readonly property int tabHeight: 32
    readonly property int tabGap: 6
    readonly property int tabMinWidth: 108
    readonly property int fieldHeight: 30
    readonly property int slotMinHeight: 112
    readonly property int sliderHeight: 22
    readonly property int footerHeight: 44

    readonly property int colorAnimMs: 140
    // Delay before a settings HoverTip appears. Every settings control uses one.
    readonly property int tooltipDelay: 400
    readonly property int persistDelayMs: 40
    readonly property int specialSyncMs: 40
    // Overview IPC ignores a second toggle, desktop, or all call inside this window.
    readonly property int overviewDebounceMs: 280
    // Ignore the workspace-changed close for this long after our own Hyprland dispatch.
    readonly property int overviewSuppressMs: 700
    readonly property int startupAttemptMs: 350
    // Late window classes (games, some toolkits) arrive after focus.
    readonly property int activeWindowClassMs: 350
    // How wide the active-window popup may grow, in pixels, before text is cut off.
    readonly property int activeWindowWidthMin: 240
    readonly property int activeWindowWidthMax: 1600
    readonly property int activeWindowWidthDefault: 640
    readonly property int activeWindowWidthStep: 20
    // Clock face size is a percent of the bar font. The region map uses the GNOME pictures.
    readonly property int clockFontMin: 70
    readonly property int clockFontMax: 150
    readonly property int clockFontDefault: 100
    readonly property int clockFontStep: 5
    readonly property int clockFormatMax: 80
    readonly property int regionMapHeight: 420
    readonly property int opacityMin: 5
    readonly property int opacityMax: 100
    readonly property int opacityStep: 5
    readonly property int volumeMax: 150
    readonly property int volumeStep: 5
    readonly property int volumeOsdMs: 40
    readonly property int dockScaleMin: 110
    readonly property int dockScaleMax: 160
    readonly property int dockScaleDefault: 128
    readonly property int dockScaleStep: 5
    readonly property int dockRadiusMin: 40
    readonly property int dockRadiusMax: 140
    readonly property int dockRadiusDefault: 72
    readonly property int dockRadiusStep: 4
    readonly property int dockJumpMin: 4
    readonly property int dockJumpMax: 16
    readonly property int dockJumpDefault: 8
    readonly property int dockJumpStep: 1
    readonly property int dockRiseMs: 90
    readonly property int dockSettleMs: 220
    readonly property int dockPollMs: 50
    readonly property color dockDotDefault: "#00f5ff"
    readonly property int audioBarWidth: 56
    readonly property int audioBarHeight: 7
    readonly property int audioBarRadius: 3
    readonly property int audioScrollMin: 1
    readonly property int audioScrollMax: 20
    readonly property int notificationTimeoutMax: 60
    readonly property int notificationTimeoutDefault: 8
    readonly property int notificationPanelWidth: 440
    readonly property int notificationPanelHeight: 488
    readonly property int notificationSyncMs: 2500
    readonly property int notificationThumbWidth: 112
    readonly property int notificationThumbHeight: 72
    readonly property int wallpaperTileMin: 100
    readonly property int wallpaperTileMax: 260
    readonly property int wallpaperTileStep: 10
    readonly property int wallpaperTile: 148
    readonly property int popupWidth: 280
    readonly property int networkPopupWidth: 460
    readonly property int networkPopupMaxHeight: 560
    readonly property int bluetoothPopupWidth: 380
    readonly property int bluetoothPopupMaxHeight: 480
    readonly property int bluetoothScanMin: 5
    readonly property int bluetoothScanMax: 120
    readonly property int bluetoothScanDefault: 45
    readonly property int bluetoothScanStep: 5
    readonly property int launcherMin: 1
    readonly property int launcherMax: 4
    readonly property int launcherPinMax: 24
    readonly property int launcherListMax: 80
    // nf-md-apps, one glyph: a square of nine squares.
    readonly property string menuSymbolDefault: "󰀻"
    readonly property int menuFontMin: 8
    readonly property int menuFontMax: 32
    readonly property int menuCommandMax: 400

    // System Stats face. The poll matches the old bar: one sample about every 2s.
    readonly property int statPollMs: 2000
    readonly property int statFontMin: 9
    readonly property int statGaugeWidth: 56
    readonly property int statGaugeHeight: 7
    readonly property int statGaugeRadius: 3
    readonly property int statGaugeMinWidth: 18
    readonly property int statGaugeMinHeight: 4
    readonly property int statRowGap: 5
    readonly property int statValGap: 3
    readonly property int statPadH: 10
    readonly property int statSep: 8
    readonly property int statInnerPad: 4
    // Thickness of a popup scrollbar. The menus keep a wider gutter so the bar sits beside the text.
    readonly property int scrollBarWidth: 6
    readonly property int workspaceHeartbeatMs: 60000
    readonly property int workspaceColdPollMs: 150
    readonly property int workspaceColdPolls: 6
    // Timers that were written into widgets and services.
    readonly property int regionApplyDelayMs: 180
    readonly property int opacityApplyDelayMs: 80
    readonly property int copiedFlashMs: 1200
    readonly property int networkFaceMs: 15000
    readonly property int networkPollMs: 2000
    readonly property int networkRefreshMs: 400
    readonly property int networkRateFirstMs: 1000
    // Tailscale: a light status check while the pill is on the bar, a faster
    // one while its menu is open, and how long to wait before deciding the
    // tailscale CLI is missing.
    readonly property int tailscaleIdlePollMs: 30000
    readonly property int tailscaleOpenPollMs: 3000
    readonly property int tailscaleStartMs: 3000
    readonly property int tailscalePopupWidth: 440
    readonly property int tailscalePopupMaxHeight: 620
    readonly property int tailscaleSearchMin: 8
    readonly property int dependencyTimeoutMs: 5000
    readonly property int audioPopupWidth: 480
    readonly property int audioPopupMaxHeight: 720
    readonly property int audioMeterHeight: 4
    readonly property int bluetoothPulseMs: 1000
    readonly property int bluetoothRefreshMs: 1000

    readonly property int chip: 24
    readonly property int toggleWidth: 28
    readonly property int widgetRowHeight: 72
    readonly property int dividerRowHeight: 40
    readonly property int dividerLength: 18
    readonly property int dividerThickness: 2
    readonly property int badgeHeight: 22
    readonly property real widgetOffOpacity: 0.78

    // Bar UI scale. 0 in config means automatic from screen width.
    readonly property int uiDesignWidth: 2560
    readonly property real uiScaleMin: 0.65
    readonly property real uiScaleMax: 1.0
    readonly property int gapsFallback: 14

    readonly property color barBg: root.palette.colBg
    readonly property color pageBg: root.palette.colPage
    readonly property color sectionBg: root.palette.colSection
    readonly property color pillBg: root.palette.colSurface
    readonly property color fieldBg: root.palette.colField
    readonly property color hover: root.palette.colHover
    readonly property color accent: root.palette.colAccent
    readonly property color accentDim: root.palette.colAccentDim
    readonly property color text: root.palette.colFg
    readonly property color subtext: root.palette.colFgMuted
    readonly property color border: root.palette.colBorder
    readonly property color ok: root.palette.colOk
    readonly property color danger: root.palette.colDanger
    readonly property color wsActiveBg: root.palette.colWsActive
    readonly property color wsActiveText: root.palette.colWsActiveFg
    readonly property color wsInactiveText: root.palette.colWsIdleFg

    // Text size for every bar pill: the bar text size, scaled with the UI
    // and the widget's width, times the widget's own percent override when it
    // has one, and kept inside the bar. Pills use fontFamily unless the
    // widget has its own font override.
    function barTextPx(ui, widthFactor, percent) {
        const pct = Number(percent) > 0 ? Number(percent) : 100
        const wanted = Math.round(root.fontPx * pct / 100 * Number(ui) * Number(widthFactor))
        const cap = Math.max(1, Math.round((root.barHeight - root.barPad) * Number(ui)) - root.borderWidth * 4)
        return Math.max(root.statFontMin, Math.min(cap, wanted))
    }

    function statUtilColor(util, metric, t1, t2, t3) {
        const kind = String(metric || "")
        const colors = root.statColors(kind)
        let u = Number(util)
        if (!(u >= 0))
            u = 0
        else if (u > 100)
            u = 100
        let lowAt = Number(t1)
        let midAt = Number(t2)
        let highAt = Number(t3)
        if (!(lowAt >= 0) || !(midAt >= 0) || !(highAt >= 0)) {
            const saved = root.statThresholds(kind)
            lowAt = saved[0]
            midAt = saved[1]
            highAt = saved[2]
        }
        if (u <= lowAt)
            return colors[0]
        if (u <= midAt)
            return colors[1]
        if (u <= highAt)
            return colors[2]
        return colors[3]
    }

    function statTempColor(temp) {
        const p = root.palette
        let t = Math.round(Number(temp))
        if (!(t >= 0))
            t = 0
        if (t > p.statTempHotAt)
            return p.colStatTempHot
        if (t > p.statTempWarmAt)
            return p.colStatTempWarm
        return p.colStatTempCool
    }

    // Saved threshold steps and colors. theme/theme.json overrides DefaultTheme.
    // An empty file keeps the defaults in DefaultTheme.qml. Apply writes this file.
    property bool themeReady: false
    property bool themeApplying: false
    property bool themeWriting: false
    property alias statsJson: themeStore.statsJson
    property alias audioJson: themeStore.audioJson

    function colorHex(value) {
        const text = String(value === undefined || value === null ? "" : value)
        if (text.length < 4)
            return ""
        const color = Qt.color(text)
        const byte = (channel) => {
            const n = Math.round(Math.max(0, Math.min(1, Number(channel))) * 255)
            const hex = n.toString(16)
            return hex.length < 2 ? "0" + hex : hex
        }
        return "#" + byte(color.r) + byte(color.g) + byte(color.b)
    }

    function normSteps(raw, fallback) {
        const base = fallback && fallback.length >= 3 ? fallback : [25, 50, 75]
        let low = base[0]
        let mid = base[1]
        let high = base[2]
        if (raw && raw.length >= 3) {
            low = Math.round(Number(raw[0]) / 5) * 5
            mid = Math.round(Number(raw[1]) / 5) * 5
            high = Math.round(Number(raw[2]) / 5) * 5
        }
        if (!(low >= 0))
            low = 0
        if (low > 100)
            low = 100
        if (!(mid >= low))
            mid = low
        if (mid > 100)
            mid = 100
        if (!(high >= mid))
            high = mid
        if (high > 100)
            high = 100
        return [low, mid, high]
    }

    function normColors(raw, fallback) {
        const base = fallback && fallback.length >= 4 ? fallback : ["#10b981", "#f59e0b", "#f97316", "#ef4444"]
        const out = [base[0], base[1], base[2], base[3]]
        if (!raw || raw.length < 4)
            return out
        for (let i = 0; i < 4; i++) {
            const hex = root.colorHex(raw[i])
            if (hex.length)
                out[i] = hex
        }
        return out
    }

    function defaultStatColors(metric) {
        const p = DefaultTheme
        const kind = String(metric || "")
        if (kind === "cpu")
            return [root.colorHex(p.colStatCpu1), root.colorHex(p.colStatCpu2), root.colorHex(p.colStatCpu3), root.colorHex(p.colStatCpu4)]
        if (kind === "mem")
            return [root.colorHex(p.colStatMem1), root.colorHex(p.colStatMem2), root.colorHex(p.colStatMem3), root.colorHex(p.colStatMem4)]
        if (kind === "gpu")
            return [root.colorHex(p.colStatGpu1), root.colorHex(p.colStatGpu2), root.colorHex(p.colStatGpu3), root.colorHex(p.colStatGpu4)]
        if (kind === "vram")
            return [root.colorHex(p.colStatVram1), root.colorHex(p.colStatVram2), root.colorHex(p.colStatVram3), root.colorHex(p.colStatVram4)]
        return [root.colorHex(p.colStatUtil1), root.colorHex(p.colStatUtil2), root.colorHex(p.colStatUtil3), root.colorHex(p.colStatUtil4)]
    }

    function defaultStatSteps() {
        return [DefaultTheme.statUtilThreshold1, DefaultTheme.statUtilThreshold2, DefaultTheme.statUtilThreshold3]
    }

    function defaultStatVisual() {
        const steps = root.defaultStatSteps()
        return {
            cpu: { t: steps.slice(), c: root.defaultStatColors("cpu") },
            mem: { t: steps.slice(), c: root.defaultStatColors("mem") },
            gpu: { t: steps.slice(), c: root.defaultStatColors("gpu") },
            vram: { t: steps.slice(), c: root.defaultStatColors("vram") }
        }
    }

    function defaultAudioVisual() {
        return {
            t: [DefaultTheme.audioUtilThreshold1, DefaultTheme.audioUtilThreshold2, DefaultTheme.audioUtilThreshold3],
            c: [root.colorHex(DefaultTheme.colAudio1), root.colorHex(DefaultTheme.colAudio2), root.colorHex(DefaultTheme.colAudio3), root.colorHex(DefaultTheme.colAudio4)]
        }
    }

    function parsedObject(text) {
        const body = String(text || "").trim()
        if (!body.length)
            return null
        try {
            const parsed = JSON.parse(body)
            if (!parsed || typeof parsed !== "object" || parsed.length !== undefined)
                return null
            return parsed
        } catch (e) {
            return null
        }
    }

    function hasStatEntry(metric) {
        const all = root.parsedObject(root.statsJson)
        if (!all)
            return false
        const row = all[String(metric || "")]
        return !!(row && row.t && row.t.length >= 3 && row.c && row.c.length >= 4)
    }

    function statThresholds(metric) {
        const key = String(metric || "cpu")
        const fallback = root.defaultStatSteps()
        if (!root.hasStatEntry(key))
            return fallback.slice()
        return root.normSteps(root.parsedObject(root.statsJson)[key].t, fallback)
    }

    function statColors(metric) {
        const key = String(metric || "cpu")
        const fallback = root.defaultStatColors(key)
        if (!root.hasStatEntry(key))
            return fallback.slice()
        return root.normColors(root.parsedObject(root.statsJson)[key].c, fallback)
    }

    function hasAudioEntry() {
        const row = root.parsedObject(root.audioJson)
        return !!(row && row.t && row.t.length >= 3 && row.c && row.c.length >= 4)
    }

    function audioVisual() {
        const base = root.defaultAudioVisual()
        if (!root.hasAudioEntry())
            return { t: base.t.slice(), c: base.c.slice() }
        const row = root.parsedObject(root.audioJson)
        return {
            t: root.normSteps(row.t, base.t),
            c: root.normColors(row.c, base.c)
        }
    }

    function audioSpeakerColor(percent) {
        const visual = root.audioVisual()
        let u = Number(percent)
        if (!(u >= 0))
            u = 0
        if (u <= visual.t[0])
            return visual.c[0]
        if (u <= visual.t[1])
            return visual.c[1]
        if (u <= visual.t[2])
            return visual.c[2]
        return visual.c[3]
    }

    function queueThemeSave() {
        if (!root.themeReady || root.themeApplying || root.themeWriting)
            return
        root.themeWriting = true
        themeFile.writeAdapter()
    }

    function saveStats(visual) {
        const source = visual || {}
        const defaults = root.defaultStatVisual()
        const keys = ["cpu", "mem", "gpu", "vram"]
        const out = {}
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            const row = source[key] || defaults[key]
            out[key] = {
                t: root.normSteps(row.t, defaults[key].t),
                c: root.normColors(row.c, defaults[key].c)
            }
        }
        root.themeApplying = true
        root.statsJson = JSON.stringify(out)
        root.themeApplying = false
        root.queueThemeSave()
    }

    function saveAudio(visual) {
        const base = root.defaultAudioVisual()
        const row = visual || base
        const out = {
            t: root.normSteps(row.t, base.t),
            c: root.normColors(row.c, base.c)
        }
        root.themeApplying = true
        root.audioJson = JSON.stringify(out)
        root.themeApplying = false
        root.queueThemeSave()
    }

    FileView {
        id: themeFile
        path: Quickshell.shellDir + "/theme/theme.json"
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: root.themeReady = true
        onLoadFailed: root.themeReady = true
        onAdapterUpdated: root.queueThemeSave()
        onSaved: root.themeWriting = false
        onSaveFailed: root.themeWriting = false
        onFileChanged: {
            if (!root.themeWriting)
                themeFile.reload()
        }

        // qmllint disable unresolved-type
        JsonAdapter {
        // qmllint enable unresolved-type
            id: themeStore
            property string statsJson: ""
            property string audioJson: ""
        }
    }
}
