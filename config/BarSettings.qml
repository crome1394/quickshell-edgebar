pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Which widgets are on the bars, bar alignment, span, and UI scale. The
// widget editor in WidgetService drafts these; apply() saves its state.
Singleton {
    id: root

    // Widget id → saved flag. The BT · Audio row ("connectivity") is gone
    // from the catalog, but its flag still round-trips so Apply keeps it.
    readonly property var widgetFields: ({
        launcher: "showLauncherPill",
        quickLaunch: "showQuickLaunchPill",
        quickLaunch2: "showQuickLaunch2Pill",
        quickLaunch3: "showQuickLaunch3Pill",
        quickLaunch4: "showQuickLaunch4Pill",
        freshRss: "showFreshRssPill",
        clipboard: "showClipboardPill",
        caffeine: "showCaffeinePill",
        nightLight: "showNightLightPill",
        recorder: "showRecorderPill",
        firewall: "showFirewallPill",
        battery: "showBatteryPill",
        brightness: "showBrightnessPill",
        workspaces: "showWorkspacesPill",
        stats: "showStatsWidget",
        statCpu: "showStatCpuPill",
        statMem: "showStatMemPill",
        statGpu: "showStatGpuPill",
        statVram: "showStatVramPill",
        tray: "showTrayPill",
        connectivity: "showAudioPill",
        bluetooth: "showBluetoothPill",
        networkPanel: "showNetworkPanel",
        clock: "showClockPill",
        notifications: "showNotificationPill",
        volume: "showVolumePill",
        audioOut: "showSpeakerPill",
        audioIn: "showMicPill",
        hyprInsp: "showHyprInspPill",
        controlBar: "showControlBarPill",
        tailscale: "showTailscalePill",
        opacity: "showOpacityPill",
        power: "showPowerPill",
        activeWindow: "showActiveWindowPill"
    })

    // Active Window is saved by its own settings page, not the bar editor.
    readonly property var barWidgets: Object.keys(root.widgetFields).filter(id => id !== "activeWindow")

    function isWidget(id) {
        return root.widgetFields[String(id || "")] !== undefined
    }

    function shown(id) {
        const field = root.widgetFields[String(id || "")]
        return field ? !!Config[field] : false
    }

    function setShown(id, enabled) {
        const field = root.widgetFields[String(id || "")]
        const on = !!enabled
        if (!field || !!Config[field] === on)
            return
        Config[field] = on
        Config.touch()
    }

    // Saved flags for every bar widget, keyed by widget id.
    function shownSnapshot() {
        const out = {}
        for (let i = 0; i < root.barWidgets.length; i++)
            out[root.barWidgets[i]] = !!Config[root.widgetFields[root.barWidgets[i]]]
        return out
    }

    readonly property var edges: ["top", "bottom", "left", "right"]
    readonly property var autoHideFields: ({
        top: "topBarAutoHide",
        bottom: "bottomBarAutoHide",
        left: "leftBarAutoHide",
        right: "rightBarAutoHide"
    })

    // Saved auto-hide flag for one edge.
    function autoHides(edge) {
        const field = root.autoHideFields[String(edge || "")]
        return field ? !!Config[field] : false
    }

    // { top, bottom, left, right } → booleans, for the widget editor.
    function autoHideSnapshot() {
        const out = {}
        for (let i = 0; i < root.edges.length; i++)
            out[root.edges[i]] = root.autoHides(root.edges[i])
        return out
    }

    function delayNorm(value, low, high, fallback) {
        const step = Math.max(1, Theme.barDelayStep)
        let n = Math.round(Number(value) / step) * step
        if (isNaN(n))
            n = fallback
        return Math.max(low, Math.min(high, n))
    }

    function hideDelayNorm(value) {
        return root.delayNorm(value, Theme.barHideDelayMin, Theme.barHideDelayMax, 600)
    }

    function revealDelayNorm(value) {
        return root.delayNorm(value, Theme.barRevealDelayMin, Theme.barRevealDelayMax, 150)
    }

    function hideDelayValue() {
        return root.hideDelayNorm(Config.barHideDelayMs)
    }

    function revealDelayValue() {
        return root.revealDelayNorm(Config.barRevealDelayMs)
    }

    function alignNorm(align) {
        const value = String(align || "")
        return value === "left" || value === "right" ? value : "center"
    }

    // Save the widget editor's state: layout, scales, shown flags, bars,
    // alignment, span, auto-hide, UI scale, and flush.
    function apply(state) {
        const src = state || {}
        const shown = src.shown || {}
        let manual = Number(src.uiScaleManual)
        if (!(manual > 0))
            manual = 0
        else
            manual = Math.max(Theme.uiScaleMin, Math.min(Theme.uiScaleMax, manual))
        Config.saveFields(() => {
            Config.widgetLayoutJson = String(src.layout || "[]")
            Config.widgetLayoutDualJson = Config.widgetLayoutJson
            Config.barLayoutMode = "dual"
            Config.widgetScalesJson = String(src.scales || "")
            for (let i = 0; i < root.barWidgets.length; i++) {
                const id = root.barWidgets[i]
                Config[root.widgetFields[id]] = !!shown[id]
            }
            Config.showTopBar = !!src.showTopBar
            Config.showBottomBar = !!src.showBottomBar
            Config.showLeftBar = !!src.showLeftBar
            Config.showRightBar = !!src.showRightBar
            Config.topBarAlign = root.alignNorm(src.topBarAlign)
            Config.bottomBarAlign = root.alignNorm(src.bottomBarAlign)
            Config.leftBarAlign = root.alignNorm(src.leftBarAlign)
            Config.rightBarAlign = root.alignNorm(src.rightBarAlign)
            Config.barSpanFull = !!src.barSpanFull
            Config.panelSpanFull = !!src.panelSpanFull
            Config.leftBarSpanFull = !!src.leftBarSpanFull
            Config.rightBarSpanFull = !!src.rightBarSpanFull
            Config.uiScaleManual = manual
            Config.flushWindowsToBar = !!src.flushWindowsToBar
            const hides = src.autoHide || {}
            for (let e = 0; e < root.edges.length; e++)
                Config[root.autoHideFields[root.edges[e]]] = !!hides[root.edges[e]]
            Config.barHideDelayMs = root.hideDelayNorm(src.hideDelayMs)
            Config.barRevealDelayMs = root.revealDelayNorm(src.revealDelayMs)
        })
    }
}
