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
    // Register the caffeine, nightLight, and recorder IPC targets. Night
    // light also needs to load at start to follow its schedule; the others
    // run nothing until used.
    property bool caffeineWatch: CaffeineService.on
    property bool nightWatch: NightLightService.on
    property bool recorderWatch: RecorderService.recording
    // Registers the firewall IPC target; it only reads UFW's files.
    property bool firewallWatch: FirewallService.enabled
    // Registers the clipboard IPC target and keeps the history watcher
    // (one wl-paste) running while history is on.
    property bool clipboardWatch: ClipboardService.recording
    // Registers the wallpaper IPC target (picker, next, previous). Nothing
    // runs until one is used.
    property bool wallpaperWatch: WallpaperService.pickerOpen
    // Registers the display IPC target (turn a monitor off or on). Nothing
    // runs until it is used or the Display page opens.
    property bool displayWatch: DisplayService.busy
    // Register the launcher and App Library IPC targets. Neither has a
    // window until it opens.
    property bool searchWatch: SearchService.open
    property bool libraryWatch: LibraryService.open
    // Registers the Code Aid IPC target; it reads nothing until opened.
    property bool codeAidWatch: CodeAidService.open

    // The one tooltip window every bar widget shares (TipService).
    BarTipHost {}

    // The on-screen display for volume, microphone, media, and brightness
    // (Settings → Notifications → On-Screen Display). Its window exists
    // only while a popup shows.
    OsdHost {}

    // Edge bars on each monitor that draws one (Widgets → Bars → Monitors,
    // and each bar's M button). An edge that is off is not created.
    Variants {
        model: ScreenService.barHostScreens
        delegate: ScreenBars {
            onOpenSettings: settings.show()
        }
    }

    // Space kept clear on the cropped edges of a TV (System → Display →
    // Edges), only on monitors that have an inset.
    Variants {
        model: Quickshell.screens.filter((s) => DisplaySettings.hasInsets(String(s.name)))
        delegate: ScreenInsets {}
    }

    // The frame shown while adjusting an inset.
    Loader {
        active: DisplaySettings.guideMonitor.length > 0
        sourceComponent: Component {
            InsetGuide {}
        }
    }

    SettingsPanel {
        id: settings
    }

    // Caffeine's idle inhibitor, only while Caffeine is on.
    Loader {
        active: CaffeineService.on
        sourceComponent: Component {
            CaffeineInhibitor {}
        }
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

    // The wallpaper picker exists only while open (Ctrl+Super+Space).
    Loader {
        active: WallpaperService.pickerOpen
        sourceComponent: Component {
            WallpaperPicker {}
        }
    }

    // The FreshRSS reader exists only while open (pill or qs ipc call freshRss toggle).
    Loader {
        active: FreshRssService.open
        sourceComponent: Component {
            FreshRssPanel {}
        }
    }

    // The launcher exists only while open (qs ipc call launcher toggle).
    Loader {
        active: SearchService.open
        sourceComponent: Component {
            SearchPanel {}
        }
    }

    // The App Library exists only while open (Application Menu widget, or
    // qs ipc call appLibrary toggle).
    Loader {
        active: LibraryService.open
        sourceComponent: Component {
            LibraryPanel {}
        }
    }

    // Code Aid exists only while open (qs ipc call codeAid toggle).
    Loader {
        active: CodeAidService.open
        sourceComponent: Component {
            CodeAidPanel {}
        }
    }

    // The clipboard viewer exists only while open (qs ipc call clipboard toggle).
    Loader {
        active: ClipboardService.open
        sourceComponent: Component {
            ClipboardPanel {}
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
