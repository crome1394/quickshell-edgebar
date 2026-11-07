pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.theme

// The laptop battery and power profile, from UPower and the power profiles
// service over D-Bus (Quickshell's native modules, no processes). `present`
// is false on a desktop, so the Battery pill hides itself.
//
// IPC (qs ipc call battery …), the same functions the pill uses:
//   status          "85% discharging, 3 h 10 min left · balanced"
//   setProfile <name>  power-saver, balanced, or performance
//   cycleProfile    the next profile, as a click on the pill
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!root.device && root.device.ready && root.device.isLaptopBattery && root.device.isPresent
    // UPower reports 0–1 in newer Quickshell, 0–100 in older.
    readonly property int percent: {
        if (!root.present)
            return 0
        const p = Number(root.device.percentage)
        return Math.round(Math.max(0, Math.min(100, p <= 1 ? p * 100 : p)))
    }
    readonly property bool charging: root.present && (root.device.state === UPowerDeviceState.Charging
        || root.device.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: root.present && root.device.state === UPowerDeviceState.FullyCharged
    readonly property bool low: root.present && !root.charging && root.percent <= Theme.batteryLowPercent
    // Seconds to empty while discharging, to full while charging; 0 unknown.
    readonly property int secondsLeft: !root.present ? 0
        : Math.max(0, Math.round(Number(root.charging ? root.device.timeToFull : root.device.timeToEmpty) || 0))

    readonly property var profiles: PowerProfiles.hasPerformanceProfile
        ? ["power-saver", "balanced", "performance"] : ["power-saver", "balanced"]
    readonly property string profile: root.profileName(PowerProfiles.profile)

    function profileName(value) {
        if (value === PowerProfile.PowerSaver)
            return "power-saver"
        if (value === PowerProfile.Performance)
            return "performance"
        return "balanced"
    }

    function profileLabel(name) {
        if (name === "power-saver")
            return "Power saver"
        if (name === "performance")
            return "Performance"
        return "Balanced"
    }

    // "3 h 10 min", "45 min", or "" when unknown.
    function duration(seconds) {
        const total = Math.round(Number(seconds) / 60)
        if (!(total > 0))
            return ""
        const h = Math.floor(total / 60)
        const m = total % 60
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    function glyph() {
        if (root.charging)
            return Theme.batteryChargingGlyph
        const list = Theme.batteryGlyphs
        return list[Math.max(0, Math.min(list.length - 1, Math.round(root.percent / 10)))]
    }

    function summary() {
        if (!root.present)
            return "no battery"
        const left = root.duration(root.secondsLeft)
        const state = root.full ? "full" : (root.charging ? "charging" : "on battery")
        return root.percent + "% " + state
            + (left.length && !root.full ? ", " + left + (root.charging ? " to full" : " left") : "")
    }

    // False for an unknown name or one this machine lacks.
    function setProfile(name) {
        const want = String(name || "")
        if (root.profiles.indexOf(want) < 0)
            return false
        PowerProfiles.profile = want === "power-saver" ? PowerProfile.PowerSaver
            : (want === "performance" ? PowerProfile.Performance : PowerProfile.Balanced)
        return true
    }

    function cycleProfile() {
        const list = root.profiles
        root.setProfile(list[(list.indexOf(root.profile) + 1) % list.length])
    }

    IpcHandler {
        target: "battery"

        function status(): string {
            return root.summary() + " · " + root.profile
        }

        function setProfile(name: string): string {
            return root.setProfile(name) ? "ok" : "unknown profile; use " + root.profiles.join(", ")
        }

        function cycleProfile(): string {
            root.cycleProfile()
            return root.profile
        }
    }
}
