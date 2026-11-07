pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The UFW firewall (CachyOS's default). Status, default policies, and the
// rules are read from UFW's own files, which anyone can read, so looking
// needs no password and nothing polls: the files are watched. Changes
// (enable, disable, add or delete a rule) run "pkexec /usr/bin/ufw …" with
// a fixed argv built from checked values, so the polkit agent asks for
// your password each time.
//
//   qs ipc call firewall status | enable | disable | toggle
Singleton {
    id: root

    readonly property bool available: confFile.loaded || rulesFile.loaded
    property bool enabled: false
    property string logging: ""
    property var policy: ({ input: "", output: "", forward: "" })
    property var rules: []
    property bool busy: false
    property string error: ""
    property string notice: ""

    readonly property var actions: ["allow", "deny", "reject", "limit"]

    // ── Reading ─────────────────────────────────────────────────────────
    function readConf(text) {
        const m = /^ENABLED=(\w+)/m.exec(String(text || ""))
        root.enabled = !!m && m[1].toLowerCase() === "yes"
        const l = /^LOGLEVEL=(\w+)/m.exec(String(text || ""))
        root.logging = l ? l[1] : ""
    }

    function readDefaults(text) {
        const word = (key) => {
            const m = new RegExp("^DEFAULT_" + key + "_POLICY=\"?(\\w+)\"?", "m").exec(String(text || ""))
            if (!m)
                return ""
            const v = m[1].toUpperCase()
            return v === "ACCEPT" ? "allow" : (v === "DROP" ? "deny" : v === "REJECT" ? "reject" : v.toLowerCase())
        }
        root.policy = { input: word("INPUT"), output: word("OUTPUT"), forward: word("FORWARD") }
    }

    // UFW writes one "### tuple ###" comment per rule:
    //   ### tuple ### allow tcp 22 0.0.0.0/0 any 192.168.1.0/24 in
    // action proto dport dst sport src [app names] direction [comment=hex]
    function parseTuples(text, v6) {
        const out = []
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const m = /^### tuple ### (.+)$/.exec(lines[i].trim())
            if (!m)
                continue
            const t = m[1].split(/\s+/).filter((x) => !x.startsWith("comment="))
            if (t.length < 7 || root.actions.indexOf(t[0].replace(/_(log|log-all)$/, "")) < 0)
                continue
            const direction = t.indexOf("out") > 5 ? "out" : "in"
            out.push({
                action: t[0].replace(/_(log|log-all)$/, ""),
                proto: t[1],
                port: t[2],
                to: t[3],
                fromPort: t[4],
                from: t[5],
                direction: direction,
                v6: !!v6
            })
        }
        return out
    }

    // v4 and v6 copies of the same rule show once, marked with both.
    function mergeRules(v4, v6) {
        const key = (r) => [r.action, r.proto, r.port, r.fromPort, r.direction, root.anyAddr(r.from) ? "any" : r.from, root.anyAddr(r.to) ? "any" : r.to].join("|")
        const out = v4.map((r) => Object.assign({}, r, { families: ["v4"] }))
        for (let i = 0; i < v6.length; i++) {
            const twin = out.find((r) => key(r) === key(v6[i]))
            if (twin)
                twin.families = ["v4", "v6"]
            else
                out.push(Object.assign({}, v6[i], { families: ["v6"] }))
        }
        return out
    }

    function anyAddr(a) {
        return a === "0.0.0.0/0" || a === "::/0" || a === "any"
    }

    // "22/tcp", "8000:8100/udp", "any port", for the menu.
    function describePort(r) {
        if (r.port === "any")
            return r.proto === "any" ? "any port" : "any " + r.proto
        return r.port + (r.proto === "any" ? "" : "/" + r.proto)
    }

    property string v4Text: ""
    property string v6Text: ""

    function rebuild() {
        root.rules = root.mergeRules(root.parseTuples(root.v4Text, false), root.parseTuples(root.v6Text, true))
    }

    function reloadAll() {
        confFile.reload()
        defaultsFile.reload()
        rulesFile.reload()
        rules6File.reload()
    }

    FileView {
        id: confFile
        path: "/etc/ufw/ufw.conf"
        watchChanges: true
        printErrors: false
        onLoaded: root.readConf(confFile.text())
        onFileChanged: confFile.reload()
    }

    FileView {
        id: defaultsFile
        path: "/etc/default/ufw"
        watchChanges: true
        printErrors: false
        onLoaded: root.readDefaults(defaultsFile.text())
        onFileChanged: defaultsFile.reload()
    }

    FileView {
        id: rulesFile
        path: "/etc/ufw/user.rules"
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.v4Text = rulesFile.text()
            root.rebuild()
        }
        onFileChanged: rulesFile.reload()
    }

    FileView {
        id: rules6File
        path: "/etc/ufw/user6.rules"
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.v6Text = rules6File.text()
            root.rebuild()
        }
        onFileChanged: rules6File.reload()
    }

    // ── Checking input ──────────────────────────────────────────────────
    // A port, a range a:b, or "" for any; 1 to 65535.
    function portOk(text) {
        const m = /^(\d{1,5})(?::(\d{1,5}))?$/.exec(String(text || ""))
        if (!m)
            return false
        const a = Number(m[1])
        const b = m[2] === undefined ? a : Number(m[2])
        return a >= 1 && b <= 65535 && a <= b
    }

    // An IPv4 or IPv6 address, optionally with a /prefix.
    function addrOk(text) {
        const s = String(text || "")
        const v4 = /^(25[0-5]|2[0-4]\d|1?\d?\d)(\.(25[0-5]|2[0-4]\d|1?\d?\d)){3}(\/([0-9]|[12]\d|3[0-2]))?$/
        const v6 = /^[0-9A-Fa-f:]{2,39}(\/([0-9]|[1-9]\d|1[01]\d|12[0-8]))?$/
        return v4.test(s) || (v6.test(s) && s.indexOf(":") >= 0)
    }

    // The ufw words for a rule: { action, port, proto, from }. Returns [] when
    // a value does not pass. Ranges need a protocol, as ufw requires.
    function ruleWords(r) {
        const action = String(r.action || "")
        const port = String(r.port || "").trim()
        const proto = String(r.proto || "any")
        const from = String(r.from || "").trim()
        if (root.actions.indexOf(action) < 0 || ["tcp", "udp", "any"].indexOf(proto) < 0)
            return []
        if (port.length && !root.portOk(port))
            return []
        if (port.indexOf(":") >= 0 && proto === "any")
            return []
        const anyFrom = !from.length || root.anyAddr(from)
        if (!anyFrom && !root.addrOk(from))
            return []
        if (!port.length && anyFrom)
            return []
        // Simple form: "allow 22/tcp".
        if (anyFrom)
            return [action, proto === "any" ? port : port + "/" + proto]
        const words = [action, "from", from, "to", "any"]
        if (port.length)
            words.push("port", port)
        if (proto !== "any")
            words.push("proto", proto)
        return words
    }

    // The words to delete a rule as listed (from the rule files).
    function deleteWords(r) {
        if (r.direction !== "in" || r.fromPort !== "any")
            return []
        return root.ruleWords({
            action: r.action,
            port: r.port === "any" ? "" : r.port,
            proto: r.proto,
            from: root.anyAddr(r.from) ? "" : r.from
        })
    }

    // ── Changing ────────────────────────────────────────────────────────
    function runUfw(words, done) {
        if (root.busy || !words.length)
            return false
        root.busy = true
        root.error = ""
        root.notice = ""
        ufwProc.done = done || ""
        ufwProc.command = ["pkexec", "/usr/bin/ufw"].concat(words)
        ufwProc.running = true
        return true
    }

    function setEnabled(on) {
        return root.runUfw(on ? ["--force", "enable"] : ["disable"], on ? "Firewall on." : "Firewall off.")
    }

    function toggle() {
        return root.setEnabled(!root.enabled)
    }

    function addRule(r) {
        const words = root.ruleWords(r)
        if (!words.length) {
            root.error = "Check the rule: a port (1–65535, or a range like 6000:6010 with TCP or UDP) and an address or anywhere."
            return false
        }
        return root.runUfw(words, "Rule added: ufw " + words.join(" "))
    }

    function deleteRule(r) {
        const words = root.deleteWords(r)
        if (!words.length) {
            root.error = "This rule is too detailed to delete here; use ufw status numbered and ufw delete in a terminal."
            return false
        }
        return root.runUfw(["delete"].concat(words), "Rule deleted.")
    }

    function describe() {
        if (!root.available)
            return "ufw is not installed"
        return (root.enabled ? "on" : "off") + "; incoming " + (root.policy.input || "?") + ", outgoing " + (root.policy.output || "?")
            + "; " + root.rules.length + (root.rules.length === 1 ? " rule" : " rules")
    }

    Process {
        id: ufwProc
        property string done: ""
        stdout: StdioCollector {
            id: ufwOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: ufwErr
            waitForEnd: true
        }
        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                root.notice = ufwProc.done
            } else if (code === 126 || code === 127) {
                root.error = code === 126 ? "Not changed: the password was cancelled." : "pkexec is not available."
            } else {
                const said = [String(ufwErr.text || ""), String(ufwOut.text || "")].join(" ").trim()
                root.error = "ufw refused: " + (said.length ? said.substring(0, 240) : "exit " + code)
            }
            root.reloadAll()
        }
    }

    // qs ipc call firewall status     on or off, policies, rule count
    // qs ipc call firewall enable | disable | toggle   asks for your password
    IpcHandler {
        target: "firewall"
        function status(): string { return root.describe() }
        function enable(): string { return root.setEnabled(true) ? "asking for your password" : "busy" }
        function disable(): string { return root.setEnabled(false) ? "asking for your password" : "busy" }
        function toggle(): string { return root.toggle() ? "asking for your password" : "busy" }
    }
}
