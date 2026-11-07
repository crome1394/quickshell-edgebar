pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The graphics cards in /sys/class/drm, listed once when something first
// asks (the System Stats pill or its settings page), and which one the
// pill reads. Each card: { card, vendor, driver, bus, primary, hwmon, source }.
// `source` is how its load is read: "nvidia" (nvidia-smi), "amd" (sysfs),
// "intel" (frequency, as an estimate), or "" (not readable).
// Auto picks the only card, else the one the firmware booted the display
// on: the integrated GPU on a hybrid laptop, so the discrete one can sleep.
Singleton {
    id: root

    property var cards: []
    property bool checked: false

    readonly property var chosen: root.pick(Config.statGpu, root.cards)

    function vendorName(id) {
        if (id === "0x10de")
            return "NVIDIA"
        if (id === "0x1002")
            return "AMD"
        if (id === "0x8086")
            return "Intel"
        return "GPU"
    }

    function sourceFor(driver) {
        if (driver === "nvidia")
            return "nvidia"
        if (driver === "amdgpu")
            return "amd"
        if (driver === "i915" || driver === "xe")
            return "intel"
        return ""
    }

    // One line per card: card|vendor|driver|bus|boot_vga|hwmon dir.
    // Fields are checked here, so only sysfs paths and plain names pass.
    function parse(text) {
        const out = []
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const f = lines[i].split("|")
            if (f.length !== 6 || !/^card[0-9]{1,3}$/.test(f[0]))
                continue
            const hwmon = /^\/sys\/[A-Za-z0-9_.:\/-]+$/.test(f[5]) ? f[5] : ""
            out.push({
                card: f[0],
                vendor: root.vendorName(f[1]),
                driver: /^[A-Za-z0-9_-]{1,32}$/.test(f[2]) ? f[2] : "",
                bus: /^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]$/.test(f[3]) ? f[3] : "",
                primary: f[4] === "1",
                hwmon: hwmon,
                source: root.sourceFor(f[2])
            })
        }
        return out
    }

    // The card for a saved choice: "auto", "none", or a card name.
    function pick(choice, list) {
        const want = String(choice || "auto")
        if (want === "none" || !list || !list.length)
            return null
        if (want !== "auto") {
            const named = list.find((c) => c.card === want)
            if (named)
                return named
        }
        if (list.length === 1)
            return list[0]
        return list.find((c) => c.primary) || list[0]
    }

    // True when reading this card may keep a sleeping discrete GPU awake.
    function wakes(card) {
        return !!card && root.cards.length > 1 && !card.primary
    }

    function label(card) {
        if (!card)
            return "None"
        return card.vendor + " · " + card.card + (card.bus.length ? " · " + card.bus.replace(/^0000:/, "") : "")
    }

    // Fixed script, no outside input. Reads only cached PCI and sysfs
    // links (vendor, driver, boot_vga), which do not wake a sleeping GPU.
    Process {
        running: true
        command: ["sh", "-c",
            "for c in /sys/class/drm/card*; do "
            + "n=${c##*/}; case \"$n\" in *-*) continue;; esac; "
            + "d=\"$c/device\"; [ -r \"$d/vendor\" ] || continue; "
            + "h=''; for x in \"$d\"/hwmon/hwmon*; do [ -d \"$x\" ] && h=\"$x\" && break; done; "
            + "printf '%s|%s|%s|%s|%s|%s\\n' \"$n\" \"$(cat \"$d/vendor\")\" "
            + "\"$(basename \"$(readlink -f \"$d/driver\")\")\" \"$(basename \"$(readlink -f \"$d\")\")\" "
            + "\"$(cat \"$d/boot_vga\" 2>/dev/null)\" \"$h\"; done"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: {
            root.cards = root.parse(listOut.text)
            root.checked = true
        }
    }
}
