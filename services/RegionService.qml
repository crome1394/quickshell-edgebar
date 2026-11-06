pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Time zones for Settings → Region. The list is read once, when that tab opens.
Singleton {
    id: root

    property bool loaded: false
    property bool loading: false
    property bool applying: false
    property var zones: []
    property string currentId: ""
    property string status: ""
    property string error: ""
    property string queuedId: ""

    function zoneById(id) {
        const want = String(id || "")
        if (!want.length)
            return null
        const list = root.zones || []
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].id === want)
                return list[i]
        }
        return null
    }

    function ensureLoaded() {
        root.refreshCurrent()
        if (root.loaded || listProc.running)
            return
        root.loading = true
        root.error = ""
        listProc.running = true
    }

    function refreshCurrent() {
        if (currentProc.running)
            return
        currentProc.running = true
    }

    function takeZones(text) {
        let parsed = []
        try {
            parsed = JSON.parse(String(text || ""))
        } catch (e) {
            parsed = []
        }
        const out = []
        if (parsed && parsed.length !== undefined) {
            for (let i = 0; i < parsed.length; i++) {
                const row = parsed[i]
                if (!row || typeof row.id !== "string")
                    continue
                out.push(row)
            }
        }
        root.zones = out
        root.loaded = out.length > 0
        root.loading = false
        if (!out.length)
            root.error = "No time zones found"
    }

    function applyZone(id) {
        const zone = root.zoneById(id)
        if (!zone || root.applying)
            return
        root.applying = true
        root.error = ""
        root.status = "Setting " + zone.id + "…"
        root.queuedId = zone.id
        applyDelay.restart()
    }

    function finishApply(code, errText) {
        root.applying = false
        const zone = root.zoneById(root.queuedId)
        if (code === 0 && zone) {
            root.currentId = zone.id
            root.status = "Region set to " + zone.id
            root.error = ""
            return
        }
        const message = String(errText || "").trim()
        root.status = ""
        root.error = message.length ? message.slice(0, 180) : "Could not set the time zone"
    }

    Timer {
        id: applyDelay
        interval: Theme.regionApplyDelayMs
        repeat: false
        onTriggered: {
            const zone = root.zoneById(root.queuedId)
            if (!zone) {
                root.applying = false
                return
            }
            setProc.running = false
            setProc.command = ["timedatectl", "set-timezone", zone.id]
            setProc.running = true
        }
    }

    Process {
        id: listProc
        command: ["python3", Quickshell.shellDir + "/scripts/region-zones.py"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: (code) => {
            if (code === 0)
                root.takeZones(listOut.text)
            else {
                root.loading = false
                root.loaded = false
                root.error = "Could not read time zones"
            }
        }
    }

    Process {
        id: currentProc
        command: ["timedatectl", "show", "-p", "Timezone", "--value"]
        stdout: StdioCollector {
            id: currentOut
            waitForEnd: true
        }
        onExited: (code) => {
            if (code !== 0)
                return
            const id = String(currentOut.text || "").trim()
            if (id.length)
                root.currentId = id
        }
    }

    Process {
        id: setProc
        command: ["timedatectl", "--version"]
        stderr: StdioCollector {
            id: setErr
            waitForEnd: true
        }
        onExited: (code) => root.finishApply(code, setErr.text)
    }
}
