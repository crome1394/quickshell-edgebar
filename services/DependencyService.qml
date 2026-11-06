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

    // need: "required" breaks the bar or a core widget, "optional" one feature.
    readonly property var programs: [
        { name: "qs", pkg: "quickshell", area: "Core", need: "required", use: "Runs this bar" },
        { name: "hyprctl", pkg: "hyprland", area: "Core", need: "required", use: "Workspaces, gaps, opacity rules, log out" },
        { name: "python3", pkg: "python", area: "Core", need: "required", use: "Helper scripts: network, notifications, wallpaper, opacity" },
        { name: "bash", pkg: "bash", area: "Core", need: "required", use: "Terminal list for System Stats" },
        { name: "fc-list", pkg: "fontconfig", area: "Core", need: "required", use: "Font pickers in Settings" },
        { name: "find", pkg: "findutils", area: "Core", need: "required", use: "CPU temperature sensor lookup" },
        { name: "systemctl", pkg: "systemd", area: "Core", need: "required", use: "Reboot, power off, Restart Audio, service checks" },
        { name: "xdg-open", pkg: "xdg-utils", area: "Core", need: "optional", use: "Open links (Tailscale login, admin console)" },
        { name: "gtk-launch", pkg: "gtk3", area: "Launchers", need: "required", use: "Start pinned desktop apps" },
        { name: "wpctl", pkg: "wireplumber", area: "Audio", need: "required", use: "Volume changes" },
        { name: "pactl", pkg: "libpulse", area: "Audio", need: "optional", use: "Sound profiles in the audio menu" },
        { name: "pw-top", pkg: "pipewire", area: "Audio", need: "optional", use: "pw-top button in the audio menu" },
        { name: "canberra-gtk-play", pkg: "libcanberra", area: "Audio", need: "optional", use: "Volume change sound" },
        { name: "swayosd-client", pkg: "swayosd", area: "Audio", need: "optional", use: "Volume pop-up" },
        { name: "swaync-client", pkg: "swaync", area: "Notifications", need: "required", use: "Do Not Disturb and the bell" },
        { name: "dbus-monitor", pkg: "dbus", area: "Notifications", need: "required", use: "Notification history" },
        { name: "wl-copy", pkg: "wl-clipboard", area: "Notifications", need: "optional", use: "Copy a notification" },
        { name: "nmcli", pkg: "networkmanager", area: "Network", need: "required", use: "Network menu" },
        { name: "resolvectl", pkg: "systemd", area: "Network", need: "optional", use: "Flush DNS in the network menu" },
        { name: "nvidia-smi", pkg: "nvidia-utils", area: "System Stats", need: "optional", use: "GPU and VRAM readings" },
        { name: "tailscale", pkg: "tailscale", area: "Tailscale", need: "optional", use: "Tailscale widget" },
        { name: "zenity", pkg: "zenity", area: "Tailscale", need: "optional", use: "File picker for Taildrop" },
        { name: "hyprpaper", pkg: "hyprpaper", area: "Wallpaper", need: "optional", use: "Set the wallpaper" },
        { name: "timedatectl", pkg: "systemd", area: "Region", need: "optional", use: "Change the time zone" },
        { name: "hyprlock", pkg: "hyprlock", area: "Power", need: "optional", use: "Lock from the power menu" }
    ]

    readonly property var fonts: [
        { name: "MesloLGS Nerd Font", pkg: "ttf-meslo-nerd", need: "required", use: "Bar text" },
        { name: "Symbols Nerd Font", pkg: "ttf-nerd-fonts-symbols", need: "required", use: "Bar icons" },
        { name: "Inter", pkg: "inter-font", need: "required", use: "Menus and Settings" }
    ]

    // scope "user" runs under systemctl --user.
    readonly property var services: [
        { name: "pipewire", scope: "user", pkg: "pipewire", need: "required", use: "Audio" },
        { name: "wireplumber", scope: "user", pkg: "wireplumber", need: "required", use: "Audio devices and volume" },
        { name: "pipewire-pulse", scope: "user", pkg: "pipewire-pulse", need: "optional", use: "Sound profiles (pactl)" },
        { name: "NetworkManager", scope: "system", pkg: "networkmanager", need: "required", use: "Network widget" },
        { name: "bluetooth", scope: "system", pkg: "bluez", need: "optional", use: "Bluetooth widget" },
        { name: "tailscaled", scope: "system", pkg: "tailscale", need: "optional", use: "Tailscale widget" }
    ]

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
