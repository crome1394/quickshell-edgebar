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
        workspaces: "showWorkspacesPill",
        stats: "showStatsWidget",
        tray: "showTrayPill",
        connectivity: "showAudioPill",
        bluetooth: "showBluetoothPill",
        networkPanel: "showNetworkPanel",
        clock: "showClockPill",
        notifications: "showNotificationPill",
        volume: "showVolumePill",
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

    function alignNorm(align) {
        const value = String(align || "")
        return value === "left" || value === "right" ? value : "center"
    }

    // Save the widget editor's state: layout, scales, shown flags, bars,
    // alignment, span, UI scale, and flush.
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
        })
    }
}
