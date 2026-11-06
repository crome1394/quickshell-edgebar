pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.theme

Singleton {
    id: service

    property bool specialActive: false
    property var shown: []
    property string _shownSig: ""
    property int _coldPolls: 0
    property int _startupAttempts: 0
    property bool _startupFinished: false

    function hasWindows(workspace) {
        if (!workspace || !workspace.toplevels)
            return false
        const tops = workspace.toplevels
        if (typeof tops.count === "number")
            return tops.count > 0
        if (tops.values && typeof tops.values.length === "number")
            return tops.values.length > 0
        return false
    }

    function setSpecialActive(active) {
        const next = !!active
        if (service.specialActive === next)
            return
        service.specialActive = next
        service.rebuild()
    }

    function syncSpecialFromMonitor() {
        const mon = Hyprland.focusedMonitor
        if (!mon || !mon.lastIpcObject)
            return
        const sw = mon.lastIpcObject.specialWorkspace
        const name = sw ? (sw.name || "") : ""
        service.setSpecialActive(name.length > 0 && WorkspaceSettings.isSpecialName(name))
    }

    function requestSpecialSync() {
        try {
            Hyprland.refreshMonitors()
        } catch (e) {
        }
        specialTimer.restart()
    }

    function dispatch(command) {
        try {
            Hyprland.dispatch(command)
        } catch (e) {
        }
    }

    function toggleSpecial(name) {
        const safe = WorkspaceSettings.nameNorm(name)
        const resolved = safe.length ? safe : WorkspaceSettings.defaultSpecialName
        service.dispatch("hl.dsp.workspace.toggle_special('" + resolved + "')")
    }

    function rebuild() {
        const byId = {}
        const values = (Hyprland.workspaces && Hyprland.workspaces.values)
            ? Hyprland.workspaces.values : []
        for (let i = 0; i < values.length; i++) {
            const workspace = values[i]
            if (!workspace || workspace.id <= 0)
                continue
            byId[workspace.id] = workspace
        }

        const focused = Hyprland.focusedWorkspace
        const focusedId = (focused && focused.id > 0) ? focused.id : 0
        const slots = WorkspaceSettings.effectiveSlots()
        const inSlot = {}
        const result = []
        if (Config.showSpecial)
            result.push({ id: -1, isSpecial: true, active: service.specialActive })

        for (let i = 0; i < slots.length; i++) {
            const id = slots[i].id
            inSlot[id] = true
            const workspace = byId[id]
            const occupied = workspace && (service.hasWindows(workspace) || workspace.active || workspace.focused)
            if (Config.showOnlyActive && !occupied && focusedId !== id)
                continue
            result.push({
                id: id,
                isSpecial: false,
                active: focusedId === id || !!(workspace && (workspace.active || workspace.focused))
            })
        }

        const keys = Object.keys(byId)
        for (let i = 0; i < keys.length; i++) {
            const id = Number(keys[i])
            if (inSlot[id])
                continue
            const workspace = byId[id]
            if (service.hasWindows(workspace) || workspace.active || workspace.focused) {
                result.push({
                    id: id,
                    isSpecial: false,
                    active: focusedId === id || !!(workspace && (workspace.active || workspace.focused))
                })
            }
        }
        const specials = []
        const numbered = []
        for (let i = 0; i < result.length; i++) {
            if (result[i].isSpecial)
                specials.push(result[i])
            else
                numbered.push(result[i])
        }
        numbered.sort(function(a, b) { return a.id - b.id })
        const shown = specials.concat(numbered)

        const sig = JSON.stringify(shown)
        if (sig === service._shownSig)
            return
        service._shownSig = sig
        service.shown = shown
    }

    function floorId() {
        const slots = WorkspaceSettings.effectiveSlots()
        if (!slots.length)
            return 1
        let floor = slots[0].id
        for (let i = 1; i < slots.length; i++)
            floor = Math.min(floor, slots[i].id)
        return floor
    }

    function activate(entry) {
        if (!entry)
            return
        const name = WorkspaceSettings.resolvedSpecialName()
        if (entry.isSpecial) {
            service.toggleSpecial(name)
            return
        }
        if (!(entry.id > 0))
            return
        if (service.specialActive)
            service.toggleSpecial(name)
        const focused = Hyprland.focusedWorkspace
        if (focused && focused.id === entry.id)
            return
        service.dispatch("hl.dsp.focus({ workspace = " + entry.id + " })")
    }

    // Same order as ~/.local/bin/cycle-workspace.sh: specials sit in front.
    // Right from the special closes it and leaves the numbered workspace underneath.
    function switchRelative(delta) {
        const name = WorkspaceSettings.resolvedSpecialName()
        if (service.specialActive) {
            if (delta > 0)
                service.toggleSpecial(name)
            return
        }
        const focused = Hyprland.focusedWorkspace
        const wsId = (focused && focused.id > 0) ? focused.id : service.floorId()
        if (delta > 0) {
            service.dispatch("hl.dsp.focus({ workspace = \"+1\" })")
            return
        }
        if (wsId <= service.floorId())
            service.toggleSpecial(name)
        else
            service.dispatch("hl.dsp.focus({ workspace = \"-1\" })")
    }

    function maybeStart() {
        if (service._startupFinished || !Config.ready)
            return
        if (Config.startupWorkspace <= 0) {
            service._startupFinished = true
            return
        }
        service._startupAttempts = 0
        startupTimer.start()
    }

    function runStartup() {
        const target = Config.startupWorkspace
        if (target <= 0) {
            startupTimer.stop()
            service._startupFinished = true
            return
        }
        service._startupAttempts += 1
        service.requestSpecialSync()
        const focused = Hyprland.focusedWorkspace
        const focusedId = (focused && focused.id > 0) ? focused.id : 0
        let magicOpen = false
        if (Config.startupCloseSpecial) {
            const mon = Hyprland.focusedMonitor
            const sw = (mon && mon.lastIpcObject) ? mon.lastIpcObject.specialWorkspace : null
            const magicName = sw ? (sw.name || "") : ""
            magicOpen = magicName.length > 0 && WorkspaceSettings.isSpecialName(magicName)
            if (magicOpen)
                service.toggleSpecial(WorkspaceSettings.resolvedSpecialName())
        }
        if (focusedId !== target)
            service.dispatch("hl.dsp.focus({ workspace = " + target + " })")
        if ((!magicOpen && focusedId === target) || service._startupAttempts >= 4) {
            startupTimer.stop()
            service._startupFinished = true
            service._startupAttempts = 0
        }
    }

    function onHyprEvent(event) {
        if (!event)
            return
        const name = event.name
        if (name === "activespecial" || name === "activespecialv2") {
            const argc = name === "activespecialv2" ? 3 : 2
            let args = []
            try {
                args = event.parse(argc) || []
            } catch (e) {
                return
            }
            const wsName = name === "activespecialv2" ? (args[1] || "") : (args[0] || "")
            const monName = name === "activespecialv2" ? (args[2] || "") : (args[1] || "")
            const mon = Hyprland.focusedMonitor
            if (monName && mon && mon.name && monName !== mon.name)
                return
            service.setSpecialActive(String(wsName || "").length > 0 && WorkspaceSettings.isSpecialName(wsName))
            service.requestSpecialSync()
            return
        }
        if (name === "configreloaded") {
            try {
                Hyprland.refreshWorkspaces()
            } catch (e2) {
            }
            service.requestSpecialSync()
            service.rebuild()
            return
        }
        if (name === "workspace" || name === "workspacev2"
                || name === "focusedmon" || name === "focusedmonv2"
                || name === "createworkspace" || name === "createworkspacev2"
                || name === "destroyworkspace" || name === "destroyworkspacev2"
                || name === "moveworkspace" || name === "moveworkspacev2"
                || name === "activewindow" || name === "activewindowv2"
                || name === "renameworkspace"
                || name === "movewindow" || name === "movewindowv2"
                || name === "openwindow" || name === "closewindow") {
            service.rebuild()
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { service.rebuild() }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            service.requestSpecialSync()
            service.rebuild()
        }
        function onActiveToplevelChanged() { service.rebuild() }
        function onFocusedMonitorChanged() {
            service.requestSpecialSync()
            service.rebuild()
        }
        function onRawEvent(event) { service.onHyprEvent(event) }
    }

    Connections {
        target: Hyprland.focusedMonitor
        function onLastIpcObjectChanged() { service.syncSpecialFromMonitor() }
    }

    Connections {
        target: Config
        function onRevisionChanged() {
            service.rebuild()
            service.maybeStart()
        }
        function onReadyChanged() { service.maybeStart() }
    }

    Timer {
        id: specialTimer
        interval: Theme.specialSyncMs
        repeat: false
        onTriggered: {
            service.syncSpecialFromMonitor()
            service.rebuild()
        }
    }

    Timer {
        id: startupTimer
        interval: Theme.startupAttemptMs
        repeat: true
        running: false
        onTriggered: service.runStartup()
    }

    Timer {
        id: coldTimer
        interval: Theme.workspaceColdPollMs
        repeat: true
        running: true
        onTriggered: {
            service.requestSpecialSync()
            service.rebuild()
            service._coldPolls += 1
            if (service._coldPolls >= Theme.workspaceColdPolls)
                coldTimer.stop()
        }
    }

    // Safety net only. Hyprland events above drive normal updates.
    Timer {
        interval: Theme.workspaceHeartbeatMs
        repeat: true
        running: true
        onTriggered: {
            try {
                Hyprland.refreshWorkspaces()
            } catch (e) {
            }
            service.syncSpecialFromMonitor()
            service.rebuild()
        }
    }

    Component.onCompleted: {
        service.requestSpecialSync()
        service.rebuild()
        service.maybeStart()
    }
}
