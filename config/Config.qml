pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// The saved settings store: every field in state/bar-layout.json, the
// save timer, shared validators, and the shell IPC target. Feature logic
// and settings-page drafts live in the *Settings singletons beside this
// file. Field names keep the old bar's keys so a copied layout loads, and
// the cycle script reads wsSpecialNameCustom and wsSlotsJson directly.
Singleton {
    id: root

    readonly property string storePath: Quickshell.shellDir + "/state/bar-layout.json"

    property bool ready: false
    property bool applying: false
    property bool writing: false
    // A change came in while a save was running; save again when it ends.
    property bool savePending: false
    property int revision: 0

    property alias showSpecial: data.wsShowSpecialPill
    property alias showOnlyActive: data.wsShowOnlyActive
    property alias showNumbers: data.wsShowNumbers
    property alias minimumShown: data.wsMinimumShown
    property alias startupWorkspace: data.wsStartupWorkspace
    property alias startupCloseSpecial: data.wsStartupCloseMagic
    property alias hasSlots: data.hasWsSlots
    property alias specialNameCustom: data.wsSpecialNameCustom
    property alias specialLabel: data.wsIconSpecialCustom
    property alias specialFont: data.wsSpecialFont
    property alias specialFontPx: data.wsSpecialFontPx
    property alias specialText: data.wsSpecialText
    property alias specialBold: data.wsSpecialBold
    property alias specialItalic: data.wsSpecialItalic
    property alias specialColor: data.wsSpecialColor
    // Workspace colors: "theme", "custom", or "" (custom when a face has
    // a color, else theme). Custom colors: "" falls back to the theme.
    property alias wsColorMode: data.wsColorMode
    // Monitors (ScreenService): bars on "main" | "all" | "pick", the picked
    // monitor names (JSON list), and the main monitor's name ("" = first).
    property alias barScreenMode: data.barScreenMode
    property alias barScreenNames: data.barScreenNames
    property alias mainScreen: data.mainScreen
    property alias wsActiveBg: data.wsActiveBg
    property alias wsActiveFg: data.wsActiveFg
    property alias wsIdleFg: data.wsIdleFg
    property alias wsHoverFg: data.wsHoverFg
    property alias slotsJson: data.wsSlotsJson

    property alias barLayoutMode: data.barLayoutMode
    property alias showLeftBar: data.showLeftBar
    property alias showRightBar: data.showRightBar
    property alias showTopBar: data.showTopBar
    property alias showBottomBar: data.showBottomBar
    property alias topBarAlign: data.topBarAlign
    property alias barMonitorsJson: data.barMonitorsJson
    property alias displayInsetsJson: data.displayInsetsJson
    property alias displayOffJson: data.displayOffJson
    property alias bottomBarAlign: data.bottomBarAlign
    property alias leftBarAlign: data.leftBarAlign
    property alias rightBarAlign: data.rightBarAlign
    property alias barSpanFull: data.barSpanFull
    property alias panelSpanFull: data.panelSpanFull
    property alias leftBarSpanFull: data.leftBarSpanFull
    property alias rightBarSpanFull: data.rightBarSpanFull
    property alias uiScaleManual: data.uiScaleManual
    property alias flushWindowsToBar: data.flushWindowsToBar
    property alias topBarAutoHide: data.topBarAutoHide
    property alias bottomBarAutoHide: data.bottomBarAutoHide
    property alias leftBarAutoHide: data.leftBarAutoHide
    property alias rightBarAutoHide: data.rightBarAutoHide
    property alias barHideDelayMs: data.barHideDelayMs
    property alias barRevealDelayMs: data.barRevealDelayMs
    property alias widgetLayoutJson: data.widgetLayoutJson
    property alias widgetLayoutDualJson: data.widgetLayoutDualJson
    property alias widgetScalesJson: data.widgetScalesJson
    property alias showLauncherPill: data.showLauncherPill
    property alias showQuickLaunchPill: data.showQuickLaunchPill
    property alias showQuickLaunch2Pill: data.showQuickLaunch2Pill
    property alias showQuickLaunch3Pill: data.showQuickLaunch3Pill
    property alias showQuickLaunch4Pill: data.showQuickLaunch4Pill
    property alias launcherCount: data.launcherCount
    property alias quickLaunchJson: data.quickLaunchJson
    property alias menuSymbol: data.menuSymbol
    property alias menuFont: data.menuFont
    property alias menuFontPx: data.menuFontPx
    property alias menuBold: data.menuBold
    property alias menuItalic: data.menuItalic
    property alias menuColor: data.menuColor
    property alias menuCommand: data.menuCommand
    property alias menuIconMode: data.menuIconMode
    property alias menuImagePath: data.menuImagePath
    property alias menuImageTint: data.menuImageTint
    property alias showFreshRssPill: data.showFreshRssPill
    property alias showClipboardPill: data.showClipboardPill
    property alias clipboardHistory: data.clipboardHistory
    property alias clipboardMaxItems: data.clipboardMaxItems
    property alias clipboardImages: data.clipboardImages
    property alias menuAction: data.menuAction
    property alias codeAidBuiltIn: data.codeAidBuiltIn
    property alias codeAidCommand: data.codeAidCommand
    property alias codeAidDir: data.codeAidDir
    property alias codeAidCloseOnCopy: data.codeAidCloseOnCopy
    property alias codeAidRecent: data.codeAidRecent
    property alias searchBuiltIn: data.searchBuiltIn
    property alias searchCommand: data.searchCommand
    property alias searchPluginsJson: data.searchPluginsJson
    property alias searchMaxResults: data.searchMaxResults
    property alias searchPlace: data.searchPlace
    property alias searchDim: data.searchDim
    property alias searchTerminal: data.searchTerminal
    property alias searchHistory: data.searchHistory
    property alias searchWebRulesJson: data.searchWebRulesJson
    property alias libraryBuiltIn: data.libraryBuiltIn
    property alias libraryColumns: data.libraryColumns
    property alias libraryIconPx: data.libraryIconPx
    property alias libraryHideFoldered: data.libraryHideFoldered
    property alias libraryShowNames: data.libraryShowNames
    property alias libraryFoldersJson: data.libraryFoldersJson
    property alias defaultAppsKeptJson: data.defaultAppsKeptJson
    property alias showCaffeinePill: data.showCaffeinePill
    property alias showNightLightPill: data.showNightLightPill
    property alias showRecorderPill: data.showRecorderPill
    property alias showFirewallPill: data.showFirewallPill
    property alias showBatteryPill: data.showBatteryPill
    property alias showBrightnessPill: data.showBrightnessPill
    // Caffeine: 0 off, -1 on until turned off, else when it ends (ms since epoch).
    property alias caffeineUntil: data.caffeineUntil
    // Night light (NightLightSettings): Kelvin, schedule on/off, and HH:MM times.
    property alias nightTemp: data.nightTemp
    property alias nightSchedule: data.nightSchedule
    property alias nightStart: data.nightStart
    property alias nightEnd: data.nightEnd
    // Screen recorder (RecorderSettings). Empty or 0 means the default.
    property alias recDir: data.recDir
    property alias recCodec: data.recCodec
    property alias recContainer: data.recContainer
    property alias recQuality: data.recQuality
    property alias recFps: data.recFps
    property alias recAudio: data.recAudio
    property alias recCursor: data.recCursor
    property alias recTarget: data.recTarget
    property alias recNotify: data.recNotify
    property alias showWorkspacesPill: data.showWorkspacesPill
    property alias showStatsWidget: data.showStatsWidget
    property alias statsCombined: data.statsCombined
    property alias audioCombined: data.audioCombined
    property alias showSpeakerPill: data.showSpeakerPill
    property alias showMicPill: data.showMicPill
    property alias showStatCpuPill: data.showStatCpuPill
    property alias showStatMemPill: data.showStatMemPill
    property alias showStatGpuPill: data.showStatGpuPill
    property alias showStatVramPill: data.showStatVramPill
    property alias showStatCpu: data.showStatCpu
    property alias showStatMem: data.showStatMem
    property alias showStatGpu: data.showStatGpu
    property alias showStatVram: data.showStatVram
    property alias showStatGauges: data.showStatGauges
    property alias statGaugeWidth: data.statGaugeWidth
    property alias statTerminal: data.statTerminal
    property alias statGpu: data.statGpu
    property alias statClick: data.statClick
    property alias statActionsJson: data.statActionsJson
    property alias statFont: data.statFont
    property alias statStyleJson: data.statStyleJson
    property alias statFontPercent: data.statFontPercent
    property alias statBold: data.statBold
    property alias statItalic: data.statItalic
    property alias statThresholdsJson: data.statThresholdsJson
    property alias showTrayPill: data.showTrayPill
    property alias showNetworkPanel: data.showNetworkPanel
    property alias showBluetoothPill: data.showBluetoothPill
    property alias showAudioPill: data.showAudioPill
    property alias showVolumePill: data.showVolumePill
    property alias audioScrollStep: data.audioScrollStep
    property alias audioShowPercent: data.audioShowPercent
    property alias audioMeterStreams: data.audioMeterStreams
    property alias audioLimit100: data.audioLimit100
    property alias audioMeterDevices: data.audioMeterDevices
    property alias audioPlaybackOpen: data.audioPlaybackOpen
    property alias audioRecordingOpen: data.audioRecordingOpen
    property alias showClockPill: data.showClockPill
    property alias showNotificationPill: data.showNotificationPill
    property alias notificationAutoExpand: data.notificationAutoExpand
    property alias notificationStaggerRows: data.notificationStaggerRows
    property alias notificationClearOnBoot: data.notificationClearOnBoot
    property alias notificationShowCount: data.notificationShowCount
    property alias notificationCorner: data.notificationCorner
    // Notification server: "" (Auto) or "builtin" (NotificationDaemon).
    property alias notificationServer: data.notificationServer
    // Do Not Disturb for the built-in server.
    property alias notificationDnd: data.notificationDnd
    property alias notificationReadTs: data.notificationReadTs
    // Built-in popup look (PopupSettings), as JSON.
    property alias notificationPopupJson: data.notificationPopupJson
    property alias osdJson: data.osdJson
    property alias notificationTimeout: data.notificationTimeout
    property alias showPowerPill: data.showPowerPill
    property alias showOpacityPill: data.showOpacityPill
    property alias showTailscalePill: data.showTailscalePill
    property alias showHyprInspPill: data.showHyprInspPill
    property alias showControlBarPill: data.showControlBarPill
    property alias showActiveWindowPill: data.showActiveWindowPill
    property alias activeWindowPillCorner: data.activeWindowPillCorner
    property alias activeWindowPillWidth: data.activeWindowPillWidth
    property alias activeWindowShowPid: data.activeWindowShowPid
    property alias activeWindowExcludesJson: data.activeWindowExcludesJson
    property alias clockFormat: data.clockFormat
    property alias clockFont: data.clockFont
    property alias clockFontPercent: data.clockFontPercent
    property alias clockBold: data.clockBold
    property alias clockItalic: data.clockItalic
    property alias clockColor: data.clockColor
    property alias clockWeekStart: data.clockWeekStart
    property alias clockClick: data.clockClick
    property alias opacityQuickshell: data.opacityQuickshell
    property alias opacitySatty: data.opacitySatty
    property alias opacityOverridesJson: data.opacityOverridesJson
    // Settings → Theme: saved themes (ThemeSettings).
    property alias themeLibraryJson: data.themeLibraryJson
    // Quick Launch page: Installed apps open (true) or folded.
    property alias launcherAppsOpen: data.launcherAppsOpen
    // Settings window tabs: "" (index dividers) or "flat"; colors "" (rainbow) or "accent".
    property alias settingsTabStyle: data.settingsTabStyle
    property alias settingsTabColors: data.settingsTabColors
    // FreshRSS reader (FreshRssSettings). The server and password live in
    // ~/.config/freshrss-quickshell/freshrss.env, not here.
    property alias freshRssPollMin: data.freshRssPollMin
    property alias freshRssPerFeed: data.freshRssPerFeed
    property alias freshRssItemLimit: data.freshRssItemLimit
    property alias freshRssMaxDays: data.freshRssMaxDays
    property alias freshRssFiltersOpen: data.freshRssFiltersOpen
    property alias freshRssScope: data.freshRssScope
    property alias freshRssListWidth: data.freshRssListWidth
    property alias freshRssFullFeeds: data.freshRssFullFeeds
    property alias wallpaperDir: data.wallpaperDir
    property alias wallpaperCurrent: data.wallpaperCurrent
    property alias wallpaperTileSize: data.wallpaperTileSize
    property alias wallpaperPickerJson: data.wallpaperPickerJson
    property alias showNetworkFullIp: data.showNetworkFullIp
    property alias showNetworkLastOctet: data.showNetworkLastOctet
    property alias showNetworkDeviceName: data.showNetworkDeviceName
    property alias bluetoothScanSeconds: data.bluetoothScanSeconds
    property alias dockEffect: data.dockEffect
    property alias dockScope: data.dockScope
    property alias dockPercent: data.dockPercent
    property alias dockRadius: data.dockRadius
    property alias dockJump: data.dockJump
    property alias dockDot: data.dockDot
    property alias ovLayout: data.ovLayout
    property alias ovAnchor: data.ovAnchor
    property alias ovGap: data.ovGap
    property alias ovPadding: data.ovPadding
    property alias ovPaddingTop: data.ovPaddingTop
    property alias ovPaddingBottom: data.ovPaddingBottom
    property alias ovMaxScale: data.ovMaxScale
    property alias ovDuration: data.ovDuration
    property alias ovPreviewRound: data.ovPreviewRound
    property alias ovBlur: data.ovBlur
    property alias ovBackdropBlur: data.ovBackdropBlur
    property alias ovSwitchAnimation: data.ovSwitchAnimation
    property alias ovSwitchDuration: data.ovSwitchDuration
    property alias ovMoveAnimation: data.ovMoveAnimation
    property alias ovMoveDuration: data.ovMoveDuration
    property alias ovStripOffset: data.ovStripOffset
    property alias ovStripHeight: data.ovStripHeight
    property alias ovStripWidth: data.ovStripWidth
    property alias ovStripCardMax: data.ovStripCardMax
    property alias ovStripMargin: data.ovStripMargin
    property alias ovStripGap: data.ovStripGap
    property alias ovStripCardRound: data.ovStripCardRound
    property alias ovHoverBorder: data.ovHoverBorder
    property alias ovSelectBorder: data.ovSelectBorder
    property alias ovLivePreviews: data.ovLivePreviews
    property alias ovShowWindowLabels: data.ovShowWindowLabels
    property alias ovShowWsLabels: data.ovShowWsLabels
    property alias ovStripPreviews: data.ovStripPreviews
    property alias ovNumberLabels: data.ovNumberLabels
    property alias ovDynamic: data.ovDynamic
    property alias ovAutodelete: data.ovAutodelete
    property alias ovShowEmpty: data.ovShowEmpty
    property alias ovShowSpecial: data.ovShowSpecial
    property alias ovStripAllCard: data.ovStripAllCard
    property alias ovShowAll: data.ovShowAll
    property alias ovSwitchOnNew: data.ovSwitchOnNew
    property alias ovSwitchOnDrop: data.ovSwitchOnDrop
    property alias ovDragToSwap: data.ovDragToSwap
    property alias ovFocusFollowsMouse: data.ovFocusFollowsMouse
    property alias ovScrollSwitches: data.ovScrollSwitches
    property alias ovExitOnClick: data.ovExitOnClick
    property alias ovExitOnSwitch: data.ovExitOnSwitch
    property alias displayRejectedJson: data.displayRejectedJson

    function symbolClamp(value) {
        let text = String(value || "").trim()
        const chars = Array.from(text)
        if (chars.length > 3)
            text = chars.slice(0, 3).join("")
        return text
    }

    function textClamp(value) {
        let text = String(value || "").trim()
        const chars = Array.from(text)
        if (chars.length > 24)
            text = chars.slice(0, 24).join("")
        return text
    }

    function fontClamp(value) {
        let name = String(value || "").trim()
        if (name.length > 120)
            name = name.substring(0, 120)
        return name
    }

    function fontPxClamp(value) {
        const n = Math.round(Number(value))
        if (n >= 8 && n <= 32)
            return n
        return 0
    }

    function colorNorm(value) {
        let c = String(value || "").trim()
        if (!c.length)
            return ""
        if (c.charAt(0) !== "#")
            c = "#" + c
        if (/^#[0-9a-fA-F]{3}$/.test(c)) {
            c = "#" + c.charAt(1) + c.charAt(1)
                + c.charAt(2) + c.charAt(2)
                + c.charAt(3) + c.charAt(3)
        }
        if (/^#[0-9a-fA-F]{8}$/.test(c))
            c = c.substring(0, 7)
        if (/^#[0-9a-fA-F]{6}$/.test(c))
            return c.toLowerCase()
        return ""
    }

    function touch() {
        root.revision++
    }

    function queueSave() {
        if (!root.ready || root.applying)
            return
        if (root.writing) {
            root.savePending = true
            return
        }
        saveTimer.restart()
    }

    function saveDone() {
        root.writing = false
        if (root.savePending) {
            root.savePending = false
            saveTimer.restart()
        }
    }

    // A number snapped to step, or fallback when outside low–high.
    function stepped(value, low, high, step, fallback) {
        const n = Math.round(Number(value) / step) * step
        return n >= low && n <= high ? n : fallback
    }

    // A text size percent, on the clock's step and range.
    function fontPercentNorm(pct) {
        const step = Math.max(1, Theme.clockFontStep)
        let n = Math.round(Number(pct) / step) * step
        if (!(n >= Theme.clockFontMin))
            n = Theme.clockFontMin
        if (n > Theme.clockFontMax)
            n = Theme.clockFontMax
        return n
    }

    // Threshold steps are 0–100 in steps of 5.
    function bandStep(value) {
        let n = Math.round(Number(value) / 5) * 5
        if (!(n >= 0))
            n = 0
        if (n > 100)
            n = 100
        return n
    }

    // A copy of a { t: [low, mid, high], c: [4 colors] } threshold set with
    // one step moved. The other steps move with it so low ≤ mid ≤ high.
    function withBand(visual, slot, value) {
        const triple = visual.t.slice()
        triple[slot] = root.bandStep(value)
        if (slot === 0) {
            triple[1] = Math.max(triple[1], triple[0])
            triple[2] = Math.max(triple[2], triple[1])
        } else if (slot === 1) {
            triple[0] = Math.min(triple[0], triple[1])
            triple[2] = Math.max(triple[2], triple[1])
        } else {
            triple[1] = Math.min(triple[1], triple[2])
            triple[0] = Math.min(triple[0], triple[1])
        }
        return { t: triple, c: visual.c.slice() }
    }

    // A copy with one color changed, or null when the color is not valid.
    function withColor(visual, slot, color) {
        const hex = ThemeStore.colorHex(color)
        if (!hex.length)
            return null
        const colors = visual.c.slice()
        colors[slot] = hex
        return { t: visual.t.slice(), c: colors }
    }

    // Write several saved fields as one change: one revision bump, one save.
    function saveFields(write) {
        root.applying = true
        try {
            write()
        } finally {
            root.applying = false
        }
        root.touch()
        root.queueSave()
    }

    function programOk(text) {
        const program = String(text || "").trim()
        if (program.length < 1 || program.length > 240)
            return false
        if (program.charAt(0) === "-")
            return false
        return !/[\r\n;&|`$<>\\]/.test(program)
    }

    // A command line to argv: split on spaces, never run through a shell.
    // [] when empty, null when the program or an argument is not allowed.
    function commandArgv(line, maxLength) {
        const raw = String(line || "").trim()
        if (!raw.length)
            return []
        if (raw.length > maxLength)
            return null
        const parts = raw.split(/\s+/)
        if (!root.programOk(parts[0]))
            return null
        const command = [String(parts[0]).trim()]
        for (let i = 1; i < parts.length && command.length < 13; i++) {
            if (!root.argOk(parts[i]))
                return null
            command.push(parts[i])
        }
        return command
    }

    function argOk(text) {
        return /^[A-Za-z0-9_./:@+=,~%-]+$/.test(String(text || ""))
    }

    function iconOk(text) {
        const icon = String(text || "")
        if (!icon.length)
            return true
        if (icon.length > 240)
            return false
        return !/[\r\n;&|`$<>\\]/.test(icon)
    }

    function desktopIdOk(text) {
        return /^[A-Za-z0-9._+-]{1,200}$/.test(String(text || ""))
    }

    Process {
        id: ensureStateDir
        command: ["mkdir", "-p", Quickshell.shellDir + "/state"]
        running: true
        onExited: (exitCode) => {
            store.path = root.storePath
            if (exitCode !== 0)
                root.ready = true
        }
    }

    FileView {
        id: store
        atomicWrites: true
        watchChanges: true
        printErrors: true
        blockLoading: true

        onLoaded: {
            root.ready = true
            root.touch()
        }
        onLoadFailed: {
            root.ready = true
            root.touch()
        }
        onAdapterUpdated: root.queueSave()
        onSaved: root.saveDone()
        onSaveFailed: root.saveDone()
        // Reload edits made outside the bar. Skip while a save of ours is
        // running or waiting, so the newer values in memory are not lost.
        onFileChanged: {
            if (!root.writing && !root.savePending && !saveTimer.running)
                store.reload()
        }
        // qmllint disable unresolved-type
        JsonAdapter {
        // qmllint enable unresolved-type
            id: data
            property bool wsShowSpecialPill: true
            property bool wsShowOnlyActive: false
            property bool wsShowNumbers: true
            property int wsMinimumShown: 3
            property int wsStartupWorkspace: 0
            property bool wsStartupCloseMagic: false
            property bool hasWsSlots: false
            property string wsSpecialNameCustom: ""
            property string wsIconSpecialCustom: ""
            property string wsSpecialFont: ""
            property int wsSpecialFontPx: 0
            property string wsSpecialText: ""
            property bool wsSpecialBold: true
            property bool wsSpecialItalic: false
            property string wsSpecialColor: ""
            property string wsColorMode: ""
            property string barScreenMode: ""
            property string barScreenNames: "[]"
            property string mainScreen: ""
            property string wsActiveBg: ""
            property string wsActiveFg: ""
            property string wsIdleFg: ""
            property string wsHoverFg: ""
            property var wsSlotsJson: []

            property string barLayoutMode: "dual"
            property bool showLeftBar: false
            property bool showRightBar: false
            property bool showTopBar: true
            property bool showBottomBar: false
            property string topBarAlign: "left"
            // Edge → monitor name, or "" for every bar monitor (BarSettings).
            property string barMonitorsJson: ""
            // Monitor → { top, bottom, left, right } px kept clear for TV
            // overscan (DisplaySettings.insetsFor).
            property string displayInsetsJson: ""
            // Monitors turned off in System → Display: name → { spec (to
            // turn it back on as it was), workspaces (to move back) }.
            property string displayOffJson: ""
            property string bottomBarAlign: "left"
            property string leftBarAlign: "left"
            property string rightBarAlign: "left"
            property bool barSpanFull: false
            property bool panelSpanFull: false
            property bool leftBarSpanFull: false
            property bool rightBarSpanFull: false
            property real uiScaleManual: 0
            property bool flushWindowsToBar: false
            property bool topBarAutoHide: false
            property bool bottomBarAutoHide: false
            property bool leftBarAutoHide: false
            property bool rightBarAutoHide: false
            property int barHideDelayMs: 600
            property int barRevealDelayMs: 150
            property string widgetLayoutJson: ""
            property string widgetLayoutDualJson: ""
            property string widgetScalesJson: ""
            property bool showLauncherPill: false
            property bool showQuickLaunchPill: false
            property bool showQuickLaunch2Pill: false
            property bool showQuickLaunch3Pill: false
            property bool showQuickLaunch4Pill: false
            property int launcherCount: 1
            // Four arrays, index 0 is launcher 1. Missing JSON keeps this empty list.
            property string quickLaunchJson: "[]"
            property string menuSymbol: ""
            property string menuFont: ""
            property int menuFontPx: 0
            property bool menuBold: false
            property bool menuItalic: false
            property string menuColor: ""
            property string menuCommand: ""
            property string menuIconMode: "symbol"
            property string menuImagePath: ""
            property bool menuImageTint: false
            property bool showFreshRssPill: false
            property bool showClipboardPill: false
            // Clipboard history (cliphist): keep it, how many entries (0 =
            // default), and whether pictures are kept too.
            property bool clipboardHistory: true
            property int clipboardMaxItems: 0
            property bool clipboardImages: true
            // Code Aid (CodeAidSettings): built in, or a command run instead.
            property bool codeAidBuiltIn: true
            property string codeAidCommand: ""
            property string codeAidDir: ""
            property bool codeAidCloseOnCopy: true
            property bool codeAidRecent: true
            // Application Menu click: "library" (App Library, or menuCommand
            // when the built-in one is off) or "search" (the launcher).
            property string menuAction: "library"
            // Launcher (SearchSettings): built in, or a command run instead.
            property bool searchBuiltIn: true
            property string searchCommand: ""
            property string searchPluginsJson: ""
            property int searchMaxResults: 8
            property string searchPlace: "top"
            property bool searchDim: false
            property string searchTerminal: ""
            property bool searchHistory: true
            property string searchWebRulesJson: ""
            // App Library (LibrarySettings). Off, menuCommand runs instead.
            property bool libraryBuiltIn: true
            property int libraryColumns: 7
            property int libraryIconPx: 64
            property bool libraryHideFoldered: true
            property bool libraryShowNames: true
            property string libraryFoldersJson: ""
            // Default Apps (DefaultAppsSettings): problem keys you chose to keep.
            property string defaultAppsKeptJson: ""
            property bool showCaffeinePill: false
            property bool showNightLightPill: false
            property bool showRecorderPill: false
            property bool showFirewallPill: false
            // On by default: each hides itself without a battery or backlight.
            property bool showBatteryPill: true
            property bool showBrightnessPill: true
            property real caffeineUntil: 0
            property int nightTemp: 0
            property bool nightSchedule: false
            property string nightStart: "20:00"
            property string nightEnd: "07:00"
            property string recDir: ""
            property string recCodec: ""
            property string recContainer: ""
            property string recQuality: ""
            property int recFps: 0
            property string recAudio: ""
            property bool recCursor: true
            property string recTarget: ""
            property bool recNotify: true
            property bool showWorkspacesPill: true
            property bool showStatsWidget: false
            // One System Stats pill, or a widget per metric (the *Pill flags).
            property bool statsCombined: true
            // One Audio pill, or Speaker and Microphone widgets (the *Pill flags).
            property bool audioCombined: true
            property bool showSpeakerPill: true
            property bool showMicPill: true
            property bool showStatCpuPill: true
            property bool showStatMemPill: true
            property bool showStatGpuPill: true
            property bool showStatVramPill: true
            property bool showStatCpu: true
            property bool showStatMem: true
            property bool showStatGpu: true
            property bool showStatVram: true
            property bool showStatGauges: true
            property int statGaugeWidth: 56
            property string statTerminal: "kitty"
            // "auto", "none", or a card name such as "card1" (GpuService).
            property string statGpu: "auto"
            property string statClick: "left"
            property string statActionsJson: ""
            property string statFont: ""
            // Text Style (StatStyle). Empty: built from statFont and the
            // three fields below, which older layouts saved.
            property string statStyleJson: ""
            property int statFontPercent: 100
            property bool statBold: true
            property bool statItalic: false
            property string statThresholdsJson: ""
            property bool showTrayPill: false
            property bool showNetworkPanel: false
            property bool showBluetoothPill: false
            property bool showAudioPill: false
            property bool showVolumePill: false
            property int audioScrollStep: 5
            property bool audioShowPercent: true
            property bool audioMeterStreams: true
            property bool audioLimit100: false
            property bool audioMeterDevices: true
            property bool audioPlaybackOpen: true
            property bool audioRecordingOpen: true
            property bool showClockPill: false
            property bool showNotificationPill: false
            property bool notificationAutoExpand: false
            property bool notificationStaggerRows: true
            property bool notificationClearOnBoot: false
            property bool notificationShowCount: true
            property string notificationCorner: "bottomRight"
            property string notificationServer: ""
            property bool notificationDnd: false
            // Notifications at or before this time (seconds) count as read.
            property real notificationReadTs: 0
            property string notificationPopupJson: ""
            // On-screen display settings (OsdSettings).
            property string osdJson: ""
            property int notificationTimeout: 8
            property bool showPowerPill: false
            property bool showOpacityPill: false
            property bool showTailscalePill: false
            property bool showHyprInspPill: false
            property bool showControlBarPill: true
            property bool showActiveWindowPill: true
            property string activeWindowPillCorner: "topLeft"
            property int activeWindowPillWidth: 640
            property bool activeWindowShowPid: false
            property string activeWindowExcludesJson: "[\"hypr-screensaver\"]"
            property string clockFormat: "dddd, MM·dd·yyyy | HH:mm:ss"
            property string clockFont: ""
            property int clockFontPercent: 100
            property bool clockBold: true
            property bool clockItalic: false
            property string clockColor: ""
            property int clockWeekStart: 0
            property string clockClick: "right"
            // 0 means the theme file's opacity numbers.
            property int opacityQuickshell: 0
            property int opacitySatty: 0
            property string opacityOverridesJson: ""
            property string themeLibraryJson: ""
            property bool launcherAppsOpen: true
            property string settingsTabStyle: ""
            property string settingsTabColors: ""
            property int freshRssPollMin: 0
            property int freshRssPerFeed: 0
            property int freshRssItemLimit: 0
            property int freshRssMaxDays: -1
            property bool freshRssFiltersOpen: true
            property string freshRssScope: ""
            property int freshRssListWidth: 0
            // Feed ids whose articles open as the full web page.
            property var freshRssFullFeeds: []
            property string wallpaperDir: ""
            property string wallpaperCurrent: ""
            property int wallpaperTileSize: 148
            // The Ctrl+Super+Space picker (WallpaperSettings.picker).
            property string wallpaperPickerJson: ""
            property bool showNetworkFullIp: false
            property bool showNetworkLastOctet: true
            property bool showNetworkDeviceName: false
            property int bluetoothScanSeconds: 45
            property string ovLayout: "rows"
            property string ovAnchor: "top"
            property int ovGap: 34
            property int ovPadding: 80
            property int ovPaddingTop: 40
            property int ovPaddingBottom: 70
            property real ovMaxScale: 1
            property int ovDuration: 360
            property int ovPreviewRound: 12
            property real ovBlur: 1
            property bool ovBackdropBlur: false
            property bool ovSwitchAnimation: true
            property int ovSwitchDuration: 260
            property bool ovMoveAnimation: true
            property int ovMoveDuration: 240
            property int ovStripOffset: 0
            property int ovStripHeight: 150
            property int ovStripWidth: 150
            property int ovStripCardMax: 300
            property int ovStripMargin: 22
            property int ovStripGap: 18
            property int ovStripCardRound: 10
            property int ovHoverBorder: 3
            property int ovSelectBorder: 3
            property bool ovLivePreviews: true
            property bool ovShowWindowLabels: true
            property bool ovShowWsLabels: true
            property bool ovStripPreviews: true
            property bool ovNumberLabels: false
            property bool ovDynamic: true
            property bool ovAutodelete: true
            property bool ovShowEmpty: true
            property bool ovShowSpecial: false
            property bool ovStripAllCard: false
            property bool ovShowAll: false
            property bool ovSwitchOnNew: true
            property bool ovSwitchOnDrop: false
            property bool ovDragToSwap: true
            property bool ovFocusFollowsMouse: true
            property bool ovScrollSwitches: true
            property bool ovExitOnClick: true
            property bool ovExitOnSwitch: false
            property string displayRejectedJson: "[]"
            property string dockEffect: "both"
            property string dockScope: "icons"
            property int dockPercent: 128
            property int dockRadius: 72
            property int dockJump: 8
            property string dockDot: "#00f5ff"
        }
    }

    Timer {
        id: saveTimer
        interval: Theme.persistDelayMs
        repeat: false
        onTriggered: {
            if (!root.ready || root.writing)
                return
            root.writing = true
            store.writeAdapter()
        }
    }

    IpcHandler {
        target: "shell"
        function setShowMagicWorkspacePill(enabled: bool): void {
            WorkspaceSettings.setShowSpecial(enabled)
        }
        function toggleShowMagicWorkspacePill(): void {
            WorkspaceSettings.setShowSpecial(!root.showSpecial)
        }
        function setWsMinimumShown(count: string): void {
            WorkspaceSettings.setMinimumShown(count)
        }
        function setWsShowOnlyActive(enabled: bool): void {
            WorkspaceSettings.setShowOnlyActive(enabled)
        }
        function setWsShowNumbers(enabled: bool): void {
            WorkspaceSettings.setShowNumbers(enabled)
        }
        function setWsStartupWorkspace(workspace: string): void {
            WorkspaceSettings.setStartupWorkspace(workspace)
        }
        function setWsStartupCloseMagic(enabled: bool): void {
            WorkspaceSettings.setStartupCloseSpecial(enabled)
        }
    }
}
