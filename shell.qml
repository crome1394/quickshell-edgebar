pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.panels
import qs.services
import qs.theme

ShellRoot {
    id: shell

    // Keeps a saved transparency override applied after a reload.
    property bool opacityWatch: OpacityService.appliedOnce
    // Registers the overview IPC target. The overlay itself stays unloaded until it opens.
    property bool overviewWatch: OverviewService.surfaceLive
    // Registers the notification IPC target. The history watcher starts with the bell.
    property bool notificationWatch: NotificationService.resident
    // Registers the theme IPC target (switch themes from a keybind).
    property string themeWatch: ThemeSettings.format
    // Registers the FreshRSS IPC target and reads its env file. Nothing
    // polls until the pill is on a bar or the reader is open.
    property bool freshRssWatch: FreshRssService.envLoaded

    // The one tooltip window every bar widget shares (TipService).
    BarTipHost {}

    // One set of edge bars per monitor that gets bars (Widgets → Bars →
    // Monitors). An edge that is off is not created.
    Variants {
        model: ScreenService.barScreens
        delegate: ScreenBars {
            onOpenSettings: settings.show()
        }
    }

    SettingsPanel {
        id: settings
    }

    // "Keep this display mode?" while a display change is tried.
    Loader {
        active: DisplayService.pending !== null
        sourceComponent: Component {
            DisplayConfirmPanel {}
        }
    }

    // Popups for the built-in notification server (Settings → Notifications).
    Loader {
        active: BuiltinNotifications.enabled
        sourceComponent: Component {
            NotificationToasts {}
        }
    }

    // The FreshRSS reader exists only while open (pill or qs ipc call freshRss toggle).
    Loader {
        active: FreshRssService.open
        sourceComponent: Component {
            FreshRssPanel {}
        }
    }

    // Exists only while open (qs ipc call inspector toggle), so a closed
    // Inspector reads no files and runs nothing.
    Loader {
        active: InspectorService.open
        sourceComponent: Component {
            InspectorPanel {}
        }
    }

    // Unloaded while the Active Window switch is off.
    Loader {
        active: Config.showActiveWindowPill
        sourceComponent: Component {
            ActiveWindowPanel {
                theme: Theme.palette
            }
        }
    }

    // Screencopy stays out of the shell until the overview is open or still fading.
    Loader {
        active: shell.overviewWatch
        source: active ? Qt.resolvedUrl("panels/OverviewLayer.qml") : ""
    }

    // History anchored to the bell when that pill is on a bar.
    // This host is only for IPC while the bell is off.
    Loader {
        active: NotificationService.historyOpen && !Config.showNotificationPill
        source: active ? Qt.resolvedUrl("panels/NotificationHost.qml") : ""
    }
}
