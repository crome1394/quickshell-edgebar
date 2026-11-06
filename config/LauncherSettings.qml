pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Applications → App Launcher: how many launchers there are and the pins
// on each. Pins are desktop ids or argv commands, never shell lines.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function countNorm(value) {
        let count = Math.round(Number(value))
        if (!(count >= Theme.launcherMin))
            count = Theme.launcherMin
        return Math.min(count, Theme.launcherMax)
    }

    function pinKey(row) {
        if (!row)
            return ""
        const id = String(row.id || "")
        if (id.length)
            return "desk:" + id
        const command = row.command || []
        const parts = []
        for (let i = 0; i < command.length; i++)
            parts.push(String(command[i] || ""))
        return "cmd:" + parts.join("\n")
    }

    function cleanPin(row) {
        if (!row)
            return null
        const name = String(row.name || "").replace(/[\r\n]/g, " ").trim().slice(0, 80)
        if (!name.length)
            return null
        const icon = String(row.icon || "")
        if (!Config.iconOk(icon))
            return null
        const id = String(row.id || "")
        if (id.length) {
            if (!Config.desktopIdOk(id))
                return null
            return { id: id, name: name, icon: icon, command: [] }
        }
        const raw = row.command || []
        if (!raw.length)
            return null
        const program = String(raw[0] || "").trim()
        if (!Config.programOk(program))
            return null
        const command = [program]
        for (let i = 1; i < raw.length && command.length < 13; i++) {
            const token = String(raw[i] || "")
            if (!Config.argOk(token))
                return null
            command.push(token)
        }
        return { id: "", name: name, icon: icon, command: command }
    }

    // Four clean boards: pins checked, duplicates dropped, each capped.
    function cleanBoards(boards) {
        const clean = [[], [], [], []]
        const src = boards || []
        for (let b = 0; b < clean.length; b++) {
            const list = src[b] || []
            if (!list || list.length === undefined)
                continue
            const seen = {}
            for (let i = 0; i < list.length && clean[b].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(list[i])
                if (!pin)
                    continue
                const key = root.pinKey(pin)
                if (seen[key])
                    continue
                seen[key] = true
                clean[b].push(pin)
            }
        }
        return clean
    }

    // Saved JSON to boards. A flat list from an older layout becomes Launcher 1.
    function parseBoards(raw) {
        let parsed = []
        try {
            parsed = JSON.parse(String(raw || "[]"))
        } catch (e) {
            parsed = []
        }
        const boards = [[], [], [], []]
        if (!parsed || parsed.length === undefined)
            return boards
        const first = parsed.length ? parsed[0] : null
        const nested = !!(first && first.length !== undefined && first.id === undefined && first.name === undefined)
        if (!nested) {
            for (let i = 0; i < parsed.length && boards[0].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(parsed[i])
                if (pin)
                    boards[0].push(pin)
            }
            return boards
        }
        for (let b = 0; b < boards.length && b < parsed.length; b++) {
            const list = parsed[b] || []
            if (!list || list.length === undefined)
                continue
            const seen = {}
            for (let i = 0; i < list.length && boards[b].length < Theme.launcherPinMax; i++) {
                const pin = root.cleanPin(list[i])
                if (!pin)
                    continue
                const key = root.pinKey(pin)
                if (seen[key])
                    continue
                seen[key] = true
                boards[b].push(pin)
            }
        }
        return boards
    }

    // Saved values, for the bar.
    function slots() {
        return root.countNorm(Config.launcherCount)
    }

    function savedBoards() {
        return root.parseBoards(Config.quickLaunchJson)
    }

    // The draft, for the settings page. draftBoards() is a copy the page
    // may change and pass back to setBoards().
    function draftSlots() {
        return root.editor.value.count
    }

    function draftBoards() {
        return JSON.parse(JSON.stringify(root.editor.value.boards))
    }

    function setBoards(boards) {
        root.editor.set("boards", boards)
    }

    function setCount(value) {
        root.editor.set("count", value)
    }

    function normalize(src) {
        return {
            count: root.countNorm(src.count),
            boards: root.cleanBoards(src.boards)
        }
    }

    function snapshot() {
        return root.normalize({ count: Config.launcherCount, boards: root.savedBoards() })
    }

    function defaults() {
        return { count: Theme.launcherMin, boards: [[], [], [], []] }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.launcherCount = clean.count
            Config.quickLaunchJson = JSON.stringify(clean.boards)
        })
    }
}
