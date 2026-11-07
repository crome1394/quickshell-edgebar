pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.theme

// The edge bars on one monitor. shell.qml makes one of these for each
// monitor ScreenService.barScreens lists. An edge that is off is not
// created, so its widgets do not load.
Scope {
    id: root

    required property ShellScreen modelData

    signal openSettings()

    Loader {
        active: Config.ready && Config.showTopBar
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "top"
                theme: Theme.palette
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showBottomBar
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "bottom"
                theme: Theme.palette
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showLeftBar
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "left"
                theme: Theme.palette
                onOpenSettings: root.openSettings()
            }
        }
    }

    Loader {
        active: Config.ready && Config.showRightBar
        sourceComponent: Component {
            EdgeBar {
                screen: root.modelData
                screenName: String(root.modelData.name)
                edge: "right"
                theme: Theme.palette
                onOpenSettings: root.openSettings()
            }
        }
    }
}
