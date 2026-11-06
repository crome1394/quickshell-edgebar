pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sound cards and their profiles, read with `pactl -f json list cards`.
// Quickshell's PipeWire module has no profiles, so this fills the gap. It
// reads only when asked (the audio menu opens, or after a change). A node's
// "device.id" property is its card's index.
Singleton {
    id: root

    property var cards: []
    property string lastError: ""

    function refresh() {
        if (!listProc.running)
            listProc.running = true
    }

    function cardFor(node) {
        if (!node || !node.properties)
            return null
        const index = Number(node.properties["device.id"])
        return root.cards.find(c => c.index === index) || null
    }

    // Profiles the card can use now, for a dropdown.
    function choicesFor(card) {
        if (!card)
            return []
        return card.profiles.filter(p => p.available || p.name === card.active)
            .map(p => ({ id: p.name, label: p.description, tip: p.name }))
    }

    function setProfile(card, profile) {
        if (!card || setProc.running)
            return
        const name = String(profile || "")
        if (!card.profiles.some(p => p.name === name) || name === card.active)
            return
        root.lastError = ""
        setProc.command = ["pactl", "set-card-profile", String(card.index), name]
        setProc.running = true
    }

    Process {
        id: listProc
        command: ["pactl", "-f", "json", "list", "cards"]
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
        }
        onExited: {
            let parsed = []
            try {
                parsed = JSON.parse(String(listOut.text || "[]"))
            } catch (e) {
                parsed = []
            }
            const out = []
            for (let i = 0; i < (parsed.length || 0); i++) {
                const c = parsed[i] || {}
                const profiles = []
                for (const name in (c.profiles || {})) {
                    const p = c.profiles[name] || {}
                    profiles.push({ name: name, description: String(p.description || name), available: p.available !== false })
                }
                out.push({
                    index: Number(c.index),
                    name: String(c.name || ""),
                    description: String((c.properties && c.properties["device.description"]) || c.name || ""),
                    active: String(c.active_profile || ""),
                    profiles: profiles
                })
            }
            root.cards = out
        }
    }

    Process {
        id: setProc
        stderr: StdioCollector {
            id: setErr
            waitForEnd: true
        }
        onExited: (code) => {
            if (code !== 0)
                root.lastError = String(setErr.text || "Could not change the profile").trim().split("\n")[0]
            root.refresh()
        }
    }
}
