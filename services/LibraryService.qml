pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The App Library (Pop's application library): whether it is open.
// shell.qml creates LibraryPanel only while open. With the built-in
// library off (Settings → Applications → App Library), toggling runs the
// Application Menu command instead.
Singleton {
    id: root

    property bool open: false

    function toggle() {
        if (root.open)
            root.hide()
        else
            root.show()
    }

    function show() {
        if (!LibrarySettings.builtIn()) {
            const argv = MenuSettings.savedArgv()
            if (argv && argv.length)
                Quickshell.execDetached(argv)
            return
        }
        SearchService.hide()
        root.open = true
    }

    function hide() {
        root.open = false
    }

    // qs ipc call appLibrary toggle | open | close   (same as the Application Menu widget)
    IpcHandler {
        target: "appLibrary"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
