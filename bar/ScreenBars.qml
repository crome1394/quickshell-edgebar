pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.theme

// The edge bars on one monitor. shell.qml makes one of these for each
// monitor that draws a bar (ScreenService.barHostScreens). An edge that is
// off, or placed on another monitor with its M button, is not created, so
// its widgets do not load.
Scope {
    id: root

    required property ShellScreen modelData

    signal openSettings()

    Loader {
        active: Config.ready && Config.showTopBar && ScreenService.edgeOn("top", String(root.modelData.name))
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "top"
                theme: Theme.barPalette("top")
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showBottomBar && ScreenService.edgeOn("bottom", String(root.modelData.name))
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "bottom"
                theme: Theme.barPalette("bottom")
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showLeftBar && ScreenService.edgeOn("left", String(root.modelData.name))
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "left"
                theme: Theme.barPalette("left")
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showRightBar && ScreenService.edgeOn("right", String(root.modelData.name))
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "right"
                theme: Theme.barPalette("right")
                onOpenSettings: root.openSettings()
            }
        }
    }
}
