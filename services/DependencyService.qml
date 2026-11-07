pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// The programs, fonts, and services the bar relies on, and whether each is
// present. Nothing runs until check() is called (Settings → System →
// Dependencies). A missing program does not break the bar loudly; the widget
// that needs it just does nothing, so this list makes that visible.
Singleton {
    id: root

    // The lists live in config/dependencies.json, shared with
    // scripts/install-deps.sh. need: "required" breaks the bar or a core
    // widget, "optional" one feature. A service's scope "user" runs under
    // systemctl --user.
    // Every program in the file, and those that apply to your setup:
    // entries with when "swaync" show only while SwayNC is the server in
    // use (chosen, or found by Auto); entries with when "nvidia" only when
    // an NVIDIA card is present; "laptop" only with a battery or backlight.
    property var allPrograms: []
    readonly property var programs: root.allPrograms.filter((p) => (p.when !== "swaync" || NotificationDaemon.mode === "swaync")
        && (p.when !== "nvidia" || GpuService.cards.some((c) => c.vendor === "NVIDIA"))
        && (p.when !== "laptop" || BatteryService.present || BrightnessService.available))
    property var fonts: []
    property var services: []

    function readList(text) {
        let data = {}
        try {
            data = JSON.parse(String(text || "{}")) || {}
        } catch (e) {
            data = {}
        }
        root.allPrograms = Array.isArray(data.programs) ? data.programs : []
        root.fonts = Array.isArray(data.fonts) ? data.fonts : []
        root.services = Array.isArray(data.services) ? data.services : []
    }

    FileView {
        id: listFile
        path: Quickshell.shellDir + "/config/dependencies.json"
        blockLoading: true
        printErrors: true
        onLoaded: root.readList(listFile.text())
        onLoadFailed: root.readList("")
    }

    property bool checking: false
    property bool checkedOnce: false
    property var found: ({})        // program name → path, "" when missing
    property var fontFound: ({})    // font family → true
    property var serviceState: ({}) // service name → "active", "inactive", …
    property var settingRows: []    // programs named in your own settings

    // Programs your settings point at: the System Stats click commands,
    // their terminal, and the Application Menu command.
    function settingPrograms() {
        const out = []
        const seen = {}
        function add(program, use) {
            const name = String(program || "")
            if (!name.length || seen[name])
                return
            seen[name] = true
            out.push({ name: name, pkg: "", area: "Your settings", need: "optional", use: use })
        }
        const actions = StatsSettings.savedActions()
        let usesTerminal = false
        for (let i = 0; i < StatsSettings.actionSlots.length; i++) {
            const slot = StatsSettings.actionSlots[i]
            const argv = Config.commandArgv(actions[slot.id].cmd, Theme.menuCommandMax)
            if (argv && argv.length) {
                add(argv[0], slot.label)
                usesTerminal = usesTerminal || actions[slot.id].term
            }
        }
        if (usesTerminal)
            add(StatsSettings.terminalValue(), "Terminal for System Stats clicks and pw-top")
        const menu = MenuSettings.savedArgv()
        if (menu && menu.length)
            add(menu[0], "Application Menu command")
        return out
    }

    function check() {
        if (root.checking)
            return
        // The page can ask before the file's loaded signal arrives.
        if (!root.allPrograms.length)
            root.readList(listFile.text())
        root.checking = true
        root.settingRows = root.settingPrograms()
        const names = root.programs.map(p => p.name).concat(root.settingRows.map(p => p.name))
        // Names are passed as arguments, never pasted into the script.
        whichProc.command = ["sh", "-c", "for p do printf '%s\\t%s\\n' \"$p\" \"$(command -v -- \"$p\")\"; done", "sh"].concat(names)
        whichProc.running = true
        fontProc.running = true
        userProc.command = ["systemctl", "--user", "is-active"].concat(root.services.filter(s => s.scope === "user").map(s => s.name))
        systemProc.command = ["systemctl", "is-active"].concat(root.services.filter(s => s.scope === "system").map(s => s.name))
        userProc.running = true
        systemProc.running = true
        giveUp.restart()
    }

    function finish() {
        if (whichProc.running || fontProc.running || userProc.running || systemProc.running)
            return
        giveUp.stop()
        root.checking = false
        root.checkedOnce = true
    }

    // A tool that is itself missing never starts, so it never finishes;
    // stop waiting and show what was found.
    Timer {
        id: giveUp
        interval: Theme.dependencyTimeoutMs
        onTriggered: {
            root.checking = false
            root.checkedOnce = true
        }
    }

    function readStates(text, scope) {
        const names = root.services.filter(s => s.scope === scope).map(s => s.name)
        const lines = String(text || "").split("\n")
        const next = Object.assign({}, root.serviceState)
        for (let i = 0; i < names.length; i++)
            next[names[i]] = String(lines[i] || "unknown").trim()
        root.serviceState = next
    }

    // Rows that are missing, for the summary and the install line.
    function missingPrograms() {
        return root.programs.concat(root.settingRows).filter(p => root.checkedOnce && !root.found[p.name])
    }

    function missingFonts() {
        return root.fonts.filter(f => root.checkedOnce && !root.fontFound[f.name])
    }

    function stoppedServices() {
        return root.services.filter(s => root.checkedOnce && root.serviceState[s.name] !== "active")
    }

    // One pacman line for every missing package that has a known name.
    function installLine() {
        const pkgs = []
        const all = root.missingPrograms().concat(root.missingFonts())
        for (let i = 0; i < all.length; i++) {
            const pkg = String(all[i].pkg || "")
            if (pkg.length && pkgs.indexOf(pkg) < 0)
                pkgs.push(pkg)
        }
        return pkgs.length ? "sudo pacman -S --needed " + pkgs.join(" ") : ""
    }

    Process {
        id: whichProc
        stdout: StdioCollector {
            id: whichOut
            waitForEnd: true
        }
        onExited: {
            const next = {}
            const lines = String(whichOut.text || "").split("\n")
            for (let i = 0; i < lines.length; i++) {
                const tab = lines[i].indexOf("\t")
                if (tab > 0)
                    next[lines[i].slice(0, tab)] = lines[i].slice(tab + 1).trim()
            }
            root.found = next
            root.finish()
        }
    }

    Process {
        id: fontProc
        command: ["fc-list", ":", "family"]
        stdout: StdioCollector {
            id: fontOut
            waitForEnd: true
        }
        onExited: {
            const have = {}
            const lines = String(fontOut.text || "").split("\n")
            for (let i = 0; i < lines.length; i++) {
                const families = lines[i].split(",")
                for (let j = 0; j < families.length; j++)
                    have[families[j].trim()] = true
            }
            const next = {}
            for (let k = 0; k < root.fonts.length; k++)
                next[root.fonts[k].name] = !!have[root.fonts[k].name]
            root.fontFound = next
            root.finish()
        }
    }

    Process {
        id: userProc
        stdout: StdioCollector {
            id: userOut
            waitForEnd: true
        }
        onExited: {
            root.readStates(userOut.text, "user")
            root.finish()
        }
    }

    Process {
        id: systemProc
        stdout: StdioCollector {
            id: systemOut
            waitForEnd: true
        }
        onExited: {
            root.readStates(systemOut.text, "system")
            root.finish()
        }
    }
}
