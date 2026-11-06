pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.bar
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

    // A bar that is turned off is not created, so its widgets do not load.
    Loader {
        active: Config.ready && Config.showTopBar
        sourceComponent: Component {
            EdgeBar {
                edge: "top"
                theme: Theme.palette
                onOpenSettings: settings.show()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showBottomBar
        sourceComponent: Component {
            EdgeBar {
                edge: "bottom"
                theme: Theme.palette
                onOpenSettings: settings.show()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showLeftBar
        sourceComponent: Component {
            EdgeBar {
                edge: "left"
                theme: Theme.palette
                onOpenSettings: settings.show()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showRightBar
        sourceComponent: Component {
            EdgeBar {
                edge: "right"
                theme: Theme.palette
                onOpenSettings: settings.show()
            }
        }
    }

    SettingsPanel {
        id: settings
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
