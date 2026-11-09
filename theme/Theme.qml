pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // The object bar modules receive: the active theme's palette
    // (Settings → Theme). Changes the moment a theme is applied.
    readonly property ThemePalette palette: ThemePalette {
        colors: ThemeBuilder.build(ThemeStore.activeTheme)
        temp: ThemeStore.activeTheme.temp
        fonts: ThemeStore.activeTheme.fonts
    }

    // A bar with its own glass (Theme → Bar glass → one bar) gets its own
    // palette, so the bar and its pills follow that value. Only colBar and
    // colSurface differ; menus keep Menu glass. A bar that follows bar
    // glass gets the main palette, and its palette below builds nothing.
    function ownGlass(edge) {
        const bars = ThemeStore.activeTheme.barGlass
        return bars ? Number(bars[edge]) >= 0 : false
    }

    function edgeColors(edge) {
        return root.ownGlass(edge) ? ThemeBuilder.build(ThemeBuilder.forEdge(ThemeStore.activeTheme, edge)) : root.palette.colors
    }

    function barPalette(edge) {
        if (!root.ownGlass(edge))
            return root.palette
        if (edge === "top")
            return root.topPalette
        if (edge === "bottom")
            return root.bottomPalette
        if (edge === "left")
            return root.leftPalette
        return root.rightPalette
    }

    readonly property ThemePalette topPalette: ThemePalette {
        colors: root.edgeColors("top")
        temp: ThemeStore.activeTheme.temp
        fonts: ThemeStore.activeTheme.fonts
    }

    readonly property ThemePalette bottomPalette: ThemePalette {
        colors: root.edgeColors("bottom")
        temp: ThemeStore.activeTheme.temp
        fonts: ThemeStore.activeTheme.fonts
    }

    readonly property ThemePalette leftPalette: ThemePalette {
        colors: root.edgeColors("left")
        temp: ThemeStore.activeTheme.temp
        fonts: ThemeStore.activeTheme.fonts
    }

    readonly property ThemePalette rightPalette: ThemePalette {
        colors: root.edgeColors("right")
        temp: ThemeStore.activeTheme.temp
        fonts: ThemeStore.activeTheme.fonts
    }


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
    // Gap kept around a window sized to fit a small screen.
    readonly property int windowScreenMargin: 40
    // Inspector window (Bindings, System Info).
    readonly property int inspectorWidth: 1000
    readonly property int inspectorHeight: 720
    readonly property int inspectorMinWidth: 560
    readonly property int inspectorMinHeight: 360
    readonly property int inspectorKeyWidth: 240
    readonly property int inspectorLabelWidth: 200
    // Bindings columns: as many as fit at this width, up to the max.
    readonly property int inspectorColumnMin: 440
    readonly property int inspectorColumnsMax: 3
    readonly property int inspectorRowHeight: 28
    readonly property int inspectorKeyHeight: 20
    // A clicked binding runs this long after the Inspector closes, so it
    // acts on the window you had focused.
    readonly property int inspectorRunDelayMs: 200
    readonly property int settingsTwoColMin: 860
    readonly property int headerHeight: 40
    readonly property int tabHeight: 32
    readonly property int tabGap: 6
    readonly property int tabMinWidth: 100
    // Width of a section's title bar when the title runs down the left side.
    readonly property int sideHeaderWidth: 30
    // Settings tabs as index dividers (IndexTabStrip).
    readonly property int indexTabHeight: 34
    readonly property int indexTabEdge: 3
    readonly property int indexTabOverlap: 8
    readonly property int indexTabSlant: 10
    readonly property int indexTabRadius: 5
    readonly property int indexTabInset: 5
    readonly property real indexTabIdleOpacity: 0.8
    readonly property int indexTabMinPx: 8
    // Section dividers along the top of a page: widest tab, and how much
    // each next tab's shade steps away from the parent color.
    readonly property int indexTabMaxWidth: 200
    readonly property real indexTabShadeStep: 0.14
    readonly property color indexTabDarkInk: "#1c1917"
    readonly property color indexTabLightInk: "#ffffff"
    // Rainbow divider colors, one per Settings tab in order.
    readonly property var indexTabColors: ["#e53935", "#fdd835", "#1e88e5", "#43a047", "#fb8c00", "#f48fb1", "#8e24aa", "#00acc1", "#a1887f", "#78909c"]
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
    // After a window event: wait, ask Hyprland for fresh window data, then
    // rebuild once it has arrived.
    readonly property int overviewRefreshMs: 60
    readonly property int overviewSettleMs: 140
    readonly property int overviewCommitDelayMs: 90
    readonly property int overviewGrabRetryMs: 250
    readonly property int overviewGrabRetries: 6
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
    readonly property int opacityOverrideMax: 32
    readonly property int opacityOverrideDefault: 85
    // FreshRSS reader. Saved 0 (or -1 for days) means the default here.
    readonly property int freshRssWidth: 980
    readonly property int freshRssHeight: 640
    readonly property int freshRssMinWidth: 640
    readonly property int freshRssMinHeight: 420
    readonly property int freshRssListDefault: 340
    readonly property int freshRssListMin: 200
    readonly property int freshRssDetailMin: 280
    readonly property int freshRssRowHeight: 30
    // Space above and below a row's text, and the cursor bar on its left.
    readonly property int freshRssRowPad: 6
    readonly property int freshRssCursorBar: 3
    // Long feed and article titles wrap up to this many lines.
    readonly property int freshRssTitleLines: 3
    // Site icon beside a feed title.
    readonly property int freshRssIconSize: 16
    // The open article's lead picture is at most this tall.
    readonly property int freshRssLeadImageMax: 360
    // Web page view: most page HTML read, least text that counts as an
    // article, shortest paragraph kept, pages kept while open, and the
    // pause after moving before a page loads by itself.
    readonly property int freshRssPageMax: 1500000
    readonly property int freshRssPageMinText: 200
    readonly property int freshRssPageMinParagraph: 40
    readonly property int freshRssPageCache: 20
    readonly property int freshRssPageDelayMs: 400
    // Article title size over fontPx, and the article text line spacing.
    readonly property int freshRssTitleBoost: 6
    readonly property real freshRssBodyLineHeight: 1.3
    readonly property int freshRssBadgeHeight: 18
    // The "?" shortcut sheet: card width, key column, and the dimmed backdrop.
    readonly property int freshRssHelpWidth: 760
    readonly property int freshRssHelpKeyColumn: 110
    readonly property color freshRssScrim: Qt.rgba(0, 0, 0, 0.55)
    readonly property int keyCapHeight: 20
    readonly property int freshRssPollDefault: 5
    readonly property int freshRssPollMax: 60
    readonly property int freshRssPerFeedDefault: 12
    readonly property var freshRssPerFeedChoices: [5, 8, 10, 12, 15, 20, 25, 30]
    readonly property int freshRssItemLimitDefault: 80
    readonly property var freshRssItemLimitChoices: [20, 40, 50, 80, 100, 150, 200]
    readonly property int freshRssMaxDaysDefault: 30
    // 0 is "no limit".
    readonly property var freshRssMaxDaysChoices: [7, 14, 30, 60, 90, 180, 0]
    readonly property int freshRssRequestMs: 20000
    // Parallel requests while loading every feed.
    readonly property int freshRssParallel: 6
    // Login is reused this long before asking again.
    readonly property int freshRssAuthMs: 1500000
    // Longest article HTML kept for the reader, and the search text per item.
    readonly property int freshRssHtmlMax: 120000
    readonly property int freshRssSearchTextMax: 400
    readonly property string freshRssGlyph: "󰑫"
    // Clipboard viewer: window size, list row height, preview pane share,
    // history sizes to pick from (cliphist's own default is 750), the
    // longest preview read per entry, and the pause before a preview loads.
    readonly property string clipboardGlyph: "\u{f0a38}"
    readonly property int clipboardWidth: 920
    readonly property int clipboardHeight: 560
    readonly property int clipboardRowHeight: 44
    readonly property real clipboardListShare: 0.46
    readonly property int clipboardMaxItemsDefault: 500
    readonly property var clipboardMaxItemsChoices: [100, 250, 500, 750, 1000]
    readonly property int clipboardPreviewWidth: 400
    readonly property int clipboardPreviewMax: 20000
    readonly property int clipboardPreviewDelayMs: 120
    readonly property int clipboardTagWidth: 46
    readonly property int clipboardRestartMs: 3000
    // Caffeine: tea cup outline when off, filled when on (nf-md-tea).
    readonly property string caffeineOffGlyph: "\u{f0d9f}"
    readonly property string caffeineOnGlyph: "\u{f0d9e}"
    // Caffeine durations a right-click steps through, in minutes (0 = until off).
    readonly property var caffeineSteps: [30, 60, 120, 0]
    // Night light (hyprsunset): Kelvin range and the step for the wheel.
    readonly property string nightGlyph: "\u{f0594}"
    readonly property int nightTempMin: 2500
    readonly property int nightTempMax: 6500
    readonly property int nightTempDefault: 4000
    readonly property int nightTempStep: 100
    // Wait this long after a temperature change before restarting hyprsunset.
    readonly property int nightRestartMs: 300
    // Screen recorder (gpu-screen-recorder).
    readonly property string recordGlyph: "\u{f044a}"
    readonly property string recordingGlyph: "\u{f044b}"
    readonly property var recFpsChoices: [30, 60, 120, 144]
    // Battery (UPower): outline at 0, then 10 % steps to full (nf-md-battery-*).
    readonly property var batteryGlyphs: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
        "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property string batteryChargingGlyph: "\u{f0084}"
    // At or below this percent the battery turns the alert color.
    readonly property int batteryLowPercent: 15
    readonly property int batteryTextPx: 10
    // Screen brightness (/sys/class/backlight, set through logind).
    readonly property string brightnessGlyph: "\u{f00e0}"
    readonly property int brightnessStep: 5
    readonly property int brightnessMinPercent: 1
    readonly property var brightnessSteps: [25, 50, 75, 100]

    // Settings → Theme.
    readonly property int themeCardMinWidth: 200
    readonly property int themeCardHeight: 78
    readonly property int themePreviewHeight: 30
    readonly property int themeLibraryMax: 40
    readonly property int themeImportMaxBytes: 262144
    readonly property int themeGlassStep: 2
    readonly property int themeMenuGlassMin: 50
    readonly property int themeTempMin: 40
    readonly property int themeTempMax: 110
    readonly property int themeTempStep: 5
    // Tallest the Transparency menu's open-window list grows before it scrolls.
    readonly property int opacityPickMaxHeight: 220
    readonly property int volumeMax: 150
    readonly property int volumeStep: 5
    // On-screen display (Settings → Notifications → On-Screen Display).
    readonly property int osdWidth: 320
    readonly property int osdMargin: 96
    readonly property int osdTimeoutMs: 1500
    readonly property int osdFadeMs: 180
    readonly property int osdSoundGapMs: 120
    readonly property int osdSettleMs: 1500
    readonly property int osdArt: 56
    readonly property int osdBarHeight: 8
    readonly property int osdGlyphMax: 8
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
    // Auto: how long to wait for a notification daemon at start before the
    // built-in server takes over.
    readonly property int notificationClaimDelayMs: 4000
    readonly property int notificationThumbWidth: 112
    readonly property int notificationThumbHeight: 72
    // Built-in server popups.
    readonly property int notificationToastWidth: 380
    readonly property int notificationToastImage: 48
    readonly property int notificationToastMax: 4
    readonly property int notificationToastBodyLines: 4
    // Gap between the popups and the screen edge (beside any bar).
    readonly property int notificationToastMargin: 16
    readonly property int popupAppColorsMax: 24
    readonly property int popupStripeWidth: 4
    readonly property int popupProgressHeight: 3
    readonly property int popupMotionMs: 220
    // Big image previews: height as a share of the popup width.
    readonly property real popupPreviewRatio: 0.5
    readonly property int wallpaperTileMin: 100
    readonly property int wallpaperTileMax: 260
    readonly property int wallpaperTileStep: 10
    readonly property int wallpaperTile: 148
    // The wallpaper picker strip (Ctrl+Super+Space).
    readonly property int wallpaperPickHeight: 200
    readonly property int wallpaperPickDelay: 250
    readonly property int wallpaperPickGap: 12
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
    // Inspector pill: nf-md-text-search, a page with a magnifier.
    readonly property string inspectorGlyph: "󱎸"
    readonly property int menuFontMin: 8
    readonly property int menuFontMax: 32
    readonly property int menuImagePathMax: 1024
    readonly property int menuPreviewSize: 64
    // Width of the label column on form-style settings pages.
    readonly property int formLabelWidth: 96

    // Auto-hide bars: the strip left at the edge to bring a bar back, the
    // slide time, and the delay ranges under Widgets → Bars.
    readonly property int barTriggerPx: 2
    readonly property int barSlideMs: 180
    readonly property int barHideDelayMin: 100
    readonly property int barHideDelayMax: 3000
    readonly property int barRevealDelayMin: 0
    readonly property int barRevealDelayMax: 1000
    readonly property int barDelayStep: 50

    // Settings → Tools. Longest path or program name a page accepts.
    readonly property int toolPathMax: 1024

    // Settings → Tools → Screensaver. Minutes of idle before it starts.
    readonly property int screensaverMinutesMin: 1
    readonly property int screensaverMinutesMax: 180
    readonly property int screensaverMinutesDefault: 10

    // Settings → System → Display.
    readonly property int displayConfirmSeconds: 15
    readonly property int displayConfirmWidth: 420
    // Settings → System → Display → Arrangement.
    readonly property int displayLayoutHeight: 380
    // Thickness of the green line where two monitors touch.
    readonly property int displayJoinPx: 4
    // Edge inset for TV overscan: the most a slider allows, its step, and
    // the guide frame's line.
    readonly property int displayInsetMax: 200
    readonly property int displayInsetStep: 2
    readonly property int displayGuidePx: 3
    // After turning a monitor on, how long to wait for Hyprland to bring it
    // up before moving its workspaces back.
    readonly property int displayPowerSettleMs: 1200
    // The open Arrangement column's width range.
    readonly property int displayArrangeMin: 300
    readonly property int displayArrangeMax: 460
    // Applications → App Launcher: the open Installed apps column, and the
    // narrowest a launcher column may get before they stack.
    readonly property int launcherAppsMin: 300
    readonly property int launcherAppsMax: 440
    readonly property int launcherColumnMin: 260
    // Snap a dropped monitor's edges to a neighbor's within this many logical pixels.
    readonly property int displaySnapPx: 160
    readonly property int displaySettleMs: 1500
    readonly property int displayTileWidth: 150
    readonly property int displayTileHeight: 92
    readonly property int displayPreviewHeight: 120
    readonly property int displayRejectedMax: 64
    readonly property int menuCommandMax: 400

    // System Stats face. The poll matches the old bar: one sample about every 2s.
    readonly property int statPollMs: 2000
    readonly property int statFontMin: 9
    readonly property int statGaugeWidth: 56
    readonly property int statGaugeHeight: 7
    readonly property int statGaugeRadius: 3
    readonly property int statGaugeMinWidth: 18
    // Bar graph width choices under Widgets → System Stats.
    readonly property int statGaugeWidthMin: 20
    readonly property int statGaugeWidthMax: 120
    readonly property int statGaugeWidthStep: 4
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
    // Firewall menu, and its shields (nf-md-shield-check / shield-off).
    readonly property int firewallPopupWidth: 440
    readonly property int firewallPopupMaxHeight: 620
    readonly property string firewallOnGlyph: "\u{f0565}"
    readonly property string firewallOffGlyph: "\u{f099e}"
    readonly property int tailscaleSearchMin: 8
    readonly property int dependencyTimeoutMs: 5000
    readonly property int audioPopupWidth: 552
    readonly property int audioPopupMaxHeight: 720
    readonly property int audioMeterHeight: 4
    // Audio menu: Active Streams shows this many rows, then scrolls.
    readonly property int audioStreamRowsMax: 5
    readonly property int audioStreamNameWidth: 150
    readonly property int audioMuteChipWidth: 64
    readonly property int bluetoothPulseMs: 1000
    readonly property int bluetoothRefreshMs: 1000

    readonly property int chip: 24
    // Small fixed controls shared by windows and settings pages.
    readonly property int headerButtonWidth: 28
    readonly property int headerButtonHeight: 24
    readonly property int checkBoxWidth: 28
    readonly property int checkBoxHeight: 22
    readonly property int checkGlyphPx: 14
    readonly property int sliderKnob: 14
    readonly property int resizeGrip: 18
    readonly property int buttonHeight: 32
    readonly property int buttonPadX: 20
    readonly property int historyButtonWidth: 96
    readonly property int historyWideButtonWidth: 110
    // Behind a notification image while it loads or has transparent parts.
    readonly property color thumbBackdrop: Qt.rgba(0, 0, 0, 0.25)
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
    // Inspector → Bindings key chips: one fixed color per key type, so no
    // two types match whatever the theme accent is.
    readonly property color keySuper: "#facc15"
    readonly property color keyAlt: "#2dd4bf"
    readonly property color keyShift: "#fb7185"
    readonly property color keyCtrl: "#a78bfa"
    readonly property color keyMouse: "#38bdf8"
    readonly property color keyOther: "#64748b"
    readonly property color keyText: "#111418"
    readonly property color keyOtherText: "#f1f5f9"

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

}
