import QtQuick
import Quickshell
import qs.config
import qs.services
import "tests"

// ScreenService: which monitors get bars, the main monitor, and which bar
// owns a menu. Uses the monitors of the session it runs in.
ShellRoot {
    Check { id: t }

    Timer {
        interval: 300
        running: Config.ready
        onTriggered: {
            const S = ScreenService
            const main = S.mainName
            t.ok("a main monitor exists", main.length > 0)
            t.eq("main mode by default", S.mode, "main")
            t.eq("main mode: one set of bars", S.barScreens.length, 1)
            t.eq("IPC menus open on main", S.owns("", main), true)
            t.eq("a click opens on its own monitor", S.owns("OTHER-1", main), false)
            S.setMode("pick")
            t.eq("pick with nothing picked falls back to main", S.barScreens.map((s) => String(s.name)), [main])
            S.togglePicked(main)
            t.eq("picking a monitor", S.picked, [main])
            S.togglePicked("NOT-CONNECTED")
            t.eq("unknown monitors are ignored", S.picked, [main])
            S.togglePicked(main)
            t.eq("unpicking", S.picked, [])
            S.setMode("all")
            t.eq("all mode", S.barScreens.length, Quickshell.screens.length)
            S.setMain("NOT-CONNECTED")
            t.eq("unknown main is ignored", S.mainName, main)
            S.setMode("sideways")
            t.eq("unknown modes are ignored", S.mode, "all")

            AudioMenuService.toggle("A")
            t.eq("menu opens on the clicked monitor", [AudioMenuService.open, AudioMenuService.screen], [true, "A"])
            AudioMenuService.toggle("B")
            t.eq("a click on another monitor moves it", [AudioMenuService.open, AudioMenuService.screen], [true, "B"])
            AudioMenuService.toggle("B")
            t.eq("a second click closes it", AudioMenuService.open, false)
            t.done()
        }
    }
}
