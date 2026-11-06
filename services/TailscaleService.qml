pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Tailscale state and actions for the Tailscale pill. Runs only while that
// pill is on the bar (retain/release): a light `tailscale status` check on
// a slow timer, and a full one plus settings and accounts while the menu is
// open. Every command is a fixed argv with checked values, never a shell.
Singleton {
    id: root

    property int watchers: 0
    property bool menuOpen: false

    // CLI presence: unknown until the first command starts or times out.
    property bool checked: false
    property bool available: false

    property string backendState: ""
    readonly property bool running: root.backendState === "Running"
    readonly property bool needsLogin: root.backendState === "NeedsLogin"
    readonly property bool starting: root.backendState === "Starting"
    property string authUrl: ""
    property string version: ""
    property string tailnet: ""
    property string selfName: ""
    property string selfDns: ""
    property string selfIp4: ""
    property string selfIp6: ""
    property string selfUserId: ""
    property bool fileSharing: false
    property var health: []
    property var peers: []
    property var exitNodes: []
    property string exitNodeId: ""

    // `tailscale get --json`, keyed by the `tailscale set` flag names.
    property var prefs: ({})
    property var accounts: []

    property bool busy: false
    property string lastError: ""
    property string notice: ""

    // The switches the menu offers. Each key is a `tailscale set` flag.
    readonly property var options: [
        { key: "accept-dns", label: "Use Tailscale DNS", tip: "MagicDNS names and your tailnet's DNS settings (--accept-dns)" },
        { key: "accept-routes", label: "Accept subnet routes", tip: "Reach subnets other machines advertise (--accept-routes)" },
        { key: "exit-node-allow-lan-access", label: "Allow LAN with exit node", tip: "Keep reaching your local network while an exit node is in use (--exit-node-allow-lan-access)" },
        { key: "shields-up", label: "Shields up", tip: "Block all incoming connections from the tailnet (--shields-up)" },
        { key: "ssh", label: "Tailscale SSH", tip: "Let tailnet machines SSH in, as your tailnet's SSH rules allow (--ssh)" },
        { key: "advertise-exit-node", label: "Offer as exit node", tip: "Let other machines route their internet through this one. Approve it in the admin console. (--advertise-exit-node)" }
    ]

    readonly property var optionKeys: root.options.map(o => o.key)

    function retain() {
        root.watchers += 1
        if (root.watchers === 1)
            root.refresh()
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
    }

    function setMenu(open) {
        root.menuOpen = !!open
        if (root.menuOpen) {
            root.lastError = ""
            root.notice = ""
            root.refresh()
            root.readPrefs()
            root.readAccounts()
        }
    }

    // ---- reading -------------------------------------------------------

    function refresh() {
        if (root.watchers < 1 || statusProc.running)
            return
        statusProc.command = root.menuOpen
            ? ["tailscale", "status", "--json"]
            : ["tailscale", "status", "--json", "--peers=false"]
        statusProc.running = true
        startCheck.restart()
    }

    function readPrefs() {
        if (!prefsProc.running)
            prefsProc.running = true
    }

    function readAccounts() {
        if (!accountsProc.running)
            accountsProc.running = true
    }

    function json(text) {
        try {
            return JSON.parse(String(text || ""))
        } catch (e) {
            return null
        }
    }

    function cleanDns(name) {
        const value = String(name || "")
        return value.endsWith(".") ? value.slice(0, -1) : value
    }

    function ipv4(list) {
        const src = list || []
        for (let i = 0; i < src.length; i++) {
            if (/^100\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(String(src[i])))
                return String(src[i])
        }
        return ""
    }

    function ipv6(list) {
        const src = list || []
        for (let i = 0; i < src.length; i++) {
            if (/^fd7a:115c:a1e0:/i.test(String(src[i])))
                return String(src[i])
        }
        return ""
    }

    // The machine name is the first label of its DNS name, as the admin
    // console shows it. The OS hostname is a fallback ("localhost" on phones).
    function displayName(host, dns) {
        const short = root.cleanDns(dns).split(".")[0]
        if (short.length)
            return short
        const name = String(host || "")
        return name.length && name.toLowerCase() !== "localhost" ? name : "Unknown"
    }

    function peerRow(id, p) {
        const loc = p.Location || null
        const place = loc ? [String(loc.City || ""), String(loc.Country || "")].filter(s => s.length && s !== "Any").join(", ") : ""
        return {
            id: String(id),
            stableId: String(p.ID || ""),
            name: root.displayName(p.HostName, p.DNSName),
            dns: root.cleanDns(p.DNSName),
            ip4: root.ipv4(p.TailscaleIPs),
            ip6: root.ipv6(p.TailscaleIPs),
            os: String(p.OS || ""),
            online: p.Online === true,
            lastSeen: String(p.LastSeen || ""),
            direct: String(p.CurAddr || "").length > 0,
            relay: String(p.Relay || ""),
            active: p.Active === true,
            exitOption: p.ExitNodeOption === true,
            exitActive: p.ExitNode === true,
            mullvad: /\.mullvad\.ts\.net\.?$/i.test(String(p.DNSName || "")),
            place: place,
            taildrop: p.TaildropTarget === 1,
            tags: p.Tags || []
        }
    }

    function applyStatus(text) {
        const d = root.json(text)
        if (!d) {
            root.backendState = ""
            return
        }
        root.backendState = String(d.BackendState || "")
        root.authUrl = /^https:\/\/[^\s"'<>]+$/.test(String(d.AuthURL || "")) ? String(d.AuthURL) : ""
        root.version = String(d.Version || "").split("-")[0]
        root.tailnet = String((d.CurrentTailnet && d.CurrentTailnet.Name) || "")
        const self = d.Self || {}
        root.selfName = root.displayName(self.HostName, self.DNSName)
        root.selfDns = root.cleanDns(self.DNSName)
        root.selfIp4 = root.ipv4(self.TailscaleIPs || d.TailscaleIPs)
        root.selfIp6 = root.ipv6(self.TailscaleIPs || d.TailscaleIPs)
        root.selfUserId = String(self.UserID || "")
        const caps = self.Capabilities || []
        root.fileSharing = caps.indexOf("https://tailscale.com/cap/file-sharing") >= 0
            || !!(self.CapMap && self.CapMap["https://tailscale.com/cap/file-sharing"] !== undefined)
        // "Tailscale is stopped." repeats the state, so it is not a warning.
        root.health = (d.Health || []).map(String).filter(h => h !== "Tailscale is stopped.")
        root.exitNodeId = String((d.ExitNodeStatus && d.ExitNodeStatus.ID) || "")
        if (d.Peer === undefined || d.Peer === null) {
            if (root.menuOpen)
                root.peers = []
            return
        }
        const rows = []
        for (const id in d.Peer)
            rows.push(root.peerRow(id, d.Peer[id] || {}))
        rows.sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name))
        root.peers = rows.filter(r => !r.mullvad)
        root.exitNodes = rows.filter(r => r.exitOption).sort((a, b) => (a.mullvad - b.mullvad) || (a.place || a.name).localeCompare(b.place || b.name))
    }

    // ---- actions -------------------------------------------------------

    function run(args, message) {
        if (actionProc.running) {
            root.lastError = "Busy, try again"
            return
        }
        root.lastError = ""
        root.notice = ""
        root.busy = true
        actionProc.doneMessage = String(message || "")
        actionProc.command = ["tailscale"].concat(args)
        actionProc.running = true
    }

    function toggle() {
        if (root.running || root.starting)
            root.run(["down"], "Tailscale is off")
        else
            root.run(["up"], "Tailscale is on")
    }

    function setOption(key, on) {
        if (root.optionKeys.indexOf(key) < 0)
            return
        root.run(["set", "--" + key + "=" + (on ? "true" : "false")], "")
    }

    function optionOn(key) {
        return String(root.prefs[key]) === "true" || root.prefs[key] === true
    }

    // An empty value clears the exit node. Otherwise it must be the IPv4
    // address of a machine in the exit-node list. Tailscale itself does not
    // check the address while it is stopped.
    function setExitNode(ip) {
        const value = String(ip || "")
        if (value.length && !root.exitNodes.some(n => n.ip4 === value))
            return
        root.run(["set", "--exit-node=" + value], value.length ? "Exit node set" : "Exit node off")
    }

    function switchAccount(id) {
        const value = String(id || "")
        if (!/^[0-9a-f]{1,32}$/i.test(value))
            return
        root.run(["switch", value], "Switched account")
    }

    // Send local files to a peer's inbox. Paths are passed as argv items.
    function sendFiles(paths, peer) {
        if (!peer || !peer.taildrop || !/^100\./.test(peer.ip4))
            return
        const files = (paths || []).map(String).filter(p => p.startsWith("/") && p.indexOf("\n") < 0)
        if (!files.length)
            return
        root.run(["file", "cp"].concat(files).concat([peer.ip4 + ":"]), "Sent to " + peer.name)
    }

    // Ask for files in a zenity window, then send them to the peer.
    function pickAndSend(peer) {
        if (!peer || !peer.taildrop || pickProc.running)
            return
        pickProc.peer = peer
        root.lastError = ""
        pickProc.running = true
        pickCheck.restart()
    }

    function openUrl(url) {
        if (/^https:\/\/[^\s"'<>]+$/.test(String(url || "")))
            Quickshell.execDetached(["xdg-open", String(url)])
    }

    function login() {
        if (root.authUrl.length) {
            root.openUrl(root.authUrl)
            return
        }
        // `up` prints a login URL that the next status check picks up.
        root.run(["up"], "")
    }

    function adminConsole() {
        root.openUrl("https://login.tailscale.com/admin/machines")
    }

    // ---- processes -----------------------------------------------------

    Process {
        id: statusProc
        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
        }
        onStarted: {
            startCheck.stop()
            root.checked = true
            root.available = true
        }
        onExited: root.applyStatus(statusOut.text)
    }

    // A missing CLI never starts, so it never exits either.
    Timer {
        id: startCheck
        interval: Theme.tailscaleStartMs
        onTriggered: {
            if (!statusProc.running && !root.available) {
                root.checked = true
                root.available = false
            }
        }
    }

    Process {
        id: prefsProc
        command: ["tailscale", "get", "--json"]
        stdout: StdioCollector {
            id: prefsOut
            waitForEnd: true
        }
        onExited: {
            const d = root.json(prefsOut.text)
            if (d && typeof d === "object")
                root.prefs = d
        }
    }

    Process {
        id: accountsProc
        command: ["tailscale", "switch", "--list", "--json"]
        stdout: StdioCollector {
            id: accountsOut
            waitForEnd: true
        }
        onExited: {
            const d = root.json(accountsOut.text)
            root.accounts = d && d.length !== undefined ? d : []
        }
    }

    Process {
        id: actionProc
        property string doneMessage: ""
        stdout: StdioCollector {
            id: actionOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: actionErr
            waitForEnd: true
        }
        onExited: (code) => {
            root.busy = false
            if (code !== 0) {
                const text = String(actionErr.text || actionOut.text || "").trim().split("\n")[0]
                root.lastError = text.length ? text.slice(0, 200) : "Tailscale command failed"
            } else {
                root.notice = actionProc.doneMessage
            }
            root.refresh()
            if (root.menuOpen) {
                root.readPrefs()
                root.readAccounts()
            }
        }
    }

    Process {
        id: pickProc
        property var peer: null
        command: ["zenity", "--file-selection", "--multiple", "--separator=\n", "--title=Send with Taildrop"]
        stdout: StdioCollector {
            id: pickOut
            waitForEnd: true
        }
        onStarted: pickCheck.stop()
        onExited: (code) => {
            if (code === 0)
                root.sendFiles(String(pickOut.text || "").split("\n").filter(p => p.length), pickProc.peer)
            pickProc.peer = null
        }
    }

    Timer {
        id: pickCheck
        interval: Theme.tailscaleStartMs
        onTriggered: {
            if (!pickProc.running)
                root.lastError = "Install zenity to pick files to send"
        }
    }

    Timer {
        interval: root.menuOpen ? Theme.tailscaleOpenPollMs : Theme.tailscaleIdlePollMs
        repeat: true
        running: root.watchers > 0 && root.available
        onTriggered: root.refresh()
    }
}
