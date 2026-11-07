import QtQuick
import Quickshell
import qs.config
import qs.services
import "tests"

// GpuService: parsing the card list, and which card Auto reads.
ShellRoot {
    Check { id: t }

    Component.onCompleted: {
        const G = GpuService
        const desktop = G.parse("card1|0x10de|nvidia|0000:01:00.0||\n")
        t.eq("one NVIDIA card", [desktop.length, desktop[0].vendor, desktop[0].source, desktop[0].bus], [1, "NVIDIA", "nvidia", "0000:01:00.0"])
        t.eq("single card is Auto", G.pick("auto", desktop).card, "card1")

        const laptop = G.parse("card0|0x10de|nvidia|0000:01:00.0|0|\n"
            + "card1|0x8086|i915|0000:00:02.0|1|\n"
            + "card2|0x1002|amdgpu|0000:03:00.0|0|/sys/class/drm/card2/device/hwmon/hwmon4\n"
            + "card1-eDP-1|x|y|z|1|\n"
            + "card9|0x1af4|virtio-pci|bad bus|0|/tmp/evil\n")
        t.eq("connectors skipped", laptop.length, 4)
        t.eq("Auto picks the boot display GPU", G.pick("auto", laptop).card, "card1")
        t.eq("Intel source", G.pick("auto", laptop).source, "intel")
        t.eq("a named card is kept", G.pick("card2", laptop).source, "amd")
        t.eq("AMD hwmon kept", G.pick("card2", laptop).hwmon, "/sys/class/drm/card2/device/hwmon/hwmon4")
        t.eq("unknown card falls back to Auto", G.pick("card7", laptop).card, "card1")
        t.eq("none reads nothing", G.pick("none", laptop), null)
        t.eq("bad fields dropped", [laptop[3].bus, laptop[3].hwmon, laptop[3].source], ["", "", ""])
        t.eq("no cards", G.pick("auto", []), null)

        t.eq("gpu choice normalizes", [StatsSettings.gpuCardNorm("card3"), StatsSettings.gpuCardNorm("../x"), StatsSettings.gpuCardNorm("none")], ["card3", "auto", "none"])
        t.done()
    }
}
