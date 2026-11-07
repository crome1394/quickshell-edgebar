pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Night light: warms the screen to cut blue light, with hyprsunset (it
// uses Hyprland's color transform, so it works on any GPU). hyprsunset
// runs only while the light is on; a new temperature restarts it. With a
// schedule, the light follows the start and end times; a toggle in
// between holds until the next scheduled switch.
//
//   qs ipc call nightLight toggle | on | off | temperature <K> | status
Singleton {
    id: root

    property bool available: false
    property bool checked: false
    property string error: ""

    // The manual choice, and whether it overrides the schedule right now.
    property bool manualOn: false
    property bool overriding: false
    property bool scheduledNow: false

    readonly property bool on: Config.nightSchedule && !root.overriding ? root.scheduledNow : root.manualOn
    readonly property int temp: NightLightSettings.temp()
    property int appliedTemp: root.temp

    // Look for hyprsunset again (it may have been installed since start).
    function recheck() {
        if (!root.available && !probe.running)
            probe.running = true
    }

    function setOn(next) {
        root.recheck()
        root.manualOn = !!next
        root.overriding = Config.nightSchedule
    }

    function toggle() {
        root.setOn(!root.on)
    }

    function setTemp(kelvin) {
        const n = Math.round(Number(kelvin))
        if (!(n >= Theme.nightTempMin && n <= Theme.nightTempMax))
            return false
        NightLightSettings.setTempLive(n)
        return true
    }

    function describe() {
        root.recheck()
        if (!root.available)
            return "hyprsunset is not installed"
        return (root.on ? "on at " : "off; set to ") + root.temp + " K" + (Config.nightSchedule ? " (schedule " + Config.nightStart + "–" + Config.nightEnd + ")" : "")
    }

    function checkSchedule() {
        const inside = NightLightSettings.inWindow(new Date(), Config.nightStart, Config.nightEnd)
        // Crossing a scheduled switch ends a manual override.
        if (inside !== root.scheduledNow)
            root.overriding = false
        root.scheduledNow = inside
    }

    Component.onCompleted: {
        root.checkSchedule()
        probe.running = true
    }

    Connections {
        target: Config
        function onNightScheduleChanged() {
            root.overriding = false
            root.checkSchedule()
        }
        function onNightStartChanged() {
            root.checkSchedule()
        }
        function onNightEndChanged() {
            root.checkSchedule()
        }
    }

    // Once a minute, only while a schedule is set.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: Config.nightSchedule
        onMinutesChanged: root.checkSchedule()
    }

    // Is hyprsunset installed? Fixed script, no input.
    Process {
        id: probe
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: (code) => {
            root.available = code === 0
            root.checked = true
        }
    }

    // Wait for the wheel to settle before restarting hyprsunset.
    Timer {
        id: settle
        interval: Theme.nightRestartMs
        onTriggered: root.appliedTemp = root.temp
    }

    onTempChanged: settle.restart()

    onAppliedTempChanged: {
        if (!sunset.running)
            return
        sunset.running = false
        Qt.callLater(() => sunset.running = Qt.binding(() => root.on && root.available))
    }

    Process {
        id: sunset
        running: root.on && root.available
        command: ["hyprsunset", "-t", String(root.appliedTemp)]
        stderr: StdioCollector {
            id: sunsetErr
            waitForEnd: true
        }
        onExited: (code) => {
            if (code !== 0 && root.on && root.available)
                root.error = "hyprsunset stopped (exit " + code + "): " + String(sunsetErr.text || "").trim().substring(0, 200)
            else
                root.error = ""
        }
    }

    // qs ipc call nightLight toggle           same as a left click
    // qs ipc call nightLight on | off
    // qs ipc call nightLight temperature 3500 Kelvin, 2500 to 6500
    // qs ipc call nightLight status
    IpcHandler {
        target: "nightLight"
        function toggle(): void { root.toggle() }
        function on(): void { root.setOn(true) }
        function off(): void { root.setOn(false) }
        function temperature(kelvin: int): string { return root.setTemp(kelvin) ? root.describe() : "temperature must be 2500 to 6500" }
        function status(): string { return root.describe() }
    }
}
