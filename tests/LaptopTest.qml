import QtQuick
import Quickshell
import qs.services
import "tests"

// BatteryService and BrightnessService helpers: picking the backlight,
// percent to raw levels, durations, and profile names.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const B = BrightnessService
        t.eq("firmware beats raw", B.pickDevice("intel_backlight|raw|96000\nacpi_video0|firmware|100\n").name, "acpi_video0")
        t.eq("raw alone", B.pickDevice("amdgpu_bl1|raw|255\n"), { name: "amdgpu_bl1", max: 255 })
        t.eq("same type: finer scale", B.pickDevice("a|raw|100\nb|raw|1000\n").name, "b")
        t.eq("odd names and zero max skipped", B.pickDevice("bad name|raw|10\nz|raw|0\n"), null)
        t.eq("nothing", B.pickDevice(""), null)

        const P = BatteryService
        t.eq("hours and minutes", P.duration(3 * 3600 + 600), "3 h 10 min")
        t.eq("minutes", P.duration(45 * 60), "45 min")
        t.eq("unknown", P.duration(0), "")
        t.eq("profile labels", [P.profileLabel("power-saver"), P.profileLabel("balanced"), P.profileLabel("performance")],
            ["Power saver", "Balanced", "Performance"])
        t.eq("unknown profile refused", P.setProfile("turbo; rm"), false)
        t.eq("desktop has no battery", P.summary(), P.present ? P.summary() : "no battery")
        t.done()
    }
}
