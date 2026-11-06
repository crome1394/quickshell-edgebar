pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import Quickshell.Networking

// Link facts and the few NetworkManager actions Quickshell.Networking does not
// cover. Referenced only by the network pill, so the module stays unloaded
// until that widget is on the bar.
Singleton {
    id: root

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/network.py"

    property int watchers: 0
    property bool popupOpen: false
    property bool fieldFocused: false
    property int tick: 0
    property bool airplaneOn: false
    property bool wiredOn: true
    property bool vpnOn: false
    property bool vpnTouched: false
    property string lastError: ""
    property string notice: ""
    property var facts: ({})
    property var vpnRows: []
    property var wiredRows: []
    property var wifiRows: []
    property bool wifiRadio: true
    property bool wwanRadio: true
    property int rxRate: 0
    property int txRate: 0
    property string wifiKey: ""
    property string wiredKey: ""
    property string rateIface: ""
    property var rateLast: null

    readonly property bool wifiOn: Networking.wifiEnabled

    function deviceValues() {
        const model = Networking.devices
        // qmllint disable missing-property
        const rows = model ? model.values : null
        // qmllint enable missing-property
        return rows || []
    }

    function networkValues(device) {
        const model = device ? device.networks : null
        // qmllint disable missing-property
        const rows = model ? model.values : null
        // qmllint enable missing-property
        return rows || []
    }

    function retain() {
        root.watchers += 1
        if (root.watchers === 1) {
            root.tick += 1
            root.refreshStatus()
        }
    }

    function release() {
        root.watchers = Math.max(0, root.watchers - 1)
        if (root.watchers === 0)
            root.setPopup(false)
    }

    function setPopup(open) {
        const next = !!open
        root.popupOpen = next
        if (next) {
            root.setScanner(Networking.wifiEnabled)
            root.refreshStatus()
            root.sampleRates()
            root.rebuildLists()
            return
        }
        root.setScanner(false)
        root.fieldFocused = false
        // Start fresh next time so the first rate is not averaged over the closed time.
        root.rateIface = ""
        root.rateLast = null
    }

    function setScanner(on) {
        const rows = root.deviceValues()
        const enabled = !!on
        for (let i = 0; i < rows.length; i++) {
            const device = rows[i]
            if (!device || device.type !== DeviceType.Wifi)
                continue
            device.scannerEnabled = enabled
        }
    }

    function percent(strength) {
        const value = Number(strength)
        if (isNaN(value) || value < 0)
            return 0
        if (value <= 1.01)
            return Math.round(value * 100)
        return Math.round(Math.min(100, value))
    }

    function bareIp(text) {
        const raw = String(text || "").split("/")[0].trim()
        return raw.split(" ")[0]
    }

    // device.address is the MAC on this NetworkManager setup. The bar only
    // shows a dotted IPv4, from the status facts when that read has arrived.
    function looksLikeIpv4(text) {
        const parts = String(text || "").split(".")
        if (parts.length !== 4)
            return false
        for (let i = 0; i < 4; i++) {
            const part = parts[i]
            if (!part.length || part.length > 3)
                return false
            for (let c = 0; c < part.length; c++) {
                const ch = part.charCodeAt(c)
                if (ch < 48 || ch > 57)
                    return false
            }
            if (Number(part) > 255)
                return false
        }
        return true
    }

    function formatRate(value) {
        const rate = Math.max(0, Number(value) || 0)
        if (rate < 1024)
            return Math.round(rate) + " B/s"
        if (rate < 1024 * 1024)
            return (rate / 1024).toFixed(1) + " KB/s"
        return (rate / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    function primary() {
        const rows = root.deviceValues()
        let wifi = null
        for (let i = 0; i < rows.length; i++) {
            const device = rows[i]
            if (!device)
                continue
            if (device.type === DeviceType.Wired && device.connected)
                return device
            if (device.type === DeviceType.Wifi && device.connected && !wifi)
                wifi = device
        }
        return wifi
    }

    function primaryIface() {
        const device = root.primary()
        return device ? String(device.name || "") : ""
    }

    function primaryAddress() {
        void root.tick
        const device = root.primary()
        if (!device)
            return ""
        const fact = root.factFor(device.name)
        const fromFact = fact ? root.bareIp(fact.ipv4) : ""
        if (root.looksLikeIpv4(fromFact))
            return fromFact
        const fromDevice = root.bareIp(device.address)
        if (root.looksLikeIpv4(fromDevice))
            return fromDevice
        return ""
    }

    function primaryLabel() {
        void root.tick
        const device = root.primary()
        if (!device || !device.connected)
            return ""
        const fact = root.factFor(device.name)
        if (fact && fact.connection)
            return String(fact.connection)
        if (device.type === DeviceType.Wifi) {
            const nets = root.networkValues(device)
            for (let i = 0; i < nets.length; i++) {
                if (nets[i] && nets[i].connected && nets[i].name)
                    return String(nets[i].name)
            }
        }
        return String(device.name || "")
    }

    function primarySignal() {
        void root.tick
        const device = root.primary()
        if (!device || device.type !== DeviceType.Wifi || !device.connected)
            return -1
        const nets = root.networkValues(device)
        for (let i = 0; i < nets.length; i++) {
            if (nets[i] && nets[i].connected)
                return root.percent(nets[i].signalStrength)
        }
        return -1
    }

    function vpnActive() {
        const rows = root.vpnRows || []
        for (let i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].active)
                return true
        }
        return false
    }

    function linkKind() {
        void root.tick
        if (root.airplaneOn)
            return "airplane"
        if (Networking.connectivity === NetworkConnectivity.Portal)
            return "portal"
        if (root.vpnActive())
            return "vpn"
        const device = root.primary()
        if (device && device.type === DeviceType.Wired && device.connected)
            return "wired"
        if (device && device.type === DeviceType.Wifi && device.connected)
            return "wifi"
        if (!Networking.wifiEnabled)
            return "wifioff"
        return "down"
    }

    function factFor(iface) {
        const map = root.facts
        if (!map)
            return null
        const row = map[String(iface || "")]
        return row || null
    }

    function networkOpen(net) {
        if (!net)
            return false
        const security = net.security
        return security === WifiSecurityType.Open || security === WifiSecurityType.Owe
    }

    function securityLabel(net) {
        if (!net)
            return ""
        if (root.networkOpen(net))
            return "Open"
        const label = String(WifiSecurityType.toString(net.security) || "")
        return label.length ? label : "Secured"
    }

    function linesFor(iface, security, signal) {
        void root.tick
        const fact = root.factFor(iface) || {}
        const out = []
        function add(label, value) {
            const text = String(value || "").trim()
            if (text.length && text !== "--")
                out.push({ label: label, value: text })
        }
        add("IPv4", fact.ipv4)
        add("IPv6", fact.ipv6)
        add("Gateway", fact.gateway)
        add("DNS", fact.dns)
        add("MAC", fact.mac)
        add("SSID", fact.ssid)
        add("Band", fact.band)
        add("Channel", fact.channel)
        add("Security", fact.security || security)
        if (Number(signal) >= 0)
            add("Signal", String(signal) + "%")
        add("Link", fact.speed)
        add("Addressing", fact.method)
        add("State", fact.state)
        add("MTU", fact.mtu)
        add("Device", iface)
        return out
    }

    function wifiIface() {
        const rows = root.deviceValues()
        for (let i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].type === DeviceType.Wifi)
                return String(rows[i].name || "")
        }
        return ""
    }

    function takeJson(text) {
        const raw = String(text || "").trim()
        if (!raw.length)
            return null
        try {
            return JSON.parse(raw)
        } catch (e) {
            return null
        }
    }

    function refreshStatus() {
        if (statusProc.running || root.watchers < 1)
            return
        statusProc.command = [root.scriptPath, "status"]
        statusProc.running = true
    }

    // Reads the kernel byte counters directly; the rate is the change since
    // the last poll. No process runs.
    function sampleRates() {
        if (!root.popupOpen)
            return
        const iface = root.primaryIface()
        if (!/^[A-Za-z0-9_.:-]{1,15}$/.test(iface) || iface.indexOf("..") >= 0) {
            root.rateIface = ""
            return
        }
        if (root.rateIface !== iface) {
            // New interface: take a baseline now and the first rate soon.
            root.rateIface = iface
            root.rateLast = null
            rateSoon.restart()
        }
        rxFile.reload()
        txFile.reload()
        const rx = Number(String(rxFile.text()).trim())
        const tx = Number(String(txFile.text()).trim())
        const now = Date.now()
        const last = root.rateLast
        root.rateLast = { rx: rx, tx: tx, at: now }
        if (!last || !(rx >= 0) || !(tx >= 0) || now <= last.at)
            return
        const secs = (now - last.at) / 1000
        root.rxRate = Math.max(0, Math.round((rx - last.rx) / secs))
        root.txRate = Math.max(0, Math.round((tx - last.tx) / secs))
    }

    function run(args) {
        if (actionProc.running) {
            root.lastError = "Busy"
            return
        }
        root.lastError = ""
        root.notice = ""
        const command = [root.scriptPath]
        for (let i = 0; i < args.length; i++)
            command.push(String(args[i]))
        actionProc.command = command
        actionProc.running = true
    }

    function noteChange() {
        root.tick += 1
        refreshSoon.restart()
    }

    function applyStatus(payload) {
        const devices = payload.devices || []
        const map = {}
        for (let i = 0; i < devices.length; i++) {
            const row = devices[i]
            if (row && row.iface)
                map[String(row.iface)] = row
        }
        root.facts = map
        root.vpnRows = payload.vpns || []
        root.wifiRadio = !!payload.wifiRadio
        root.wwanRadio = !!payload.wwanRadio
        if (!root.vpnTouched && root.vpnActive())
            root.vpnOn = true
        root.tick += 1
    }

    function rebuildLists() {
        if (root.fieldFocused)
            return
        const devices = root.deviceValues()
        const wired = []
        for (let i = 0; i < devices.length; i++) {
            if (devices[i] && devices[i].type === DeviceType.Wired)
                wired.push(devices[i])
        }
        let wiredSig = ""
        for (let i = 0; i < wired.length; i++)
            wiredSig += String(wired[i].name || "") + "\n"
        if (wiredSig !== root.wiredKey) {
            root.wiredKey = wiredSig
            root.wiredRows = wired
        }

        const found = []
        const seen = {}
        for (let i = 0; i < devices.length; i++) {
            const device = devices[i]
            if (!device || device.type !== DeviceType.Wifi)
                continue
            const nets = root.networkValues(device)
            for (let j = 0; j < nets.length; j++) {
                const net = nets[j]
                if (!net)
                    continue
                const name = String(net.name || "")
                if (!name.length || seen[name])
                    continue
                seen[name] = true
                found.push(net)
            }
        }
        found.sort(function(a, b) {
            const ac = a.connected ? 1 : 0
            const bc = b.connected ? 1 : 0
            if (ac !== bc)
                return bc - ac
            return root.percent(b.signalStrength) - root.percent(a.signalStrength)
        })
        let wifiSig = ""
        for (let i = 0; i < found.length; i++) {
            const net = found[i]
            wifiSig += String(net.name || "") + ":" + (net.connected ? "1" : "0") + ":" + (net.known ? "1" : "0") + "\n"
        }
        if (wifiSig !== root.wifiKey) {
            root.wifiKey = wifiSig
            root.wifiRows = found
        }
    }

    function setWifi(on) {
        const next = !!on
        if (next)
            root.airplaneOn = false
        Networking.wifiEnabled = next
        if (root.popupOpen)
            root.setScanner(next)
    }

    function toggleWifi() {
        root.setWifi(!Networking.wifiEnabled)
    }

    function setAirplane(on) {
        const next = !!on
        if (root.airplaneOn === next)
            return
        root.airplaneOn = next
        root.run(["radio", next ? "off" : "on"])
    }

    function setWired(on) {
        const next = !!on
        root.wiredOn = next
        const rows = root.deviceValues()
        const names = []
        for (let i = 0; i < rows.length; i++) {
            const device = rows[i]
            if (!device || device.type !== DeviceType.Wired)
                continue
            const name = String(device.name || "")
            if (!name.length)
                continue
            if (next && !device.connected)
                names.push(name)
            if (!next && device.connected)
                names.push(name)
        }
        if (names.length)
            root.run(["device", next ? "connect" : "disconnect"].concat(names))
    }

    function setVpn(on) {
        const next = !!on
        root.vpnTouched = true
        root.vpnOn = next
        if (next)
            return
        const rows = root.vpnRows || []
        const ids = []
        for (let i = 0; i < rows.length; i++) {
            if (rows[i] && rows[i].active && rows[i].uuid)
                ids.push(String(rows[i].uuid))
        }
        if (ids.length)
            root.run(["vpn", "down"].concat(ids))
    }

    function toggleVpn(uuid, active) {
        const id = String(uuid || "")
        if (!id.length)
            return
        root.run(["vpn", active ? "down" : "up", id])
    }

    function connectIface(iface) {
        const name = String(iface || "")
        if (!name.length)
            return
        root.run(["device", "connect", name])
    }

    function connectHidden(ssid, psk) {
        const iface = root.wifiIface()
        if (!iface.length) {
            root.lastError = "No Wi-Fi device"
            return
        }
        const args = ["hidden", iface, String(ssid || "")]
        const secret = String(psk || "")
        if (secret.length)
            args.push(secret)
        root.run(args)
    }

    function refreshIp() {
        const iface = root.primaryIface()
        if (!iface.length) {
            root.lastError = "No active device"
            return
        }
        root.run(["reapply", iface])
    }

    function flushDns() {
        root.run(["flush-dns"])
    }

    function openEditor() {
        root.run(["editor"])
    }

    function finishAction(text) {
        const payload = root.takeJson(text)
        if (!payload || payload.ok === false) {
            root.lastError = payload && payload.error ? String(payload.error) : "Network action failed"
            return
        }
        root.lastError = ""
        root.notice = String(payload.message || "")
        root.refreshStatus()
    }

    Timer {
        id: faceTimer
        interval: Theme.networkFaceMs
        repeat: true
        running: root.watchers > 0 && !root.popupOpen
        onTriggered: root.tick += 1
    }

    Timer {
        id: pollTimer
        interval: Theme.networkPollMs
        repeat: true
        running: root.popupOpen
        onTriggered: {
            root.refreshStatus()
            root.sampleRates()
        }
    }

    Timer {
        id: rateSoon
        interval: Theme.networkRateFirstMs
        repeat: false
        onTriggered: root.sampleRates()
    }

    Timer {
        id: refreshSoon
        interval: Theme.networkRefreshMs
        repeat: false
        onTriggered: root.refreshStatus()
    }

    Process {
        id: statusProc
        command: [root.scriptPath, "status"]
        stdout: StdioCollector {
            id: statusOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: statusErr
            waitForEnd: true
        }
        onExited: (code) => {
            const payload = root.takeJson(statusOut.text)
            if (code !== 0 || !payload || payload.ok === false) {
                const message = payload && payload.error ? String(payload.error) : String(statusErr.text || "").trim()
                root.lastError = message.length ? message.slice(0, 180) : "NetworkManager is not available"
                return
            }
            root.applyStatus(payload)
        }
    }

    Process {
        id: actionProc
        command: ["true"]
        stdout: StdioCollector {
            id: actionOut
            waitForEnd: true
        }
        onExited: (_code) => root.finishAction(actionOut.text)
    }

    FileView {
        id: rxFile
        blockLoading: true
        path: root.rateIface.length ? "/sys/class/net/" + root.rateIface + "/statistics/rx_bytes" : ""
    }

    FileView {
        id: txFile
        blockLoading: true
        path: root.rateIface.length ? "/sys/class/net/" + root.rateIface + "/statistics/tx_bytes" : ""
    }

    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (Networking.wifiEnabled)
                root.airplaneOn = false
            if (root.popupOpen)
                root.setScanner(Networking.wifiEnabled)
            root.tick += 1
        }
        function onConnectivityChanged() {
            root.tick += 1
        }
    }

    onTickChanged: root.rebuildLists()
    onFieldFocusedChanged: {
        if (!root.fieldFocused)
            root.rebuildLists()
    }
}
